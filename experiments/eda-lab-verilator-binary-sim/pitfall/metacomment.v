// metacomment.v —— 坑 2 复现素材：下一行注释以「verilator 」开头，
// verilator 会把「// verilator ...」当作 lint pragma 解析，后面跟的不是合法指令就报错。
// verilator 要求：这句话会被当成 Unknown verilator comment
module metacomment (
    input  wire clk,
    output wire y
);
    assign y = clk;
endmodule
