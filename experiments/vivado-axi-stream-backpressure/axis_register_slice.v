`timescale 1ns/1ps

module axis_register_slice (
    input wire clk,
    input wire rst,
    input wire s_valid,
    output wire s_ready,
    input wire [7:0] s_data,
    output reg m_valid,
    input wire m_ready,
    output reg [7:0] m_data
);
assign s_ready = ~m_valid | m_ready;
always @(posedge clk) begin
    if (rst) begin
        m_valid <= 1'b0;
        m_data <= 8'b0;
    end else if (s_ready) begin
        m_valid <= s_valid;
        if (s_valid) m_data <= s_data;
    end
end
endmodule
