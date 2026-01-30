// Reset Test
// 复位测试 - 测试主从机复位功能

class fifo_reset_test extends fifo_base_test;
    `uvm_component_utils(fifo_reset_test)
    
    // Virtual interface for reset control
    virtual fifo_if vif;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // 获取virtual interface用于复位控制
        if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("RESET_TEST", "Failed to get virtual interface")
        end
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        master_continuous_reset_sequence mst_seq;
        slave_continuous_reset_sequence  slv_seq;
        
        phase.raise_objection(this);
        
        `uvm_info("RESET_TEST", "========================================", UVM_LOW)
        `uvm_info("RESET_TEST", "Starting FIFO Reset Test", UVM_LOW)
        `uvm_info("RESET_TEST", "========================================", UVM_LOW)
        
        // 等待初始复位结束
        #200ns;
        
        // 创建序列
        mst_seq = master_continuous_reset_sequence::type_id::create("mst_seq");
        slv_seq = slave_continuous_reset_sequence::type_id::create("slv_seq");
        
        // 并行启动序列和复位控制
        fork
            // 主机序列
            mst_seq.start(env.mst_agent.sequencer);
            
            // 从机序列
            slv_seq.start(env.slv_agent.sequencer);
            
            // 复位控制任务
            reset_control_task();
        join
        
        // 等待稳定
        #500ns;
        
        `uvm_info("RESET_TEST", "========================================", UVM_LOW)
        `uvm_info("RESET_TEST", "FIFO Reset Test Completed", UVM_LOW)
        `uvm_info("RESET_TEST", "========================================", UVM_LOW)
        
        phase.drop_objection(this);
    endtask
    
    // 复位控制任务
    virtual task reset_control_task();
        `uvm_info("RESET_TEST", "Reset control task started", UVM_MEDIUM)
        
        // Test 1: 写复位
        #100ns;
        `uvm_info("RESET_TEST", "Asserting write reset...", UVM_LOW)
        force tb_top.wr_rst_n = 1'b0;
        #50ns;
        release tb_top.wr_rst_n;
        `uvm_info("RESET_TEST", "Write reset released", UVM_LOW)
        
        // 等待恢复
        #100ns;
        
        // Test 2: 读复位
        `uvm_info("RESET_TEST", "Asserting read reset...", UVM_LOW)
        force tb_top.rd_rst_n = 1'b0;
        #50ns;
        release tb_top.rd_rst_n;
        `uvm_info("RESET_TEST", "Read reset released", UVM_LOW)
        
        // 等待恢复
        #100ns;
        
        // Test 3: 同时复位
        `uvm_info("RESET_TEST", "Asserting both resets...", UVM_LOW)
        force tb_top.wr_rst_n = 1'b0;
        force tb_top.rd_rst_n = 1'b0;
        #50ns;
        release tb_top.wr_rst_n;
        release tb_top.rd_rst_n;
        `uvm_info("RESET_TEST", "Both resets released", UVM_LOW)
        
        `uvm_info("RESET_TEST", "Reset control task completed", UVM_MEDIUM)
    endtask
    
endclass : fifo_reset_test

// ==================== 异步复位测试 ====================
// 测试不同时间释放复位的情况
class fifo_async_reset_test extends fifo_base_test;
    `uvm_component_utils(fifo_async_reset_test)
    
    virtual fifo_if vif;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("ASYNC_RST_TEST", "Failed to get virtual interface")
        end
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        master_sequence mst_seq;
        slave_reactive_sequence slv_seq;
        
        phase.raise_objection(this);
        
        `uvm_info("ASYNC_RST_TEST", "========================================", UVM_LOW)
        `uvm_info("ASYNC_RST_TEST", "Starting Async Reset Test", UVM_LOW)
        `uvm_info("ASYNC_RST_TEST", "========================================", UVM_LOW)
        
        // 等待初始复位结束
        #200ns;
        
        // 创建序列
        mst_seq = master_sequence::type_id::create("mst_seq");
        slv_seq = slave_reactive_sequence::type_id::create("slv_seq");
        mst_seq.num_transactions = 50;
        slv_seq.max_reads = 50;
        
        // 并行启动
        fork
            mst_seq.start(env.mst_agent.sequencer);
            slv_seq.start(env.slv_agent.sequencer);
            async_reset_control();
        join
        
        #500ns;
        
        `uvm_info("ASYNC_RST_TEST", "Async Reset Test Completed", UVM_LOW)
        
        phase.drop_objection(this);
    endtask
    
    // 异步复位控制 - 写和读复位在不同时间释放
    virtual task async_reset_control();
        // Test: 写复位先释放，读复位后释放
        #150ns;
        `uvm_info("ASYNC_RST_TEST", "Asserting async reset (wr first release)", UVM_LOW)
        force tb_top.wr_rst_n = 1'b0;
        force tb_top.rd_rst_n = 1'b0;
        
        #30ns;
        release tb_top.wr_rst_n;  // 写复位先释放
        `uvm_info("ASYNC_RST_TEST", "Write reset released", UVM_LOW)
        
        #40ns;
        release tb_top.rd_rst_n;  // 读复位后释放
        `uvm_info("ASYNC_RST_TEST", "Read reset released", UVM_LOW)
        
        // Test: 读复位先释放，写复位后释放
        #200ns;
        `uvm_info("ASYNC_RST_TEST", "Asserting async reset (rd first release)", UVM_LOW)
        force tb_top.wr_rst_n = 1'b0;
        force tb_top.rd_rst_n = 1'b0;
        
        #30ns;
        release tb_top.rd_rst_n;  // 读复位先释放
        `uvm_info("ASYNC_RST_TEST", "Read reset released", UVM_LOW)
        
        #40ns;
        release tb_top.wr_rst_n;  // 写复位后释放
        `uvm_info("ASYNC_RST_TEST", "Write reset released", UVM_LOW)
    endtask
    
endclass : fifo_async_reset_test
