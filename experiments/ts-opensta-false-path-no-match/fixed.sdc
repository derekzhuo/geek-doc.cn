# 正确：层次路径用斜杠；约束前先用 -quiet 计数确认对象非空
set target_pins [get_pins u_b/D]
set_false_path -to $target_pins
