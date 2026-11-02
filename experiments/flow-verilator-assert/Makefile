# Verilator --assert 断言最小实验
# 默认走 geek-eda:0.3-sta 容器；本机已装 Verilator 5.x 时可 make NATIVE=1 run
IMAGE ?= geek-eda:0.3-sta
DOCKER ?= docker run --rm -v "$(CURDIR)":/work -w /work $(IMAGE)

ifeq ($(NATIVE),1)
RUN = bash run-native.sh
else
RUN = $(DOCKER) bash run-native.sh
endif

run:
	$(RUN)

clean:
	rm -rf build_noassert build_bad build_fixed

.PHONY: run clean
