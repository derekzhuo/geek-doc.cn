all: run

run: nodump dumpoff fixed

nodump:
	iverilog -o simv_nodump tb_blink_nodump.v blink.v
	vvp simv_nodump
	ls *.vcd

dumpoff:
	iverilog -o simv_off tb_blink_dumpoff.v blink.v
	vvp simv_off
	wc -l blink_off.vcd

fixed:
	iverilog -o simv tb_blink.v blink.v
	vvp simv
	wc -l blink.vcd

clean:
	rm -f simv simv_nodump simv_off *.vcd

.PHONY: all run nodump dumpoff fixed clean
