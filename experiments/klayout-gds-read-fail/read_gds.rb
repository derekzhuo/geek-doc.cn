# Generic reader: load the stream file named in the INPUT environment
# variable and print one summary line. KLayout consumes positional .gds
# arguments itself, so the path is passed through the environment instead
# of Ruby ARGV. Fails with a non-zero exit code on any parse error,
# which is exactly what the experiment observes.
include RBA

path = ENV["INPUT"] || raise("usage: INPUT=<stream-file> klayout -b -r read_gds.rb")
layout = RBA::Layout.new
layout.read(path)
top = layout.top_cell || raise("no top cell in #{path}")
li = layout.layer(RBA::LayerInfo.new(1, 0))
count = li >= 0 ? top.shapes(li).size : 0
puts "READ OK #{path} top=#{top.name} boxes_on_L1D0=#{count}"
