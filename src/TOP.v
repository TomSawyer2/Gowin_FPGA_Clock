`timescale 1ns / 1ps
module top(
    input CLK_12,
    );
    // 设置Adj_Min默认为低电平
    wire Adj_Min=1'b0;
    // 设置Adj_Hour默认为低电平
    wire Adj_Hour=1'b0;
    // 设置nCR复位信号默认为低电平
    wire nCR=1'b0;
    // 设置EN使能信号默认为高电平
    wire EN=1'b1;
    
    wire[7:0] Hour,Minute,Second;
    wire MinL_EN,MinH_EN,Hour_EN;
    wire CP_1Hz;
    wire[2:0] sel; 
    wire flag0,flag1;
    btn_deb B0(.clk(CLK_12),
              .btn_in(Adj_Min),
              .btn_out(flag0));
    btn_deb B1(.clk(CLK_12),
              .btn_in(Adj_Hour),
              .btn_out(flag1));
    Divider U0(.CLK_12(CLK_12),
               .nCR(nCR),
               .EN(EN),
               .CP_1Hz(CP_1Hz)
    );
    defparam U0.N=25,U0.CLK_Freq=12000000,U0.OUT_Freq=1;
    counter10 S0(.Q(Second[3:0]),
                 .nCR(nCR),
                 .EN(EN),
                 .CP_1Hz(CP_1Hz));
    counter6 S1( .Q(Second[7:4]),
                 .nCR(nCR),
                 .EN((Second[3:0]==4'h9)),
                 .CP_1Hz(CP_1Hz));
    counter10 M0(.Q(Minute[3:0]),
                 .nCR(nCR),
                 .EN(MinL_EN),
                 .CP_1Hz(CP_1Hz));
    counter6 M1(.Q(Minute[7:4]),
                 .nCR(nCR),
                 .EN(MinH_EN),
                 .CP_1Hz(CP_1Hz));
    assign MinL_EN=flag0  ? 1 : (Second==8'h59);
    assign MinH_EN=(flag0 &&(Minute[3:0]==4'h9))||((Minute[3:0]==4'h9)&&(Second==8'h59));
    assign Hour_EN=flag1 ? 1 : ((Minute==8'h59)&&(Second==8'h59));
   counter24 H0(.cntH(Hour[7:4]),
                .cntL(Hour[3:0]),
                .nCR(nCR),
                .Hour_EN(Hour_EN),
                .CP_1Hz(CP_1Hz));
    Dividerother D0(.CLK_12(CLK_12),.nCR(nCR),.sel(sel));
//    SEG_LUT u0(.Q0(Second[3:0]),
//               .Q1(Second[7:4]),
//               .Q2(Minute[3:0]),
//               .Q3(Minute[7:4]),
//               .Q4(Hour[3:0]),
//               .Q5(Hour[7:4]), 
//               .dig(dig),
//               .smg(smg),
//               .sel(sel));
    
endmodule 
