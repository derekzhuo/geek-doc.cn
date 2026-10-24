// TB: counter rolls 0..F twice, decode checked against reference LUT.
`timescale 1ns/1ps
module tb_seg7;
    reg clk = 0, rst_n = 0;
    wire [6:0] seg;

    seg7_demo dut (.clk(clk), .rst_n(rst_n), .seg(seg));
    always #5 clk = ~clk;

    reg [6:0] seg_ref [0:15];
    integer i, errors = 0;
    initial begin
        seg_ref[0]=7'b1000000; seg_ref[1]=7'b1111001; seg_ref[2]=7'b0100100; seg_ref[3]=7'b0110000;
        seg_ref[4]=7'b0011001; seg_ref[5]=7'b0010010; seg_ref[6]=7'b0000010; seg_ref[7]=7'b1111000;
        seg_ref[8]=7'b0000000; seg_ref[9]=7'b0010000; seg_ref[10]=7'b0001000; seg_ref[11]=7'b0000011;
        seg_ref[12]=7'b1000110; seg_ref[13]=7'b0100001; seg_ref[14]=7'b0000110; seg_ref[15]=7'b0001110;

        $dumpfile("seg7_demo.vcd");
        $dumpvars(0, tb_seg7);
        repeat (3) @(posedge clk);
        rst_n <= 1;

        for (i = 0; i < 32; i = i + 1) begin
            @(posedge clk); #1;
            if (seg !== seg_ref[dut.cnt]) begin
                errors = errors + 1;
                $display("[%0t] DECODE ERROR cnt=%h seg=%b expect=%b",
                         $time, dut.cnt, seg, seg_ref[dut.cnt]);
            end
        end
        $display("checked 32 clocks, errors=%0d", errors);
        if (errors == 0) $display("RESULT: PASS");
        else             $display("RESULT: FAIL");
        $finish;
    end
endmodule
