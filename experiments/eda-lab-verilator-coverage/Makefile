VERILATOR ?= verilator
COV       ?= verilator_coverage

.PHONY: run naive full clean

run: naive full

# 第一轮：朴素 TB，收集 line/toggle 覆盖
naive:
	$(VERILATOR) --cc --exe --build --coverage --timing -Mdir obj_naive -o sim_naive \
	    --top-module tb_naive counter.v tb_naive.v sim_main.cpp \
	    -CFLAGS '-DTOP_HEADER=Vtb_naive.h -DTOP_CLASS=Vtb_naive -DCOV_FILE=\"coverage_naive.dat\"' \
	    2>&1 | tee out/build_naive.log
	./obj_naive/sim_naive 2>&1 | tee out/run_naive.log
	mv coverage_naive.dat out/coverage_naive.dat
	$(COV) --write-info out/coverage_naive.info out/coverage_naive.dat \
	    2>&1 | tee out/cov_write_naive.log

# 第二轮：补全 TB，同口径收集
full:
	$(VERILATOR) --cc --exe --build --coverage --timing -Mdir obj_full -o sim_full \
	    --top-module tb_full counter.v tb_full.v sim_main.cpp \
	    -CFLAGS '-DTOP_HEADER=Vtb_full.h -DTOP_CLASS=Vtb_full -DCOV_FILE=\"coverage_full.dat\"' \
	    2>&1 | tee out/build_full.log
	./obj_full/sim_full 2>&1 | tee out/run_full.log
	mv coverage_full.dat out/coverage_full.dat
	$(COV) --write-info out/coverage_full.info out/coverage_full.dat \
	    2>&1 | tee out/cov_write_full.log

clean:
	rm -rf obj_naive obj_full out coverage_naive.dat coverage_full.dat
