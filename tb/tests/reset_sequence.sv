// Reset Test Sequences
// 复位测试序列 - 测试主从机复位行为

// ==================== 写复位序列 ====================
// 在写操作过程中触发写端口复位
class master_reset_sequence extends uvm_sequence #(fifo_transaction);
    `uvm_object_utils(master_reset_sequence)
    
    // 复位前写入的数据数量
    int unsigned pre_reset_count = 5;
    // 复位后写入的数据数量
    int unsigned post_reset_count = 10;
    
    function new(string name = "master_reset_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        fifo_transaction tx;
        
        `uvm_info("MST_RST_SEQ", "Starting master reset sequence", UVM_LOW)
        
        // Phase 1: 复位前写入一些数据
        `uvm_info("MST_RST_SEQ", $sformatf("Phase 1: Writing %0d items before reset", pre_reset_count), UVM_LOW)
        repeat (pre_reset_count) begin
            tx = fifo_transaction::type_id::create("tx");
            start_item(tx);
            if (!tx.randomize() with { wr_en == 1'b1; rd_en == 1'b0; }) begin
                `uvm_error("MST_RST_SEQ", "Randomization failed")
            end
            finish_item(tx);
        end
        
        // Phase 2: 等待复位被外部触发（通过test控制）
        `uvm_info("MST_RST_SEQ", "Phase 2: Waiting for reset to be triggered externally", UVM_LOW)
        #100ns;
        
        // Phase 3: 复位后继续写入数据
        `uvm_info("MST_RST_SEQ", $sformatf("Phase 3: Writing %0d items after reset", post_reset_count), UVM_LOW)
        repeat (post_reset_count) begin
            tx = fifo_transaction::type_id::create("tx");
            start_item(tx);
            if (!tx.randomize() with { wr_en == 1'b1; rd_en == 1'b0; }) begin
                `uvm_error("MST_RST_SEQ", "Randomization failed")
            end
            finish_item(tx);
        end
        
        `uvm_info("MST_RST_SEQ", "Master reset sequence completed", UVM_LOW)
    endtask
    
endclass : master_reset_sequence

// ==================== 读复位序列 ====================
// 在读操作过程中触发读端口复位
class slave_reset_sequence extends uvm_sequence #(fifo_transaction);
    `uvm_object_utils(slave_reset_sequence)
    
    // 复位前读取的数据数量
    int unsigned pre_reset_count = 5;
    // 复位后读取的数据数量
    int unsigned post_reset_count = 10;
    
    function new(string name = "slave_reset_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        fifo_transaction tx;
        
        `uvm_info("SLV_RST_SEQ", "Starting slave reset sequence", UVM_LOW)
        
        // Phase 1: 复位前读取一些数据
        `uvm_info("SLV_RST_SEQ", $sformatf("Phase 1: Reading %0d items before reset", pre_reset_count), UVM_LOW)
        repeat (pre_reset_count) begin
            tx = fifo_transaction::type_id::create("tx");
            start_item(tx);
            tx.rd_en = 1'b1;
            tx.wr_en = 1'b0;
            finish_item(tx);
        end
        
        // Phase 2: 等待复位被外部触发
        `uvm_info("SLV_RST_SEQ", "Phase 2: Waiting for reset to be triggered externally", UVM_LOW)
        #100ns;
        
        // Phase 3: 复位后继续读取数据
        `uvm_info("SLV_RST_SEQ", $sformatf("Phase 3: Reading %0d items after reset", post_reset_count), UVM_LOW)
        repeat (post_reset_count) begin
            tx = fifo_transaction::type_id::create("tx");
            start_item(tx);
            tx.rd_en = 1'b1;
            tx.wr_en = 1'b0;
            finish_item(tx);
        end
        
        `uvm_info("SLV_RST_SEQ", "Slave reset sequence completed", UVM_LOW)
    endtask
    
endclass : slave_reset_sequence

// ==================== 同时复位序列（虚拟序列） ====================
// 同时复位主从机
class reset_virtual_sequence extends uvm_sequence;
    `uvm_object_utils(reset_virtual_sequence)
    `uvm_declare_p_sequencer(uvm_sequencer)
    
    // 子序列句柄
    master_reset_sequence mst_rst_seq;
    slave_reset_sequence  slv_rst_seq;
    
    // Sequencer句柄（由test设置）
    master_sequencer mst_sqr;
    slave_sequencer  slv_sqr;
    
    function new(string name = "reset_virtual_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        `uvm_info("RST_VSEQ", "Starting reset virtual sequence", UVM_LOW)
        
        // 创建子序列
        mst_rst_seq = master_reset_sequence::type_id::create("mst_rst_seq");
        slv_rst_seq = slave_reset_sequence::type_id::create("slv_rst_seq");
        
        // 并行启动主从复位序列
        fork
            if (mst_sqr != null) mst_rst_seq.start(mst_sqr);
            if (slv_sqr != null) slv_rst_seq.start(slv_sqr);
        join
        
        `uvm_info("RST_VSEQ", "Reset virtual sequence completed", UVM_LOW)
    endtask
    
endclass : reset_virtual_sequence

// ==================== 写复位期间持续写入序列 ====================
// 测试复位期间的写操作行为
class master_continuous_reset_sequence extends uvm_sequence #(fifo_transaction);
    `uvm_object_utils(master_continuous_reset_sequence)
    
    // 总写入次数
    int unsigned total_writes = 30;
    
    function new(string name = "master_continuous_reset_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        fifo_transaction tx;
        
        `uvm_info("MST_CONT_RST_SEQ", "Starting continuous write during reset sequence", UVM_LOW)
        
        // 持续写入，期间外部会触发复位
        repeat (total_writes) begin
            tx = fifo_transaction::type_id::create("tx");
            start_item(tx);
            if (!tx.randomize() with { wr_en == 1'b1; rd_en == 1'b0; }) begin
                `uvm_error("MST_CONT_RST_SEQ", "Randomization failed")
            end
            finish_item(tx);
            
            // 每次写入后等待一小段时间
            #10ns;
        end
        
        `uvm_info("MST_CONT_RST_SEQ", "Continuous write sequence completed", UVM_LOW)
    endtask
    
endclass : master_continuous_reset_sequence

// ==================== 读复位期间持续读取序列 ====================
// 测试复位期间的读操作行为
class slave_continuous_reset_sequence extends uvm_sequence #(fifo_transaction);
    `uvm_object_utils(slave_continuous_reset_sequence)
    
    // 总读取次数
    int unsigned total_reads = 30;
    
    function new(string name = "slave_continuous_reset_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        fifo_transaction tx;
        
        `uvm_info("SLV_CONT_RST_SEQ", "Starting continuous read during reset sequence", UVM_LOW)
        
        // 持续读取，期间外部会触发复位
        repeat (total_reads) begin
            tx = fifo_transaction::type_id::create("tx");
            start_item(tx);
            tx.rd_en = 1'b1;
            tx.wr_en = 1'b0;
            finish_item(tx);
            
            // 每次读取后等待一小段时间
            #15ns;
        end
        
        `uvm_info("SLV_CONT_RST_SEQ", "Continuous read sequence completed", UVM_LOW)
    endtask
    
endclass : slave_continuous_reset_sequence
