// driver：主动侧。get_next_item 取事务 -> 拍引脚 -> item_done
class my_driver extends uvm_driver #(my_item);
  `uvm_component_utils(my_driver)

  virtual my_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual my_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "virtual interface not set")
  endfunction

  virtual task run_phase(uvm_phase phase);
    my_item req;
    forever begin
      seq_item_port.get_next_item(req);
      drive_item(req);
      seq_item_port.item_done();
    end
  endtask

  virtual task drive_item(my_item req);
    @(posedge vif.clk);
    vif.in_valid <= 1'b1;
    vif.in_data  <= req.data;
    @(posedge vif.clk);
    vif.in_valid <= 1'b0;
  endtask
endclass
