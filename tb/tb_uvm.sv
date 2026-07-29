`include "uvm_macros.svh"
import uvm_pkg::*;
import axi4lite_pkg::*;

module tb_uvm;

    logic clk;
    logic reset;

    axi4lite_if axiif(.ACLK(clk), .ARESETn(reset));
    axi4lite_subordinate dut(.axiif(axiif));
    bind axi4lite_subordinate axi4lite_assertions assertions_inst();

    initial clk = 0;

    always #5 clk = !clk;

    // initial begin
    //     `ifdef RESET_TEST
    //         int unsigned reset_delay;
    //         reset_delay = $urandom_range(10, 40);
    //         repeat(reset_delay) @(posedge clk);
    //         reset = 0;
    //         `uvm_info("TB_TOP", $sformatf("Asserting reset at time %0t, DUT state = %s", $time, dut.write_state.name()), UVM_LOW)
    //         repeat(5) @(posedge clk);
    //         reset = 1;
    //     `endif
    //     //+define+BUG_DATA_CORRUPTION
    // end

    initial begin 
        int unsigned reset_delay;
        reset <= 0;
        repeat(5) @(posedge clk);
        reset <= 1;

        `ifdef RESET_TEST
          //  $display("Inside reset test");
            reset_delay = $urandom_range(10, 40);
            repeat(reset_delay) @(posedge clk);
            reset <= 0;
            `uvm_info("TB_TOP", $sformatf("Asserting reset at time %0t, DUT state = %s", $time, dut.write_state.name()), UVM_LOW)
            repeat(5) @(posedge clk);
            reset <= 1;
        `endif
        //+define+BUG_DATA_CORRUPTION
    end

    initial begin
        uvm_config_db #(virtual axi4lite_if)::set(null, "*", "vif", axiif);

        // reset = 0;
        // repeat(5) @(posedge clk);
        // reset = 1;

        run_test("axi4lite_base_test");
    end

endmodule