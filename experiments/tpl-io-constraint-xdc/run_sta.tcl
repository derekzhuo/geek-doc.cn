# OpenSTA：读库 + 读综合后网表 + 读正确 XDC + 报时序
read_liberty mini.lib
read_verilog top_synth.v
link_design top
read_sdc io_good.xdc
puts "===== SETUP / HOLD CHECKS (good xdc) ====="
report_checks -path_delay min_max -digits 3
