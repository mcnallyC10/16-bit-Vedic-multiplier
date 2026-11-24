`timescale 1ns / 1ps
module top #(
    parameter DEBOUNCE_BITS = 20,          // 2^20 cycles @ 100 MHz = ~10.5 ms
    parameter SCROLL_TICKS  = 40_000_000,  // 0.4 s per scroll step
    parameter REFRESH_BITS  = 19           // each digit lit for 2^17 cycles (~1.3 ms)
)(
    input  wire        clk,                // 100 MHz
    input  wire [15:0] sw,
    input  wire        btnC,               // next / confirm
    input  wire        btnD,               // decimal
    input  wire        btnU,               // reset#
    input  wire        btnR,               // right
    input  wire        btnL,               // left
    output reg  [15:0] led,
    output reg  [6:0]  seg,                // active low, seg[0]=a ... seg[6]=g
    output reg  [3:0]  an        // active low, an[3] = leftmost digit
);
    // one-clock pulse per button press
    wire next;   
    wire base;
    wire scrollRight;   
    wire scrollLeft;
    
    /*
    The reset button does not need a debouncer.
    As it does not matter if we reset it more then once from bouncing
    */
    debounce #(.N(DEBOUNCE_BITS)) c_db (.clk(clk), .btn_in(btnC), .pulse(next));
    debounce #(.N(DEBOUNCE_BITS)) d_db (.clk(clk), .btn_in(btnD), .pulse(base));
    debounce #(.N(DEBOUNCE_BITS)) r_db (.clk(clk), .btn_in(btnR), .pulse(scrollRight));
    debounce #(.N(DEBOUNCE_BITS)) l_db (.clk(clk), .btn_in(btnL), .pulse(scrollLeft));

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
    wire [19:0] sw_bcd;
    wire [39:0] vedic_bcd;

    sixteenMult u_mult (.A(opA), .B(opB), .S(vedic_out));
    
    //converts the binary of the switches and the vedic respectively to binary converted decimal.
    binToBcd #(.n(16)) sw_bin_bcd(sw, sw_bcd); //16 switches = 16 bits -> n = 16
    binToBcd #(.n(32)) vedic_bin_bcd(vedic_out, vedic_bcd); //32 bit output -> n=32

    // -------------------------------------------------------------------------
    // Control FSM
    // -------------------------------------------------------------------------
    localparam S_A    = 2'd0,   // entering operand A
               S_B    = 2'd1,   // entering operand B
               S_CALC = 2'd2,   // let the combinational multiplier settle
               S_SHOW = 2'd3;   // scroll the product

    reg [1:0] state    = S_A;
    //stores whether we should display in hex numbers or in decimal numbers. 0 for hex, 1 for decimal.
    reg hexOrDecimal   = 1'b0;
    
    //   pos = index of the leftmost displayed character, 0..12 for hex. 0-15 for decimal
    reg [3:0]  pos;

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
        if(base) begin
        hexOrDecimal <= ~hexOrDecimal;
        pos = 0;
        end
        else begin end
    end

    // -------------------------------------------------------------------------
    // Scroll position: window of 4 over a 16-character buffer
    //   buffer[0..3]   = blank
    //   buffer[4..11]  = product hex digits, MSB first
    //   buffer[12..15] = blank
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        /*
        if our current state is not set to scroll and show the numbers, 
        then we reset to 0 for the pos
        */
        if (state != S_SHOW) begin
            pos        <= 0;
        end
        else begin end
        if(hexOrDecimal == 1'b0) begin
            if(scrollRight) begin
                pos <= (pos == 4'd12) ? 0 : pos + 1;
             end
            else if(scrollLeft) begin
                pos <= (pos == 4'd0) ? 4'd12 : pos - 1;
            end
        else begin end
        end else begin 
            if(scrollRight) begin
                pos <= (pos == 4'd15) ? 0 : pos + 1;
             end
            else if(scrollLeft) begin
                pos <= (pos == 4'd0) ? 4'd15 : pos - 1;
            end
        end
    end


    // Character at buffer index: {blank, hex nibble}
    function [4:0] buf_at;
        input [4:0]  index; //4 bits to store 8 possible 
        input [31:0] p; //p = product of the multiplication
        
        /*
        this is our normalized index. Which ignores all padding. We use this to figure out the purely hex numbers.
        Ex: if our hex number was 0_12345678_0000. j would only store 12345678. As it removes the first 4. And drops the bits for the last 1.
        The code doing this normalizaton is found below.
        */
        reg   [2:0]  j; 
        reg   [31:0] shifted;
        
        begin
        /*
        if our index is less then 4. or if it greater then 11. 
        We return 0. This is the padding we add to make the product more readable.
        */
            if (index < 5'd4 || index > 5'd11)
                buf_at = 5'b1_0000;// blank on the display
            else begin
                //normalize our index.
                j = index - 5'd4; // 0 = most significant digit here. As we scroll by showing the larger hex number first
                /*
                shifts the product by 2 bits, and then by 7-j. 
                This shifts the product we're looking for to indices 0-3, for easy access.
                */
                shifted = p >> {(3'd7 - j), 2'b00};
                //return the hex number found at the given index. 
                //concatenate 0 with the hex digit, as 0 means a number is to be shown. 1 means blank
                buf_at  = {1'b0, shifted[3:0]}; 
            end
        end
    endfunction
    
    function [4:0] decimalAt;
    input [4:0] index;
    input [39:0] bcd;
    
    reg [3:0] j;
    reg [39:0] shifted;
    
    begin
        if (index < 5'd2 || index > 5'd12)
                decimalAt = 5'b1_0000;// blank on the display
        else begin
            j = index - 5'd2;
            shifted = bcd >> {(3'd7 - j), 2'b00};
            decimalAt = {1'b0,shifted[3:0]};
        end
    end
    
    endfunction
    // -------------------------------------------------------------------------
    // Seven-segment multiplexor
    // -------------------------------------------------------------------------
    
    /*
     refresh every Refresh bits, we cycle through each seven segment (4 in total)
     and refresh the number to ensure it is the correct one. 
    */
    
    reg  [REFRESH_BITS-1:0] refresh = 0;
    always @(posedge clk) refresh <= refresh + 1'b1;
       
    /*
    we take the 2 most significant bits (most signiciant or least significant does not matter here)
    we take those 2 bits as a 2^2 number, 4 segments total. This lets us decide which seven segment display to refresh.
    */
    wire [1:0]  digit = refresh[REFRESH_BITS-1 -: 2];  
    wire [15:0] sw_shifted = switches >> {digit, 2'b00}; // this is the switch number to be displayed on the 7 segment display
    reg  [4:0]  code; // {blank, nibble} where blank tells us if we should display a blank integer, and nibble is our number.

    always @(*) begin
    case (hexOrDecimal)
        0: case (state)
            S_A, S_B: code = {1'b0, sw_shifted[3:0]};  // live switch value
            //grab the number at the index specified.
            S_SHOW:   code = buf_at({1'b0, pos} + (5'd3 - digit), prod);
            default:  code = 5'b10000;
        endcase
        1: case (state)
            S_A, S_B: code = decimalAt({1'b0, pos} + (5'd3 - digit), {16'b0, sw_bcd});
            //grab the number at the index specified.
            S_SHOW:   code = decimalAt({1'b0, pos} + (5'd3 - digit), vedic_bcd);
            default:  code = 5'b10000;
         endcase
         default: code = 5'b10000; //should never happen. Unless pos magically became x or z
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
        //led 3 = hex on
        //led 4 = decimal on
        led[3] = (1'b0 == hexOrDecimal);
        led[4] = (1'b1 == hexOrDecimal);
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
