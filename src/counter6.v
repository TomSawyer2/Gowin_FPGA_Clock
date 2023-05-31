`timescale 1ns / 1ps
module counter6(
   input nCR,EN,CP_1Hz,[3:0] newTens, [3:0] Status,
   output reg[3:0] Q
);
always @(posedge CP_1Hz or negedge nCR) begin 
   if(~nCR) Q <= 4'b0000;
   else if (Status == 4'd3) begin
      Q <= newTens;
   end else if(~EN) Q <= Q;
   else if(Q == 4'b0101) Q <= 4'b0000;
   else Q <= Q + 1'b1;
end
endmodule
