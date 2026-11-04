/* Diagram References for each module: 
2x2 vedic multiplier: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRMQ_C0mZwlZ1D124xFTUTIAlLNZ9pw9GMy2AM12y7zDZB_zHO2C293QMx8&s=10" 
4x4 vedic multiplier: "https://ars.els-cdn.com/content/image/1-s2.0-S2405844024071512-gr003.jpg" 
8x8 vedic multiplier: "https://www.researchgate.net/publication/276200751/figure/fig2/AS:1137809817640960@1648286408020/Structure-of-Urdhva-8x8-Vedic-Multiplier.png" 
16x16 vedic multiplier: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQpYNGZl258aQnVQlp5gXCF9zhMB23kkJtfTaIAHW3fSRUQP73evs_a2v75&s=10%22%20CA:%20%22https://codestall.wordpress.com/wp-content/uploads/2017/09/4-bit-adder.jpg" 
*/ 

module sixteenMultTest; 

  reg[15:0] x;

  reg [31:0] y; 
    
  wire andWire; 
  wire [1:0]  HAWire; 
  wire [1:0]  FAWire; 
  wire [4:0]  fourRCAWire; 
  wire [8:0]  eightRCAWire; 
  wire [15:0] sixteenRCAWire; 
  wire [23:0] twentyfourRCAWire; 
  wire [3:0]  twoMultWire; 
  wire [7:0]  fourMultWire; 
  wire [15:0] eightMultWire; 
  wire [31:0] sixteenMultWire; 

  eightMult emult(x[7:0],x[7:0],eightMultWire[15:0]); 
  sixteenMult smult(x[15:0],x[15:0],sixteenMultWire[31:0]);  
  initial 
    begin
      x = 16'd0; 
      #2 x = 16'd200; 
      #2 x = 16'd210; 
      #2 x = 16'd220; 
      #2 x = 16'd230; 
      #2 x = 16'd240; 
      #2 x = 16'd250; 
      #2 x = 16'd255; 
      
      #2 x = 16'd12478;
      #2 x = 16'd12357;
      #2 x = 16'd43525;
      #2 x = 16'd20002;
      #2 x = 16'd10000;
      #2 x = 16'd1354;
      #2 x = 16'd5050;
      #2 x = 16'd65000;
      
      #2 x = 16'd0; 
      #2 $stop; 
    end 
  initial 
	begin
      $monitor ("input = %d,%b, eightMult = %d, sixteenMult = %d", x,x,eightMultWire, sixteenMultWire);
      
	  $dumpfile("dump.vcd"); 
	  $dumpvars(1,sixteenMultTest);
	end 
endmodule 
