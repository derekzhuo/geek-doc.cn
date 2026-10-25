open_vcd dump.vcd
log_vcd [get_objects -r /tb_ts/*]
run 200ns
close_vcd
quit
