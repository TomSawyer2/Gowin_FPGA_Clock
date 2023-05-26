`timescale 1ns / 1ps
module counter24(
   input nCR,Hour_EN,CP_1Hz,
   output reg[3:0] cntH,cntL
   );
   always @(posedge CP_1Hz or negedge nCR)
   begin
     if(~nCR)
         {cntH,cntL}<=8'h00;
     else if(~Hour_EN)
         {cntH,cntL}<={cntH,cntL};
     else if((cntH>2)||(cntL>9)||((cntH==2)&&(cntL>=3)))
         {cntH,cntL}<=8'h00;
     else if((cntH==2)&&(cntL<3))
        begin cntH<=cntH;cntL<=cntL+1'b1;end
     else if(cntL==9)
        begin cntH<=cntH+1'b1;cntL<=4'b0000;end
     else begin cntH<=cntH;cntL<=cntL+1'b1;end
   end
endmodule
