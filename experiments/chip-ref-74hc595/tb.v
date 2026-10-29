`timescale 1ns/1ps
module tb;
    reg ds = 0, shcp = 0, stcp = 0, mr_n = 1, oe_n = 0;
    wire [7:0] q;
    wire q7s;
    integer i;
    integer errors = 0;
    reg [7:0] pattern = 8'ha6;

    shift_74hc595 dut(.ds(ds), .shcp(shcp), .stcp(stcp), .mr_n(mr_n), .oe_n(oe_n), .q(q), .q7s(q7s));

    task pulse_shcp;
        begin
            #2 shcp = 1;
            #2 shcp = 0;
        end
    endtask

    initial begin
        #2 mr_n = 0;
        #2 stcp = 1;
        #2 stcp = 0;
        #2 mr_n = 1;
        for (i = 7; i >= 0; i = i - 1) begin
            ds = pattern[i];
            pulse_shcp;
        end
        #1;
        if (q !== 8'h00) begin
            errors = errors + 1;
            $display("FAIL latch changed before STCP q=%02h", q);
        end
        if (q7s !== pattern[7]) begin
            errors = errors + 1;
            $display("FAIL serial output q7s=%b", q7s);
        end
        #2 stcp = 1;
        #2 stcp = 0;
        #1;
        if (q !== 8'ha6) begin
            errors = errors + 1;
            $display("FAIL latched q=%02h expected=a6", q);
        end else begin
            $display("LATCH q=a6 after eight shifts and one STCP");
        end
        oe_n = 1;
        #1;
        if (q !== 8'hzz) begin
            errors = errors + 1;
            $display("FAIL OE high q=%02h expected=zz", q);
        end else begin
            $display("TRISTATE OE high released outputs");
        end
        oe_n = 0;
        mr_n = 0;
        #1;
        if (q !== 8'ha6 || q7s !== 1'b0) begin
            errors = errors + 1;
            $display("FAIL MR immediate q=%02h q7s=%b", q, q7s);
        end else begin
            $display("RESET MR low cleared shift register but Q held a6");
        end
        #2 stcp = 1;
        #2 stcp = 0;
        #1;
        if (q !== 8'h00) begin
            errors = errors + 1;
            $display("FAIL latch after reset q=%02h", q);
        end else begin
            $display("LATCH next STCP copied cleared shift register to Q");
        end
        $display("SUMMARY errors=%0d", errors);
        if (errors == 0) $display("PASS shift latch tristate reset");
        else $display("FAIL mismatches detected");
        $finish;
    end
endmodule
