define_corners ss ff
read_liberty -corner ss ff.lib
read_liberty -corner ss ss.lib
foreach libcell [get_lib_cells */invx1] {
  puts "PROBE libcell=[get_full_name $libcell]"
}
