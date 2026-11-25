proc require {condition message} {
    if {![uplevel 1 [list expr $condition]]} {
        error "ASSERT_FAILED: $message"
    }
}

source connectivity.tcl

read_lef fixtures/tech.lef
read_lef fixtures/cells.lef
read_def results/roundtrip.def
set block [ord::get_db_block]
require {$block ne "NULL"} "database block is missing after re-read"
require {[llength [$block getInsts]] == 3} "instance count changed"
require {[llength [$block getNets]] == 4} "net count changed"
require {[llength [$block getBTerms]] == 2} "top-level pin count changed"

set expected_connectivity {}
lappend expected_connectivity [list n0 [list u_buf0:A] [list a]]
lappend expected_connectivity [list n1 [list u_buf0:Y u_buf1:A] [list]]
lappend expected_connectivity [list n2 [list u_buf1:Y u_buf2:A] [list]]
lappend expected_connectivity [list n3 [list u_buf2:Y] [list y]]
set actual_connectivity [connectivity_snapshot $block]
require {$actual_connectivity eq $expected_connectivity} "net or terminal attachments changed after DEF re-read"
print_connectivity "CONNECT_REREAD_PASS" $actual_connectivity

define_property -object_type instance -type string review_state
set sta_instances [get_cells *]
require {[llength $sta_instances] == 3} "set_property reread selection must contain 3 instances"
foreach sta_instance $sta_instances {
    set sta_name [get_full_name $sta_instance]
    set review [get_property $sta_instance review_state]
    require {$review eq ""} "set_property value unexpectedly serialized for $sta_name"
    puts "SETPROPERTY_REREAD inst=$sta_name review_state=empty"
}

set expected_x {u_buf0 1500 u_buf1 3500 u_buf2 5500}
foreach inst [$block getInsts] {
    set name [$inst getName]
    lassign [$inst getLocation] x y
    set wanted [dict get $expected_x $name]
    require {$x == $wanted && $y == 1000} "$name location did not persist"
    require {[$inst getPlacementStatus] eq "FIRM"} "$name placement status did not persist"
    set transient [odb::dbStringProperty_find $inst audit_tag]
    require {$transient eq "NULL"} "generic ODB property unexpectedly serialized for $name"
    puts "REREAD_PASS inst=$name status=[$inst getPlacementStatus] x=$x y=$y audit_tag=absent"
}
puts "ROUNDTRIP_RESULT PASS instances=3 nets=4 top_pins=2 connectivity=exact set_property=transient shift_dbu=500 status=FIRM"
