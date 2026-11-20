`timescale 1ns / 1ps
// =============================================================================
// Basys 3 top level - 16x16 Vedic multiplier demo
//
// Operation:
//   1. Power-up: set operand A on SW15..SW0 (shown live in hex on the display).
//        - BTNU (T18): save the switches into A and scroll A once in DECIMAL,
//                      then go back to the live hex view. Stays on operand A.
//        - BTNC (U18): store A and move on to operand B.
//   2. Same for operand B (BTNU previews B in decimal, BTNC stores B).
//   3. The 32-bit product scrolls across the four digits in hex
//      (8 digits, with a blank gap between repeats).
//   4. Press BTNC again to start over. BTND (U17) resets at any time.
//
// LEDs: LD0 = entering A, LD1 = entering B, LD2 = showing result,
//       LD3 = decimal preview scrolling.
//
// The multiplier itself is the unchanged sixteenMult from modules.v.
// The '*' operator is not used anywhere in this file.
// =============================================================================
module top #(
    parameter DEBOUNCE_BITS = 20,          // 2^20 cycles @ 100 MHz = ~10.5 ms
    parameter SCROLL_TICKS  = 40_000_000,  // 0.4 s per scroll step
    parameter REFRESH_BITS  = 19           // each digit lit for 2^17 cycles (~1.3 ms)
)(
    input  wire        clk,                // 100 MHz
    input  wire [15:0] sw,
    input  wire        btnC,               // next / confirm
    input  wire        btnU,               // save + show in decimal
    input  wire        btnD,               // reset
    output reg  [15:0] led,
    output reg  [6:0]  seg,                // active low, seg[0]=a ... seg[6]=g
    output wire        dp,                 // active low
    output reg  [3:0]  an                  // active low, an[3] = leftmost digit
);

    // -------------------------------------------------------------------------
    // Input synchronisers
    // -------------------------------------------------------------------------
    reg [15:0] sw_meta = 16'd0, sw_s = 16'd0;
    reg        rst_meta = 1'b0, rst = 1'b0;

    always @(posedge clk) begin
        sw_meta  <= sw;    sw_s <= sw_meta;
        rst_meta <= btnD;  rst  <= rst_meta;
    end

    wire next;      // one-clock pulse per BTNC press
    wire preview;   // one-clock pulse per BTNU press
    debounce #(.N(DEBOUNCE_BITS)) u_dbC (.clk(clk), .btn_in(btnC), .pulse(next));
    debounce #(.N(DEBOUNCE_BITS)) u_dbU (.clk(clk), .btn_in(btnU), .pulse(preview));

    // -------------------------------------------------------------------------
    // Operand registers + Vedic multiplier (unchanged)
    // -------------------------------------------------------------------------
    reg  [15:0] opA  = 16'd0;
    reg  [15:0] opB  = 16'd0;
    reg  [31:0] prod = 32'd0;
    wire [31:0] vedic_out;

    sixteenMult u_mult (.A(opA), .B(opB), .S(vedic_out));

    // -------------------------------------------------------------------------
    // States
    // -------------------------------------------------------------------------
    localparam S_A    = 2'd0,   // entering operand A
               S_B    = 2'd1,   // entering operand B
               S_CALC = 2'd2,   // let the combinational multiplier settle
               S_SHOW = 2'd3;   // scroll the product

    reg [1:0] state    = S_A;
    reg [3:0] wait_cnt = 4'd0;
    reg       dec_mode = 1'b0;  // 1 = decimal preview is scrolling

    // BTNU only does something while entering an operand
    wire entering  = (state == S_A) || (state == S_B);
    wire dec_start = preview && entering && !next;

    // -------------------------------------------------------------------------
    // Binary -> decimal (BCD) converter for the preview
    // -------------------------------------------------------------------------
    wire [19:0] bcd;            // 5 decimal digits, 4 bits each
    bin2bcd u_bcd (.clk(clk), .start(dec_start), .bin(sw_s), .bcd(bcd));

    // -------------------------------------------------------------------------
    // Scroll timer (shared by the decimal preview and the product display)
    // -------------------------------------------------------------------------
    reg  [26:0] scroll_cnt = 27'd0;
    reg  [3:0]  pos        = 4'd0;
    wire        tick       = (scroll_cnt == SCROLL_TICKS - 1);
    wire        scrolling  = (state == S_SHOW) || dec_mode;

    localparam DEC_LAST_POS  = 4'd9;    // decimal strip: 4 blank + 5 digits + 4 blank
    localparam PROD_LAST_POS = 4'd12;   // product strip: 4 blank + 8 digits + 4 blank

    always @(posedge clk) begin
        if (!scrolling || dec_start) begin      // idle, or (re)start from the beginning
            scroll_cnt <= 27'd0;
            pos        <= 4'd0;
        end else if (tick) begin
            scroll_cnt <= 27'd0;
            if (state == S_SHOW)
                pos <= (pos == PROD_LAST_POS) ? 4'd0 : pos + 1'b1;   // loop forever
            else
                pos <= pos + 1'b1;                                   // decimal: one pass
        end else begin
            scroll_cnt <= scroll_cnt + 1'b1;
        end
    end

    // -------------------------------------------------------------------------
    // Control FSM
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            state    <= S_A;
            opA      <= 16'd0;
            opB      <= 16'd0;
            prod     <= 32'd0;
            dec_mode <= 1'b0;
        end else begin
            case (state)
                S_A: if (next) begin                 // store A, move on
                         opA      <= sw_s;
                         dec_mode <= 1'b0;
                         state    <= S_B;
                     end else if (preview) begin     // store A, show it in decimal
                         opA      <= sw_s;
                         dec_mode <= 1'b1;
                     end
                S_B: if (next) begin                 // store B, move on
                         opB      <= sw_s;
                         dec_mode <= 1'b0;
                         wait_cnt <= 4'd0;
                         state    <= S_CALC;
                     end else if (preview) begin     // store B, show it in decimal
                         opB      <= sw_s;
                         dec_mode <= 1'b1;
                     end
                // Operands are held steady for 16 clocks before the product is
                // captured (matches the multicycle constraint in the .xdc).
                S_CALC: begin
                         wait_cnt <= wait_cnt + 1'b1;
                         if (wait_cnt == 4'd15) begin
                             prod  <= vedic_out;
                             state <= S_SHOW;
                         end
                     end
                S_SHOW: if (next) state <= S_A;
            endcase

            // Decimal preview finished its single pass -> back to live hex
            if (dec_mode && tick && pos == DEC_LAST_POS && !dec_start && !next)
                dec_mode <= 1'b0;
        end
    end

    // -------------------------------------------------------------------------
    // Character lookup functions. Each returns {blank, value}.
    // -------------------------------------------------------------------------
    // Product strip, 16 chars: [0..3] blank, [4..11] hex digits MSB first, [12..15] blank
    function [4:0] prod_at;
        input [4:0]  idx;
        input [31:0] p;
        reg   [2:0]  j;
        reg   [31:0] shifted;
        begin
            if (idx < 5'd4 || idx > 5'd11)
                prod_at = 5'b10000;                       // blank
            else begin
                j       = idx - 5'd4;                     // 0 = most significant digit
                shifted = p >> {(3'd7 - j), 2'b00};
                prod_at = {1'b0, shifted[3:0]};
            end
        end
    endfunction

    // Decimal strip, 13 chars: [0..3] blank, [4..8] decimal digits MSD first, [9..12] blank
    // Leading zeros are blanked (so 11 shows as "11", not "00011").
    function [4:0] dec_at;
        input [4:0]  idx;
        input [19:0] d;
        reg   [2:0]  k;
        reg   [19:0] upper;     // this digit and every digit to its left
        begin
            if (idx < 5'd4 || idx > 5'd8)
                dec_at = 5'b10000;                        // blank
            else begin
                k     = idx - 5'd4;                       // 0 = ten-thousands digit
                upper = d >> {(3'd4 - k), 2'b00};
                if (upper == 20'd0 && k != 3'd4)          // leading zero (keep last digit)
                    dec_at = 5'b10000;
                else
                    dec_at = {1'b0, upper[3:0]};
            end
        end
    endfunction

    // -------------------------------------------------------------------------
    // Seven-segment multiplexing
    // -------------------------------------------------------------------------
    reg  [REFRESH_BITS-1:0] refresh = 0;
    always @(posedge clk) refresh <= refresh + 1'b1;

    wire [1:0]  digit      = refresh[REFRESH_BITS-1 -: 2];   // 0 = rightmost
    wire [15:0] sw_shifted = sw_s >> {digit, 2'b00};
    wire [4:0]  strip_idx  = {1'b0, pos} + (5'd3 - digit);   // leftmost digit shows strip[pos]
    reg  [4:0]  code;                                        // {blank, nibble}

    always @(*) begin
        if (state == S_SHOW)
            code = prod_at(strip_idx, prod);                 // product, hex, looping
        else if (dec_mode)
            code = dec_at(strip_idx, bcd);                   // operand, decimal, one pass
        else if (entering)
            code = {1'b0, sw_shifted[3:0]};                  // live switch value, hex
        else
            code = 5'b10000;
    end

    always @(*) begin
        an = ~(4'b0001 << digit);
        if (code[4])
            seg = 7'b1111111;                         // blank
        else case (code[3:0])                         //   gfedcba
            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
            4'hA: seg = 7'b0001000;
            4'hB: seg = 7'b0000011;
            4'hC: seg = 7'b1000110;
            4'hD: seg = 7'b0100001;
            4'hE: seg = 7'b0000110;
            4'hF: seg = 7'b0001110;
        endcase
    end

    assign dp = 1'b1;   // decimal points off

    always @(*) begin
        led    = 16'd0;
        led[0] = (state == S_A);
        led[1] = (state == S_B);
        led[2] = (state == S_SHOW);
        led[3] = dec_mode;
    end

endmodule


// =============================================================================
// Binary to BCD converter (sequential "double dabble", shift-and-add-3).
// After a start pulse it takes 16 clocks; bcd then holds 5 decimal digits:
//   bcd[19:16] = ten-thousands ... bcd[3:0] = units.
// Uses only comparisons, +3 and shifts - no multiply or divide.
// =============================================================================
module bin2bcd (
    input  wire        clk,
    input  wire        start,
    input  wire [15:0] bin,
    output reg  [19:0] bcd = 20'd0
);
    reg [15:0] sh   = 16'd0;    // binary bits still to shift in
    reg [19:0] acc  = 20'd0;    // BCD being built up
    reg [4:0]  n    = 5'd0;     // shift counter
    reg        busy = 1'b0;

    // Combinational step: add 3 to every BCD digit that is 5 or more
    wire [19:0] adj;
    assign adj[3:0]   = (acc[3:0]   >= 4'd5) ? acc[3:0]   + 4'd3 : acc[3:0];    // units
    assign adj[7:4]   = (acc[7:4]   >= 4'd5) ? acc[7:4]   + 4'd3 : acc[7:4];    // tens
    assign adj[11:8]  = (acc[11:8]  >= 4'd5) ? acc[11:8]  + 4'd3 : acc[11:8];   // hundreds
    assign adj[15:12] = (acc[15:12] >= 4'd5) ? acc[15:12] + 4'd3 : acc[15:12];  // thousands
    assign adj[19:16] = (acc[19:16] >= 4'd5) ? acc[19:16] + 4'd3 : acc[19:16];  // ten-thousands

    always @(posedge clk) begin
        if (start) begin
            sh   <= bin;
            acc  <= 20'd0;
            n    <= 5'd0;
            busy <= 1'b1;
        end else if (busy) begin
            // shift {acc, sh} left by one, using the adjusted digits
            acc <= {adj[18:0], sh[15]};
            sh  <= {sh[14:0], 1'b0};
            n   <= n + 1'b1;
            if (n == 5'd15) begin
                busy <= 1'b0;
                bcd  <= {adj[18:0], sh[15]};   // final (16th) shift
            end
        end
    end
endmodule


// =============================================================================
// Button debouncer: synchroniser + stable-for-2^N-cycles filter.
// Outputs a single-clock pulse on each press.
// =============================================================================
module debounce #(parameter N = 20) (
    input  wire clk,
    input  wire btn_in,
    output reg  pulse
);
    reg         s0 = 1'b0, s1 = 1'b0;
    reg         stable = 1'b0;
    reg [N-1:0] cnt = 0;

    always @(posedge clk) begin
        s0    <= btn_in;
        s1    <= s0;
        pulse <= 1'b0;
        if (s1 == stable)
            cnt <= 0;
        else begin
            cnt <= cnt + 1'b1;
            if (&cnt) begin
                stable <= s1;
                cnt    <= 0;
                if (s1) pulse <= 1'b1;   // rising edge = press
            end
        end
    end
endmodule
