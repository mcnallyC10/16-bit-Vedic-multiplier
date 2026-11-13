// Code your design here
module andGate(A, B, O);
  input A,B;
  output O;

  assign O = A&B;
endmodule

module HA(A, B, S, C);
  	
  input A, B;
  	output S, C;

  
	assign S = A^B;
  	assign C = A&B;
  
endmodule



module FA(A, B, Cin, S, Cout);
  
  input A, B, Cin;
  output S, Cout;
  
  wire w[2:0];
  
  HA ha1 (A,B,w[0],w[1]);
  HA ha2 (w[0], Cin, S,w[2]);
  
  assign Cout = w[1]|w[2];

endmodule

module RCA(A,B,Cin,S, Cout);
  parameter inputSize = 4;
  parameter outputSize = inputSize;
  input Cin;
  input [inputSize-1:0]A,B;
  
  
  output Cout;
  output [outputSize - 1:0] S;
  
  wire [inputSize : 0] w;
  
  assign w[0] = Cin;
  assign Cout = w[inputSize];
  
  
  genvar j;
  generate for( j = 0; j<inputSize; j = j+1)
    begin: FA_loop
      FA f1 (A[j],B[j], w[j], S[j], w[j+1]);
    end
  endgenerate
endmodule
        

module twoMult (A,B,S);  
  
  input [1:0]A, B;
  output [3:0]S;
  
  wire [3:0]w;
  
  andGate a1(A[0],B[0],S[0]);
  andGate a2(A[1],B[0],w[0]);
  andGate a3(A[0],B[1],w[1]);
  andGate a4(A[1],B[1],w[2]);
  
  HA ha1(w[0],w[1],S[1], w[3]);
  HA ha2(w[2],w[3],S[2],S[3]);
  
  
endmodule


module fourMult(A,B,S, Cout);
  
  input [3:0]A, B;
  output [7:0]S;
  output Cout;
  
  wire [1:0] multWire1;
  wire [3:0] multWire2, multWire3, multWire4;
  
  wire [4:0] rcaWire1;
  wire [2:0] rcaWire2;
  
  wire [1:0] haWire;
  
  twoMult tm1(A[1:0],B[1:0], {multWire1[1:0],S[1:0]});
  twoMult tm2(A[1:0],B[3:2], multWire2[3:0]);
  twoMult tm3(A[3:2],B[1:0], multWire3[3:0]);
  twoMult tm4(A[3:2],B[3:2], multWire4[3:0]);
  
  RCA #(4) fRCA1(multWire2[3:0],multWire3[3:0], 1'b0,rcaWire1[3:0],rcaWire1[4]);
  RCA #(4) fRCA2({2'b0, multWire1[1:0]}, rcaWire1[3:0], 1'b0,{rcaWire2[1:0], S[3:2]}, rcaWire2[2]);
  
  HA h(rcaWire1[4], rcaWire2[2], haWire[0],haWire[1]);
  
  RCA #(4) fRCA3({haWire[1],haWire[0],rcaWire2[1:0]}, multWire4[3:0],1'b0, S[7:4],Cout);
  
endmodule 

module eightMult(A,B,S);
  
  input [7:0]A,B;
  output [15:0]S;
  
  reg GND;
  wire [3:0] mult1;
  wire [7:0] mult2, mult3, mult4;
  
  wire [7:0]rcaWire1;
  wire [3:0]rcaWire2;
  
  wire [4:0] unusedCarry;
  wire [1:0] usedCarry;
  
  wire [1:0] haOut;
  
  fourMult fourMult1(A[3:0],B[3:0],{mult1[3:0],S[3:0]}, unusedCarry[0]);
  fourMult fourMult2(A[3:0],B[7:4],mult2[7:0], unusedCarry[1]);
  fourMult fourMult3(A[7:4],B[3:0],mult3[7:0], unusedCarry[2]);
  fourMult fourMult4(A[7:4],B[7:4],mult4[7:0], unusedCarry[3]);
  
  RCA #(8) eRCA1(mult2[7:0], mult3[7:0], 1'b0, rcaWire1[7:0], usedCarry[0]);
  RCA #(8) eRCA2({4'b0, mult1[3:0]}, rcaWire1[7:0], 1'b0, {rcaWire2[3:0], S[7:4]}, usedCarry[1]);
  
  HA ha (usedCarry[0],usedCarry[1],haOut[0],haOut[1]);
  
  RCA #(8) eRCA3({2'b0,haOut[1],haOut[0],rcaWire2[3:0]}, mult4[7:0], 1'b0, S[15:8],unusedCarry[4]);
  
endmodule

module sixteenMult(A,B,S);
  
  input [15:0]A,B;
  output [31:0]S;
  
  
  wire  [7:0]  mult1;
  wire  [15:0] mult2, mult3, mult4;
  
  wire [15:0]  rcaWire1;
  wire [23:0]  rcaWire2;
  
  wire [6:0]   unusedCarry;
  
  eightMult eightMult1(A[7:0],B[7:0],{mult1[7:0],S[7:0]});
  eightMult eightMult2(A[15:8],B[7:0],mult2[15:0]);
  eightMult eightMult3(A[7:0],B[15:8],mult3[15:0]);
  eightMult eightMult4(A[15:8],B[15:8],mult4[15:0]);
  
  RCA #(16) sRCA({8'b0,mult1[7:0]}, mult2[15:0],1'b0,rcaWire1[15:0],unusedCarry[4]);
  
  RCA #(24) tfRCA1({8'b0,mult3[15:0]},{mult4[15:0],8'b0}, 1'b0,rcaWire2[23:0]);
  RCA #(24) tfRCA2({8'b0, rcaWire1[15:0]}, rcaWire2[23:0], 1'b0,S[31:8]);
   
endmodule