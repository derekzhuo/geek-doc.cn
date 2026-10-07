# Makefile —— 同一个真实 VCD 的三轨呈现对比实验
# make run 依次产出：
#   out/wave-window.json   轨① wavedrom 的 WaveJSON（10ns-90ns 窗口）
#   out/wave-table.txt     轨③ awk 解码 VCD 得到的文本对照表
#   out/vcd-excerpt.txt    轨③ VCD 原文节选（头部 + 复位释放段）
#   out/gtkwave.png        轨② GTKWave 无头截图（Xvfb + ImageMagick）

.PHONY: run clean

run: wavedrom table shot
	@echo "== 三轨产物 =="
	@ls -l out/

wavedrom: wave-window.json | out
	cp wave-window.json out/wave-window.json

table: counter.vcd vcd2table.awk | out
	awk -f vcd2table.awk counter.vcd > out/wave-table.txt
	{ sed -n '1,40p' counter.vcd; echo '...(略)...'; \
	  sed -n '/^#10000/,/^#35000/p' counter.vcd; } > out/vcd-excerpt.txt

shot: counter.vcd signals.gtkw shot.sh | out
	sh shot.sh

out:
	mkdir -p out

clean:
	rm -rf out
