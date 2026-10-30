`timescale 1ns/1ps

module tb;
    reg [7:0] mem [0:3];
    integer index;
    integer i;
    reg [2:0] x_index;

    task show_mem;
        begin
            $display("MEM [0]=%h [1]=%h [2]=%h [3]=%h",
                     mem[0], mem[1], mem[2], mem[3]);
        end
    endtask

    initial begin
        for (i = 0; i < 4; i = i + 1)
            mem[i] = 8'ha0 + i;

        $display("--- runtime out-of-bounds reads ---");
        index = 4;
        $display("READ index=%0d value=%h", index, mem[index]);
        index = -1;
        $display("READ index=%0d value=%h", index, mem[index]);
        x_index = 3'bxxx;
        $display("READ index=x value=%h", mem[x_index]);

        $display("--- runtime out-of-bounds writes ---");
        index = 4;
        mem[index] = 8'hff;
        $display("WRITE index=%0d value=ff", index);
        show_mem;

        index = -1;
        mem[index] = 8'hee;
        $display("WRITE index=%0d value=ee", index);
        show_mem;

        x_index = 3'bxxx;
        mem[x_index] = 8'hdd;
        $display("WRITE index=x value=dd");
        show_mem;

        $display("END: simulation reached finish normally");
        $finish;
    end
endmodule
