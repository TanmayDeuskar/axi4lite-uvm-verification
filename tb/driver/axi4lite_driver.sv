import uvm_pkg::*;



class axi4lite_driver extends uvm_driver #(axi4lite_seq_item);
    `uvm_component_utils(axi4lite_driver)
    virtual axi4lite_if vif;

    function new(string name = "axi4lite_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction //new()

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db #(virtual axi4lite_if)::get(this, "", "vif", vif))
            `uvm_fatal("DRIVER", "Could not get virtual interface from config db")
    endfunction

    task run_phase(uvm_phase phase);
        axi4lite_seq_item seq_item;
        // vif.AWVALID <= 0;
        // vif.AWADDR <= 0;
        // vif.WVALID <= 0;
        // vif.WDATA <= 0;
        // vif.WSTRB <= 0;
        // vif.BREADY <= 0;

        // vif.ARVALID <= 0;
        // vif.ARADDR <= 0;
        // vif.RREADY <= 0;

        //@(posedge vif.ACLK iff vif.ARESETn);
        reset_signals();

        forever begin
            seq_item_port.get_next_item(seq_item);

            if(seq_item.write) begin
                driver_write(seq_item);
            end
            else begin
                driver_read(seq_item);
            end

            if(!vif.ARESETn) begin
                `uvm_info("DRIVER", "Reset detected - aborting current transaction", UVM_LOW)
                reset_signals();
            end
            seq_item_port.item_done();

        end 

    endtask

    task reset_signals();
        vif.AWVALID <= 0;
        vif.AWADDR <= 0;
        vif.WVALID <= 0;
        vif.WDATA <= 0;
        vif.WSTRB <= 0;
        vif.BREADY <= 0;

        vif.ARVALID <= 0;
        vif.ARADDR <= 0;
        vif.RREADY <= 0;
        $display("Signals Reset");
        @(posedge vif.ACLK iff vif.ARESETn);
    endtask

    task wait_for_signal_or_reset(ref logic sig);
        do begin
            @(posedge vif.ACLK);
        end
        while(!sig && vif.ARESETn);
        // while(!sig && vif.ARESETn)
        //     @(posedge vif.ACLK);
    endtask

    task driver_write(axi4lite_seq_item seq_item);
        `uvm_info("DRIVER", $sformatf("aw_w_delay = %0d", seq_item.aw_w_delay), UVM_LOW)
        vif.AWADDR <= seq_item.addr;
        vif.AWVALID <= 1;
        
       fork
            begin : branch1
                //@(posedge vif.ACLK iff vif.AWREADY);
                wait_for_signal_or_reset(vif.AWREADY);
                if(!vif.ARESETn) disable branch1;
                vif.AWVALID <= 0;
            end
            begin : branch2
                //repeat(seq_item.aw_w_delay) @(posedge vif.ACLK);
                for(int i = 0; i < seq_item.aw_w_delay; i++) begin
                    if(vif.ARESETn) @(posedge vif.ACLK);
                    else disable branch2;
                end
                vif.WDATA <= seq_item.data;
                vif.WVALID <= 1;
                vif.WSTRB <= seq_item.strobe;
                //vif.BREADY <= 1;
                //@(posedge vif.ACLK iff vif.WREADY);
                wait_for_signal_or_reset(vif.WREADY);
                if(!vif.ARESETn) disable branch2;
                vif.WVALID <= 0;
            end
        join

        //@(posedge vif.ACLK iff vif.BVALID)
        `uvm_info("DRIVER", $sformatf("w_b_delay = %0d", seq_item.w_b_delay), UVM_LOW)
        `ifndef BUG_B_HANDSHAKE_TIMEOUT
            for(int i = 0; i < seq_item.w_b_delay; i++) begin
                if(vif.ARESETn) @(posedge vif.ACLK);
                else continue;
            end
            vif.BREADY <= 1;
        `else
            vif.BREADY <= 0;
        `endif
        wait_for_signal_or_reset(vif.BVALID);
        if(!vif.ARESETn) return;
        vif.BREADY <= 0;
        
        `uvm_info("DRIVER", $sformatf("Write done: addr=0x%0h data=0x%0h", 
                  seq_item.addr, seq_item.data), UVM_MEDIUM)
    endtask

    task driver_read(axi4lite_seq_item seq_item);
        `uvm_info("DRIVER", $sformatf("ar_r_delay = %0d", seq_item.ar_r_delay), UVM_LOW)

        vif.ARVALID <= 1;
        vif.ARADDR <= seq_item.addr;
        `ifndef BUG_R_HANDSHAKE_TIMEOUT
            if(seq_item.ar_r_delay == 0) vif.RREADY <= 1;
            //@(posedge vif.ACLK iff vif.ARREADY);
            wait_for_signal_or_reset(vif.ARREADY);
            if(!vif.ARESETn) return;
            vif.ARVALID <= 0;
            if(seq_item.ar_r_delay > 0) begin
                vif.RREADY <= 0;
                //repeat(seq_item.ar_r_delay) @(posedge vif.ACLK);
                for(int i = 0; i < seq_item.ar_r_delay; i++) begin
                    if(vif.ARESETn) @(posedge vif.ACLK);
                    else return;
                end
                vif.RREADY <= 1;
            end
        `else
            vif.RREADY <= 0;
        `endif
        //@(posedge vif.ACLK iff vif.RVALID);
        wait_for_signal_or_reset(vif.RVALID);
        if(!vif.ARESETn) return;
        vif.RREADY <= 0; 
        `uvm_info("DRIVER", $sformatf("Read done: addr=0x%0h data=0x%0h",
                  seq_item.addr, vif.RDATA), UVM_MEDIUM)

    endtask
endclass //axi4lite_driver extents uvm_driver #(axilite4_seq_item)