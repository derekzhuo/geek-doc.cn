# Build a minimal valid GDS2 stream: one TOP cell with a single box
# on layer 1, datatype 0. Database unit 1 nm.
include RBA

layout = RBA::Layout.new
layout.dbu = 0.001
top = layout.create_cell("TOP")
layer = layout.insert_layer(RBA::LayerInfo.new(1, 0))
top.shapes(layer).insert(RBA::Box.new(0, 0, 1000, 2000))
layout.write("demo.gds")
puts "WROTE demo.gds cells=#{layout.top_cells.size} dbu=#{layout.dbu}"
