add_wave {{/tb_counter4/dut/clk} {/tb_counter4/dut/rst_n} {/tb_counter4/dut/count}}
run all
save_wave_config C:/eda-lab/xsim-du/wave.wcfg
close_wave_config
set fp [open C:/eda-lab/xsim-du/wave.wcfg r]
set xml [read $fp]
close $fp
regsub -all {<ZoomStartTime>[^<]*</ZoomStartTime>} $xml {<ZoomStartTime>0</ZoomStartTime>} xml
regsub -all {<ZoomEndTime>[^<]*</ZoomEndTime>} $xml {<ZoomEndTime>300000000</ZoomEndTime>} xml
set fp [open C:/eda-lab/xsim-du/wave.wcfg w]
puts -nonewline $fp $xml
close $fp
open_wave_config C:/eda-lab/xsim-du/wave.wcfg
