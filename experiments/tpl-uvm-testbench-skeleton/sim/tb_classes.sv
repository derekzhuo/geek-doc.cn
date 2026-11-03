`timescale 1ns/1ns
// 去 UVM 依赖的最小验证平台骨架（普通 SystemVerilog class）
// 对应 UVM 五件套：sequencer / driver / monitor / scoreboard / test(env)
// 用 mailbox 代替 TLM 端口，手工调用 phase 代替 uvm_component 自动调度

// ---- sequence item：一笔事务（对应 uvm_sequence_item）----
class seq_item;
  bit [7:0] data;
  function new(bit [7:0] d);
    data = d;
  endfunction
endclass

// ---- sequencer：产生事务（对应 sequence + uvm_sequencer）----
class sequencer;
  mailbox #(seq_item) req_fifo;
  function new(mailbox #(seq_item) m);
    req_fifo = m;
  endfunction
  task run(int n);
    for (int i = 0; i < n; i++) begin
      bit [7:0] d;
      seq_item it;
      d = 8'($urandom() & 32'h0000_00FF);
      it = new(d);
      req_fifo.put(it);
    end
  endtask
endclass

// ---- driver：事务翻译成引脚波形，经 virtual interface 驱动 DUT ----
class driver;
  virtual dut_if vif;
  mailbox #(seq_item) req_fifo;
  mailbox #(seq_item) exp_fifo;  // 同一笔输入送给参考侧
  function new(virtual dut_if v, mailbox #(seq_item) r,
               mailbox #(seq_item) e);
    vif      = v;
    req_fifo = r;
    exp_fifo = e;
  endfunction
  task run(int n);
    @(posedge vif.rst_n);
    repeat (n) begin
      seq_item it;
      req_fifo.get(it);
      @(posedge vif.clk);
      vif.in_valid <= 1'b1;
      vif.in_data  <= it.data;
      $display("[DRIVER] drive data=%0d", it.data);
      exp_fifo.put(it);              // 参考模型据此算期望值
      @(posedge vif.clk);
      vif.in_valid <= 1'b0;
      repeat ($urandom() % 3) @(posedge vif.clk);  // 随机空闲
    end
  endtask
endclass

// ---- monitor：永远被动，引脚还原成事务向外广播 ----
class monitor;
  virtual dut_if vif;
  mailbox #(seq_item) rsp_fifo;
  function new(virtual dut_if v, mailbox #(seq_item) s);
    vif      = v;
    rsp_fifo = s;
  endfunction
  task run(int n);
    @(posedge vif.rst_n);
    repeat (n) begin
      do @(posedge vif.clk);
      while (vif.out_valid !== 1'b1);
      begin
        seq_item it;
        it = new(vif.out_data);
        rsp_fifo.put(it);
      end
      $display("[MONITOR] sample out_data=%0d", vif.out_data);
    end
  endtask
endclass

// ---- scoreboard：期望（data+1）与实际逐笔比对 ----
class scoreboard;
  mailbox #(seq_item) exp_fifo;
  mailbox #(seq_item) rsp_fifo;
  int m_count;
  int m_errors;
  function new(mailbox #(seq_item) e, mailbox #(seq_item) r);
    exp_fifo = e;
    rsp_fifo = r;
    m_count  = 0;
    m_errors = 0;
  endfunction
  task run(int n);
    repeat (n) begin
      seq_item e, a;
      bit [7:0] expected;
      exp_fifo.get(e);
      rsp_fifo.get(a);
      expected = e.data + 8'd1;
      m_count++;
      if (a.data !== expected) begin
        m_errors++;
        $display("[SCOREBOARD] MISMATCH #%0d in=%0d expected=%0d actual=%0d",
                 m_count, e.data, expected, a.data);
      end
    end
  endtask
endclass

// ---- base_test：组装五件套并手工按 phase 顺序调度（对应 uvm_test + env）----
class base_test;
  virtual dut_if      vif;
  mailbox #(seq_item) req_fifo;
  mailbox #(seq_item) exp_fifo;
  mailbox #(seq_item) rsp_fifo;
  sequencer sqr;
  driver    drv;
  monitor   mon;
  scoreboard scb;
  int n_items;

  function new(virtual dut_if v);
    vif     = v;
    n_items = 8;
  endfunction

  task build_phase;
    $display("[PHASE] build_phase: construct components");
    req_fifo = new();
    exp_fifo = new();
    rsp_fifo = new();
    sqr = new(req_fifo);
    drv = new(vif, req_fifo, exp_fifo);
    mon = new(vif, rsp_fifo);
    scb = new(exp_fifo, rsp_fifo);
  endtask

  task connect_phase;
    $display("[PHASE] connect_phase: wire mailboxes / virtual interface");
  endtask

  task run_phase;
    $display("[PHASE] run_phase: phase_started -> raise_objection");
    fork
      sqr.run(n_items);
      drv.run(n_items);
      mon.run(n_items);
      scb.run(n_items);
    join
    #200ns;  // 等最后一笔输出排空
    $display("[PHASE] run_phase: drop_objection");
  endtask

  task check_phase;
    if (m_errors_pass())
      $display("[REPORT] TEST FAIL: %0d/%0d mismatches", scb.m_errors, n_items);
    else
      $display("[REPORT] TEST PASS: %0d items matched", n_items);
  endtask

  function bit m_errors_pass();
    return (scb.m_errors != 0);
  endfunction

  task run;
    build_phase;
    connect_phase;
    run_phase;
    check_phase;
    $finish;
  endtask
endclass
