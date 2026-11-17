`timescale 1ns/1ps
// CP2102 USB-UART bridge link budget experiment (v2).
//
// v1 found two testbench artifacts: (1) the oversampling task's 5-sample
// stop-bit vote kept it from re-arming before the next back-to-back start
// edge below -3.5% error, a scheduling artifact rather than a receiver
// effect; (2) a single aggregate error count could not attribute failures
// to frame pattern or failure reason.
//
// v2 changes: both receivers now finish their stop-bit check exactly at
// the 9.5-bit point and re-arm with identical timing, so midpoint vs
// oversampling differ only in how data bits are sampled; every scenario
// reports 0x55-frame and 0xAA-frame failures separately, and frame errors
// (watchdog/stop) are counted separately from data mismatches.
// Same 25-step sweep (-6.0%..+6.0%, 0.5%), 50 alternating 8N1 frames,
// back-to-back vs 1-frame idle, directly comparable to ch340g control.
module tb;
  localparam real BAUD   = 115200.0;
  localparam real BIT_NS = 1.0e9 / BAUD;
  localparam real TICK   = BIT_NS / 16.0;

  reg line = 1;
  integer k;

  task tx_stream(input real err, input integer frames, input integer idle_bits);
    integer i;
    integer f;
    integer g;
    real bp;
    reg [7:0] d;
    begin
      bp = BIT_NS * (1.0 + err / 100.0);
      for (f = 0; f < frames; f = f + 1) begin
        d = (f % 2 == 0) ? 8'h55 : 8'hAA;
        line = 0; #(bp);
        for (i = 0; i < 8; i = i + 1) begin
          line = d[i]; #(bp);
        end
        line = 1; #(bp);
        for (g = 0; g < idle_bits; g = g + 1) #(BIT_NS);
      end
    end
  endtask

  // Receiver A: nominal midpoint sampler, 20-bit watchdog.
  task rx_mid(output [7:0] data, output integer frame_err);
    integer i;
    integer to;
    begin
      frame_err = 0; data = 8'h00; to = 0;
      fork : wait_mid
        begin @(negedge line); disable wait_mid; end
        begin #(BIT_NS * 20); to = 1; disable wait_mid; end
      join
      if (to) begin
        frame_err = 1;
      end else begin
        #(BIT_NS * 1.5);
        for (i = 0; i < 8; i = i + 1) begin
          data[i] = line;
          #(BIT_NS);
        end
        if (line !== 1) frame_err = 1;
      end
    end
  endtask

  // Receiver B: 16x oversampling. 4-sample start confirmation, 5-of-5
  // majority vote on data bits; stop bit checked at the same 9.5-bit
  // point as receiver A so re-arm timing is identical between the two.
  task rx_ovs(output [7:0] data, output integer frame_err);
    integer to;
    integer i;
    integer j;
    integer ones;
    begin
      frame_err = 0; data = 8'h00; to = 0;
      fork : wait_ovs
        begin : ovs_detect
          forever begin
            @(negedge line);
            #(TICK * 0.5);
            if (line === 0) begin
              #(TICK * 3);
              if (line === 0) disable wait_ovs;
            end
          end
        end
        begin #(BIT_NS * 20); to = 1; disable wait_ovs; end
      join
      if (to) begin
        frame_err = 1;
      end else begin
        // Detection ends ~3.5 ticks after the edge; data bit 0 center is
        // at 24 ticks, first vote sample at (center - 2) = 22 ticks.
        #(TICK * 18.5);
        for (i = 0; i < 8; i = i + 1) begin
          ones = 0;
          for (j = 0; j < 5; j = j + 1) begin
            if (line === 1) ones = ones + 1;
            #(TICK);
          end
          data[i] = (ones >= 3);
          #(TICK * 11);
        end
        // Loop leaves time at the stop bit center minus 2 ticks (150T);
        // advance to the center (152T = 9.5 bits) for a single stop check,
        // matching receiver A's re-arm instant.
        #(TICK * 2);
        if (line !== 1) frame_err = 1;
      end
    end
  endtask

  integer e2;
  reg [7:0] got;
  integer ferr;
  reg [7:0] expect;

  // Per-scenario counters: failures split by frame pattern and reason.
  integer f55;   // 0x55 frames with any failure
  integer faa;   // 0xAA frames with any failure
  integer nferr; // frame errors (watchdog timeout or bad stop bit)
  integer nmis;  // data mismatches with frame_err deasserted

  task run_scenario(input integer use_ovs, input integer idle_bits,
                    input real err);
    begin
      f55 = 0; faa = 0; nferr = 0; nmis = 0;
      fork
        begin #(BIT_NS); tx_stream(err, 50, idle_bits); end
        begin
          for (k = 0; k < 50; k = k + 1) begin
            expect = (k % 2 == 0) ? 8'h55 : 8'hAA;
            if (use_ovs) rx_ovs(got, ferr);
            else         rx_mid(got, ferr);
            if (ferr) begin
              nferr = nferr + 1;
              if (k % 2 == 0) f55 = f55 + 1; else faa = faa + 1;
            end else if (got !== expect) begin
              nmis = nmis + 1;
              if (k % 2 == 0) f55 = f55 + 1; else faa = faa + 1;
            end
          end
        end
      join
    end
  endtask

  initial begin
    $display("CP2102 link bench v2: BAUD=%0d 8N1, 50 frames 0x55/0xAA, TX error swept", BAUD);
    $display("counters per scenario: f55=failed 0x55 frames, faa=failed 0xAA frames, nferr=frame errors, nmis=data mismatches");
    for (e2 = -12; e2 <= 12; e2 = e2 + 1) begin
      run_scenario(0, 0,  e2 / 2.0);
      $display("MEAS err_pct_x0p5=%0d scen=mid_b2b f55=%0d faa=%0d nferr=%0d nmis=%0d",
               e2, f55, faa, nferr, nmis);
      run_scenario(1, 0,  e2 / 2.0);
      $display("MEAS err_pct_x0p5=%0d scen=ovs_b2b f55=%0d faa=%0d nferr=%0d nmis=%0d",
               e2, f55, faa, nferr, nmis);
      run_scenario(0, 10, e2 / 2.0);
      $display("MEAS err_pct_x0p5=%0d scen=mid_idle f55=%0d faa=%0d nferr=%0d nmis=%0d",
               e2, f55, faa, nferr, nmis);
      run_scenario(1, 10, e2 / 2.0);
      $display("MEAS err_pct_x0p5=%0d scen=ovs_idle f55=%0d faa=%0d nferr=%0d nmis=%0d",
               e2, f55, faa, nferr, nmis);
    end
    $display("CP2102_BENCH_DONE");
    $finish;
  end
endmodule
