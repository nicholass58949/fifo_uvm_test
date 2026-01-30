// Slave Sequence - 根据empty信号生成读请求
class slave_sequence extends uvm_sequence #(fifo_transaction);
    `uvm_object_utils(slave_sequence)
    
    // 要读取的数据数量
    rand int unsigned num_transactions;
    
    constraint num_trans_c {
        num_transactions inside {[10:50]};
    }
    
    function new(string name = "slave_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        fifo_transaction tx;
        
        `uvm_info("SLAVE_SEQ", $sformatf("Starting sequence with %0d transactions", num_transactions), UVM_LOW)
        
        repeat (num_transactions) begin
            tx = fifo_transaction::type_id::create("tx");
            
            start_item(tx);
            
            // 从机只需要发送读使能
            tx.rd_en = 1'b1;
            tx.wr_en = 1'b0;
            tx.data  = 8'h0;  // 数据由DUT返回
            
            finish_item(tx);
            
            `uvm_info("SLAVE_SEQ", "Sent read request", UVM_HIGH)
        end
        
        `uvm_info("SLAVE_SEQ", "Sequence completed", UVM_LOW)
    endtask
    
endclass : slave_sequence

// 持续读取序列 - 只要FIFO不空就持续读取
class slave_reactive_sequence extends uvm_sequence #(fifo_transaction);
    `uvm_object_utils(slave_reactive_sequence)
    
    // 最大读取次数
    int unsigned max_reads = 100;
    
    function new(string name = "slave_reactive_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        fifo_transaction tx;
        int count = 0;
        
        `uvm_info("SLAVE_REACTIVE_SEQ", "Starting reactive sequence", UVM_LOW)
        
        while (count < max_reads) begin
            tx = fifo_transaction::type_id::create("tx");
            
            start_item(tx);
            
            tx.rd_en = 1'b1;
            tx.wr_en = 1'b0;
            tx.data  = 8'h0;
            
            finish_item(tx);
            count++;
        end
        
        `uvm_info("SLAVE_REACTIVE_SEQ", $sformatf("Reactive sequence completed, read %0d times", count), UVM_LOW)
    endtask
    
endclass : slave_reactive_sequence
