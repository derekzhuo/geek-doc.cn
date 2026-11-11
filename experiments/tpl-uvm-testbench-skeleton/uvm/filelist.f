// UVM 五件套模板编译文件清单（需仿真器自带 UVM 库，如 VCS / Questa / Xcelium）
// 用法示例：
//   vcs -sverilog -ntb_opts uvm -f uvm/filelist.f -top top_tb
//   vsim -c -do "vlog +incdir+$UVM_HOME/src $UVM_HOME/src/uvm.sv -f uvm/filelist.f; run -all"
+incdir+.
../sim/dut.sv
my_if.sv
my_item.sv
my_sequencer.sv
my_driver.sv
my_monitor.sv
my_scoreboard.sv
my_coverage.sv
my_agent.sv
my_env.sv
my_test.sv
top_tb.sv
