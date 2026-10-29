`timescale 1ns/1ps

module typo_tb;
    integer fd;

    initial begin
        fd = $fopne("smoke.txt", "r");
        $fclose(fd);
    end
endmodule
