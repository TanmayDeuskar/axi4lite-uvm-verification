import uvm_pkg::*;


class axi4lite_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(axi4lite_scoreboard)
    uvm_analysis_imp #(axi4lite_seq_item, axi4lite_scoreboard) ap;

    logic [31:0] memory_sim [255:0];
    int unsigned pass_count;
    int unsigned fail_count;


    function new(string name = "axi4lite_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction //new()

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
    endfunction

    function void write(axi4lite_seq_item seq_item);
        if(seq_item.write) begin
            for(int i = 0; i < 4; i++) begin
                if(seq_item.strobe[i]) begin
                    memory_sim[seq_item.addr[9:2]][i*8 +: 8] = seq_item.data[i*8 +: 8];
                end
            end
            if(seq_item.resp == 2'b00) begin
                `uvm_info("SCOREBOARD", $sformatf(
                        "Write PASS: addr=0x%0h data=0x%0h", seq_item.addr, seq_item.data), UVM_MEDIUM)
                pass_count++;
            end
            else begin
                `uvm_error("SCOREBOARD", $sformatf(
                        "Write at addr=0x%0h got bad response: %0b", seq_item.addr, seq_item.resp))
                fail_count++;
            end
        end
        else begin
            if(memory_sim[seq_item.addr[9:2]] != seq_item.data) begin
                `uvm_error("SCOREBOARD", $sformatf(
                        "Read MISMATCH at addr=0x%0h: expected=0x%0h got=0x%0h",
                        seq_item.addr, memory_sim[seq_item.addr[9:2]], seq_item.data))
                fail_count++;
            end
            else begin
                `uvm_info("SCOREBOARD", $sformatf(
                        "Read PASS: addr=0x%0h data=0x%0h", seq_item.addr, seq_item.data), UVM_MEDIUM)
                pass_count++;
            end
        end

    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SCOREBOARD", $sformatf(
                "Results: %0d PASS, %0d FAIL", pass_count, fail_count), UVM_NONE)
    endfunction

endclass //axi4lite_scoreboard extends uvm_scoreboard
