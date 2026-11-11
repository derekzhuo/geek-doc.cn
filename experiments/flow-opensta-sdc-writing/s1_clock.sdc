# 阶段 1：只建时钟。
# clk 周期 10ns，-waveform 显式给出上升沿 0、下降沿 5（占空比 50%）；
# clk2 周期 15ns，演示后面的异步时钟分组。
create_clock -name clk  -period 10.0 -waveform {0.0 5.0} [get_ports clk]
create_clock -name clk2 -period 15.0 [get_ports clk2]
# 时钟不确定度：综合/抖动余量，仅收紧 setup 0.3ns。
set_clock_uncertainty -setup 0.3 [get_clocks clk]
