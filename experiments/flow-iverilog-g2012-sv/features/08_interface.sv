// 08 interface + modport: 接口封装与 modport 视角
interface itf #(parameter W = 8) (input logic clk);
  logic [W-1:0] data;
  logic valid;
  modport sink  (input clk, input data, input valid);
  modport source(output data, output valid, input clk);
endinterface

module receiver(itf.sink p);
  logic [p.W-1:0] got;
  always_ff @(posedge p.clk) if (p.valid) got <= p.data;
endmodule

module t;
  logic clk = 0;
  always #5 clk = ~clk;
  itf u_bus(.clk(clk));
  receiver r(.p(u_bus.sink));
  initial begin
    @(posedge clk);
    u_bus.data = 8'ha7; u_bus.valid = 1;
    @(posedge clk);
    u_bus.valid = 0;
    repeat (2) @(posedge clk);
    $display("PASS interface: got=0x%0h (expect a7)", r.got);
    $finish;
  end
endmodule
