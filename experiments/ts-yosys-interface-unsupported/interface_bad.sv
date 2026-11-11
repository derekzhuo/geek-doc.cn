interface counter_if(input logic clk);
    logic req;
    logic [7:0] data;

    modport producer(input clk, input req, output data);
endinterface

module counter(bus);
    counter_if.producer bus;

    always_ff @(posedge bus.clk) begin
        if (bus.req)
            bus.data <= bus.data + 1'b1;
    end
endmodule

module top(input logic clk, input logic req, output logic [7:0] data);
    counter_if bus(clk);
    counter dut(bus);
endmodule
