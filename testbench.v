/* Diagram References for each module:
2x2 vedic multiplier: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRMQ_C0mZwlZ1D124xFTUTIAlLNZ9pw9GMy2AM12y7zDZB_zHO2C293QMx8&s=10"
4x4 vedic multiplier: "https://ars.els-cdn.com/content/image/1-s2.0-S2405844024071512-gr003.jpg"
8x8 vedic multiplier: "https://www.researchgate.net/publication/276200751/figure/fig2/AS:1137809817640960@1648286408020/Structure-of-Urdhva-8x8-Vedic-Multiplier.png"
16x16 vedic multiplier: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQpYNGZl258aQnVQlp5gXCF9zhMB23kkJtfTaIAHW3fSRUQP73evs_a2v75&s=10"

RCA: "https://codestall.wordpress.com/wp-content/uploads/2017/09/4-bit-adder.jpg"
*/

module sixteenMultTest;
  reg [23:0]x;
  
  wire andWire;
  wire [1:0]  HAWire;
  wire [1:0]  FAWire;
  wire [4:0]  fourRCAWire;
  wire [8:0]  eightRCAWire;
  wire [16:0] sixteenRCAWire;
  wire [23:0] twentyfourRCAWire;
  wire [3:0]  twoMultWire;
  wire [7:0]  fourMultWire;
  wire [15:0] eightMultWire;
  wire [31:0] sixteenMultWire;
  
  andGate a(x[0],x[1],andWire);
  HA h(x[0],x[1],HAWire[0],HAWire[1]);
  FA f(x[0],x[1],x[2],FAWire[0],FAWire[1]);
  fourRCA frca(x[3:0],x[7:4],fourRCAWire[3:0],fourRCAWire[4]);
  eightRCA erca(x[7:0],x[15:8],eightRCAWire[7:0],eightRCAWire[8]);
  sixteenRCA srca(x[15:0], x[15:0],sixteenRCAWire[15:0]);
  twentyfourRCA tfrca(x[23:0],x[23:0], twentyfourRCAWire[23:0]);
  twoMult tmult(x[1:0],x[1:0],twoMultWire[0],twoMultWire[1],twoMultWire[2],twoMultWire[3]);
  fourMult fmult(x[3:0],x[3:0],fourMultWire[7:0]);
  eightMult emult(x[7:0],x[7:0],eightMultWire[15:0]);
  sixteenMult smult(x[15:0],x[15:0],sixteenMultWire[31:0]);

  initial
    begin
      x = 16'b0;
      #2 $stop;
    end

endmodule