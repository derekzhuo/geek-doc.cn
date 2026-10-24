// tb_axi_lite_regs.v — self-checking AXI4-Lite master driver tasks.
// Exits via $fatal on mismatch (non-zero exit under iverilog -> run_all marks FAIL).
`timescale 1ns/1ps
`default_nettype none
module tb;
    reg        aclk = 0, aresetn = 0;
    always #5 aclk = ~aclk;

    reg  [31:0] awaddr=0;  reg awvalid=0; wire awready;
    reg  [31:0] wdata=0;   reg  wvalid=0; wire wready;
    reg  [ 3:0] wstrb=4'b1111;
    wire [ 1:0] bresp;    wire bvalid;   reg  bready=0;
    reg  [31:0] araddr=0; reg arvalid=0; wire arready;
    wire [31:0] rdata;    wire [1:0] rresp; wire rvalid; reg rready=0;

    axi_lite_regs dut(
        .aclk(aclk), .aresetn(aresetn),
        .awaddr(awaddr), .awvalid(awvalid), .awready(awready),
        .wdata(wdata), .wvalid(wvalid), .wready(wready), .wstrb(wstrb),
        .bresp(bresp), .bvalid(bvalid), .bready(bready),
        .araddr(araddr), .arvalid(arvalid), .arready(arready),
        .rdata(rdata), .rresp(rresp), .rvalid(rvalid), .rready(rready)
    );

    task automatic axi_write(input [31:0] addr, input [31:0] data);
        begin
            @(posedge aclk);
            awaddr=addr; awvalid=1; wdata=data; wvalid=1; bready=1;
            wait (awready && wready);
            @(posedge aclk);
            awvalid=0; wvalid=0;
            wait (bvalid);
            @(posedge aclk); bready=0;
        end
    endtask

    reg [31:0] got_data; reg [1:0] got_resp;
    task automatic axi_read(input [31:0] addr);
        begin
            @(posedge aclk);
            araddr=addr; arvalid=1; rready=1;
            wait (arready);
            @(posedge aclk); arvalid=0;
            wait (rvalid);
            got_data=rdata; got_resp=rresp;
            @(posedge aclk); rready=0;
        end
    endtask

    task check(input [8*40-1:0] name, input [31:0] got, input [31:0] exp);
        begin
            if (got !== exp) begin
                $display("FAIL %0s: got %h expected %h", name, got, exp);
                $fatal(1);
            end else $display("ok   %0s = %h", name, got);
        end
    endtask

    integer k;
    initial begin
        $dumpfile("dump.vcd"); $dumpvars(0, tb);
        repeat (3) @(posedge aclk);
        aresetn = 1;
        repeat (2) @(posedge aclk);

        axi_write(32'h0, 32'hDEAD_BEEF);
        axi_write(32'h4, 32'h1234_5678);
        axi_write(32'h8, 32'hCAFE_F00D);

        axi_read(32'h0); check("reg0", got_data, 32'hDEAD_BEEF);
        if (got_resp !== 2'b00) begin $display("FAIL reg0 resp"); $fatal(1); end
        axi_read(32'h4); check("reg1", got_data, 32'h1234_5678);
        axi_read(32'h8); check("reg2", got_data, 32'hCAFE_F00D);
        axi_read(32'hC); check("reg3-reset", got_data, 32'h0);

        // decode error path
        axi_read(32'h100);
        if (got_resp !== 2'b10) begin $display("FAIL expected SLVERR got %b", got_resp); $fatal(1); end
        $display("ok   out-of-range read returns SLVERR");

        // overwrite / persistence
        axi_write(32'h0, 32'h0000_0001);
        axi_read(32'h0); check("reg0-overwrite", got_data, 32'h1);

        $display("AXI-LITE SELFCHECK PASS");
        $finish;
    end

    initial begin #20000; $display("FAIL watchdog timeout"); $fatal(1); end
endmodule
`default_nettype wire
