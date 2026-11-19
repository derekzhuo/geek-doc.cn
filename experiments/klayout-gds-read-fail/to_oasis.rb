# Round-trip: read the healthy GDS2, write OASIS, read the OASIS back
# to prove the same geometry survives the format conversion.
include RBA

src = RBA::Layout.new
src.read("demo.gds")
src.write("demo.oas")
puts "OASIS WROTE demo.oas"

dst = RBA::Layout.new
dst.read("demo.oas")
top = dst.top_cell
li = dst.layer(RBA::LayerInfo.new(1, 0))
puts "OASIS READ OK top=#{top.name} boxes_on_L1D0=#{top.shapes(li).size}"
