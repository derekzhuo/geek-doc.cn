# 诊断三件套：时钟对象与源点 / 时钟网络逐脚连通性 / 端点覆盖
proc clock_chain {} {
  puts "DIAG all_clocks:"
  foreach c [all_clocks] {
    puts "  CLOCK=[get_property $c name] sources=[get_property $c sources]"
  }
  puts "DIAG clock network pins (clk -> u_clkbuf -> u_stage/C):"
  foreach pn {u_clkbuf/A u_clkbuf/Y u_stage/C} {
    puts "  PIN=$pn clocks=[get_property [get_pins $pn] clocks]"
  }
}
