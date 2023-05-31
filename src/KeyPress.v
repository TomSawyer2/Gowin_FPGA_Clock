module KeyPress(
	input CLK,
	input nRST,
	input KEY_IN,
	output reg KEY_FLAG,
	output reg KEY_STATE
);
	
reg key_a, key_b;
reg en_cnt, cnt_full;
reg [3:0]state;
// 想办法使用外部的DIVIDER模块分出的1Hz频率，内部不要再实现一遍，太浪费LUT资源
reg [12:0]cnt;
wire flag_H2L, flag_L2H;

localparam
	Key_up			=	4'b0001,
	Filter_Up2Down	=	4'b0010,
	Key_down			=	4'b0100,
	Filter_Down2Up	=	4'b1000;
	
//======判断按键输入信号跳变沿========//
always @(posedge CLK or negedge nRST)
	if(!nRST)
		begin
			key_a <= 1'b0;
			key_b <= 1'b0;
		end
	else
		begin
			key_a <= KEY_IN;
			key_b <= key_a;
		end
assign flag_H2L = key_b && (!key_a);
assign flag_L2H = (!key_b) && key_a;

//============计数使能模块==========//
always @(posedge CLK or negedge nRST)
	if(!nRST)
		cnt <= 1'b0;
	else if(en_cnt)
		cnt <= cnt + 1'b1;
	else
		cnt <= 1'b0;
		
//=============计数模块=============//
always @(posedge CLK or negedge nRST)
	if(!nRST)
		cnt_full <= 1'b0;
	else if(cnt == 13'd8191)
		cnt_full <= 1'b1;
	else
		cnt_full <= 1'b0;

//=============有限状态机============//
always @(posedge CLK or negedge nRST)
	if(!nRST)
		begin
			en_cnt <= 1'b0;
			state <= Key_up;
			KEY_FLAG <= 1'b0;
			KEY_STATE <= 1'b1;
		end
	else
		case(state)
			//保持没按
			Key_up: begin 
				KEY_FLAG <= 1'b0;
				if (flag_H2L) begin
					state <= Filter_Up2Down;
					en_cnt <= 1'b1;
				end
				else
					state <= Key_up;							
			end

			//正在向下按	
			Filter_Up2Down: begin
				if (cnt_full) begin
					en_cnt <= 1'b0;
					state <= Key_down;
					KEY_STATE <= 1'b0;
					KEY_FLAG <= 1'b1;
				end
				else if(flag_L2H) begin
					en_cnt <= 1'b0;
					state <= Key_up;
				end
				else
					state <= Filter_Up2Down;
			end

			//保持按下状态
			Key_down: begin
				KEY_FLAG <= 1'b0;
				if(flag_L2H) begin
					state <= Filter_Down2Up;
					en_cnt <= 1'b1;
				end
				else 
					state <= Key_down;
			end

			//正在释放按键
			Filter_Down2Up: begin
				if(cnt_full) begin
					en_cnt <= 1'b0;
					state <= Key_up;
					KEY_FLAG <= 1'b1;
					KEY_STATE <= 1'b1;
				end
				else if(flag_H2L) begin
					en_cnt <= 1'b0;
					state <= Key_down;
				end						
				else
					state <= Filter_Down2Up;
			end
			
			//其他未定义状态
			default: begin
				en_cnt <= 1'b0;
				state <= Key_up;
				KEY_FLAG <= 1'b0;
				KEY_STATE <= 1'b1;
			end
		endcase	
endmodule
