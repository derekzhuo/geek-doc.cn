`timescale 1ns/1ps

module timescalemod_top;
    wire pulse;

    timescalemod_leaf u_leaf (
        .pulse(pulse)
    );

    initial begin
        #0.5ns;
        if (pulse !== 1'b0) begin
            $fatal(1, "FAIL: pulse changed before 1ns");
        end

        #1.0ns;
        if (pulse !== 1'b1) begin
            $fatal(1, "FAIL: pulse did not change by 1.5ns");
        end

        $display("PASS: pulse stayed low through 0.5ns and rose by 1.5ns");
        $finish;
    end
endmodule
