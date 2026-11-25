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
