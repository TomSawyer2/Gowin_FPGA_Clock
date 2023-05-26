`timescale 1ns / 1ps
module Dividerother(
   input CLK_12,
   input nCR,
   output reg[2:0]sel
   );
   reg[6:0] count;
   always @(posedge CLK_12)
   begin
      if(0)
      begin 
         count<=0;
         sel<=0;
      end
      else if(count==0&&sel!=5)
      begin 
         count<=count+1'b1;
         sel<=sel+1'b1;
         
      end
      else if(sel==5&&count==0) 
       begin 
         count<=count+1'b1;
         sel<=0;
      end
      else 
      begin 
         count<=count+1'b1;
         sel<=sel;
      end
   end
endmodule
