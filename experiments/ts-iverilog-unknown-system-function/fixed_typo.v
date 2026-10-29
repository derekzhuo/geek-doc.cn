`timescale 1ns/1ps

module fixed_tb;
    integer fd;

    initial begin
        fd = $fopen("smoke.txt", "r");
        if (fd == 0) begin
            $display("FAIL: could not open smoke.txt");
            $fatal(1);
        end

        $display("PASS: $fopen opened smoke.txt");
        $fclose(fd);
    end
endmodule
