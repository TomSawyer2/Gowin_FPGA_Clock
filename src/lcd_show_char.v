//----------------------------------------------------------------------------------------
// File name: lcd_show_char
// Descriptions: 让st7735-SPI-LCD展示Ascii字符及数字的数据组织提供模块
//----------------------------------------------------------------------------------------
//****************************************************************************************//
module lcd_show_char
(
    input       wire            sys_clk             ,
    input       wire            sys_rst_n           ,
    input       wire            wr_done             ,
    input       wire            en_size             ,   //为0时字体大小的12x6，为1时字体大小的16x8
    input       wire            show_char_flag      ,   //显示字符标志信号
    input       wire    [6:0]   ascii_num           ,   //需要显示字符的ascii码
    input       wire    [8:0]   start_x             ,   //起点的x坐标    
    input       wire    [8:0]   start_y             ,   //起点的y坐标    

    output      wire    [8:0]   show_char_data      ,   //传输的命令或者数据
    output      wire            en_write_show_char  ,   //使能写spi信号
    output      wire            show_char_done          //显示字符完成标志信号
);

//画笔颜色
//localparam  BLUE          = 16'h001F,
//            GREEN         = 16'h07E0,	  
localparam  RED           = 16'hF800,  
//            CYAN          = 16'h07FF,
//            MAGENTA       = 16'hF81F,
//            YELLOW        = 16'hFFE0,
//            LIGHTBLUE     = 16'h841F,
//            LIGHTGREEN    = 16'h87F0,
//            LIGHTRED      = 16'hFC10,
//            LIGHTCYAN     = 16'h87FF,
//            LIGHTMAGENTA  = 16'hFC1F, 
//            LIGHTYELLOW   = 16'hFFF0, 
            DARKBLUE      = 16'h0010;
//            DARKGREEN     = 16'h0400,
//            DARKRED       = 16'h8000,
//            DARKCYAN      = 16'h0410,
//            DARKMAGENTA   = 16'h8010,
//            DARKYELLOW    = 16'h8400,
//            WHITE         = 16'hFFFF, //白色
//            LIGHTGRAY     = 16'hD69A, //灰色
//            GRAY          = 16'h8410,
//            DARKGRAY      = 16'h4208,
//            BLACK         = 16'h0000, //黑色
//            BROWN         = 16'hA145,
//            ORANGE        = 16'hFD20;

localparam  CLRSCR1  = DARKBLUE;  
localparam  FRONTCOLOR  = RED;  

//****************** Parameter and Internal Signal *******************//
//en_size == 0时选用字体大小为12x6   //注意12正好是6的两倍，后面用到此点
parameter   SIZE0_WIDTH_MAX  = 3'd5; //宽度6，但在Rom中是占1byte~8bit存放
parameter   SIZE0_LENGTH_MAX = 4'd11;

//en_size == 1时选用字体大小为16x8   //注意16正好是8的两倍
parameter   SIZE1_WIDTH_MAX  = 3'd7;
parameter   SIZE1_LENGTH_MAX = 4'd15;

parameter   STATE0 = 4'b0_001;     
parameter   STATE1 = 4'b0_010;
parameter   STATE2 = 4'b0_100;
parameter   DONE   = 4'b1_000;

//补齐方块结束坐标
wire    [8:0]   end_x;
wire    [8:0]   end_y;

//状态转移
reg     [3:0]   state;

//设置显示窗口
reg             the1_wr_done;
reg     [3:0]   cnt_set_windows;  
  //lcd控制芯片设置窗口操作有11bytes数据。
  //cnt_set_windows是为这11bytes用的计数器，计数范围0--10。
  //其主要作用在代码段230行，还关联123行和130行。

//状态STATE1跳转到STATE2的标志信号
reg            state1_finish_flag;

//等待rom数据读取完成的计数器
reg     [2:0]   cnt_rom_prepare;

//rom的读取地址
reg     [11:0]  rom_addr;
//rom的输出
wire    [7:0]   rom_q;

//rom输出数据移位后得到的数据temp
reg     [7:0]   temp;

//字模行加1标志信号
reg             length_num_flag;

//字模行计数器
reg     [4:0]   cnt_length_num;

//点的颜色计数器
reg     [5:0]   cnt_wr_color_data;

//要传输的命令或者数据
reg     [8:0]   data;

//状态STATE2跳转到DONE的标志信号        
wire    state2_finish_flag;

//******************************* Main Code **************************//
//补齐方块结束坐标  //en_size == 0时选用字体大小为12x6
assign end_x = (en_size) ? start_x + SIZE1_WIDTH_MAX  : start_x + SIZE0_WIDTH_MAX;
assign end_y = (en_size) ? start_y + SIZE1_LENGTH_MAX : start_y + SIZE0_LENGTH_MAX;

//状态转移
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        state <= STATE0;
    else
        case(state)
            STATE0 : state <= (show_char_flag) ? STATE1 : STATE0;    // input show_char_flag,显示字符标志信号
            STATE1 : state <= (state1_finish_flag) ? STATE2 : STATE1;//(cnt_set_windows == 'd10 && the1_wr_done) st1flag<=1
            STATE2 : state <= (state2_finish_flag) ? DONE : STATE2;  //(cnt_length_num == SIZE_LENGTH_MAX)&&length_num_flag
            DONE   : state <= STATE0; //非常简单的过渡状态，仅用于两处
        endcase
        
//重要  //～似乎只是对每个wr_done延迟了一个sys_clk
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n) 
        the1_wr_done <= 1'b0;
    else if(wr_done)
        the1_wr_done <= 1'b1;
    else
        the1_wr_done <= 1'b0;
        
//设置显示窗口计数器    //设置窗口操作有11bytes数据。
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)  
        cnt_set_windows <= 'd0;
    else if(state == STATE1 && the1_wr_done)
        cnt_set_windows <= cnt_set_windows + 1'b1;
//状态STATE1跳转到STATE2的标志信号
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        state1_finish_flag <= 1'b0;
    else if(cnt_set_windows == 'd10 && the1_wr_done)  //11个设定窗口命令字传送彻底完毕
        state1_finish_flag <= 1'b1;
    else
        state1_finish_flag <= 1'b0;

//状态STATE2跳转到DONE的标志信号        
assign state2_finish_flag = (
                             (
                                (!en_size && cnt_length_num == SIZE0_LENGTH_MAX) ||     //选用字体大小为12x6
                                (en_size && cnt_length_num == SIZE1_LENGTH_MAX)         //选用字体大小为16x8
                             ) &&
                             length_num_flag
                            ) ? 1'b1 : 1'b0;
        


//rom数据读取的（时序）步骤计数器，==1时开始计算rom_addr，==3时开始取rom数据，==5时en_write_show_char置1
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)  
        cnt_rom_prepare <= 'd0;
    else if(length_num_flag)
        cnt_rom_prepare <= 'd0;
    else if(state == STATE2 && cnt_rom_prepare < 'd5) //state2下+1变化，其他保持，出现length_num_flag则清0
        cnt_rom_prepare <= cnt_rom_prepare + 1'b1;
        
//算出rom数据-当前字模行所在地址
//  12x6字符rom从0开始，共96个字符，每个字符12行，每行1bytes，1byte中前6bit有效，每bit对应1个点有无（颜色）；
//而16x8字符rom则从1140开始，也是96个字符，每个字符16行，每行1bytes 8点。注意每点对应颜色数据是16bit格式。
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        rom_addr <= 'd0;
    else if(!en_size && cnt_rom_prepare == 'd1)     //选用字体大小为12x6
        rom_addr <= ascii_num *(SIZE0_LENGTH_MAX + 1'b1) + cnt_length_num;
    else if(en_size && cnt_rom_prepare == 'd1)      //选用字体大小为16x8
        rom_addr <= 12'd1140 + ascii_num *(SIZE1_LENGTH_MAX + 1'b1) + cnt_length_num;
//字库ROM占用2660bytes，两种字体各96个字符
    ascii_pROM your_instance_name(
        .dout(rom_q),      //output [7:0] dout
        .clk(sys_clk),     //input clk 每个sys_clk取出一字模行8个点的数据，rom_addr不变就重复取
        .oce(1'b0),        //input oce,bypass模式无效
        .ce(1'b1),         //input ce,High enable
        .reset(~sys_rst_n), //input reset，High enable，也可以留空
        .ad(rom_addr)      //input [11:0] ad
    );

//rom一单元数据=8bit点，点数（颜色）的计数器
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        cnt_wr_color_data <= 'd0;
    else if(cnt_rom_prepare == 'd3 || state == DONE)
        cnt_wr_color_data <= 'd0;
    else if(!en_size && state == STATE2 && the1_wr_done)
        cnt_wr_color_data <= cnt_wr_color_data + 1'b1;
    else if(en_size && state == STATE2 && the1_wr_done)
        cnt_wr_color_data <= cnt_wr_color_data + 1'b1;
//rom输出数据移位后得到的数据temp（rom输出数据是byte，其中的每个bit代表每个点有无，所以要移位处理）
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        temp <= 'd0;
    else if(cnt_rom_prepare == 'd3)
        temp <= rom_q;
    else if(!en_size && state == STATE2 && the1_wr_done)    //选用字体大小为12x6
        case(cnt_wr_color_data)              //rom一单元8bit，每bit对应屏上一点，一点对应颜色数据是16bit！！
            1 : temp <= temp >> 1;           //所以单数cnt_wr_color_data开始变要送的点数据，由另外块送对应的颜色高8bit数据，
            3 : temp <= temp >> 1;           //  而双数cnt_wr_color_data  不变--其实另外块在送对应的颜色低8bit颜色数据
            5 : temp <= temp >> 1;
            7 : temp <= temp >> 1;
            9 : temp <= temp >> 1;
            default : temp <= temp;
        endcase
    else if(en_size && state == STATE2 && the1_wr_done)     //选用字体大小为16x8
        case(cnt_wr_color_data)
            1 : temp <= temp >> 1;
            3 : temp <= temp >> 1;
            5 : temp <= temp >> 1;
            7 : temp <= temp >> 1;
            9 : temp <= temp >> 1;
            11: temp <= temp >> 1;
            13: temp <= temp >> 1;
            default : temp <= temp;
        endcase

//字模行加1标志信号 （即字模行一行数据处理完成标志）
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        length_num_flag <= 1'b0;
    else if(
            !en_size &&
            state == STATE2 && 
            cnt_wr_color_data == SIZE0_LENGTH_MAX &&  //cnt_wr_c_d本应对应WIDTH，但需要加倍，而LENGTH正好是WIDTH两倍
            the1_wr_done
           )
       length_num_flag <= 1'b1;
   else if(
            en_size &&
            state == STATE2 && 
            cnt_wr_color_data == SIZE1_LENGTH_MAX &&
            the1_wr_done
           )
       length_num_flag <= 1'b1;
    else
       length_num_flag <= 1'b0;
        
//字模行计数器（当字模行一行数据处理完成，判断字模行已取完--完则归零计数器，否则加1以便取下一行）
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        cnt_length_num <= 'd0;
    else if(!en_size && cnt_length_num == SIZE0_LENGTH_MAX && length_num_flag)
        cnt_length_num <= 'd0;
    else if(!en_size && cnt_length_num < SIZE0_LENGTH_MAX && length_num_flag)
        cnt_length_num <= cnt_length_num + 1'b1;
    else if(en_size && cnt_length_num == SIZE1_LENGTH_MAX && length_num_flag)
        cnt_length_num <= 'd0;
    else if(en_size && cnt_length_num < SIZE1_LENGTH_MAX && length_num_flag)
        cnt_length_num <= cnt_length_num + 1'b1;
        
//要传输的命令或者数据
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        data <= 9'h000;
    else if(state == STATE1)
        case(cnt_set_windows)
            0 : data <= 9'h02A;
            1 : data <= {1'b1,7'b0000_000,start_x[8]};
            2 : data <= {1'b1,start_x[7:0]};
            3 : data <= {1'b1,7'b0000_000,end_x[8]};
            4 : data <= {1'b1,end_x[7:0]};
            5 : data <= 9'h02B;
            6 : data <= {1'b1,7'b0000_000,start_y[8]};
            7 : data <= {1'b1,start_y[7:0]};
            8 : data <= {1'b1,7'b0000_000,end_y[8]};
            9 : data <= {1'b1,end_y[7:0]};
            10: data <= 9'h02C;
            default: data <= 9'h000;
        endcase
    else if(state == STATE2 && ((temp & 8'h01) == 'd0))
        if(cnt_wr_color_data[0] == 1'b0 )
            data <= {1'b1,CLRSCR1[15:8]};
        else
            data <= {1'b1,CLRSCR1[7:0]};
    else if(state == STATE2 && ((temp & 8'h01) == 'd1))
        if(cnt_wr_color_data[0] == 1'b0 )
            data <= {1'b1,FRONTCOLOR[15:8]};
        else
            data <= {1'b1,FRONTCOLOR[7:0]};
    else
        data <= data;   


//输出端口
assign show_char_data = data;
assign en_write_show_char = (state == STATE1 || cnt_rom_prepare == 'd5) ? 1'b1 : 1'b0;
assign show_char_done = (state == DONE) ? 1'b1 : 1'b0;


endmodule
