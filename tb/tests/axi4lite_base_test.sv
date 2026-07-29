import uvm_pkg::*;


class axi4lite_base_test extends uvm_test;
    `uvm_component_utils(axi4lite_base_test)

    axi4lite_env env;
    axi4lite_sequence seq;

    function new(string name = "axi4lite_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction //new()

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = axi4lite_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        seq = axi4lite_sequence::type_id::create("seq");
        phase.raise_objection(this);
        seq.start(env.agent.sequencer);
        phase.drop_objection(this);
    endtask
endclass 