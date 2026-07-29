import uvm_pkg::*;



class axi4lite_seq_item extends uvm_sequence_item;

    // rand logic [31:0] addr;
    // rand logic [31:0] data;
    // rand logic [3:0] strobe;
    // rand logic write;
    // rand logic [1:0] resp;


    logic [31:0] addr;
    logic [31:0] data;
    logic [3:0] strobe;
    logic write;
    logic [1:0] resp;
    int unsigned aw_w_delay;
    int unsigned ar_r_delay;
    int unsigned w_b_delay;




    `uvm_object_utils_begin(axi4lite_seq_item)
        `uvm_field_int(addr,  UVM_ALL_ON)
        `uvm_field_int(data,  UVM_ALL_ON)
        `uvm_field_int(strobe, UVM_ALL_ON)
        `uvm_field_int(write, UVM_ALL_ON)
        `uvm_field_int(resp,  UVM_ALL_ON)
        `uvm_field_int(aw_w_delay,  UVM_ALL_ON)
        `uvm_field_int(ar_r_delay,  UVM_ALL_ON)
        `uvm_field_int(w_b_delay,  UVM_ALL_ON)
    `uvm_object_utils_end


    // constraint addr_constr{
    //     addr[1:0] == 2'b00;
    // }
    // constraint addr_range{
    //     addr < 32'h400;
    // }
    // constraint strobe_consr{
    //     write -> strobe > 0;
    // }

    function new(string name = "axi4lite_seq_item");
        super.new(name);
    endfunction //new()
    
endclass //axi4_seq_item extends uvm_seq_item

