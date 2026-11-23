/*
This modules makes use of the double dable algorithm.
Details as to the flow of this algorithm may be found here:
https://web.archive.org/web/20090325002523/http://cbfalconer.home.att.net/download/dubldabl.txt
*/

//n is the number is input bits we are going to use. 32 bits stores all we need.
module binToBcd #(parameter n = 32)(A,B);
  /*
  - rtoi is an inbuilt function that drops the fraction in a number, converting it from float to integer
  - output size comes from the formula bcd = 4*floor[log10(2^n -1)+1] where n is the number of input bits
  this is due to the fact it takes 4 bits to store one max size decimal number (9)
 */
  localparam bcd = $rtoi(4*$floor($log10($pow(2,n)-1)+1));
  localparam blocks = bcd/4;
  
  input [(n-1):0] A;  //A the input stores n bit numbers
  /*
  B the output stores bcd bit numbers. Where bcd is always a multiple of 4. Where each 4 bit 
  block stores a decimal number as binary. 
  */
  output [(bcd-1):0] B;
  
  //top most significtant 40 bits are for the output B, 32 least significiant for A
  reg[(bcd+n - 1):0] BA;
  /*
  clog 2 converts an integer to the amount of bits needed to represent that integer in binary.
  ex integer 7 would be 3 bits. as 2^3 = 8. 32 bits would be 5 bits. As 2^5 = 32
  */
  reg[$clog2(n):0] i;
  reg[$clog2(blocks):0] j;
  
  /*
  This function checks the input number to see if it is greater or equal to 5. If it is
  we add 3 (or b0101) to it.
  If it is is not, we pass the input the output. 
  This function also acts as a latch for the number to be operated on. For re-assignment.
  */
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
  
  //Shifts the input number left by 1 bit. Used for the big bcd+n sized registers
  function [(bcd+n - 1):0] shiftLeft(input [(bcd+n - 1):0] in);
    begin
      shiftLeft = in<<1;
    end
  endfunction
  
  //always @* as we want to update the re-assignment whenever the input number a changes.
  always @(*)
    begin
      BA=0; //generate the scratch register wiped clean
      BA=A; //asign LSB's to A. Rest will be 0.
      
      /*
      Our algorithm requires that for n bit numbers input, we apply the shift left and increment
      to the scratch register n times.
      */
      for(i=0; i<n; i=i+1)
        begin
        /*
        The algorithm requires we check each 4 bit block to see if it is greater then 5.
        Therefore we use the below for loop to increment from 0 to blocks.
        Where blocks is the amount of bcd bits as an integer divded by 4. 
        For 32 bits, bcd=40, and thus blocks = 10.
        */
          for(j=0; j < blocks; j=j+1) 
            begin
            //(j*4)+:4 grabs j*4 and finds the next 4 MSB's
            /* 
            we assign the block from n+j*4 up to n+j*4 + 4
            to a function whos arguement is the same. The details of this function may be found
            above
            */
              BA[(n+j*4)+:4] = checkAndIncrement(BA[(n+j*4)+:4]);
            end
          begin
          //at the end of all the checks, we finally shift all the bits 1 left.
            BA=shiftLeft(BA);
          end
        end
    end
    //assign the top most bits from bcd+n to bcd. For 32 bits this would be 40+32 to 32. So the 40 topmost bits
  assign B=BA[(bcd+n-1)-: bcd];
endmodule
