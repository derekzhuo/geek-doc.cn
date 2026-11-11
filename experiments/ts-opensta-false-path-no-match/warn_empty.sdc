# 错误：想让 . 充当正则"任意字符"，却没有加 -regexp；默认按 glob 解释，点号是普通字符
set_false_path -to [get_pins {u_b./D}]
