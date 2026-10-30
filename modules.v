//4 bit Based on the image: "https://ars.els-cdn.com/content/image/1-s2.0-S2405844024071512-gr002.jpg"
//16 bit based on the image: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQpYNGZl258aQnVQlp5gXCF9zhMB23kkJtfTaIAHW3fSRUQP73evs_a2v75&s=10"
module andGate(input A, B, output O);
  assign O = A&B;
endmodule

module HA(input A, B, output S, C);
	assign S = A^B;
  	assign C = A&B;
endmodule

module FA(input A, B, Cin, output S, Cout);
  wire w[2:0];
  
  HA ha1 (A,B,w[0],w[1]);
  HA ha2 (w[0], Cin, S,w[2]);
  
  assign Cout = w[1]|w[2];
endmodule

module twoMult (A[1:0], B[1:0], S0, S1, S2, S3);

  wire w[3:0];
  
  andGate a1(A[0],B[0],S0);
  andGate a2(A[1],B[0],w[0]);
  andGate a3(A[0],B[1],w[1]);
  andGate a4(A[1],B[1],w[2]);
  
  HA ha1(w[0],w[1],S1, w[3]);
  HA ha2(w[2],w[3],S2,S3);
  
endmodule

module fourRCA(input A[3:0], B[3:0], S[3:0], Cout);
  wire w[2:0];
  
  FA f1(A[0],B[0], 1'b0,S[0], w[0]);
  FA f2(A[1],B[1], w[0],S[1], w[1]);
  FA f3(A[2],B[2], w[1],S[2], w[2]);
  FA f4(A[3],B[3], w[2],S[3], Cout);
  
endmodule 

module eightRCA(input A[7:0],B[7:0],S[7:0],Cout);
  wire w[6:0];
  
  FA fa1(A[0],B[0], 1'b0,S[0], w[0]);
  FA fa2(A[1],B[1], w[0],S[1], w[1]);
  FA fa3(A[2],B[2], w[1],S[2], w[2]);
  FA fa4(A[3],B[3], w[2],S[3], w[3]);
  FA fa5(A[4],B[4], w[3],S[4], w[4]);
  FA fa6(A[5],B[5], w[4],S[5], w[5]);
  FA fa7(A[6],B[6], w[5],S[6], w[6]);
  FA fa8(A[7],B[7], w[6],S[7], Cout);
  
endmodule  
          
module sixteenRCA(input A[15:0],B[15:0],S[15:0]);
  wire w[14:0];
  reg GND;
  
  FA fa1(A[0],B[0], 1'b0,S[0], w[0]);
  FA fa2(A[1],B[1], w[0],S[1], w[1]);
  FA fa3(A[2],B[2], w[1],S[2], w[2]);
  FA fa4(A[3],B[3], w[2],S[3], w[3]);
  FA fa5(A[4],B[4], w[3],S[4], w[4]);
  FA fa6(A[5],B[5], w[4],S[5], w[5]);
  FA fa7(A[6],B[6], w[5],S[6], w[6]);
  FA fa8(A[7],B[7], w[6],S[7], w[7]);  
  FA fa9(A[8],B[8], w[7],S[8], w[8]);
  FA fa10(A[9],B[9], w[8],S[9], w[9]);
  FA fa11(A[10],B[10], w[9],S[10], w[10]);
  FA fa12(A[11],B[11], w[10],S[11], w[11]);
  FA fa13(A[12],B[12], w[11],S[12], w[12]);
  FA fa14(A[13],B[13], w[12],S[13], w[13]);
  FA fa15(A[14],B[14], w[13],S[14], w[14]);
  FA fa16(A[15],B[15], w[14],S[15], GND);
  
  
endmodule 
module twentyfourRCA(input A[23:0],B[23:0],S[23:0]);
  wire w[22:0];
  
  reg GND
  FA fa1(A[0],B[0], 1'b0,S[0], w[0]);
  FA fa2(A[1],B[1], w[0],S[1], w[1]);
  FA fa3(A[2],B[2], w[1],S[2], w[2]);
  FA fa4(A[3],B[3], w[2],S[3], w[3]);
  FA fa5(A[4],B[4], w[3],S[4], w[4]);
  FA fa6(A[5],B[5], w[4],S[5], w[5]);
  FA fa7(A[6],B[6], w[5],S[6], w[6]);
  FA fa8(A[7],B[7], w[6],S[7], w[7]);  
  FA fa9(A[8],B[8], w[7],S[8], w[8]);
  FA fa10(A[9],B[9], w[8],S[9], w[9]);
  FA fa11(A[10],B[10], w[9],S[10], w[10]);
  FA fa12(A[11],B[11], w[10],S[11], w[11]);
  FA fa13(A[12],B[12], w[11],S[12], w[12]);
  FA fa14(A[13],B[13], w[12],S[13], w[13]);
  FA fa15(A[14],B[14], w[13],S[14], w[14]);
  FA fa16(A[15],B[15], w[14],S[15], Cout);
  FA fa17(A[16],B[16], w[15],S[16], w[8]);
  FA fa18(A[17],B[17], w[16],S[17], w[9]);
  FA fa19(A[18],B[18], w[17],S[18], w[10]);
  FA fa20(A[19],B[19], w[18],S[19], w[11]);
  FA fa21(A[20],B[20], w[19],S[20], w[12]);
  FA fa22(A[21],B[21], w[20],S[21], w[13]);
  FA fa23(A[22],B[22], w[21],S[22], w[14]);
  FA fa24(A[23],B[23], w[22],S[23], GND);
endmodule 



module fourMult(A[3:0], B[3:0], S[7:0]);
  wire w[13:0];
  wire h[15:0];
  
  reg GND;
  
  twoMult t1(A[1:0], B[1:0], S[0],S[1],w[0],w[1]);
  twoMult t2(A[1:0], B[3:2], w[2], w[3],w[4],w[5]);
  twoMult t3(A[3:2], B[1:0], w[6],w[7],w[8],w[9]);
  twoMult t4(A[3:2], B[3:2], w[10],w[11],w[12],w[13]);
  
 
  fourRCA rca1(w[5:2], w[9:6],h[3:0], h[4]);
  fourRCA rca2({w[1:0],2'b0},h[3:0],{S[3:2], h[7:6]},h[5]);
  
  HA h1(h[4],h[7],h[8],h[9]);
  fourRCA rca3(h[9:5],w[13:10],S[7:4], GND);
  
endmodule 
            
module eightMult(A[7:0],B[7:0],S[15:0],Cout);
  wire mult1[3:0];
  wire mult2[7:0];
  wire mult3[7:0];
  wire mult4[7:0];
  
  wire rca1wire[8:0];
  wire rca2wire[3:0];
  
  reg GND[1:0];
  
  fourMult fourMult1(A[3:0],B[3:0],{mult1[3:0],S[3:0]});
  fourMult fourMult2(A[3:0],B[7:4],mult2[7:0]);
  fourMult fourMult3(A[7:4],B[3:0],mult3[7:0]);
  fourMult fourMult4(A[7:4],B[7:4],mult4[7:0]);
  
  eightRCA rca1(mult2[7:0],mult3[7:0],rca1wire[7:0],rca1wire[8]);
  
  
  eightRCA rca2({4'b0,mult1[3:0]},rca1wire[7:0],{rca2wire[3:0],S[7:4]},GND[0]);
  
  eightRCA rca3({rca1wire[8],3'b0,rca2wire[3:0]},mult4[7:0],S[15:8],Cout);
  
endmodule
  
            
            
module sixteenMult(A[15:0],B[15:0],S[31:0]);
  wire mult1 [7:0];
  wire mult2 [15:0];
  wire mult3 [15:0];
  wire mult4 [15:0];
  
  wire rcaSum1 [15:0];
  wire rcaSum2 [23:0];
  
  
  reg GND [3:0];
  
  eightMult eight1(A[7:0],B[7:0],{mult1[7:0],S[7:0]},GND[0]);
  eightMult eight2(A[15:8],B[7:0],mult2[15:0], GND[1]);
  eightMult eight3(A[7:0],B[15:8],mult3[15:8],GND[2]);
  eightMult eight4(A[15:8],B[15:8],mult4[15:8],GND[3]);

  sixteenRCA srca({8'b0, mult1[7:0]}, mult2[15:0], rcaSum1[15:0]);
  twentyfourRCA tfrca1 ({8'b0, mult3[15:0]}, {mult4[15:0],8'b0}, rcaSum2[23:0]);
  twentyfourRCA tfrca1 ({8'b0, rcaSum1[15:0]}, rcaSum2[23:0], S[31:8]);
  
endmodule