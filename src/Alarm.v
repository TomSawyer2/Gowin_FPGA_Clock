module Alarm(
    input CLK,
	input nRST,
    input shouldBool,
    output reg shouldAlarm
);
always @(posedge CLK or negedge nRST) begin
    if (!nRST) begin
        shouldAlarm <= 1'b0;
    end else begin
        if (shouldBool) begin
            shouldAlarm <= 1'b1;
        end else begin
            shouldAlarm <= 1'b0;
        end
    end
end
endmodule