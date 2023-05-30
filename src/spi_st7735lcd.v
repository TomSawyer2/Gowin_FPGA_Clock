//****************************************Copyright (c)***********************************//
//----------------------------------------------------------------------------------------
// Author：Pxm
// File name: spi_st7735lcd
// First establish Date: 2022/12/15 
// Descriptions: st7735R-SPI-LCD-demo顶层模块
// OutPin--CS    屏（从机）片选
// OutPin--RESET ST7735复位          （也有标RST）
// OutPin--DC    命令or数据指示      （也有标RS）
// OutPin--MOSI  主机输出数据给屏从机（也有标SDI）
// OutPin--SCLK  主机输出数据时钟    （也有标SCK）
// OutPin--LED   背光开关            （也有标BLK）
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module  spi_st7735lcd
(
    input           xtal_clk      ,
    input           sys_rst_n     ,
    input [3:0]     key_col       ,
    inout           dht11         ,
    
    output          lcd_rst       ,
    output          lcd_dc        ,
    output          lcd_sclk      ,
    output          lcd_mosi      ,
    output          lcd_cs        ,
    output          lcd_led       ,
    output [3:0]    key_row       ,
    output          BUZZER        
);
wire    [8:0]   data;   
wire            en_write;
wire            wr_done; 

wire    [8:0]   init_data;
wire            en_write_init;
wire            init_done;

wire    [6:0]   ascii_num           ;
wire    [8:0]   start_x             ;
wire    [8:0]   start_y             ;

wire    [8:0]   show_char_data      ;

assign  lcd_led = 1'b1;  //屏背光常亮

wire sys_clk;
//Gowin_rPLL uPLL51M( .clkout(sys_clk), .clkin (xtal_clk) ); //测试速度时再开启。
assign sys_clk = xtal_clk;

// 键盘和蜂鸣器逻辑
wire Value_en;
wire [3:0] KEY_Value;
KeyValue keyValue1(
	.CLK(sys_clk),
	.nRST(sys_rst_n),
	.KEY_ROW(key_row),
	.KEY_COL(key_col),
	.KEY_Value(KEY_Value),
	.Value_en(Value_en)
);

// 数字钟逻辑
// 设置nCR复位信号默认为高电平
wire nCR=1'b1;

wire[7:0] Hour,Minute,Second;
wire[7:0] newHour,newMinute,newSecond;
wire MinL_EN,MinH_EN,Hour_EN;
wire CP_1Hz;
wire flag0,flag1;
wire [3:0] Status;
wire [7:0] alarmHour, alarmMinute;

Buzzer Buzzer1(
	.CLK(sys_clk),
	.nRST(sys_rst_n),
	.BUZZER(BUZZER),
    .Value_en(Hour == alarmHour && Minute == alarmMinute)
);

Divider U0(.CLK_12(sys_clk),
           .nCR(nCR),
           .CP_1Hz(CP_1Hz)
);
defparam U0.N=25,U0.CLK_Freq=12000000,U0.OUT_Freq=1;
counter10 S0(.Q(Second[3:0]),
             .nCR(nCR),
             .EN(1),
             .newOnes(0),
             .Status(Status),
             .CP_1Hz(CP_1Hz));
counter6 S1( .Q(Second[7:4]),
             .nCR(nCR),
             .EN((Second[3:0]==4'h9)),
             .newTens(0),
             .Status(Status),
             .CP_1Hz(CP_1Hz));
counter10 M0(.Q(Minute[3:0]),
             .nCR(nCR),
             .EN(MinL_EN),
             .newOnes(newMinute[3:0]),
             .Status(Status),
             .CP_1Hz(CP_1Hz));
counter6 M1(.Q(Minute[7:4]),
            .nCR(nCR),
            .EN(MinH_EN),
            .newTens(newMinute[7:4]),
            .Status(Status),
            .CP_1Hz(CP_1Hz));
assign MinL_EN=flag0  ? 1 : (Second==8'h59);
assign MinH_EN=(flag0 &&(Minute[3:0]==4'h9))||((Minute[3:0]==4'h9)&&(Second==8'h59));
assign Hour_EN=flag1 ? 1 : ((Minute==8'h59)&&(Second==8'h59));
counter24 H0(.cntH(Hour[7:4]),
             .cntL(Hour[3:0]),
             .nCR(nCR),
             .Hour_EN(Hour_EN),
             .Status(Status),
             .newHour(newHour),
             .CP_1Hz(CP_1Hz));

ClockStatus clockstatus_inst (.clk(sys_clk),
                              .rstn(sys_rst_n),
                              .Value_en(Value_en),
                              .KEY_Value(KEY_Value),
                              .newHour(newHour),
                              .newMinute(newMinute),
                              .alarmHour(alarmHour),
                              .alarmMinute(alarmMinute),
                              .Status(Status));

// DHT11逻辑
wire[7:0] temperature;
wire[7:0] humidity;
dht11 dht11_inst(.temp(temperature),
                 .humi(humidity),
                 .clk(sys_clk),
                 .rst_n(sys_rst_n),
                 .dht11(dht11));

// 显示屏逻辑
lcd_init 
/*
`ifdef  __SIM
#( //仿真时调用
 .TIME20MS(23'd20),   
 .TIME40MS(23'd40),   
 .TIME5MS (23'd5),   
 .HEIGHT(8'd12),
 .WIDTH (8'd10)
)
`else
#( //适配小屏硬件用，工作时钟50MHz用缺省参数即可，此处用24MHz外部时钟，所以减半！
  .TIME20MS(23'd 500_000),  //23'd1000_000  
  .TIME40MS(23'd1000_000),  //23'd2000_000  
  .TIME5MS (23'd 125_000),   //23'd 250_000  
   //小屏硬件尺寸定义，参数不能超255，也不要用表达式（如128-1这种）！
  .HEIGHT(8'd131), //131适合128x128屏，改为161则适合160x128屏
  .WIDTH (8'd131)  //Qig128屏或Air160屏除了改动Height，还要更换管脚定义文件
)
`endif  */
   lcd_init_inst
(
    .sys_clk      (sys_clk      ),
    .sys_rst_n    (sys_rst_n    ),
    .wr_done      (wr_done      ),

    .lcd_rst      (lcd_rst      ),
    .init_data    (init_data    ),
    .en_write     (en_write_init),
    .init_done    (init_done    )
);

wire en_write_show_char;
wire show_char_done;
wire en_size;
wire show_char_flag;

muxcontrol  muxcontrol_inst
(
    .sys_clk            (sys_clk           ) ,   
    .sys_rst_n          (sys_rst_n         ) ,
    .init_done          (init_done         ) ,

    .init_data          (init_data         ) ,
    .en_write_init      (en_write_init     ) ,
    .show_char_data     (show_char_data    ) ,
    .en_write_show_char (en_write_show_char) ,

    .data               (data              ) ,
    .en_write           (en_write          )
);

lcd_write  lcd_write_inst
(
    .sys_clk      (sys_clk      ),
    .sys_rst_n    (sys_rst_n    ),
    .data         (data         ),
    .en_write     (en_write     ),
                                
    .wr_done      (wr_done      ),
    .cs           (lcd_cs       ),
    .dc           (lcd_dc       ),
    .sclk         (lcd_sclk     ),
    .mosi         (lcd_mosi     )
);

show_string_number_ctrl  show_string_number_inst
(
    .sys_clk        (sys_clk        ) ,
    .sys_rst_n      (sys_rst_n      ) ,
    .init_done      (init_done      ) ,
    .show_char_done (show_char_done ) ,
    .Hour           (Hour           ) ,
    .Minute         (Minute         ) ,
    .Second         (Second         ) ,
    .Temperature    (temperature    ) ,
    .Humidity       (humidity       ) ,
    .Status         (Status         ) ,

    .en_size        (en_size        ) ,
    .show_char_flag (show_char_flag ) ,
    .ascii_num      (ascii_num      ) ,
    .start_x        (start_x        ) ,
    .start_y        (start_y        ) 
);  


lcd_show_char  lcd_show_char_inst
(
    .sys_clk            (sys_clk            ),
    .sys_rst_n          (sys_rst_n          ),
    .wr_done            (wr_done            ),
    .en_size            (en_size            ),   //为0时字体大小的12x6，为1时字体大小的16x8
    .show_char_flag     (show_char_flag     ),   //显示字符标志信号
    .ascii_num          (ascii_num          ),   //需要显示字符的ascii码
    .start_x            (start_x            ),   //起点的x坐标    
    .start_y            (start_y            ),   //起点的y坐标    

    .show_char_data     (show_char_data     ),   //传输的命令或者数据
    .en_write_show_char (en_write_show_char ),   //使能写spi信号
    .show_char_done     (show_char_done     )    //显示字符完成标志信号
);

endmodule