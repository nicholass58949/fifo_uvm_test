// Master Sequence - 生成写数据序列
class master_sequence extends uvm_sequence #(fifo_transaction);
    `uvm_object_utils(master_sequence)
    
    // 要发送的数据数量
    rand int unsigned num_transactions;
    
    constraint num_trans_c {
        num_transactions inside {[10:50]};
    }
    
    function new(string name = "master_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        fifo_transaction tx;
        
        `uvm_info("MASTER_SEQ", $sformatf("Starting sequence with %0d transactions", num_transactions), UVM_LOW)
        
        repeat (num_transactions) begin
            tx = fifo_transaction::type_id::create("tx");
            
            start_item(tx);
            
            if (!tx.randomize() with {
                wr_en == 1'b1;
                rd_en == 1'b0;
            }) begin
                `uvm_error("MASTER_SEQ", "Failed to randomize transaction")
            end
            
            finish_item(tx);
            
            `uvm_info("MASTER_SEQ", $sformatf("Sent data: %0h", tx.data), UVM_HIGH)
        end
        
        `uvm_info("MASTER_SEQ", "Sequence completed", UVM_LOW)
    endtask
    
endclass : master_sequence

// 固定数据序列 - 用于调试
class master_fixed_sequence extends uvm_sequence #(fifo_transaction);
    `uvm_object_utils(master_fixed_sequence)
    
    function new(string name = "master_fixed_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        fifo_transaction tx;
        
        for (int i = 0; i < 16; i++) begin
            tx = fifo_transaction::type_id::create("tx");
            
            start_item(tx);
            
            tx.data  = i;
            tx.wr_en = 1'b1;
            tx.rd_en = 1'b0;
            
            finish_item(tx);
            
            `uvm_info("MASTER_FIXED_SEQ", $sformatf("Sent data: %0h", tx.data), UVM_HIGH)
        end
    endtask
    
endclass : master_fixed_sequence
