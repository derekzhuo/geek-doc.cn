// env：容器，组装 agent + scoreboard（+ coverage）
class my_env extends uvm_env;
  `uvm_component_utils(my_env)

  my_agent       agt;
  my_scoreboard  scb;
  my_coverage     cov;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agt = my_agent::type_id::create("agt", this);
    scb = my_scoreboard::type_id::create("scb", this);
    cov = my_coverage::type_id::create("cov", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    agt.mon.ap_in.connect(scb.in_imp);    // 输入 -> 参考模型
    agt.mon.ap_out.connect(scb.out_imp);  // 输出 -> 比对
    agt.mon.ap_out.connect(cov.analysis_export);
  endfunction
endclass
