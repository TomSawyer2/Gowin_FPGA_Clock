//----------------------------------------------------------------------------------------
// File name: show_string_number_ctrl
// Descriptions: 控制展示内容的高层模块
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module show_string_number_ctrl(
    input       wire            sys_clk             ,
    input       wire            sys_rst_n           ,
    input       wire            init_done           ,
    input       wire            show_char_done      ,
    input       wire    [7:0]   Hour                ,
    input       wire    [7:0]   Minute              ,
    input       wire    [7:0]   Second              ,
    input       wire    [15:0]  TempHumi            ,
    input       wire    [4:0]   Status              ,
    input       wire            haveAlarm           ,
    input       wire            haveAlarmTemp       ,

    output      wire            en_size             ,
    output      reg             show_char_flag      ,
    output      reg     [6:0]   ascii_num           ,
    output      reg     [8:0]   start_x             ,
    output      reg     [8:0]   start_y
);
//****************** Parameter and Internal Signal *******************//
reg     [4:0]   cnt1;            //展示 行 计数器？！？3行故cnt1值只需0，1，2
//也可能是延迟计数器，init_done为高电平后，延迟3拍，产生show_char_flag高脉冲
reg     [6:0]   cnt_ascii_num;

//******************************* Main Code **************************//
//en_size为1时调用字体大小为16x8，为0时调用字体大小为12x6；
assign  en_size = 1'b1;

//产生输出信号show_char_flag，写到第2行！？就让show_char_flag产生一个高脉冲给后面模块
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        cnt1 <= 'd0;
    else if(show_char_flag)
        cnt1 <= 'd0;
    else if(init_done && cnt1 < 'd3)
        cnt1 <= cnt1 + 1'b1;
    else
        cnt1 <= cnt1;

always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        show_char_flag <= 1'b0;
    else if(cnt1 == 'd2)
        show_char_flag <= 1'b1;
    else
        show_char_flag <= 1'b0;

always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        cnt_ascii_num <= 'd0;
    else if(init_done && show_char_done)         //展示数目的计数器：初始化完成和上一个char展示完成后，数目+1
        cnt_ascii_num <= cnt_ascii_num + 1'b1;   //等于是展示字符的坐标（单位：个字符）
    else
        cnt_ascii_num <= cnt_ascii_num;

reg [3:0] decimal_hour_tens;      // 十位数的十进制值
reg [3:0] decimal_hour_ones;      // 个位数的十进制值

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        decimal_hour_tens <= 4'h0;        // 复位时重置十位数为 0
        decimal_hour_ones <= 4'h0;        // 复位时重置个位数为 0
    end else begin
        // 将小时值转换为十进制数
        decimal_hour_tens <= Hour[7:4];
        decimal_hour_ones <= Hour[3:0];
    end
end

reg [3:0] decimal_minute_tens;      // 十位数的十进制值
reg [3:0] decimal_minute_ones;      // 个位数的十进制值

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        decimal_minute_tens <= 4'h0;        // 复位时重置十位数为 0
        decimal_minute_ones <= 4'h0;        // 复位时重置个位数为 0
    end else begin
        // 将小时值转换为十进制数
        decimal_minute_tens <= Minute[7:4];
        decimal_minute_ones <= Minute[3:0];
    end
end

reg [3:0] decimal_second_tens;      // 十位数的十进制值
reg [3:0] decimal_second_ones;      // 个位数的十进制值

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin          // 复位时重置小时值为 0
        decimal_second_tens <= 4'h0;        // 复位时重置十位数为 0
        decimal_second_ones <= 4'h0;        // 复位时重置个位数为 0
    end else begin
        // 将小时值转换为十进制数
        decimal_second_tens <= Second[7:4];
        decimal_second_ones <= Second[3:0];
    end
end

always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        ascii_num <= 'd0;
    else if(init_done)
        case(cnt_ascii_num)         //根据当前展示数目（字符坐标）给出展示内容（ascii码）
            //ascii码 库内码-32
            // 居中显示xyz三个字母，高度为16px，y坐标为2
            0: ascii_num <= 'd120-'d32; // x
            1: ascii_num <= 'd121-'d32; // y
            2: ascii_num <= 'd122-'d32; // z
            3: ascii_num <= 'd96; // 何
            4: ascii_num <= 'd97; // 余
            5: ascii_num <= 'd98; // 郑
            // y坐标为20处显示一条高度为1的横线
            6: ascii_num <= 'd45-'d32;  // -
            7: ascii_num <= 'd45-'d32;  // -
            8: ascii_num <= 'd45-'d32;  // -
            9: ascii_num <= 'd45-'d32;  // -
            10: ascii_num <= 'd45-'d32;  // -
            11: ascii_num <= 'd45-'d32;  // -
            12: ascii_num <= 'd45-'d32;  // -
            13: ascii_num <= 'd45-'d32;  // -
            14: ascii_num <= 'd45-'d32;  // -
            15: ascii_num <= 'd45-'d32;  // -
            16: ascii_num <= 'd45-'d32;  // -
            17: ascii_num <= 'd45-'d32;  // -
            18: ascii_num <= 'd45-'d32;  // -
            19: ascii_num <= 'd45-'d32;  // -
            20: ascii_num <= 'd45-'d32;  // -
            21: ascii_num <= 'd45-'d32;  // -
            // 空行
            22: ascii_num <= 'd32-'d32;  //
            // 居中显示20:10:22一共八个字符，高度为20，y坐标为30
            23: ascii_num <= (Status == 5'd1 || Status == 5'd2 || Status == 5'd9) ? 'd95 - 'd32 : decimal_hour_tens+'d16;  // 2
            24: ascii_num <= (Status == 5'd3 || Status == 5'd4 || Status == 5'd10) ? 'd95 - 'd32 : decimal_hour_ones+'d16;  // 0
            25: ascii_num <= 'd58-'d32;  // :
            26: ascii_num <= (Status == 5'd5 || Status == 5'd6 || Status == 5'd11) ? 'd95 - 'd32 : decimal_minute_tens+'d16;  // 1
            27: ascii_num <= (Status == 5'd7 || Status == 5'd8 || Status == 5'd12) ? 'd95 - 'd32 : decimal_minute_ones+'d16;  // 0
            28: ascii_num <= 'd58-'d32;  // :
            29: ascii_num <= (Status == 5'd13) ? 'd95 - 'd32 :decimal_second_tens+'d16; // 2
            30: ascii_num <= (Status == 5'd14) ? 'd95 - 'd32 :decimal_second_ones+'d16; // 2
            // 空行
            31: ascii_num <= haveAlarm ? 'd67-'d32 : 'd45 - 'd32;  // C有无闹钟
            32: ascii_num <= haveAlarmTemp ? 'd84-'d32 : 'd45 - 'd32;  // T有无温度报警
            // 居中显示2023/05/21一共十个字符，高度为20，y坐标为78
            33: ascii_num <= 'd50-'d32;  // 2
            34: ascii_num <= 'd48-'d32;  // 0
            35: ascii_num <= 'd50-'d32;  // 2
            36: ascii_num <= 'd51-'d32;  // 3
            37: ascii_num <= 'd47-'d32;  // /
            38: ascii_num <= 'd48-'d32;  // 0
            39: ascii_num <= 'd54-'d32;  // 6
            40: ascii_num <= 'd47-'d32;  // /
            41: ascii_num <= 'd48-'d32;  // 0
            42: ascii_num <= 'd57-'d32;  // 9
            // 居中显示Mon.这四个字符，高度为20，y坐标为102
            43: ascii_num <= 'd70-'d32;  // F
            44: ascii_num <= 'd114-'d32; // r
            45: ascii_num <= 'd105-'d32; // i
            46: ascii_num <= 'd46-'d32;  // .
            // 空行
            47: ascii_num <= 'd32-'d32;  //
            // y坐标为86处显示一条高度为1的横线
            48: ascii_num <= 'd45-'d32;  // -
            49: ascii_num <= 'd45-'d32;  // -
            50: ascii_num <= 'd45-'d32;  // -
            51: ascii_num <= 'd45-'d32;  // -
            52: ascii_num <= 'd45-'d32;  // -
            53: ascii_num <= 'd45-'d32;  // -
            54: ascii_num <= 'd45-'d32;  // -
            55: ascii_num <= 'd45-'d32;  // -
            56: ascii_num <= 'd45-'d32;  // -
            57: ascii_num <= 'd45-'d32;  // -
            58: ascii_num <= 'd45-'d32;  // -
            59: ascii_num <= 'd45-'d32;  // -
            60: ascii_num <= 'd45-'d32;  // -
            61: ascii_num <= 'd45-'d32;  // -
            62: ascii_num <= 'd45-'d32;  // -
            63: ascii_num <= 'd45-'d32;  // -
            // y坐标为109处显示20℃10%这六个字符，高度为20
            64: ascii_num <= TempHumi[15:8]/10 +'d16;  // 2
            65: ascii_num <= TempHumi[15:8]%10 +'d16;  // 0
            66: ascii_num <= 'd95;  // ℃
            67: ascii_num <= 'd32-'d32;  //
            68: ascii_num <= TempHumi[7:0]/10 +'d16;  // 1
            69: ascii_num <= TempHumi[7:0]%10 +'d16;  // 0
            70: ascii_num <= 'd37-'d32;  // %
            default: ascii_num <= 'd0;
        endcase

always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        start_x <= 'd0;
    else if(init_done)
        case(cnt_ascii_num)        //根据当前展示数目（字符坐标）给出展示位置（屏幕坐标）,先定横向x
            // 居中显示xyz三个字母，高度为16px，y坐标为2
            0: start_x <= 'd8;
            1: start_x <= 'd16;
            2: start_x <= 'd24;
            3: start_x <= 'd96;
            4: start_x <= 'd104;
            5: start_x <= 'd112;
            // y坐标为20处显示一条高度为1的横线
            6: start_x <= 'd0;
            7: start_x <= 'd8;
            8: start_x <= 'd16;
            9: start_x <= 'd24;
            10: start_x <= 'd32;
            11: start_x <= 'd40;
            12: start_x <= 'd48;
            13: start_x <= 'd56;
            14: start_x <= 'd64;
            15: start_x <= 'd72;
            16: start_x <= 'd80;
            17: start_x <= 'd88;
            18: start_x <= 'd96;
            19: start_x <= 'd104;
            20: start_x <= 'd112;
            21: start_x <= 'd120;
            // 空行
            22: start_x <= 'd32;
            // 居中显示20:10:22一共八个字符，高度为20，y坐标为30
            23: start_x <= 'd32;
            24: start_x <= 'd40;
            25: start_x <= 'd48;
            26: start_x <= 'd56;
            27: start_x <= 'd64;
            28: start_x <= 'd72;
            29: start_x <= 'd80;
            30: start_x <= 'd88;
            // 空行
            31: start_x <= 'd50;
            32: start_x <= 'd70;
            // 居中显示2023/05/21一共十个字符，高度为20，y坐标为78
            33: start_x <= 'd24;
            34: start_x <= 'd32;
            35: start_x <= 'd40;
            36: start_x <= 'd48;
            37: start_x <= 'd56;
            38: start_x <= 'd64;
            39: start_x <= 'd72;
            40: start_x <= 'd80;
            41: start_x <= 'd88;
            42: start_x <= 'd96;
            // 居中显示Mon.这四个字符，高度为20，y坐标为102
            43: start_x <= 'd48;
            44: start_x <= 'd56;
            45: start_x <= 'd64;
            46: start_x <= 'd72;
            // 空行
            47: start_x <= 'd32;
            // y坐标为86处显示一条高度为1的横线
            48: start_x <= 'd0;
            49: start_x <= 'd8;
            50: start_x <= 'd16;
            51: start_x <= 'd24;
            52: start_x <= 'd32;
            53: start_x <= 'd40;
            54: start_x <= 'd48;
            55: start_x <= 'd56;
            56: start_x <= 'd64;
            57: start_x <= 'd72;
            58: start_x <= 'd80;
            59: start_x <= 'd88;
            60: start_x <= 'd96;
            61: start_x <= 'd104;
            62: start_x <= 'd112;
            63: start_x <= 'd120;
            // y坐标为109处显示20℃10%这六个字符，高度为20
            64: start_x <= 'd36;
            65: start_x <= 'd44;
            66: start_x <= 'd52;
            67: start_x <= 'd60;
            68: start_x <= 'd68;
            69: start_x <= 'd76;
            70: start_x <= 'd84;
            // 默认情况下起始位置为0
            default: start_x <= 'd0;
        endcase
    else
        start_x <= 'd0;

always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        start_y <= 'd0;
    else if(init_done)
        case(cnt_ascii_num)        //根据当前展示数目（字符坐标）给出展示位置（屏幕坐标）,再定纵向y
            0 : start_y <= 'd0;
            1 : start_y <= 'd0;
            2 : start_y <= 'd0;
            3 : start_y <= 'd0;
            4 : start_y <= 'd0;
            5 : start_y <= 'd0;
            6 : start_y <= 'd16;
            7 : start_y <= 'd16;
            8 : start_y <= 'd16;
            9 : start_y <= 'd16;
            10 : start_y <= 'd16;
            11 : start_y <= 'd16;
            12 : start_y <= 'd16;
            13 : start_y <= 'd16;
            14 : start_y <= 'd16;
            15 : start_y <= 'd16;
            16 : start_y <= 'd16;
            17 : start_y <= 'd16;
            18 : start_y <= 'd16;
            19 : start_y <= 'd16;
            20 : start_y <= 'd16;
            21 : start_y <= 'd16;
            22 : start_y <= 'd32;
            23 : start_y <= 'd48;
            24 : start_y <= 'd48;
            25 : start_y <= 'd48;
            26 : start_y <= 'd48;
            27 : start_y <= 'd48;
            28: start_y <= 'd48;
            29: start_y <= 'd48;
            30: start_y <= 'd48;
            31: start_y <= 'd64;
            32: start_y <= 'd64;
            33: start_y <= 'd80;
            34: start_y <= 'd80;
            35: start_y <= 'd80;
            36: start_y <= 'd80;
            37: start_y <= 'd80;
            38: start_y <= 'd80;
            39: start_y <= 'd80;
            40: start_y <= 'd80;
            41: start_y <= 'd80;
            42: start_y <= 'd80;
            43: start_y <= 'd96;
            44: start_y <= 'd96;
            45: start_y <= 'd96;
            46: start_y <= 'd96;
            47: start_y <= 'd112;
            48: start_y <= 'd128;
            49: start_y <= 'd128;
            50: start_y <= 'd128;
            51: start_y <= 'd128;
            52: start_y <= 'd128;
            53: start_y <= 'd128;
            54: start_y <= 'd128;
            55: start_y <= 'd128;
            56: start_y <= 'd128;
            57: start_y <= 'd128;
            58: start_y <= 'd128;
            59: start_y <= 'd128;
            60: start_y <= 'd128;
            61: start_y <= 'd128;
            62: start_y <= 'd128;
            63: start_y <= 'd128;
            64: start_y <= 'd144;
            65: start_y <= 'd144;
            66: start_y <= 'd144;
            67: start_y <= 'd144;
            68: start_y <= 'd144;
            69: start_y <= 'd144;
            70: start_y <= 'd144;
            default: start_y <= 'd0;
        endcase
    else
        start_y <= 'd0;

endmodule
