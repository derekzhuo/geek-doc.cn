`timescale 1ns/1ps
module tb_fsm;
reg clk = 0;
reg rst = 1;
reg go = 0;
wire [6:0] gb, gg, goh;
integer cycles;
integer seed = 32'h20171122;
fsm_binary b (.clk(clk), .rst(rst), .go(go), .grant(gb));
fsm_gray g (.clk(clk), .rst(rst), .go(go), .grant(gg));
fsm_onehot o (.clk(clk), .rst(rst), .go(go), .grant(goh));
always #5 clk = ~clk;
initial begin
    repeat (4) @(posedge clk);
    rst <= 0;
    for (cycles = 0; cycles < 512; cycles = cycles + 1) begin
        @(negedge clk);
        go = ($random(seed) & 3) != 0;
        @(posedge clk);
        #1;
        if (gb !== gg || gb !== goh) begin
            $display("FSM_EQUIV_FAIL cycle=%0d go=%0d binary=%b gray=%b onehot=%b", cycles, go, gb, gg, goh);
            $fatal(1);
        end
    end
    $display("FSM_EQUIV_PASS cycles=%0d", cycles);
    $finish;
end
endmodule
