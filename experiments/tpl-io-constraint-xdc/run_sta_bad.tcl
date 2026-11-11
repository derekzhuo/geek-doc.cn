# OpenSTA：读错误 XDC，复现端口名写错后的报错与漏约束
read_liberty mini.lib
read_verilog top_synth.v
link_design top
read_sdc io_bad.xdc
puts "===== CHECKS AFTER BAD XDC ====="
report_checks -path_delay min_max -digits 3
