// sequence_item：一笔事务，字段 + 约束
class my_item extends uvm_sequence_item;
  rand bit [7:0] data;

  `uvm_object_utils_begin(my_item)
    `uvm_field_int(data, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "my_item");
    super.new(name);
  endfunction

  constraint c_data { data < 250; }
endclass
