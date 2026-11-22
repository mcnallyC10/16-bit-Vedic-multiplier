/* Diagram References for each module: 
2x2 vedic multiplier: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRMQ_C0mZwlZ1D124xFTUTIAlLNZ9pw9GMy2AM12y7zDZB_zHO2C293QMx8&s=10" 
4x4 vedic multiplier: "https://ars.els-cdn.com/content/image/1-s2.0-S2405844024071512-gr003.jpg" 
8x8 vedic multiplier: "https://www.researchgate.net/publication/276200751/figure/fig2/AS:1137809817640960@1648286408020/Structure-of-Urdhva-8x8-Vedic-Multiplier.png" 
16x16 vedic multiplier: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQpYNGZl258aQnVQlp5gXCF9zhMB23kkJtfTaIAHW3fSRUQP73evs_a2v75&s=10" 
CA: "https://codestall.wordpress.com/wp-content/uploads/2017/09/4-bit-adder.jpg" 
*/ 

module vedicMultiplierTest; 

  reg [15:0] x;
  reg [15:0] y;
    
  wire [31:0] out; 

  sixteenMult smult(x[15:0],x[15:0],out[31:0]);  
  initial 
    begin
      for(x=16'd0;x<=16'd65000;x=x+16'd100)
        begin
          #2 if(x*x == out) begin
          $display("x=%d, o=%d",x,out);
          end
          else begin end
        end
      $stop; 
    end 
  initial 
	begin 
	  $dumpfile("dump.vcd"); 
	  $dumpvars(1,vedicMultiplierTest);
	end 
endmodule 
