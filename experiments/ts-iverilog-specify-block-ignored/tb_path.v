`timescale 1ns/1ps

module path_dut(input wire a, output wire y);
    assign y = a;
    specify
        (a => y) = 7;
    endspecify
endmodule

module explicit_delay(input wire a, output wire y);
    assign #7 y = a;
endmodule

module tb_path;
    reg a;
    wire specify_y;
    wire explicit_y;

    path_dut u_specify(.a(a), .y(specify_y));
    explicit_delay u_explicit(.a(a), .y(explicit_y));

    initial begin
        a = 1'b0;
        $display("PATH t=%0t a=%b specify_y=%b explicit_y=%b", $time, a, specify_y, explicit_y);
        #1 a = 1'b1;
        $display("PATH t=%0t a=%b specify_y=%b explicit_y=%b", $time, a, specify_y, explicit_y);
        #1 $display("PATH t=%0t a=%b specify_y=%b explicit_y=%b", $time, a, specify_y, explicit_y);
        #5 $display("PATH t=%0t a=%b specify_y=%b explicit_y=%b", $time, a, specify_y, explicit_y);
        #1 $display("PATH t=%0t a=%b specify_y=%b explicit_y=%b", $time, a, specify_y, explicit_y);
        $finish;
    end
endmodule
