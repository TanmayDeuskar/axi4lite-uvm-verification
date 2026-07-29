import uvm_pkg::*;
logic [31:0] written_addr [$];

class axi4lite_sequence extends uvm_sequence #(axi4lite_seq_item);
    `uvm_object_utils(axi4lite_sequence)
    int unsigned num_txn = 1000;
    function new(string name = "axi4lite_sequence");
        super.new(name);
    endfunction //new()

    task body();
        axi4lite_seq_item seq_item;
        repeat(num_txn) begin
            seq_item = axi4lite_seq_item::type_id::create("seq_item");
            start_item(seq_item);
            seq_item.aw_w_delay = $urandom_range(0,3);
            seq_item.ar_r_delay = $urandom_range(0,3);
            seq_item.w_b_delay = $urandom_range(0,3);
            
            
            if(written_addr.size() > 0 && $urandom_range(0,1)) begin
                seq_item.addr = written_addr[$urandom_range(0, written_addr.size()-1)];
                seq_item.write = 0;
            end
            else begin
                seq_item.addr = $urandom_range(0, 255) << 2;  // word aligned within range
                seq_item.data = $urandom;
                seq_item.write = 1;
                written_addr.push_back(seq_item.addr);
            end

            `ifdef BUG_ADDR_NOT_ALIGNED
                seq_item.addr[1:0] = $urandom_range(1,3);
            `endif
            
            case ($urandom_range(0,4))
                0:seq_item.strobe = 4'b1111;
                1:seq_item.strobe = 4'b1100;
                2:seq_item.strobe = 4'b0011;
                3:seq_item.strobe = 4'b0001 << $urandom_range(0,3);
                4:seq_item.strobe = $urandom_range(1,15); 
            endcase
            //seq_item.strobe = $urandom_range(0,15);
            //seq_item.write = $urandom_range(0,1);
            //assert(seq_item.randomize());

            finish_item(seq_item);
        end
    endtask
endclass //axi4lite_sequence extends uvm_sequence #(axi4lite_seq_item)