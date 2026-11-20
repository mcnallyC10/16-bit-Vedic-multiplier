`timescale 1ns / 1ps
module top #(
    parameter DEBOUNCE_BITS = 20,          // 2^20 cycles @ 100 MHz = ~10.5 ms
    parameter SCROLL_TICKS  = 40_000_000,  // 0.4 s per scroll step
    parameter REFRESH_BITS  = 19           // each digit lit for 2^17 cycles (~1.3 ms)
)(
    input  wire        clk,                // 100 MHz
    input  wire [15:0] sw,
    input  wire        btnC,               // next / confirm
    input wire         btnD,               //decimal
    input  wire        btnU,               // reset
    output reg  [15:0] led,
    output reg  [6:0]  seg,                // active low, seg[0]=a ... seg[6]=g
    output reg  [3:0]  an                  // active low, an[3] = leftmost digit
);

wire next;   // one-clock pulse per button press
    debounce #(.N(DEBOUNCE_BITS)) u_db (.clk(clk), .btn_in(btnC), .pulse(next));

    reg [15:0] switches = 16'd0;
    reg        rst = 1'b0;
    reg        dec = 1'b0;

    always @(posedge clk) begin
        switches  <= sw;
        rst <= btnU;
        dec <= btnD;
    end

    // Operand registers + Vedic multiplier
    reg  [15:0] opA  = 16'd0;
    reg  [15:0] opB  = 16'd0;
    reg  [31:0] prod = 32'd0;
    wire [31:0] vedic_out;

    sixteenMult u_mult (.A(opA), .B(opB), .S(vedic_out));

    // -------------------------------------------------------------------------
    // Control FSM
    // -------------------------------------------------------------------------
    localparam S_A    = 2'd0,   // entering operand A
               S_B    = 2'd1,   // entering operand B
               S_CALC = 2'd2,   // let the combinational multiplier settle
               S_SHOW = 2'd3;   // scroll the product

    reg [1:0] state    = S_A;

    always @(posedge clk) begin
        if (rst) begin //reset
            state <= S_A;
            opA   <= 16'd0;
            opB   <= 16'd0;
            prod  <= 32'd0;
        end else begin
            case (state)
                S_A: if (next) begin
                         opA   <= switches;
                         state <= S_B;
                     end
                        
                        
                S_B: if (next) begin
                         opB      <= switches;
                         state    <= S_CALC;
                     end 
                S_CALC: begin
                            prod  <= vedic_out;
                            state <= S_SHOW;
                     end
                S_SHOW: if (next) state <= S_A;
            endcase
        end
    end

    // -------------------------------------------------------------------------
    // Scroll position: window of 4 over a 16-character buffer
    //   buffer[0..3]   = blank
    //   buffer[4..11]  = product hex digits, MSB first
    //   buffer[12..15] = blank
    //   pos = index of the leftmost displayed character, 0..12
    // -------------------------------------------------------------------------
    reg [26:0] scroll_cnt = 27'd0;
    reg [3:0]  pos        = 4'd0;

    always @(posedge clk) begin
        if (state != S_SHOW) begin
            scroll_cnt <= 27'd0;
            pos        <= 4'd0;
        end else if (scroll_cnt == SCROLL_TICKS - 1) begin
            scroll_cnt <= 27'd0;
            pos        <= (pos == 4'd12) ? 4'd0 : pos + 1'b1;
        end else begin
            scroll_cnt <= scroll_cnt + 1'b1;
        end
    end


    // Character at buffer index idx: {blank, hex nibble}
    function [4:0] buf_at;
        input [4:0]  idx;
        input [31:0] p;
        reg   [2:0]  j;
        reg   [31:0] shifted;
        begin
            if (idx < 5'd4 || idx > 5'd11)
                buf_at = 5'b10000;                        // blank
            else begin
                j       = idx - 5'd4;                     // 0 = most significant digit
                shifted = p >> {(3'd7 - j), 2'b00};
                buf_at  = {1'b0, shifted[3:0]};
            end
        end
    endfunction
    
    // -------------------------------------------------------------------------
    // Seven-segment multiplexor
    // -------------------------------------------------------------------------
    reg  [REFRESH_BITS-1:0] refresh = 0;
    always @(posedge clk) refresh <= refresh + 1'b1;

    wire [1:0]  digit = refresh[REFRESH_BITS-1 -: 2];   // 0 = rightmost
    wire [15:0] sw_shifted = switches >> {digit, 2'b00};
    reg  [4:0]  code;                                   // {blank, nibble}

    always @(*) begin
        case (state)
            S_A, S_B: code = {1'b0, sw_shifted[3:0]};               // live switch value
            S_SHOW:   code = buf_at({1'b0, pos} + (5'd3 - digit), prod);
            default:  code = 5'b10000;
        endcase
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

// -------------------------------------------------------------------------
// leds
// -------------------------------------------------------------------------
    always @(*) begin
        led    = 16'd0;
        led[0] = (state == S_A);
        led[1] = (state == S_B);
        led[2] = (state == S_SHOW);
    end

endmodule

// -------------------------------------------------------------------------
// debouncer for buttons
// -------------------------------------------------------------------------
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
