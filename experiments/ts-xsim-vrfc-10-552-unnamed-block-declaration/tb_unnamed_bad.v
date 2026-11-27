`timescale 1ns/1ps

module tb_unnamed_bad;
  initial begin
    integer count;
    count = 0;
    #10 count = count + 3;
    if (count == 3) begin
      $display("DECLARATION_SCOPE_SIM_PASS count=%0d", count);
    end else begin
      $display("DECLARATION_SCOPE_SIM_FAIL count=%0d", count);
    end
    #10;
    $finish;
  end
endmodule
