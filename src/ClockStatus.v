module ClockStatus(
    input clk,
	input rstn,
    input Value_en,
    input [3:0] KEY_Value,
    output reg [7:0] newHour,
    output reg [7:0] newMinute,
    output reg [7:0] alarmHour,
    output reg [7:0] alarmMinute,
    output reg [3:0] Status
);
// Status 0初始 1调小时十位 2调小时个位 3调分钟十位 4调分钟个位 7设置闹钟时十位 8设置闹钟时个位 9设置闹钟分十位 10设置闹钟分个位
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
          Status <= 4'd0;
    end else begin
        // 设个默认的闹钟
        alarmHour <= 'd0;
        alarmMinute <= 'd1;
        if (Status == 4'd0) begin
            // A键
            if (KEY_Value == 4'd10) begin
                Status <= 4'd1;
            // B键
            end else if (Status == 4'd14) begin
                Status <= 4'd3;
            // D键
            end else if (Status == 4'd7) begin
                Status <= 4'd7;
            end
        end else if (Status == 4'd1 && Value_en) begin
            newHour <= {KEY_Value[3:0], 4'b0000};
            Status <= 4'd2;
        end else if (Status == 4'd2 && Value_en) begin
            newHour <= {newHour[7:4], KEY_Value[3:0]};
            Status <= 4'd0;
        end else if (Status == 4'd3 && Value_en) begin
            newMinute <= {KEY_Value[3:0], 4'b0000};
            Status <= 4'd4;
        end else if (Status == 4'd4 && Value_en) begin
            newMinute <= {newMinute[7:4], KEY_Value[3:0]};
            Status <= 4'd0;
        end else if (Status == 4'd7 && Value_en) begin
            alarmHour <= {KEY_Value[3:0], 4'b0000};
            Status <= 4'd8;
        end else if (Status == 4'd8 && Value_en) begin
            alarmHour <= {alarmHour[7:4], KEY_Value[3:0]};
            Status <= 4'd9;
        end else if (Status == 4'd9 && Value_en) begin
            alarmMinute <= {KEY_Value[3:0], 4'b0000};
            Status <= 4'd10;
        end else if (Status == 4'd10 && Value_en) begin
            alarmMinute <= {alarmMinute[7:4], KEY_Value[3:0]};
            Status <= 4'd0;
        end
    end
end
endmodule
    