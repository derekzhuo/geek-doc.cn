`timescale 1ns/1ps

module tb;
    reg r;
    reg driver;
    wire w;

    assign w = driver;

    initial begin
        r = 1'b0;
        driver = 1'b0;
        #1 $display("step=initial          reg=%b wire=%b driver=%b", r, w, driver);

        force r = 1'b1;
        force w = 1'b1;
        #1 $display("step=forced           reg=%b wire=%b driver=%b", r, w, driver);

        driver = 1'b1;
        #1 $display("step=forced_driver_1  reg=%b wire=%b driver=%b", r, w, driver);

        driver = 1'b0;
        #1 $display("step=forced_driver_0  reg=%b wire=%b driver=%b", r, w, driver);

        release r;
        release w;
        #1 $display("step=released         reg=%b wire=%b driver=%b", r, w, driver);

        driver = 1'b1;
        #1 $display("step=driver_1         reg=%b wire=%b driver=%b", r, w, driver);

        r = 1'b0;
        #1 $display("step=reg_reassigned   reg=%b wire=%b driver=%b", r, w, driver);

        $finish;
    end
endmodule
