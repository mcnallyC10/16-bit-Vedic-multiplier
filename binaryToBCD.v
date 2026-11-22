/*output size comes from the formula bcd = 4*floor[log10(2^n -1)+1] where n is the number of input bits
this is due to the fact it takes 4 bits to store one max size decimal number (9)
*/

module binToBcd(A,B);
  //rtoi is an inbuilt function that drops the fraction in a number, converting it from float to integer
  parameter n = 32;
  parameter bcd = $rtoi(4*$floor($log10($pow(2,n)-1)+1));
  parameter blocks = bcd/4;
  
  input [(n-1):0] A;
  output [(bcd-1):0] B;
  //top most significtant 40 bits are for the output B, 32 least significiant for A
  reg[(bcd+n - 1):0] BA;
  //clog 2 converts an integer to the amount of bits needed to represent that integer in binary.
  reg[$clog2(n):0] i;
  reg[$clog2(blocks):0] j;
  
  function [3:0] checkAndIncrement(input [3:0] in);
    begin
      //if the numbers greater then 5. Add 3 to it. Else carry on
      if(in>=4'b0101)
        begin
          checkAndIncrement = in + 4'b0011;
        end
      else
        begin
          checkAndIncrement = in;
        end
    end
  endfunction
  
  function [(bcd+n - 1):0] shiftLeft(input [(bcd+n - 1):0] in);
    begin
      shiftLeft = in<<1;
    end
  endfunction
  
  always @(*)
    begin
      BA=0; //generate the scratch register wiped clean
      BA=A; //asign LSB to A. Rest will be 0
      for(i=0; i<n; i=i+1)
        begin
          for(j=0; j < blocks; j=j+1) //(j*4)+:4 grabs j*4 and finds the next 4 MSB's
            begin
              BA[(n+j*4)+:4] = checkAndIncrement(BA[(n+j*4)+:4]);
            end
          begin
            BA=shiftLeft(BA);
          end
        end
    end
  assign B=BA[(bcd+n-1)-: bcd];
endmodule
