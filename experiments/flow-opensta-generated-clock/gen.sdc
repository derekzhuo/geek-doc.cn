# 版本二：在分频触发器输出上声明 2 分频生成时钟。
# -source 指主时钟实际到达的触发器时钟引脚，-divide_by 2 给出分频关系，
# 生成时钟自动继承主时钟的源延迟，周期为 8.0 ns。
create_clock -name clk -period 4.0 [get_ports clk]
create_generated_clock -name clk_div2 \
  -source [get_pins u_div/C] -divide_by 2 \
  [get_pins u_div/Q]
set_propagated_clock [all_clocks]
set_input_delay 0.30 -max -clock clk [get_ports d_in]
set_input_delay 0.15 -min -clock clk [get_ports d_in]
