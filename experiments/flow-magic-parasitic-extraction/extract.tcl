load nmos
box 2 4 18 10
paint ndiff
box 8 2 12 14
paint poly
box 2 4 8 10
label a center ndiff
box 12 4 18 10
label y center ndiff
box 8 12 12 14
label g center poly
box 0 0 20 20
save nmos
extract all
puts "EXTRACT_DONE=nmos.ext"
ext2spice cthresh 0
ext2spice rthresh 0
ext2spice
file rename -force nmos.spice nmos_c0.spice
puts "NETLIST_C0=nmos_c0.spice"
ext2spice cthresh 1000
ext2spice
file rename -force nmos.spice nmos_cthresh1000.spice
puts "NETLIST_CTHRESH1000=nmos_cthresh1000.spice"
puts "CTHRESH_QUERY_BEGIN"
ext2spice cthresh
puts "CTHRESH_QUERY_END"
quit -noprompt
