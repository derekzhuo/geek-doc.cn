// monitor：被动侧。只采样、不驱动；输入/输出各一个 analysis port
class my_monitor extends uvm_monitor;
  `uvm_component_utils(my_monitor)

  virtual my_if vif;
  uvm_analysis_port #(my_item) ap_in;   // 采样到的输入事务
  uvm_analysis_port #(my_item) ap_out;  // 采样到的输出事务

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap_in  = new("ap_in",  this);
    ap_out = new("ap_out", this);
    if (!uvm_config_db#(virtual my_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "virtual interface not set")
  endfunction

  virtual task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.clk);
      if (vif.in_valid) begin
        my_item tr = my_item::type_id::create("tr");
        tr.data = vif.in_data;
        ap_in.write(tr);
      end
      if (vif.out_valid) begin
        my_item tr = my_item::type_id::create("tr");
        tr.data = vif.out_data;
        ap_out.write(tr);
      end
    end
  endtask
endclass
