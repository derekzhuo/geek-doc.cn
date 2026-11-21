`timescale 1ns/1ps
module tb_cdc;
reg src_clk = 0;
reg dest_clk = 0;
reg src_in = 0;
wire xpm_out;
wire hand_out;
integer seed = 32'h20171122;
integer cycles;

cdc_xpm x (.src_clk(src_clk), .src_in(src_in), .dest_clk(dest_clk), .dest_out(xpm_out));
cdc_hand h (.src_clk(src_clk), .src_in(src_in), .dest_clk(dest_clk), .dest_out(hand_out));
always #3.5 src_clk = ~src_clk;
always #5 dest_clk = ~dest_clk;
always @(negedge src_clk) src_in = ($random(seed) & 1);

initial begin
    repeat (3) @(negedge dest_clk);
    for (cycles = 0; cycles < 512; cycles = cycles + 1) begin
        @(posedge dest_clk);
        #1;
        if (xpm_out !== hand_out) begin
            $display("CDC_EQUIV_FAIL cycle=%0d src_in=%b xpm=%b hand=%b", cycles, src_in, xpm_out, hand_out);
            $fatal(1);
        end
    end
    $display("CDC_EQUIV_PASS cycles=%0d", cycles);
    $finish;
end
endmodule
