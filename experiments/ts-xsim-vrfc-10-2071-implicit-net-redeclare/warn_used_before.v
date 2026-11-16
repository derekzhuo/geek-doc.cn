`timescale 1ns/1ps

// Using a localparam before its declaration statement is legal at
// module level: xvlog only emits VRFC 10-756 and the build still passes.
module warn_used_before;

    reg [W-1:0] cnt;
    localparam W = 4;

    initial begin
        cnt = {W{1'b1}};
        $display("WARN_USED_BEFORE cnt=%0h", cnt);
        #10;
        $finish;
    end

endmodule
