// Shared testbench tasks for Verilog RTL Starter Lab.
// Each testbench declares `integer errors = 0;` before including this file.
`ifndef TB_TASKS_VH
`define TB_TASKS_VH

// Print PASS/FAIL for one check and accumulate failures into `errors`.
task check_input;
  input cond;
  input [8*64-1:0] msg;
  begin
    if (cond)
      $display("  PASS: %0s", msg);
    else begin
      $display("  FAIL: %0s", msg);
      errors = errors + 1;
    end
  end
endtask

// Print the lab-level verdict and stop the simulation.
task finish_summary;
  input integer err_count;
  begin
    if (err_count == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL (%0d check(s) failed)", err_count);
    $finish;
  end
endtask

`endif
