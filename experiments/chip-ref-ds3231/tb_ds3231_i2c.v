`timescale 1ns/1ps
// DS3231 I2C RTC register-level behavior experiment.
//
// A minimal open-drain I2C master BFM talks to a behavioral DS3231 slave
// model (7-bit addr 0x68, register file 0x00..0x12, BCD timekeeping with
// a 1 Hz tick, pointer auto-increment with wrap at 0x13, read-only
// temperature registers 0x11/0x12). Six scenarios, each one MEAS line:
//   S1 bus scan: only 0x68 ACKs (1 ACK / 126 NACK over addresses 1..127)
//   S2 time write + repeated-START readback of regs 00..02
//   S3 wrong address 0x69 is NACKed and the register file stays untouched
//   S4 pointer auto-increment: aging/temp/wrap-to-00, temp regs read-only
//   S5 BCD rollover 58s59m -> 00s00m with hour carry, real 1 Hz tick
//   S6 same write/readback at 400 kHz fast mode
// All timing checks (tSU/tHD/tLOW) are out of scope: this bench verifies
// protocol/register semantics, not electrical timing compliance.
module ds3231_model (
  input scl,
  inout sda
);
  localparam [6:0] ADDR = 7'h68;

  reg [7:0] regs [0:18];
  reg [5:0] ptr;
  reg [2:0] state; // 0 IDLE, 1 ADDR, 2 WRITE, 3 READ
  reg [7:0] shifter;
  reg [3:0] bitcnt;
  reg       in_ack;
  reg       rw;
  reg       matched;
  reg       ptr_phase; // first data byte of a write sets the pointer
  reg       s_sda;

  integer k;

  assign sda = s_sda;

  initial begin
    state = 0; bitcnt = 0; in_ack = 0; rw = 1'b0;
    ptr = 0; matched = 0; ptr_phase = 0; s_sda = 1'bz;
    for (k = 0; k <= 18; k = k + 1) regs[k] = 8'h00;
    regs[8'h11] = 8'h1e; // 30.00 C temp MSB
    regs[8'h12] = 8'h00;
  end

  // 1 Hz timekeeping tick with BCD carry (24-hour mode).
  initial forever begin
    #1000000000;
    if (regs[0] == 8'h59) begin
      regs[0] = 8'h00;
      if (regs[1] == 8'h59) begin
        regs[1] = 8'h00;
        if (regs[2] == 8'h23) regs[2] = 8'h00;
        else regs[2] = regs[2] + ((regs[2][3:0] == 4'h9) ? 8'h7 : 8'h1);
      end else begin
        regs[1] = regs[1] + ((regs[1][3:0] == 4'h9) ? 8'h7 : 8'h1);
      end
    end else begin
      regs[0] = regs[0] + ((regs[0][3:0] == 4'h9) ? 8'h7 : 8'h1);
    end
  end

  // START / repeated START: SDA falls while SCL is high.
  always @(negedge sda) begin
    if (scl === 1'b1) begin
      state = 1; bitcnt = 0; in_ack = 0;
      matched = 0; ptr_phase = 0; s_sda = 1'bz;
    end
  end

  // STOP: SDA rises while SCL is high.
  always @(posedge sda) begin
    if (scl === 1'b1) begin
      state = 0; s_sda = 1'bz;
    end
  end

  // Capture data/address bits on SCL rising edges.
  always @(posedge scl) begin
    if (state != 0 && bitcnt < 8) begin
      shifter = {shifter[6:0], sda};
      bitcnt = bitcnt + 1;
    end
  end

  // ACK drive, state transitions and register commits on SCL falling edges.
  always @(negedge scl) begin
    if (state != 0) begin
      if (bitcnt == 8 && !in_ack) begin
        // Opening the ACK cell: drive ACK low when addressed.
        in_ack = 1;
        if (state == 1) begin
          matched = (shifter[7:1] == ADDR);
          rw = shifter[0];
          s_sda = matched ? 1'b0 : 1'bz;
        end else if (state == 2) begin
          s_sda = 1'b0; // write: slave ACKs data bytes
        end else begin
          s_sda = 1'bz; // read: master owns the ACK/NACK bit
        end
      end else if (bitcnt == 8 && in_ack) begin
        // Closing the ACK cell.
        in_ack = 0; bitcnt = 0; s_sda = 1'bz;
        if (state == 1) begin
          if (!matched) begin
            state = 0;
          end else if (rw == 1'b0) begin
            state = 2; ptr_phase = 1; // next byte sets the register pointer
          end else begin
            // READ: drive the first byte MSB before the next rising edge.
            state = 3;
            s_sda = regs[ptr][7] ? 1'bz : 1'b0;
          end
        end else if (state == 2) begin
          if (ptr_phase) begin
            ptr = shifter[5:0];
            ptr_phase = 0;
          end else begin
            // Temperature registers 0x11/0x12 are read-only.
            if (ptr != 8'h11 && ptr != 8'h12) regs[ptr] = shifter;
            ptr = (ptr == 6'd18) ? 6'd0 : ptr + 6'd1;
          end
        end else if (state == 3) begin
          if (sda === 1'b0) begin
            // Master ACK: advance pointer and drive the next byte MSB now,
            // before the first data bit cell's rising edge.
            ptr = (ptr == 6'd18) ? 6'd0 : ptr + 6'd1;
            s_sda = regs[ptr][7] ? 1'bz : 1'b0;
          end else begin
            state = 0; // Master NACK ends the read.
          end
        end
      end else if (state == 3 && bitcnt < 8) begin
        // Cell-closing negedge after bit cell k (bitcnt == k+1): drive
        // the next bit; bit7 is driven at ACK-close above.
        s_sda = regs[ptr][7 - bitcnt] ? 1'bz : 1'b0;
      end
    end
  end

endmodule

module tb;
  tri scl;
  tri sda;
  pullup(scl);
  pullup(sda);

  reg m_scl;
  reg m_sda;
  assign scl = m_scl;
  assign sda = m_sda;

  ds3231_model dut (.scl(scl), .sda(sda));

  integer bit_ns; // SCL bit cell width, switched per scenario
  integer q;
  integer i;
  integer ack_cnt;
  integer nack_cnt;
  integer match_cnt;
  integer mismatch_cnt;
  reg [7:0] got;
  reg       ack;

  initial begin
    m_scl = 1'bz; m_sda = 1'bz;
    bit_ns = 10000; // 100 kHz
  end

  task i2c_start;
    begin
      q = bit_ns / 4;
      m_sda = 1'bz; #q; m_scl = 1'bz; #q;
      m_sda = 1'b0;  #q; m_scl = 1'b0; #q;
    end
  endtask

  task i2c_stop;
    begin
      q = bit_ns / 4;
      m_scl = 1'b0; #q; m_sda = 1'b0; #q;
      m_scl = 1'bz; #q; m_sda = 1'bz; #q;
    end
  endtask

  task i2c_tx(input [7:0] b, output got_ack);
    integer j;
    begin
      q = bit_ns / 4;
      for (j = 7; j >= 0; j = j - 1) begin
        m_scl = 1'b0; #q;
        m_sda = b[j] ? 1'bz : 1'b0; #q;
        m_scl = 1'bz; #(2*q);
        m_scl = 1'b0; #q;
      end
      // ACK cell: release SDA, sample at SCL high.
      m_scl = 1'b0; #q; m_sda = 1'bz; #q;
      m_scl = 1'bz; #q; got_ack = (sda === 1'b0); #q;
      m_scl = 1'b0; #q;
    end
  endtask

  task i2c_rx(input send_ack, output [7:0] b);
    integer j;
    begin
      q = bit_ns / 4;
      b = 8'h00;
      for (j = 7; j >= 0; j = j - 1) begin
        m_scl = 1'b0; #q; m_sda = 1'bz; #q;
        m_scl = 1'bz; #q; b[j] = sda; #q;
        m_scl = 1'b0; #q;
      end
      m_scl = 1'b0; #q;
      m_sda = send_ack ? 1'b0 : 1'bz; #q;
      m_scl = 1'bz; #(2*q);
      m_scl = 1'b0; #q; m_sda = 1'bz; #q;
    end
  endtask

  initial begin
    #200000;

    // S1: bus scan over addresses 1..127, only 0x68 must ACK.
    bit_ns = 10000;
    ack_cnt = 0; nack_cnt = 0;
    for (i = 1; i <= 127; i = i + 1) begin
      i2c_start;
      i2c_tx({i[6:0], 1'b0}, ack);
      if (ack) ack_cnt = ack_cnt + 1; else nack_cnt = nack_cnt + 1;
      i2c_stop;
    end
    $display("MEAS scen=bus_scan ack_cnt=%0d nack_cnt=%0d", ack_cnt, nack_cnt);

    // S2: set time regs 00..02 then read back through repeated START.
    match_cnt = 0; mismatch_cnt = 0;
    i2c_start;
    i2c_tx(8'hd0, ack); // 0x68 write
    i2c_tx(8'h00, ack); // pointer = seconds
    i2c_tx(8'h30, ack); // seconds = 30 (BCD)
    i2c_tx(8'h15, ack); // minutes = 15
    i2c_tx(8'h09, ack); // hours   = 09 (24h)
    // The write advanced the pointer to 0x03; a read must re-point to 0x00.
    i2c_start;
    i2c_tx(8'hd0, ack);
    i2c_tx(8'h00, ack);
    i2c_start;          // repeated START keeps the pointer at 0x00
    i2c_tx(8'hd1, ack); // 0x68 read
    for (i = 0; i < 3; i = i + 1) begin
      i2c_rx(i < 2, got);
      if ((i == 0 && got === 8'h30) ||
          (i == 1 && got === 8'h15) ||
          (i == 2 && got === 8'h09))
        match_cnt = match_cnt + 1;
      else mismatch_cnt = mismatch_cnt + 1;
    end
    i2c_stop;
    $display("MEAS scen=time_write_readback match=%0d mismatch=%0d",
             match_cnt, mismatch_cnt);

    // S3: wrong address 0x69 must NACK; reg 00 keeps 0x30.
    begin : s3_block
      reg wrong_ack;
      i2c_start;
      i2c_tx(8'hd2, wrong_ack); // 0x69 write
      i2c_stop;
      i2c_start;
      i2c_tx(8'hd0, ack);
      i2c_tx(8'h00, ack);
      i2c_start;
      i2c_tx(8'hd1, ack);
      i2c_rx(1'b0, got);
      i2c_stop;
      $display("MEAS scen=wrong_addr nack=%0d reg_unchanged=%0d",
               wrong_ack ? 0 : 1, (got === 8'h30) ? 1 : 0);
    end

    // S4: pointer auto-increment, read-only temp regs, wrap to 0x00.
    i2c_start;
    i2c_tx(8'hd0, ack);
    i2c_tx(8'h10, ack); // pointer = aging offset
    i2c_tx(8'h0c, ack); // 0x10 aging, writable
    i2c_tx(8'h2a, ack); // 0x11 temp MSB, must be ignored (RO)
    i2c_tx(8'h40, ack); // 0x12 temp LSB, must be ignored (RO)
    i2c_tx(8'h51, ack); // wraps: lands in 0x00 seconds
    i2c_stop;
    begin : s4_check
      reg [7:0] r10, r11, r12, r00;
      i2c_start; i2c_tx(8'hd0, ack); i2c_tx(8'h10, ack);
      i2c_start; i2c_tx(8'hd1, ack);
      i2c_rx(1'b1, r10); i2c_rx(1'b1, r11); i2c_rx(1'b1, r12);
      i2c_rx(1'b0, r00); i2c_stop;
      $display("MEAS scen=ptr_wrap_ro aging_ok=%0d temp_ro_kept=%0d wrap_to_zero=%0d",
               (r10 === 8'h0c) ? 1 : 0,
               (r11 === 8'h1e && r12 === 8'h00) ? 1 : 0,
               (r00 === 8'h51) ? 1 : 0);
    end

    // S5: BCD rollover 58s59m09h -> 59 -> 00s00m10h across two 1 Hz ticks.
    // Preset lands near t~0.02s; the 2.1s window deterministically covers
    // the 1.0s and 2.0s ticks and ends before the 3.0s tick.
    i2c_start; i2c_tx(8'hd0, ack); i2c_tx(8'h00, ack);
    i2c_tx(8'h58, ack); i2c_tx(8'h59, ack); i2c_tx(8'h09, ack); i2c_stop;
    #2100000000;
    begin : s5_check
      reg [7:0] sec, min, hour;
      i2c_start; i2c_tx(8'hd0, ack); i2c_tx(8'h00, ack);
      i2c_start; i2c_tx(8'hd1, ack);
      i2c_rx(1'b1, sec); i2c_rx(1'b1, min); i2c_rx(1'b0, hour); i2c_stop;
      $display("MEAS scen=bcd_rollover sec=%02h min=%02h hour=%02h pass=%0d",
               sec, min, hour,
               (sec === 8'h00 && min === 8'h00 && hour === 8'h10) ? 1 : 0);
    end

    // S6: same access pattern at 400 kHz fast mode.
    bit_ns = 2500;
    match_cnt = 0; mismatch_cnt = 0;
    i2c_start;
    i2c_tx(8'hd0, ack);
    i2c_tx(8'h00, ack);
    i2c_tx(8'h45, ack);
    i2c_tx(8'h30, ack);
    i2c_tx(8'h11, ack);
    // Re-point to 0x00 before the read (the write left the pointer at 0x03).
    i2c_start;
    i2c_tx(8'hd0, ack);
    i2c_tx(8'h00, ack);
    i2c_start;
    i2c_tx(8'hd1, ack);
    for (i = 0; i < 3; i = i + 1) begin
      i2c_rx(i < 2, got);
      if ((i == 0 && got === 8'h45) ||
          (i == 1 && got === 8'h30) ||
          (i == 2 && got === 8'h11))
        match_cnt = match_cnt + 1;
      else mismatch_cnt = mismatch_cnt + 1;
    end
    i2c_stop;
    $display("MEAS scen=fast_mode_400k match=%0d mismatch=%0d",
             match_cnt, mismatch_cnt);

    $display("DS3231_BENCH_DONE");
    $finish;
  end
endmodule
