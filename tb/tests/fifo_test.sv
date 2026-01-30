// FIFO Base Test
class fifo_base_test extends uvm_test;
    `uvm_component_utils(fifo_base_test)
    
    fifo_env env;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // 创建环境
        env = fifo_env::type_id::create("env", this);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        master_sequence     mst_seq;
        slave_sequence      slv_seq;
        
        phase.raise_objection(this);
        
        `uvm_info("TEST", "Starting FIFO test", UVM_LOW)
        
        // 等待复位结束
        #100ns;
        
        // 创建序列
        mst_seq = master_sequence::type_id::create("mst_seq");
        slv_seq = slave_sequence::type_id::create("slv_seq");
        
        // 配置序列
        mst_seq.num_transactions = 20;
        slv_seq.num_transactions = 20;
        
        // 并行启动主从序列
        fork
            mst_seq.start(env.mst_agent.sequencer);
            slv_seq.start(env.slv_agent.sequencer);
        join
        
        // 等待所有数据处理完成
        #500ns;
        
        `uvm_info("TEST", "FIFO test completed", UVM_LOW)
        
        phase.drop_objection(this);
    endtask
    
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("TEST", "========== TEST REPORT ==========", UVM_NONE)
    endfunction
    
endclass : fifo_base_test

// 固定数据测试
class fifo_fixed_test extends fifo_base_test;
    `uvm_component_utils(fifo_fixed_test)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        master_fixed_sequence   mst_seq;
        slave_reactive_sequence slv_seq;
        
        phase.raise_objection(this);
        
        `uvm_info("TEST", "Starting FIFO fixed data test", UVM_LOW)
        
        // 等待复位结束
        #100ns;
        
        // 创建序列
        mst_seq = master_fixed_sequence::type_id::create("mst_seq");
        slv_seq = slave_reactive_sequence::type_id::create("slv_seq");
        slv_seq.max_reads = 16;
        
        // 并行启动主从序列
        fork
            mst_seq.start(env.mst_agent.sequencer);
            slv_seq.start(env.slv_agent.sequencer);
        join
        
        // 等待所有数据处理完成
        #500ns;
        
        `uvm_info("TEST", "FIFO fixed data test completed", UVM_LOW)
        
        phase.drop_objection(this);
    endtask
    
endclass : fifo_fixed_test

// 压力测试 - 大量数据
class fifo_stress_test extends fifo_base_test;
    `uvm_component_utils(fifo_stress_test)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        master_sequence         mst_seq;
        slave_reactive_sequence slv_seq;
        
        phase.raise_objection(this);
        
        `uvm_info("TEST", "Starting FIFO stress test", UVM_LOW)
        
        // 等待复位结束
        #100ns;
        
        // 创建序列
        mst_seq = master_sequence::type_id::create("mst_seq");
        slv_seq = slave_reactive_sequence::type_id::create("slv_seq");
        
        // 大量数据
        mst_seq.num_transactions = 100;
        slv_seq.max_reads = 100;
        
        // 并行启动主从序列
        fork
            mst_seq.start(env.mst_agent.sequencer);
            slv_seq.start(env.slv_agent.sequencer);
        join
        
        // 等待所有数据处理完成
        #1000ns;
        
        `uvm_info("TEST", "FIFO stress test completed", UVM_LOW)
        
        phase.drop_objection(this);
    endtask
    
endclass : fifo_stress_test
