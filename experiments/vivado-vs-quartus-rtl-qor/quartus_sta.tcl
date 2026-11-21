set root [pwd]
cd "$root/work/quartus"
project_open fifo_cross
create_timing_netlist
read_sdc "$root/constraints.sdc"
set min_wns ""
set min_whs ""
foreach {corner model temperature} {slow_85c slow 85 fast_0c fast 0} {
    set_operating_conditions -model $model -temperature $temperature -voltage 1200
    update_timing_netlist
    report_clocks
    report_timing -setup -npaths 1 -detail full_path
    report_timing -hold -npaths 1 -detail full_path
    set setup_paths [get_timing_paths -setup -npaths 1]
    set hold_paths [get_timing_paths -hold -npaths 1]
    if {[get_collection_size $setup_paths] == 0 || [get_collection_size $hold_paths] == 0} { error "Missing Quartus timing paths at $corner" }
    set wns ""
    set whs ""
    foreach_in_collection path $setup_paths {
        set wns [get_path_info -slack $path]
        break
    }
    foreach_in_collection path $hold_paths {
        set whs [get_path_info -slack $path]
        break
    }
    puts "QUARTUS_CORNER_RESULT corner=$corner wns=$wns whs=$whs"
    if {$min_wns eq "" || $wns < $min_wns} { set min_wns $wns }
    if {$min_whs eq "" || $whs < $min_whs} { set min_whs $whs }
}
puts "QUARTUS_QOR_RESULT wns=$min_wns whs=$min_whs"
if {$min_wns < 0 || $min_whs < 0} { error "Negative Quartus timing: WNS=$min_wns WHS=$min_whs" }
project_close
