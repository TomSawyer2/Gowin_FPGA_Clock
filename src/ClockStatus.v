module ClockStatus(
    input clk,
	input rstn,
    input Value_en,
    input [3:0] KEY_Value,
    output reg [7:0] newHour,
    output reg [7:0] newMinute,
    output reg [7:0] alarmHour,
    output reg [7:0] alarmMinute,
    output reg haveAlarm,
    output reg [3:0] Status
);
// Status 0初始 1调小时十位 2调小时个位 3调分钟十位 4调分钟个位 5设置闹钟时十位 6设置闹钟时个位 7设置闹钟分十位 8设置闹钟分个位
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        Status <= 4'd0;
        haveAlarm <= 1'b0;
        alarmHour <= 'd0;
        alarmMinute <= 'd0;
    end else begin
        // 设个默认的会在一分钟响的闹钟
//        haveAlarm <= 1'b0;
//        alarmHour <= 'd0;
//        alarmMinute <= 'd1;
        if (Value_en) begin
            case(Status)
                4'd0: begin
                    // A键调时
                    if (KEY_Value == 4'd10) begin
                        Status <= 4'd1;
                    // B键调分
                    end else if (KEY_Value == 4'd11) begin
                        Status <= 4'd3;
                    // C键设置闹钟
                    end else if (KEY_Value == 4'd12) begin
                        Status <= 4'd5;
                    // D键清空闹钟
                    end else if (KEY_Value == 4'd13) begin
                        haveAlarm <= 1'b0;
                    end
                end
                
                4'd1: begin
                    newHour <= {KEY_Value, 4'b0000};
                    Status <= 4'd2;
                end

                4'd2: begin
                    newHour <= {newHour[7:4], KEY_Value};
                    Status <= 4'd0;
                end

                4'd3: begin
                    newMinute <= {KEY_Value, 4'b0000};
                    Status <= 4'd4; 
                end

                4'd4: begin
                    newMinute <= {newMinute[7:4], KEY_Value};
                    Status <= 4'd0;
                end

                4'd5: begin
                    alarmHour <= {KEY_Value, 4'b0000};
                    Status <= 4'd6;
                end

                4'd6: begin
                    alarmHour <= {alarmHour[7:4], KEY_Value};
                    Status <= 4'd7;
                end

                4'd7: begin
                    alarmMinute <= {KEY_Value, 4'b0000};
                    Status <= 4'd8;
                end

                4'd8: begin
                    alarmMinute <= {alarmMinute[7:4], KEY_Value};
                    haveAlarm <= 1'b1;
                    Status <= 4'd0;
                end
            endcase
        end
    end
end
endmodule
    