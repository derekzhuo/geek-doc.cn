read_lef fixtures/tech.lef
read_lef fixtures/cells.lef
read_def fixtures/input.def
set block [ord::get_db_block]

set missing [$block findInst u_missing]
puts "BOUNDARY_EMPTY selection=u_missing result=$missing"
if {$missing eq "NULL"} {
    puts "BOUNDARY_GUARD refusing to modify an empty selection"
    error "EMPTY_SELECTION: u_missing matched zero instances"
}
