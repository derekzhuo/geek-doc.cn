// sequencer：参数化一行即可，负责把 sequence 的 item 派发给 driver
class my_sequencer extends uvm_sequencer #(my_item);
  `uvm_component_utils(my_sequencer)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass
