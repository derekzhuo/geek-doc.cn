# 教学实验：IO 约束 XDC 模板的 OpenSTA 真实验证
# 依赖 docker 镜像 geek-eda:0.4-flow（内含 Yosys 0.33 与 OpenSTA 2.0.17）
DOCKER = docker run --rm -v "$(PWD)":/work -w /work geek-eda:0.4-flow

.PHONY: all synth sta sta-bad clean

all: synth sta sta-bad

synth:
	$(DOCKER) yosys synth.ys

sta:
	$(DOCKER) sta -no_init -exit run_sta.tcl

sta-bad:
	$(DOCKER) sta -no_init -exit run_sta_bad.tcl

# 一条命令跑完：综合 -> 正确 XDC -> 错误 XDC -> 修正后重跑
run:
	$(DOCKER) sh run_all.sh

clean:
	rm -f top_synth.v synth.log
