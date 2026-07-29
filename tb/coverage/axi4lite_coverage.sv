class axi4lite_coverage extends uvm_subscriber #(axi4lite_seq_item);
    `uvm_component_utils(axi4lite_coverage)

    logic [31:0] memory_sim [255:0];
    int unsigned pass_count;
    int unsigned fail_count;

    int unsigned bin_write_high, bin_write_mid, bin_write_low;
    int unsigned bin_read_high, bin_read_mid, bin_read_low;
    int unsigned bin_full_word, bin_lower_half, bin_upper_half, bin_single_byte, bin_other_strobe;

    int unsigned resp_ok, resp_exok, resp_slverr, resp_decerr;

    function new(string name = "axi4lite_coverage", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void write(axi4lite_seq_item t);
        track_coverage(t);
    endfunction

    function void track_coverage(axi4lite_seq_item seq_item);
        int unsigned addr = seq_item.addr[9:2];

        if(seq_item.write) begin
            if(addr <= 84) bin_write_low++;
            else if(addr <= 170) bin_write_mid++;
            else bin_write_high++;

            case (seq_item.strobe)
                4'b1111: bin_full_word++;
                4'b1100: bin_upper_half++;
                4'b0011: bin_lower_half++;
                4'b0001, 4'b0010, 4'b0100, 4'b1000: bin_single_byte++; 
                default: bin_other_strobe++;
            endcase
        end
        else begin
            if(addr <= 84) bin_read_low++;
            else if(addr <= 170) bin_read_mid++;
            else bin_read_high++;
        end

        case (seq_item.resp)
            2'b00: resp_ok++;
            2'b01: resp_exok++;
            2'b10: resp_slverr++;
            2'b11: resp_decerr++; 
        endcase
    endfunction

    function void report_phase(uvm_phase phase);
        int unsigned total_bins, hit_bins;

        `uvm_info("COVERAGE", "=== Address Bin Coverage ===", UVM_NONE)
        `uvm_info("COVERAGE", $sformatf("Write - low: %0d, mid: %0d, high: %0d",
                  bin_write_low, bin_write_mid, bin_write_high), UVM_NONE)
        `uvm_info("COVERAGE", $sformatf("Read  - low: %0d, mid: %0d, high: %0d",
                  bin_read_low, bin_read_mid, bin_read_high), UVM_NONE)

        `uvm_info("COVERAGE", "=== Strobe Bin Coverage ===", UVM_NONE)
        `uvm_info("COVERAGE", $sformatf(
            "full_word: %0d, lower_half: %0d, upper_half: %0d, single_byte: %0d, other: %0d",
            bin_full_word, bin_lower_half, bin_upper_half, bin_single_byte, bin_other_strobe), UVM_NONE)

        `uvm_info("COVERAGE", "=== Response Code Coverage ===", UVM_NONE)
        `uvm_info("COVERAGE", $sformatf(
            "OKAY: %0d, EXOKAY: %0d, SLVERR: %0d, DECERR: %0d",
            resp_ok, resp_exok, resp_slverr, resp_decerr), UVM_NONE)

        total_bins = 10;
        hit_bins = (bin_write_low>0) + (bin_write_mid>0) + (bin_write_high>0) +
                   (bin_read_low>0)  + (bin_read_mid>0)  + (bin_read_high>0)  +
                   (bin_full_word>0) + (bin_lower_half>0) + (bin_upper_half>0) + (bin_single_byte>0);

        `uvm_info("COVERAGE", $sformatf(
            "TOTAL FUNCTIONAL COVERAGE: %0d/%0d bins = %0.1f%%",
            hit_bins, total_bins, (hit_bins*100.0)/total_bins), UVM_NONE)

        if(bin_write_low == 0) `uvm_warning("COVERAGE", "BIN MISS: low address write never hit")
        if(bin_write_mid == 0) `uvm_warning("COVERAGE", "BIN MISS: mid address write never hit")
        if(bin_write_high == 0) `uvm_warning("COVERAGE", "BIN MISS: high address write never hit")
        if(bin_read_low == 0) `uvm_warning("COVERAGE", "BIN MISS: low address read never hit")
        if(bin_read_mid == 0) `uvm_warning("COVERAGE", "BIN MISS: mid address read never hit")
        if(bin_read_high == 0) `uvm_warning("COVERAGE", "BIN MISS: high address read never hit")
        if(bin_full_word == 0) `uvm_warning("COVERAGE", "BIN MISS: full word strobe never hit")
        if(bin_lower_half == 0) `uvm_warning("COVERAGE", "BIN MISS: lower half strobe never hit")
        if(bin_upper_half == 0) `uvm_warning("COVERAGE", "BIN MISS: upper half strobe never hit")
        if(bin_single_byte == 0) `uvm_warning("COVERAGE", "BIN MISS: single byte strobe never hit")
        if(resp_ok == 0) `uvm_warning("COVERAGE", "BIN MISS: OKAY response never observed")
        if(resp_exok == 0) `uvm_warning("COVERAGE", "BIN MISS: EXOKAY response never observed")
        if(resp_slverr == 0) `uvm_warning("COVERAGE", "BIN MISS: SLVERR response never observed")
        if(resp_decerr == 0) `uvm_warning("COVERAGE", "BIN MISS: DECERR response never observed")
    endfunction
endclass 