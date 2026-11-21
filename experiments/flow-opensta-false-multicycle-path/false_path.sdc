# 仅在 run_en=0 的维护窗口改配置，稳定后才恢复功能采样；配置时钟始终运行。
set_false_path -from [get_cells u_cfg] -to [get_cells u_shadow]
