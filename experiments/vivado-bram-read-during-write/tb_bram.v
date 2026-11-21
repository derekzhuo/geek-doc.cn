`timescale 1ns/1ps
module tb_bram;
reg clk = 0;
reg we = 0;
reg [7:0] addr = 0;
reg [15:0] din = 0;
wire [15:0] wf, rf, nc;
integer errors = 0;
bram_write_first a (.clk(clk), .we(we), .addr(addr), .din(din), .dout(wf));
bram_read_first b (.clk(clk), .we(we), .addr(addr), .din(din), .dout(rf));
bram_no_change c (.clk(clk), .we(we), .addr(addr), .din(din), .dout(nc));
always #5 clk = ~clk;
task drive(input [7:0] a, input [15:0] d, input w);
begin
    @(negedge clk); addr = a; din = d; we = w;
    @(posedge clk); #1;
end
endtask
task check(input [15:0] ew, input [15:0] er, input [15:0] en, input [127:0] label);
begin
    $display("BRAM_CASE %s wf=%04x rf=%04x nc=%04x", label, wf, rf, nc);
    if (wf !== ew || rf !== er || nc !== en) begin
        $display("BRAM_EXPECT wf=%04x rf=%04x nc=%04x", ew, er, en);
        errors = errors + 1;
    end
end
endtask
initial begin
    drive(8'h42, 16'ha5a5, 1);
    drive(8'h43, 16'h1234, 1);
    drive(8'h43, 16'h0000, 0);
    check(16'h1234, 16'h1234, 16'h1234, "read_addr_43");
    drive(8'h42, 16'h5a5a, 1);
    check(16'h5a5a, 16'ha5a5, 16'h1234, "write_collision");
    drive(8'h42, 16'h0000, 0);
    check(16'h5a5a, 16'h5a5a, 16'h5a5a, "read_after_write");
    if (errors == 0) $display("BRAM_MODES_PASS cases=3");
    else $fatal(1, "BRAM_MODES_FAIL errors=%0d", errors);
    $finish;
end
endmodule
