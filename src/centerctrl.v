//----------------------------------------------------------------------------------------
// File name: muxcontrol
// Descriptions: （居中）控制切换选择LCD 初始化 或 展示Ascii字符及数字 信号输出。
//----------------------------------------------------------------------------------------
//****************************************************************************************//
module  muxcontrol(
    input   wire             sys_clk             ,
    input   wire             sys_rst_n           ,
    input   wire             init_done           ,

    input   wire     [8:0]   init_data           ,
    input   wire             en_write_init       ,
    input   wire     [8:0]   show_char_data      ,
    input   wire             en_write_show_char  ,

    output  reg      [8:0]   data                ,
    output  reg              en_write
);

always @(posedge sys_clk or negedge sys_rst_n)
    if (!sys_rst_n)
        data <= 'd0;
    else if(init_done == 1'b0)  //init_done=0未初试化完成
        data <= init_data;      //连接的数据是初始化数据
    else if(init_done == 1'b1)
        data <= show_char_data; //否则展示数据生效
    else
        data <= data;

always @(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        en_write <= 'd0;
    else if(init_done == 1'b0)          //初始化未完
        en_write <= en_write_init ;     //en_write由初始化模块控制
    else if(init_done == 1'b1)
        en_write <= en_write_show_char; //否则由展示模块控制
    else
        en_write <= en_write;

endmodule
