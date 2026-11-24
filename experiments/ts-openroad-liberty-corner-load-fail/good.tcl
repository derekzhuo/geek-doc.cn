define_corners ss ff
read_liberty -corner ss ss.lib
read_liberty -corner ff ff.lib
read_lef tech.lef
read_lef macro.lef
read_verilog top.v
link_design top
set_input_transition 0.01 [get_ports a]
set_load 0.01 [get_ports z]
foreach scene {ss ff} {
  puts "PROBE scene=$scene"
  report_checks -from [get_ports a] -to [get_ports z] -unconstrained -scenes $scene -path_delay max -format full -fields {slew input_pin net} -digits 4
}
