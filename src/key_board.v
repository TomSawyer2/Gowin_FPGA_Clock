module key_board(
	Clk,
	Rst_n,
	Key_Board_Row_i,

	Key_flag,
	Key_Value,
	Key_Board_Col_o
);

	input Clk ;
	input Rst_n;
	input [3:0]Key_Board_Row_i;

	output reg Key_flag;
	output reg [3:0]Key_Value;
	output reg [3:0]Key_Board_Col_o;


	// 输入列寄存器信号，输入以后做一次寄存
	reg [3:0]Key_Board_Row_r;

	reg En_Cnt ;	//滤波定时器
	reg [19:0] counter1; //滤波定时，时钟周期计数器
	reg Cnt_Done;	//滤波时间完成标志信号

	reg [3:0]Col_Tmp ; 	// 列按键按下状态
	reg  Key_Flag_r; 	// 按键成功标志位

	reg [7:0]Key_Value_tmp;

	reg  [10:0]state;

	//按键按下标志位
	always@(posedge Clk)
		Key_flag <= Key_Flag_r;

	// 状态机状态参数
	localparam
		IDEL				= 11'b00000000001,
		P_FILTER			= 11'b00000000010,
		READ_ROW_P 		= 11'b00000000100,
		SCAN_C0 			= 11'b00000001000,
		SCAN_C1 			= 11'b00000010000,
		SCAN_C2 			= 11'b00000100000,
		SCAN_C3 			= 11'b00001000000,
		PRESS_RESULT 	= 11'b00010000000,
		WAIT_R			= 11'b00100000000,
		R_FILTER 		= 11'b01000000000,
		READ_ROW_R 		= 11'b10000000000;

	// 滤波定时计数器

	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)
		counter1 <= 20'd0;
	else if(En_Cnt)begin
		if(counter1 == 20'd999999)
			counter1 <= 20'd0;
		else
			counter1 <= counter1 + 1'b1;
	end
	else
		counter1 <= 20'd0;

	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)
		Cnt_Done <= 1'b0;
	else if(counter1 == 20'd999999)
		Cnt_Done <= 1'b1;
	else
		Cnt_Done <= 1'b0;



	//状态机
	always @(posedge Clk or negedge Rst_n)
	if(!Rst_n)
	begin
	  state <= IDEL ;
	  Key_Board_Col_o <= 4'b0000 ; //输出端口默认设置为低电平，只有按键按下时，默认的上拉电平就会变成低电平
	  En_Cnt <= 1'b0;
	  Col_Tmp <= 4'd0;
	  Key_Flag_r <= 1'b0;
	  Key_Value_tmp <= 8'd0;
	  Key_Board_Row_r <= 4'b1111;
	end
	else
	begin
		case (state)
			IDEL:
				if(~&Key_Board_Row_i)begin  // Key_Board_Row_i  不等于 4‘d1111,说明有按键按下
					En_Cnt <= 1'b1 ;    // 开启滤波定时器
					state <= P_FILTER;  // 跳转进入前级滤波状态
				end
				else begin			// 按键未按下
					En_Cnt <=1'b0 ; // 消抖滤波定时器关闭
					state  <=IDEL ; // 等待状态
				end
			P_FILTER :
				if(Cnt_Done) begin	//消抖滤波定时时间结束
				  	En_Cnt <= 1'b0; //关闭滤波定时器
					state <= READ_ROW_P; //跳转进入滤波检测状态
				end
				else begin			//消抖定时未结束
					En_Cnt <= 1'b1; //继续保持
					state <= P_FILTER;// 状态继续保持当前值
				end
			READ_ROW_P:
				if (~&Key_Board_Row_i) begin  //滤波后，第二次确定按键确实按下
					Key_Board_Row_r <= Key_Board_Row_i; // 存取当前状态的值
					Key_Board_Col_o <= 4'b1110;  // 设置 Key_Board_Col_o 的输出信号为 4‘b1110，其它列设置为高电平
					state <= SCAN_C0;	// 跳转进入第C0列的判断
				end
				else begin 			//这次是按键抖动
					state  <=IDEL ; // 进入空闲等待状态
					Key_Board_Col_o <= 4'b0000;  // 设置 Key_Board_Col_o 的输出信号为 4‘b0000
				end
			SCAN_C0 :
				begin
					Key_Board_Col_o <= 4'b1101;  // 设置 Key_Board_Col_o 的输出信号为 4‘b1101
					state <= SCAN_C1;	// 跳转进入第C1列的判断
					if(~&Key_Board_Row_i) //其它3列设置为高电平后，Key_Board_Row_i 仍然为按键按下状态
						Col_Tmp <= 4'b0001 ; // 表示此次按下的按键是再第一列
					else
						Col_Tmp <= 4'b0000 ; // 表示此次按下的按键不在这列
				end
			SCAN_C1 :
				begin
					Key_Board_Col_o <= 4'b1011;  // 设置 Key_Board_Col_o 的输出信号为 4‘b1011
					state <= SCAN_C2;	// 跳转进入第C2列的判断
					if(~&Key_Board_Row_i) //其它3列设置为高电平后，Key_Board_Row_i 仍然为按键按下状态
						Col_Tmp <= 4'b0010 | Col_Tmp ; // 表示此次按下的按键是再第2列
					else
						Col_Tmp <= Col_Tmp ; // 表示此次按下的按键不在这列
				end
			SCAN_C2 :
				begin
					Key_Board_Col_o <= 4'b0111;  // 设置 Key_Board_Col_o 的输出信号为 4'b0111
					state <= SCAN_C3;	// 跳转进入第C3列的判断
					if(~&Key_Board_Row_i) //其它3列设置为高电平后，Key_Board_Row_i 仍然为按键按下状态
						Col_Tmp <= 4'b0100 | Col_Tmp ; // 表示此次按下的按键是再第2列
					else
						Col_Tmp <= Col_Tmp ; // 表示此次按下的按键不在这列
				end
			SCAN_C3 :
				begin
					state <= PRESS_RESULT;	// 进入此状态后，表示按键检测已经结束，需要进入下一个按键结果分析状态
					if(~&Key_Board_Row_i) 	// 其它3列设置为高电平后，Key_Board_Row_i 仍然为按键按下状态
						Col_Tmp <= 4'b1000 | Col_Tmp ; // 表示此次按下的按键是再第3列
					else
						Col_Tmp <= Col_Tmp ; // 表示此次按下的按键不在这列
				end
			PRESS_RESULT:
				begin
					state <= WAIT_R;		// 本次结果分析完成后，进入按键松开滤波状态
					Key_Board_Col_o <= 4'b0000; //按键检测查找完成，所以重新设置,输出Key_Board_Col_o的信号为 4‘b0000
					if(((Key_Board_Row_r[0] + Key_Board_Row_r[1] + Key_Board_Row_r[2] + Key_Board_Row_r[3]) == 4'd3) &&
					((Col_Tmp[0] + Col_Tmp[1] + Col_Tmp[2] + Col_Tmp[3]) == 4'd1)) // 检验是否只有一个按键按下
					begin
						Key_Flag_r <= 1'b1;							//产生按键成功标志信号
						Key_Value_tmp <= {Key_Board_Row_r,Col_Tmp}; //位拼接，等下来查找
					end
					else
					begin
						Key_Flag_r <= 1'b0; 			//非单个按键按下，不产生按键完成信号
						Key_Value_tmp <= Key_Value_tmp; //按键值保持上一次按键的值
					end
				end
			WAIT_R :
				begin
					Key_Flag_r <= 0 ; // 按键成功标志信号清零
					if(&Key_Board_Row_i) //  Key_Board_Row_i = 4’b1111 表示(按键未按下)即，按键松开，此时我们进入后消抖状态
					begin
						En_Cnt =1'b1; // 开启消抖滤波的计时器
						state <= R_FILTER ; //进入后消抖判断转态
					end
					else // 按键仍然按下，我们在这次保持等待状态
					begin
						state <= WAIT_R ;
						En_Cnt =1'b0; // 消抖滤波的计时器暂时先不开启
					end
				end
			R_FILTER :
				if(Cnt_Done)begin  //后消抖滤波定时完成
					En_Cnt <= 1'b0; 		//关闭滤波定时器使能信号
					state <= READ_ROW_R; 	//进入按键完全释放状态判断
				end
				else
				begin
					En_Cnt <= 1'b1; 		// 滤波消抖定时器正在进行
					state  <= R_FILTER;		// 继续保持滤波状态
				end
			READ_ROW_R :
				if(&Key_Board_Row_i)  // （Key_Board_Row_i =4'd1111）即，确定按键已经松开，本次按键检测已经完成
					state <= IDEL;
				else 	// 按键还没松开,再次后消抖滤波
				begin
					state <= R_FILTER;		// 再次进入后消抖滤波状态
					En_Cnt <= 1'b1; 		// 开启滤波消抖定时器
				end
			default:  state <= IDEL; // 默认，或者运行出错，进入空闲状态
		endcase
	end

	//按键输出状态查找表  根据 : Key_Value_tmp <= {Key_Board_Row_r,Col_Tmp};  实现数据的查找
	always @(posedge Clk or negedge Rst_n)
	if(!Rst_n)
		Key_Value <= 4'd0 ;
	else if(Key_Flag_r)  // 先判断，按键是否按下成功
	begin
		case (Key_Value_tmp)
			8'b1110_0001 : Key_Value <= 4'd1;
			8'b1110_0010 : Key_Value <= 4'd2;
			8'b1110_0100 : Key_Value <= 4'd3;
			8'b1110_1000 : Key_Value <= 4'd4;

			8'b1101_0001 : Key_Value <= 4'd5;
			8'b1101_0010 : Key_Value <= 4'd6;
			8'b1101_0100 : Key_Value <= 4'd7;
			8'b1101_1000 : Key_Value <= 4'd8;

			8'b1011_0001 : Key_Value <= 4'd9;
			8'b1011_0010 : Key_Value <= 4'd0;
			8'b1011_0100 : Key_Value <= 4'd11;
			8'b1011_1000 : Key_Value <= 4'd12;

			8'b0111_0001 : Key_Value <= 4'd13;
			8'b0111_0010 : Key_Value <= 4'd14;
			8'b0111_0100 : Key_Value <= 4'd15;
			8'b0111_1000 : Key_Value <= 4'd10;
			default: Key_Value <= Key_Value ;
		endcase
	end

endmodule
