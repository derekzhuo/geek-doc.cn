`timescale 1ns/1ps

module tb;
  reg a;
  reg b;
  wire y_udp;
  wire y_always;
  reg expected;
  integer vector;
  integer failures;

  and2_udp dut_udp(.a(a), .b(b), .y(y_udp));
  and2_always dut_always(.a(a), .b(b), .y(y_always));

  initial begin
    failures = 0;
    for (vector = 0; vector < 4; vector = vector + 1) begin
      {a, b} = vector[1:0];
      expected = a & b;
      #1;
      $display("vector=%0d a=%b b=%b udp=%b always=%b expected=%b",
               vector, a, b, y_udp, y_always, expected);
      if (y_udp !== expected || y_always !== expected ||
          y_udp !== y_always) begin
        failures = failures + 1;
      end
    end

    if (failures == 0) begin
      $display("PASS: 4/4 binary vectors match; udp and always agree");
      $finish;
    end else begin
      $fatal(1, "FAIL: %0d of 4 vectors mismatch", failures);
    end
  end
endmodule
