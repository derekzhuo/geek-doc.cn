read_verilog bank_probe.v
synth_design -top bank_probe -part xc7a35tcpg236-1
foreach pin_name {W5 V17 V16 W16 W17 W15 V15 W14 W13 U16 E19 U19 V19 W18 U15 U14 V14 V13} {
    set pin [get_package_pins -quiet $pin_name]
    if {[llength $pin] != 1} {
        puts "PIN_BANK $pin_name NOT_FOUND"
        continue
    }

    set bank_obj ""
    if {![catch {get_iobanks -quiet -of_objects $pin} result] && [llength $result] > 0} {
        set bank_obj [lindex $result 0]
    }

    set bank_prop ""
    catch {set bank_prop [get_property BANK $pin]}

    puts "PIN_BANK $pin_name bank_obj=$bank_obj bank_prop=$bank_prop"
}
