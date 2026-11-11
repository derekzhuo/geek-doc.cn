# IO 约束 XDC 模板（正确版）：系统同步输入 + 同源输出 + 虚拟时钟纯输出
# 单位与库一致：ns / pF（库 time_unit 为 1ns）

# 1) 主时钟：板上 100 MHz 晶振进入 clk 端口
create_clock -name clk -period 10.0 [get_ports clk]

# 2) 虚拟时钟：外部器件的捕获时钟没有进入本芯片任何端口，
#    只建时钟不挂端口，专供纯输出口的 output delay 引用
create_clock -name vclk -period 10.0

# 3) 系统同步输入 din：外部芯片沿同一时钟沿发射，
#    板级走线 + 器件 Tco 合计 0.5~1.2 ns（min/max 两套）
set_input_delay -clock clk -min 0.5 [get_ports {din[*]}]
set_input_delay -clock clk -max 1.2 [get_ports {din[*]}]

# 4) 寄存器输出 dout：外部芯片用同一 clk 沿捕获，
#    留给板级走线与对端建立窗口 0.4~1.0 ns
set_output_delay -clock clk -min 0.4 [get_ports {dout[*]}]
set_output_delay -clock clk -max 1.0 [get_ports {dout[*]}]

# 5) 纯输出口 led：对端用板外时钟捕获，引用虚拟时钟 vclk
set_output_delay -clock vclk -min 0.4 [get_ports led]
set_output_delay -clock vclk -max 1.0 [get_ports led]

# 6) 组合直达输出 combo：约束相对 launch 时钟 clk 写
set_output_delay -clock clk -min 0.4 [get_ports combo]
set_output_delay -clock clk -max 1.0 [get_ports combo]

# 7) 环境与余量
set_clock_uncertainty 0.2 [get_clocks clk]
set_input_transition 0.3 [all_inputs]
set_load 0.05 [all_outputs]
