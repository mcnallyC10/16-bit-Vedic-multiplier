//4 bit Based on the image: "https://ars.els-cdn.com/content/image/1-s2.0-S2405844024071512-gr002.jpg"
//16 bit based on the image: "https://ars.els-cdn.com/content/image/1-s2.0-S2405844024071512-gr003.jpg"
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

module RCA(input A0, A1, A2, A3, B0, B1, B2, B3, Cin, output S0, S1, S2, S3, Cout);
  wire w[2:0];
  
  FA fa1(A0, B0, Cin, S0, w[0]);
  FA fa2(A1, B1, w[0], S1, w[1]);
  FA fa3(A2, B2, w[1], S2, w[2]);
  FA fa4(A0, B0, w[2], S3, Cout);
  
endmodule

module fourMult(input A0,A1,B0,B1, output S0, S1, S2, S3);
  wire a[2:0];
  andGate and1 (A1, B1, a[0]);
  andGate and2 (A0, B1, a[1]);
  andGate and3 (A1, B0, a[2]);
  andGate and4 (A0, B0, S0);
  
  wire w;
  
  HA ha1(a[1], a[2], S1, w);
  HA ha2(a[0], w, S2, S3);
  
endmodule

module sixteenMult(A0, A1, A2, A3, B0, B1, B2, B3, S0, S1, S2, S3, S4, S5, S6, S7, C0);
  wire m[13:0];
  wire a[9:0];
  wire h[1:0];
  
  
  fourMult fM1(A0,A1,B0,B1,m[0],m[1],S1,S0);
  fourMult fM2(A0,A1,B2,B3,m[2],m[3],m[4],m[5]);
  fourMult fM3(A2,A3,B0,B1,m[6],m[7],m[8],m[9]);
  fourMult fM4(A3,A2,B2,B3,m[10],m[11],m[12],m[13]);
  
  RCA rca1(m[2],m[3],m[4],m[5],m[6],m[7],m[8],a[0],a[1],a[2],a[3],a[4]);
  RCA rca2(0,0,m[0],m[1],a[0],a[1],a[2],a[3],a[5],a[6],S3,S2,a[7]);
  
  HA ha(a[4],a[7],a[8],a[9]);
  
  RCA rca3(m[10],m[11],m[12],m[13],a[8],a[9],a[5],a[6],S7,S6,S5,S4,C0);
  
  
endmodule
  
  