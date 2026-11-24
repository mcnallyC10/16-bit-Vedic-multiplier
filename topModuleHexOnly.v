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
    output reg  [3:0]  activeNumber        // active low, an[3] = leftmost digit
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
    // -------------------------------------------------------------------------
     /*
    initalize the scroll count as a register large enough to store the number of scroll ticks
    this register is initialized to 0 and is incremented each clock cycle. 
    */
    reg [$clog2(SCROLL_TICKS):0] scroll_cnt = 0;
     //   pos = index of the leftmost displayed character, 0..12
    reg [3:0]  pos = 0;

    always @(posedge clk) begin
        /*
        if our current state is not set to scroll and show the numbers, 
        then we reset to 0 for the pos and scroll count
        */
        if (state != S_SHOW) begin
            scroll_cnt <= 0;
            pos        <= 0;
        /*
        Otherwise, if our state does equal S_SHOW, and we should be scrolling.
        Then we check to see if the scroll count is now full and thus equal to the scroll ticks.
        If it is equal, then we reset scroll count, so it continues to scroll, and increment the pos by 1.
        (unless the pos is at its max position. Then we set it to 0 for continuos looping)
        */
        end else if (scroll_cnt == SCROLL_TICKS - 1) begin
            scroll_cnt <= 0;
            pos        <= (pos == 4'd12) ? 0 : pos + 1;
        //If the the scroll counter is not full, then we do our normal condition which is to increment the scroll count
        end else begin
            scroll_cnt <= scroll_cnt + 1;
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
        case (state)
            S_A, S_B: code = {1'b0, sw_shifted[3:0]};  // live switch value
            //grab the number at the index specified.
            S_SHOW:   code = buf_at({1'b0, pos} + (5'd3 - digit), prod);
            default:  code = 5'b10000;
        endcase
    end

    always @(*) begin
        activeNumber = ~(4'b0001 << digit);
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
