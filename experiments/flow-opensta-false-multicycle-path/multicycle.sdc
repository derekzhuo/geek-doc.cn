# setup 把捕获沿向后移动 1 拍；hold 1 把默认前推的 hold 沿拉回原位。
set_multicycle_path -setup 2 -from [get_cells u_a] -to [get_cells u_b]
set_multicycle_path -hold  1 -from [get_cells u_a] -to [get_cells u_b]
