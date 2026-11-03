// 两级流水延迟寄存器：s 侧拍入，每个时钟沿向后挪一级，两拍后从 m 侧吐出
module pipe_delay #(
    parameter int STAGES = 2
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] s_data,
    input  wire       s_valid,
    output wire [7:0] m_data,
    output wire       m_valid
);
    reg [7:0] data_pipe  [0:STAGES-1];
    reg       valid_pipe [0:STAGES-1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < STAGES; i = i + 1) begin
                data_pipe[i]  <= 8'h00;
                valid_pipe[i] <= 1'b0;
            end
        end else begin
            data_pipe[0]  <= s_data;
            valid_pipe[0] <= s_valid;
            for (int i = 1; i < STAGES; i = i + 1) begin
                data_pipe[i]  <= data_pipe[i-1];
                valid_pipe[i] <= valid_pipe[i-1];
            end
        end
    end

    assign m_data  = data_pipe[STAGES-1];
    assign m_valid = valid_pipe[STAGES-1];
endmodule
