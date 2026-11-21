`timescale 1ns/1ps
module tb_axis_register_slice;
reg clk = 0;
reg rst = 1;
reg s_valid = 0;
wire s_ready;
reg [7:0] s_data = 0;
wire m_valid;
reg m_ready = 1;
wire [7:0] m_data;
reg [7:0] expected [0:95];
integer wr_ptr = 0;
integer rd_ptr = 0;
integer errors = 0;
integer i;
integer j = 0;
reg holding = 0;
reg [7:0] held_data = 0;

axis_register_slice dut (
    .clk(clk), .rst(rst),
    .s_valid(s_valid), .s_ready(s_ready), .s_data(s_data),
    .m_valid(m_valid), .m_ready(m_ready), .m_data(m_data)
);
always #5 clk = ~clk;

task send_word(input [7:0] value);
begin
    @(negedge clk);
    s_valid = 1;
    s_data = value;
    @(posedge clk);
    while (!s_ready) @(posedge clk);
end
endtask

always @(posedge clk) begin
    if (!rst) begin
        if (holding && (!m_valid || m_data !== held_data)) begin
            $display("AXIS_STABILITY_FAIL time=%0t valid=%b data=%02x expected=%02x", $time, m_valid, m_data, held_data);
            errors = errors + 1;
        end
        if (s_valid && s_ready) begin
            if (wr_ptr < 96) begin
                expected[wr_ptr] = s_data;
            end else begin
                $display("AXIS_OVERFLOW_FAIL actual=%02x", s_data);
                errors = errors + 1;
            end
            wr_ptr = wr_ptr + 1;
        end
        if (m_valid && m_ready) begin
            if (rd_ptr >= wr_ptr || rd_ptr >= 96) begin
                $display("AXIS_ORDER_FAIL index=%0d actual=%02x", rd_ptr, m_data);
                errors = errors + 1;
            end else if (m_data !== expected[rd_ptr]) begin
                $display("AXIS_ORDER_FAIL index=%0d actual=%02x expected=%02x", rd_ptr, m_data, expected[rd_ptr]);
                errors = errors + 1;
            end
            rd_ptr = rd_ptr + 1;
        end
        holding = m_valid && !m_ready;
        held_data = m_data;
    end
end

initial begin
    repeat (3) @(negedge clk);
    rst = 0;

    m_ready = 1;
    for (i = 0; i < 32; i = i + 1) send_word(i[7:0]);
    @(negedge clk);
    s_valid = 0;
    wait (rd_ptr == 32);
    $display("AXIS_CASE name=continuous transfers=32");

    for (i = 32; i < 64; i = i + 1) begin
        send_word(i[7:0]);
        @(negedge clk);
        s_valid = 0;
        @(posedge clk);
    end
    wait (rd_ptr == 64);
    $display("AXIS_CASE name=bubbles transfers=32");

    fork
        begin
            for (i = 64; i < 96; i = i + 1) send_word(i[7:0]);
            @(negedge clk);
            s_valid = 0;
        end
        begin
            @(negedge clk);
            m_ready = 0;
            repeat (4) @(negedge clk);
            repeat (70) begin
                @(negedge clk);
                m_ready = ((j % 3) != 2);
                j = j + 1;
            end
            @(negedge clk);
            m_ready = 1;
        end
    join
    @(negedge clk);
    s_valid = 0;
    m_ready = 1;
    wait (rd_ptr == 96);
    repeat (2) @(posedge clk);
    if (errors == 0 && wr_ptr == 96 && rd_ptr == 96) begin
        $display("AXIS_CASE name=backpressure transfers=32");
        $display("AXIS_SCENARIOS_PASS transfers=96");
    end else begin
        $display("AXIS_SCENARIOS_FAIL errors=%0d sent=%0d received=%0d", errors, wr_ptr, rd_ptr);
        $fatal(1);
    end
    $finish;
end
endmodule
