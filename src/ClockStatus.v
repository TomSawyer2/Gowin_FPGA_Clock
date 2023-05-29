module ClockStatus(
    input clk,
	input rstn,
    input Value_en,
    input [3:0] KEY_Value,
    output reg [7:0] newHour,
    output reg [3:0] Status
);
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
          Status <= 4'd0;
    end else begin
        if (Status == 4'd0) begin
            // A键
            if (KEY_Value == 4'd10) begin
                Status <= 4'd1;
            end
        end else if (Status == 4'd1 && Value_en) begin
            case (KEY_Value)
                4'd0: newHour[7:4] <= 4'b0000;
                4'd1: newHour[7:4] <= 4'b0001;
                4'd2: newHour[7:4] <= 4'b0010;
                4'd3: newHour[7:4] <= 4'b0011;
                4'd4: newHour[7:4] <= 4'b0100;
                4'd5: newHour[7:4] <= 4'b0101;
                4'd6: newHour[7:4] <= 4'b0110;
                4'd7: newHour[7:4] <= 4'b0111;
                4'd8: newHour[7:4] <= 4'b1000;
                4'd9: newHour[7:4] <= 4'b1001;
                default: newHour[7:4] <= 4'b0000;
            endcase
            Status <= 4'd2;
        end else if (Status == 4'd2 && Value_en) begin
            case (KEY_Value)
                4'd0: newHour[3:0] <= 4'b0000;
                4'd1: newHour[3:0] <= 4'b0001;
                4'd2: newHour[3:0] <= 4'b0010;
                4'd3: newHour[3:0] <= 4'b0011;
                4'd4: newHour[3:0] <= 4'b0100;
                4'd5: newHour[3:0] <= 4'b0101;
                4'd6: newHour[3:0] <= 4'b0110;
                4'd7: newHour[3:0] <= 4'b0111;
                4'd8: newHour[3:0] <= 4'b1000;
                4'd9: newHour[3:0] <= 4'b1001;
                default: newHour[3:0] <= 4'b0000;
            endcase
            Status <= 4'd0;
        end
    end
end
endmodule
    