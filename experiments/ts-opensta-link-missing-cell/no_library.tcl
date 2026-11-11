set root [file dirname [info script]]
set link_make_black_boxes 0
read_verilog "$root/fixed.v"
link_design top
