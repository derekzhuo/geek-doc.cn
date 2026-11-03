// 修改示范：coverage subscriber，挂在 monitor 的 analysis port 上
class my_coverage extends uvm_subscriber #(my_item);
  `uvm_component_utils(my_coverage)

  bit [7:0] data;
  covergroup cg_data;
    cp_data: coverpoint data {
      bins low  = {[0:84]};
      bins mid  = {[85:169]};
      bins high = {[170:255]};
    }
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg_data = new();
  endfunction

  virtual function void write(my_item t);
    data = t.data;
    cg_data.sample();
  endfunction
endclass
