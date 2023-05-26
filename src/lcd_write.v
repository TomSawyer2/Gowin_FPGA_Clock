//----------------------------------------------------------------------------------------
// File name: lcd_write
// Descriptions: 连接SPI-lcd控制芯片st7735R，进行写数据操作
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module  lcd_write
(
    input   wire            sys_clk             ,
    input   wire            sys_rst_n           ,
    input   wire    [8:0]   data                ,
    input   wire            en_write            ,

    output  reg             wr_done             ,
    output  wire            cs                  ,
    output  wire            dc                  ,
    output  reg             sclk                ,
    output  reg             mosi                
);

//****************** Parameter and Internal Signal *******************//
//设置spi的模式，分别为
//模式0：CPOL = 0, CPHA = 0;
//模式1：CPOL = 0, CPHA = 1;
//模式2：CPOL = 1, CPHA = 0;
//模式3：CPOL = 1, CPHA = 1;
parameter CPOL = 1'b0;  //时钟极性
parameter CPHA = 1'b0;  //时钟相位

parameter DELAY_TIME = 3'd3; //不能小于3

parameter CNT_SCLK_MAX = 4'd4; //不能小于3

parameter STATE0 = 4'b0_001;
parameter STATE1 = 4'b0_010;
parameter STATE2 = 4'b0_100;
parameter DONE   = 4'b1_000;

//----------------------------------------------------------------- 
reg     [3:0]   state;
reg     [4:0]   cnt_delay;
reg     [3:0]   cnt1;
reg     [3:0]   cnt_sclk;
reg             sclk_flag;
reg             state2_finish_flag;

//******************************* Main Code **************************// 
//实现状态的跳转
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        state <= STATE0;
    else
        case(state)
            STATE0 : state <= (en_write) ? STATE1 : STATE0; 
            STATE1 : state <= (cnt_delay == DELAY_TIME) ? STATE2 : STATE1; 
            STATE2 : state <= (state2_finish_flag) ? DONE : STATE2;
            DONE   : state <= STATE0;
        endcase
        
//----------------------------------------------------------------- 
//计数器cnt_delay用来延迟
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        cnt_delay <= 'd0;
    else if(state ==  DONE)
        cnt_delay <= 'd0;
    else if(state == STATE1 && cnt_delay < DELAY_TIME)
        cnt_delay <= cnt_delay + 1'b1;
    else
        cnt_delay <= 'd0;

//计数器cnt1，配合sclk_flag来指示mosi的更新和保持。
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        cnt1 <= 'd0;
    else if(state == STATE1)
        cnt1 <= 'd0;
    else if(state == STATE2 && cnt_sclk == CNT_SCLK_MAX)
        cnt1 <= cnt1 + 1'b1;
        
//计数器cnt_sclk决定spi的时钟       
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        cnt_sclk <= 'd0;
    else if(cnt_sclk == CNT_SCLK_MAX)
        cnt_sclk <= 'd0;
    else if(state == STATE2 && cnt_sclk < CNT_SCLK_MAX)
        cnt_sclk <= cnt_sclk + 1'b1;
         
//时钟sclk的标志信号
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        sclk_flag <= 1'b0;
    //时钟相位为1时，提前拉高，让后面的处理代码能统一，不必总考虑相位问题，设备在偶数沿采集数据
    else if(CPHA == 1'b1 && state == STATE1 && (cnt_delay == DELAY_TIME - 1'b1))
        sclk_flag <= 1'b1;
    else if(cnt_sclk == CNT_SCLK_MAX - 1'b1)
        sclk_flag <= 1'b1;
    else
        sclk_flag <= 1'b0;
        
//状态STATE2跳转到状态DONE的标志信号
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        state2_finish_flag <= 1'b0;
    else if(cnt1 == 'd15 && (cnt_sclk == CNT_SCLK_MAX - 1'b1))
        state2_finish_flag <= 1'b1;
    else
        state2_finish_flag <= 1'b0;
        
//-----------------------------------------------------------------           
//sclk时钟信号
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        sclk <= 1'b0;
    //时钟极性为1，空闲时sclk的状态为高电平
    else if(CPOL == 1'b1 && state == STATE0)
        sclk <= 1'b1;
    //时钟极性为0，空闲时sclk的状态为低电平
    else if(CPOL == 1'b0 && state == STATE0)
        sclk <= 1'b0;
    else if(sclk_flag)  //只要slck_flag拉高就让sclk电平反转
        sclk <= ~sclk;
    else
        sclk <= sclk;

//mosi：SPI总线写数据信号
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        mosi <= 1'b0;
    else if(state == STATE0) mosi <= 1'b0;
         else if(state == STATE1 && cnt_delay == DELAY_TIME) mosi <= data[7];
              else begin
                     if(state == STATE2 && sclk_flag)
                       case (cnt1)  //时钟相位不同的处理在前面，此处处理代码统一为奇计数准备数据
                              1 : mosi <= data[6];
                              3 : mosi <= data[5];
                              5 : mosi <= data[4];
                              7 : mosi <= data[3];
                              9 : mosi <= data[2];
                             11 : mosi <= data[1];
                             13 : mosi <= data[0];
                             15 : mosi <= 1'b0;
                         default: mosi <= mosi;
                      endcase
                     else   mosi <= mosi;
                   end

//wr_done传输完成标志信号
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        wr_done <= 1'b0;
    else if(state == DONE)
        wr_done <= 1'b1;
    else
        wr_done <= 1'b0;

//cs片选信号，低电平有效
assign cs = (state == STATE2) ? 1'b0 : 1'b1;

//dc液晶屏寄存器/数据选择信号，低电平：寄存器，高电平：数据
//接收的data的最高位决定dc的状态
assign dc = data[8]; 

endmodule