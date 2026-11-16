`timescale 1ns/1ps

module order_ok;

    localparam W = 4;
    reg [W-1:0] cnt;

    initial begin
        cnt = {W{1'b1}};
        if (cnt !== 4'hf) begin
            $display("REF_BEFORE_FLOW_UNEXPECTED cnt=%0h", cnt);
            $finish;
        end
        $display("REF_BEFORE_FLOW_PASS cnt=%0h", cnt);
        #10;
        $finish;
    end

endmodule
