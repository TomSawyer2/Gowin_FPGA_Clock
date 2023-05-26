module btn_deb (
    input            clk,
    input            btn_in,                           
    output reg       btn_out
    );
    reg [7:0] time_cnt=18'd0;//21ms计时计数寄存器；
    always @(posedge clk)
    begin
        time_cnt <= time_cnt + 18'd1;  //计数器到20'hf_ffff时周期约为21ms
    end
    always @(posedge clk)
    begin
        if(time_cnt == 0)   //每隔21ms取一次按键状态值；
            btn_out <= ~btn_in;
    end
endmodule
