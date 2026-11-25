proc require {condition message} {
    if {![uplevel 1 [list expr $condition]]} {
        error "ASSERT_FAILED: $message"
    }
}

source connectivity.tcl

read_lef fixtures/tech.lef
read_lef fixtures/cells.lef
read_def fixtures/input.def

set block [ord::get_db_block]
require {$block ne "NULL"} "database block is missing"
set insts [$block getInsts]
set nets [$block getNets]
set pins [$block getBTerms]
set libs [[ord::get_db] getLibs]
require {[llength $insts] == 3} "expected 3 instances"
require {[llength $nets] == 4} "expected 4 nets"
require {[llength $pins] == 2} "expected 2 top-level pins"

puts "COUNTS libs=[llength $libs] instances=[llength $insts] nets=[llength $nets] top_pins=[llength $pins]"
set before_connectivity [connectivity_snapshot $block]
print_connectivity "CONNECT_BEFORE" $before_connectivity

define_property -object_type instance -type string review_state
set sta_instances [get_cells *]
require {[llength $sta_instances] == 3} "set_property selection must contain 3 instances"
foreach sta_instance $sta_instances {
    set_property $sta_instance review_state ready_for_shift
    set sta_name [get_full_name $sta_instance]
    set review [get_property $sta_instance review_state]
    require {$review eq "ready_for_shift"} "set_property readback failed for $sta_name"
    puts "SETPROPERTY inst=$sta_name review_state=$review"
}

foreach inst $insts {
    set name [$inst getName]
    lassign [$inst getLocation] old_x old_y
    set old_status [$inst getPlacementStatus]
    puts "BEFORE inst=$name master=[[$inst getMaster] getName] status=$old_status x=$old_x y=$old_y"

    set prop [odb::dbStringProperty_create $inst audit_tag shift_0p5um_v1]
    require {$prop ne "NULL"} "property creation failed for $name"
    require {[odb::dbStringProperty_getValue $prop] eq "shift_0p5um_v1"} "property readback failed for $name"

    set new_x [expr {$old_x + 500}]
    $inst setLocation $new_x $old_y
    $inst setPlacementStatus FIRM
    puts "AFTER inst=$name status=[$inst getPlacementStatus] x=$new_x y=$old_y audit_tag=[odb::dbStringProperty_getValue [odb::dbStringProperty_find $inst audit_tag]]"
}

set after_connectivity [connectivity_snapshot $block]
require {$after_connectivity eq $before_connectivity} "connectivity changed during attribute edits"
print_connectivity "CONNECT_AFTER" $after_connectivity
puts "CONNECTIVITY_RESULT PASS before_after_equal=1 nets=4"
write_def results/roundtrip.def
puts "WRITE_DEF path=results/roundtrip.def instances=[llength $insts] shift_dbu=500"
