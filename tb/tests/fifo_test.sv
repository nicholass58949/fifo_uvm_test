// FIFO Base Test
class fifo_base_test extends uvm_test;
    `uvm_component_utils(fifo_base_test)
    
    fifo_env env;
    
    // Watchdog 超时时间 (ns)
    int unsigned watchdog_timeout = 10000; // 0.1us 无活动则结束
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // 创建环境
        env = fifo_env::type_id::create("env", this);
    endfunction
    
    // Watchdog 任务 - 监控长时间无 transaction
    virtual task watchdog_task(uvm_phase phase);
        int last_count;
        int current_count;
        int idle_cycles;
        
        #1us; // 等待启动
        
        last_count = env.scoreboard.total_count;
        idle_cycles = 0;
        
        forever begin
            #1us;
            current_count = env.scoreboard.total_count;
            
            if (current_count == last_count) begin
                idle_cycles++;
                if (idle_cycles * 1000 >= watchdog_timeout) begin
                    `uvm_info("WATCHDOG", $sformatf("No activity for %0d ns, ending test", watchdog_timeout), UVM_LOW)
                    phase.drop_objection(this);
                    break;
                end
            end else begin
                idle_cycles = 0;
            end
            
            last_count = current_count;
        end
    endtask
    
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
        mst_seq.num_transactions = 200;
        slv_seq.num_transactions = 200;
        
        // 并行启动主从序列和 watchdog
        fork
            mst_seq.start(env.mst_agent.sequencer);
            slv_seq.start(env.slv_agent.sequencer);
            watchdog_task(phase);
        join_any
        
        // 等待所有数据处理完成
        #1us;
        
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
