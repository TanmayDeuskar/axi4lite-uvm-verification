import uvm_pkg::*;


class axi4lite_agent extends uvm_agent;
    `uvm_component_utils(axi4lite_agent)

    axi4lite_driver driver;
    axi4lite_sequencer sequencer;
    axi4lite_monitor monitor;

    function new(string name = "axi4lite_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction //new()

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        driver    = axi4lite_driver::type_id::create("driver", this);
        sequencer = axi4lite_sequencer::type_id::create("sequencer", this);
        monitor   = axi4lite_monitor::type_id::create("monitor", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
endclass //axi4lite_agent extends uvm_agent