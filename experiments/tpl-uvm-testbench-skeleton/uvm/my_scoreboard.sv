// scoreboard：输入口接参考模型（data+1 入期望队列），
// 输出口取实际事务，按顺序逐笔比对
`uvm_analysis_imp_decl(_in)
`uvm_analysis_imp_decl(_out)

class my_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(my_scoreboard)

  uvm_analysis_imp_in  #(my_item, my_scoreboard) in_imp;
  uvm_analysis_imp_out #(my_item, my_scoreboard) out_imp;

  bit [7:0] exp_q[$];
  int m_count;
  int m_errors;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    in_imp  = new("in_imp",  this);
    out_imp = new("out_imp", this);
  endfunction

  // 输入侧 predictor：DUT 功能是 data+1
  virtual function void write_in(my_item tr);
    exp_q.push_back(tr.data + 8'd1);
  endfunction

  // 输出侧：队首期望值与实际值比对
  virtual function void write_out(my_item tr);
    bit [7:0] expected;
    m_count++;
    if (exp_q.size() == 0) begin
      `uvm_error("UNEXP", $sformatf("unexpected output %0d", tr.data))
      m_errors++;
      return;
    end
    expected = exp_q.pop_front();
    if (tr.data !== expected) begin
      m_errors++;
      `uvm_error("MISMATCH",
        $sformatf("#%0d actual=%0d expected=%0d", m_count, tr.data, expected))
    end
  endfunction

  virtual function void report_phase(uvm_phase phase);
    `uvm_info("REPORT",
      $sformatf("checked=%0d errors=%0d", m_count, m_errors), UVM_LOW)
  endfunction
endclass
