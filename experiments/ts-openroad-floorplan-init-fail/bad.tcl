read_lef tech.lef
read_lef macro.lef
read_verilog top.v
link_design top
initialize_floorplan -die_area {0 0 0.5 0.5} -core_area {0 0 0.5 0.5} -site unit
