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

module fourRCA(A,B,Cin,S,Cout);
  input [3:0]A, B;
  input Cin;
  output [3:0]S;
  output Cout;
  
  wire [2:0]w;
  
  FA f1(A[0],B[0], Cin,S[0], w[0]);
  FA f2(A[1],B[1], w[0],S[1], w[1]);
  FA f3(A[2],B[2], w[1],S[2], w[2]);
  FA f4(A[3],B[3], w[2],S[3], Cout);
  
endmodule 

module eightRCA(A,B,Cin, S,Cout);
  input [7:0]A,B;
  input Cin;
  
  output [7:0]S;
  output Cout;
  
  wire w;
  
  fourRCA f1(A[3:0],B[3:0],Cin,S[3:0],w);
  fourRCA f2(A[7:4],B[7:4],w,S[7:4],Cout);
endmodule  
          

module sixteenRCA(A,B,Cin,S,Cout); 
  input [15:0]A,B;
  input Cin;
  output [15:0]S;
  output Cout;
  
  wire w;

  
  eightRCA f1(A[7:0],B[7:0],Cin, S[7:0], w);
  eightRCA f2(A[15:8],B[15:8],w,S[15:8],Cout); 
  
endmodule



module twentyfourRCA(A, B,Cin, S);
  input [23:0]A,B;
  input Cin;
  output [23:0]S;
  
  wire w;
  
  reg GND;
  
  sixteenRCA f1(A[15:0],B[15:0],Cin,S[15:0],w);
  eightRCA f2(A[23:16],B[23:16],w,S[23:16], GND);
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
  
  fourRCA fRCA1(multWire2[3:0],multWire3[3:0], 1'b0,rcaWire1[3:0],rcaWire1[4]);
  fourRCA fRCA2({2'b0, multWire1[1:0]}, rcaWire1[3:0], 1'b0,{rcaWire2[1:0], S[3:2]}, rcaWire2[2]);
  
  HA h(rcaWire1[4], rcaWire2[2], haWire[0],haWire[1]);
  
  fourRCA fRCA3({haWire[1],haWire[0],rcaWire2[1:0]}, multWire4[3:0], S[7:4],Cout);
  
endmodule 

module eightMult(A,B,S,Cout);
  input [7:0]A,B;
  input Cout;
  output [15:0]S;
  
  
  wire [3:0] mult1;
  wire [7:0] mult2, mult3, mult4;
  
  wire [8:0]rcaWire1;
  wire [3:0]rcaWire2;
  
  wire [4:0] unusedCarry;
  
  fourMult fourMult1(A[3:0],B[3:0],{mult1[3:0],S[3:0]}, unusedCarry[0]);
  fourMult fourMult2(A[3:0],B[7:4],mult2[7:0], unusedCarry[1]);
  fourMult fourMult3(A[7:4],B[3:0],mult3[7:0], unusedCarry[2]);
  fourMult fourMult4(A[7:4],B[7:4],mult4[7:0], unusedCarry[3]);
  
  eightRCA eRCA1(mult2[7:0], mult3[7:0], 1'b0, rcaWire1[7:0], rcaWire1[8]);
  eightRCA eRCA2({4'b0, mult1[3:0]}, rcaWire1[7:0], 1'b0, {rcaWire2[3:0], S[7:4]}, unusedCarry[4]);
  eightRCA eRCA3({rcaWire1[8],3'b0,rcaWire2[3:0]}, mult4[7:0], 1'b0, S[15:8],Cout);
  
endmodule

module sixteenMult(A,B,S);
  input [15:0]A,B;
  output [31:0]S;
  
  
  wire  [7:0]  mult1;
  wire  [15:0] mult2, mult3, mult4;
  
  wire [15:0]  rcaWire1;
  wire [23:0]  rcaWire2;
  
  wire [6:0]   unusedCarry;
  
  eightMult eightMult1(A[7:0],B[7:0],{mult1[7:0],S[7:0]},unusedCarry[0]);
  eightMult eightMult2(A[15:8],B[7:0],mult2[15:0],unusedCarry[1]);
  eightMult eightMult3(A[7:0],B[15:8],mult3[15:0],unusedCarry[2]);
  eightMult eightMult4(A[15:8],B[15:8],mult4[15:0],unusedCarry[3]);
  
  sixteenRCA sRCA({8'b0,mult1[7:0]}, mult2[15:0],rcaWire1[15:0],unusedCarry[4]);
  
  twentyfourRCA tfRCA1({8'b0,mult3[15:0]},{mult4[15:0],8'b0}, rcaWire2[23:0],unusedCarry[5]);
  twentyfourRCA tfRCA2({8'b0, rcaWire1[15:0]}, rcaWire2[23:0], S[31:8], unusedCarry[6]);
   
 
  
  
endmodule