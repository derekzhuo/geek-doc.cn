`timescale 1ns/1ps
module tb;
  reg [7:0] mem [0:7];
  reg [1023:0] mem_file;
  integer i;

  initial begin
    for (i = 0; i < 8; i = i + 1)
      mem[i] = 8'hxx;

    if (!$value$plusargs("MEM_FILE=%s", mem_file)) begin
      $display("FAIL: MEM_FILE plusarg is required");
      $finish(2);
    end

    $readmemh(mem_file, mem);
    for (i = 0; i < 8; i = i + 1)
      $display("mem[%0d]=%02h", i, mem[i]);
    $finish;
  end
endmodule
