// sequence：产生 N 笔随机事务
class my_sequence extends uvm_sequence #(my_item);
  `uvm_object_utils(my_sequence)
  function new(string name = "my_sequence");
    super.new(name);
  endfunction
  virtual task body();
    repeat (8) begin
      req = my_item::type_id::create("req");
      start_item(req);
      if (!req.randomize()) `uvm_error("RAND", "randomize failed")
      finish_item(req);
    end
  endtask
endclass

// test：顶层，只做配置和启动 sequence；忘记 raise/drop objection，
// run_phase 会在 0 时刻直接结束（平台「什么都没跑」）
class my_test extends uvm_test;
  `uvm_component_utils(my_test)

  my_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = my_env::type_id::create("env", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    my_sequence seq;
    phase.raise_objection(this);
    seq = my_sequence::type_id::create("seq");
    seq.start(env.agt.sqr);
    phase.drop_objection(this);
  endtask
endclass
