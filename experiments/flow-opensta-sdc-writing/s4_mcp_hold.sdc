# 阶段 4：补全多周期路径的保持侧。
# setup 放宽到 2 拍后，OpenSTA 默认把 hold 检查沿也前推了一拍，
# 同一条路径需要显式声明 -hold 1，把保持检查拉回原时钟沿。
set_multicycle_path -hold 1 -from [get_cells u_a] -to [get_cells u_b]
