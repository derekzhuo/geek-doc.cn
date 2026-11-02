# 阶段 3：在时钟与 IO 约束之上声明三类例外。
# 1) en_in 是近乎静态的使能，不要求单周期到达，按错误路径切断检查。
set_false_path -from [get_ports en_in] -to [get_pins u_b/D]
# 2) u_a -> u_b 明确是两拍才采样一次的路径，setup 放宽到 2 个周期。
#    OpenSTA 中 -from/-to 给时序单元对象（cell），给 Q 引脚会被判为非法起点。
set_multicycle_path -setup 2 -from [get_cells u_a] -to [get_cells u_b]
# 3) clk 与 clk2 是两个异步时钟，互跨路径不由 STA 保证，整组切除。
set_clock_groups -asynchronous \
  -group [get_clocks clk] \
  -group [get_clocks clk2]
