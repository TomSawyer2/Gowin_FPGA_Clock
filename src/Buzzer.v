module Buzzer(
    input CLK,
	input nRST,
    output reg BUZZER,
    input Value_en
);

    parameter  TIME_500MS = 24'd11999999;
    parameter  DO = 18'd91603 ;        //262
//    FPGA上LUT数量不够，必须注释掉
//    parameter  RE = 18'd81631 ;       //294
//    parameter  MI = 18'd72726 ;       //330
//    parameter  FA = 18'd68766;        //349
//    parameter  SO = 18'd61224 ;       //392
//    parameter  LA = 18'd54544 ;        //440
//    parameter  XI = 18'd48581 ;         //494


    reg [24:0] cnt = 0;
    reg   cnt_500ms=0;
    reg [17:0] freq_cnt=0;
    reg [17:0] freq_data=0;
    wire [16:0] duty_data;

always @(posedge CLK or negedge nRST) begin
    if (!nRST) begin
        cnt <= 0;
    end else begin
        if (cnt == TIME_500MS) begin
            cnt <= 0;
        end else begin
            cnt <= cnt + 1;
        end
    end
end
always@(posedge CLK or negedge nRST) 
        if(!nRST)
            cnt_500ms <= 1'b0;
        else if((cnt_500ms == 1) && (cnt == TIME_500MS))
            cnt_500ms <= 1'b0;
       else if(Value_en)
            cnt_500ms <= cnt_500ms + 1'b1;
        else 
            cnt_500ms <= cnt_500ms;

always@(posedge CLK or negedge nRST) begin
        if(!nRST)begin
            freq_cnt <= 18'd0;
        end else begin
              if((freq_cnt == freq_data) || (cnt == TIME_500MS))begin
            freq_cnt <= 18'd0;
        end else begin
            freq_cnt <= freq_cnt + 1'b1;
        end
    end
end

always @(posedge CLK or negedge nRST) begin
    if (!nRST) begin
          freq_data <= 1'b0;
    end else begin
        if (cnt_500ms ) begin
//            case(KEY_Value)
//                4'd0: freq_data <= DO;
//                4'd1: freq_data <= RE;
//                4'd2: freq_data <= MI;
//                4'd3: freq_data <= FA;
//                4'd4: freq_data <= SO;
//                4'd5: freq_data <= LA;
//                4'd6: freq_data <= XI;
//                4'd7: freq_data <= DO;
//                4'd8: freq_data <= RE;
//                4'd9: freq_data <= MI;
//                4'd10: freq_data <= FA;
//                4'd11: freq_data <= SO;
//                4'd12: freq_data <= LA;
//                4'd13: freq_data <= XI;
//                4'd14: freq_data <= DO;
//                4'd15: freq_data <= RE;
//              
//                default: freq_data <= 1'b0;
//            endcase
            freq_data <= DO;
        end else begin
            freq_data <= 1'b0;
        end
    end
end

//数据左移一位表示乘2，右移一位表示除以2
    assign duty_data = freq_data >> 1'b1 ;
//频率输出
always@(posedge CLK or negedge nRST) begin
        if(!nRST) begin   
            BUZZER<= 1'b0; 
       end else begin
        if(freq_cnt == duty_data) begin
            BUZZER <= ~BUZZER;
       end else begin
            BUZZER <= BUZZER;            
       end
end
end
endmodule