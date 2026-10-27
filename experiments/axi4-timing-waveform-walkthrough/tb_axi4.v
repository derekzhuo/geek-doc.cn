// tb_axi4.v — AXI4-Full master testbench: one 4-beat write burst, one 4-beat read burst
`timescale 1ns/1ps
module tb_axi4;
    reg aclk = 0, aresetn = 0;
    always #5 aclk = ~aclk;

    reg  [31:0] awaddr; reg [7:0] awlen; reg [2:0] awsize; reg [1:0] awburst; reg awvalid;
    wire awready;
    reg  [31:0] wdata; reg [3:0] wstrb; reg wlast; reg wvalid; wire wready;
    wire [1:0] bresp; wire bvalid; reg bready;
    reg  [31:0] araddr; reg [7:0] arlen; reg [2:0] arsize; reg [1:0] arburst; reg arvalid;
    wire arready;
    wire [31:0] rdata; wire [1:0] rresp; wire rlast; wire rvalid; reg rready;

    axi4_slave dut (
        .aclk(aclk), .aresetn(aresetn),
        .awaddr(awaddr), .awlen(awlen), .awsize(awsize), .awburst(awburst),
        .awvalid(awvalid), .awready(awready),
        .wdata(wdata), .wstrb(wstrb), .wlast(wlast), .wvalid(wvalid), .wready(wready),
        .bresp(bresp), .bvalid(bvalid), .bready(bready),
        .araddr(araddr), .arlen(arlen), .arsize(arsize), .arburst(arburst),
        .arvalid(arvalid), .arready(arready),
        .rdata(rdata), .rresp(rresp), .rlast(rlast), .rvalid(rvalid), .rready(rready)
    );

    integer errors = 0;
    reg [31:0] golden [0:3];

    initial begin
        $dumpfile("axi4.vcd");
        $dumpvars(0, tb_axi4);

        awaddr=0; awlen=0; awsize=3'b010; awburst=2'b01; awvalid=0;
        wdata=0; wstrb=4'hf; wlast=0; wvalid=0; bready=0;
        araddr=0; arlen=0; arsize=3'b010; arburst=2'b01; arvalid=0; rready=0;
        golden[0]=32'hA5A5_0001; golden[1]=32'hA5A5_0002;
        golden[2]=32'hA5A5_0003; golden[3]=32'hA5A5_0004;

        repeat (4) @(posedge aclk);
        aresetn <= 1;
        @(posedge aclk);

        // ---------- burst write: 4 beats at 0x40 ----------
        awaddr <= 32'h0000_0040; awlen <= 8'd3; awvalid <= 1;
        @(posedge aclk);
        while (!awready) @(posedge aclk);
        awvalid <= 0;
        wvalid <= 1; wdata <= golden[0]; wlast <= 0;
        @(posedge aclk); while (!wready) @(posedge aclk);
        wdata <= golden[1];
        @(posedge aclk); while (!wready) @(posedge aclk);
        wdata <= golden[2];
        @(posedge aclk); while (!wready) @(posedge aclk);
        wdata <= golden[3]; wlast <= 1;
        @(posedge aclk); while (!wready) @(posedge aclk);
        wvalid <= 0; wlast <= 0;

        // write response
        bready <= 1;
        @(posedge aclk);
        while (!bvalid) @(posedge aclk);
        if (bresp !== 2'b00) begin
            $display("ERROR: BRESP=%b expected OKAY", bresp); errors = errors + 1;
        end else
            $display("WRITE burst done: BRESP=OKAY at %0t", $time);
        @(posedge aclk); bready <= 0;

        // ---------- burst read: 4 beats at 0x40 ----------
        araddr <= 32'h0000_0040; arlen <= 8'd3; arvalid <= 1;
        @(posedge aclk);
        while (!arready) @(posedge aclk);
        arvalid <= 0; rready <= 1;
        begin : read_beats
            integer i;
            for (i = 0; i < 4; i = i + 1) begin
                @(posedge aclk);
                while (!rvalid) @(posedge aclk);
                if (rdata !== golden[i]) begin
                    $display("ERROR: beat %0d rdata=%h expected %h", i, rdata, golden[i]);
                    errors = errors + 1;
                end else
                    $display("READ beat %0d: rdata=%h OK at %0t", i, rdata, $time);
                if ((i == 3) && !rlast) begin
                    $display("ERROR: RLAST missing on last beat"); errors = errors + 1;
                end
            end
        end
        @(posedge aclk); rready <= 0;

        if (errors == 0) $display("TB_RESULT: PASS (write+read burst, 4 beats each)");
        else             $display("TB_RESULT: FAIL (%0d errors)", errors);
        $finish;
    end

    initial begin
        #5000;
        $display("TB_RESULT: FAIL (timeout)");
        $finish;
    end
endmodule
