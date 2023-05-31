`timescale 1ns / 1ps
module Divider(
   input CLK_12,
   input nCR,
   output reg CP_1Hz 
);
parameter N=25, CLK_Freq=24000000, OUT_Freq=1;//24MHz
reg[N-1:0] Count_DIV;
always @(posedge CLK_12 or negedge nCR)
begin
    if(!nCR) begin
        CP_1Hz <= 0;
        Count_DIV <= 0;
    end else begin
        if (Count_DIV < (CLK_Freq / (OUT_Freq)))
            Count_DIV <= Count_DIV + 1'b1;
        else begin
            Count_DIV <= 0;
            CP_1Hz <= ~CP_1Hz;
        end
    end
end
endmodule
