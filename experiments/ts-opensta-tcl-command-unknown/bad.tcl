read_liberty tiny.lib
read_verilog top.v
link_design top
read_sdc base.sdc
report_qor
