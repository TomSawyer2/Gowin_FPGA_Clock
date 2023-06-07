module ClockStatus(
    input clk,
	input rstn,
    input Value_en,
    input [3:0] KEY_Value,
    input [7:0] Hour,
    input [7:0] Minute,
    input [7:0] Second,
    output reg [7:0] newHour,
    output reg [7:0] newMinute,
    output reg [7:0] alarmHour,
    output reg [7:0] alarmMinute,
    output reg haveAlarm,
    output reg haveAlarmTemp,
    output reg [7:0] alarmTemp,
    output reg shouldTick,
    output reg [4:0] Status
);
// Status 0初始 
// 1输入小时十位 2 设置小时十位 3调小时个位 4设置小时个位
// 5调分钟十位 6设置分钟十位 7调分钟个位 8设置分钟十位 
// 9调闹钟时十位 10调闹钟时个位 11调闹钟分十位 12调闹钟分个位
// 13调温度十位 14调温度个位
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        Status <= 5'd0;
        shouldTick <= 1'b1;
        alarmHour <= 'd0;
        alarmMinute <= 'd0;
        haveAlarm <= ~shouldTick;
        haveAlarmTemp <= ~shouldTick;
    end else begin
        if (Value_en) begin
            case(Status)
                5'd0: begin
                    // A键调时
                    if (KEY_Value == 4'd11) begin
                        Status <= 5'd1;
                    // B键调分
                    end else if (KEY_Value == 4'd12) begin
                        Status <= 5'd5;
                    // C键设置闹钟
                    end else if (KEY_Value == 4'd13) begin
                        Status <= 5'd9;
                    // D键清空闹钟
                    end else if (KEY_Value == 4'd14) begin
                        haveAlarm <= 1'b0;
                    // E键开关声音
                    end else if (KEY_Value == 4'd15) begin
                        shouldTick <= ~shouldTick;
                    // F键设置报警温度
                    end else if (KEY_Value == 4'd10) begin
                        if (haveAlarmTemp) 
                            haveAlarmTemp <= 1'b0;
                        else 
                            Status <= 5'd13;
                    end
                end
                
                5'd1: begin
                    newHour <= {KEY_Value, 4'd0000};
                    Status <= 5'd2;
                end

                5'd3: begin
                    newHour <= {newHour[7:4], KEY_Value};
                    Status <= 5'd4;
                end

                5'd5: begin
                    newMinute <= {KEY_Value, 4'd0000};
                    Status <= 5'd6; 
                end

                5'd7: begin
                    newMinute <= {newMinute[7:4], KEY_Value};
                    Status <= 5'd8;
                end

                5'd9: begin
                    alarmHour <= {KEY_Value, 4'd0000};
                    Status <= 5'd10;
                end

                5'd10: begin
                    alarmHour <= {alarmHour[7:4], KEY_Value};
                    Status <= 5'd11;
                end

                5'd11: begin
                    alarmMinute <= {KEY_Value, 4'd0000};
                    Status <= 5'd12;
                end

                5'd12: begin
                    alarmMinute <= {alarmMinute[7:4], KEY_Value};
                    haveAlarm <= 1'b1;
                    Status <= 5'd0;
                end

                5'd13: begin
                    alarmTemp <= {KEY_Value, 4'd0000};
                    Status <= 5'd14;
                end

                5'd14: begin
                    alarmTemp <= {alarmTemp[7:4], KEY_Value};
                    haveAlarmTemp <= 1'b1;
                    Status <= 5'd0;
                end
            endcase
        end

        case(Status)
            5'd2: begin
                if (Hour[7:4] == newHour[7:4]) Status <= 5'd3;
            end

            5'd4: begin
                if (Hour[3:0] == newHour[3:0]) Status <= 5'd0;
            end

            5'd6: begin
                if (Minute[7:4] == newMinute[7:4]) Status <= 5'd7;
            end

            5'd8: begin
                if (Minute[3:0] == newMinute[3:0]) Status <= 5'd0;
           end
        endcase
    end
end
endmodule
    