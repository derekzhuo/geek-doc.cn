set root [file dirname [info script]]
set link_make_black_boxes 0
read_liberty "$root/experiment.lib"
read_verilog "$root/missing_cell.v"
link_design top
