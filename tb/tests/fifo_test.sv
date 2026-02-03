// FIFO Base Test
class fifo_base_test extends uvm_test;
    `uvm_component_utils(fifo_base_test)
    
    fifo_env env;
    
    // Watchdog 超时时间 (ns)
    int unsigned watchdog_timeout = 10000; // 10us 无活动则结束
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // 创建环境
        env = fifo_env::type_id::create("env", this);

        // 配置序列重载（工厂机制）
        configure_sequence_overrides();
    endfunction

    // 虚函数：配置序列类型重载（由子类或+SEQUENCE_TYPE控制）
    virtual function void configure_sequence_overrides();
        string seq_type;

        // 默认序列映射
        uvm_factory::get().set_type_override_by_type(master_base_sequence::get_type(), master_sequence::get_type());
        uvm_factory::get().set_type_override_by_type(slave_base_sequence::get_type(), slave_sequence::get_type());

        // 运行时切换序列类型：+SEQUENCE_TYPE=fixed/stress
        if ($value$plusargs("SEQUENCE_TYPE=%s", seq_type)) begin
            seq_type = seq_type.tolower();

            if (seq_type == "fixed") begin
                uvm_factory::get().set_type_override_by_type(master_base_sequence::get_type(), master_fixed_sequence::get_type());
                uvm_factory::get().set_type_override_by_type(slave_base_sequence::get_type(), slave_reactive_sequence::get_type());
            end else if (seq_type == "stress") begin
                uvm_factory::get().set_type_override_by_type(master_base_sequence::get_type(), master_sequence::get_type());
                uvm_factory::get().set_type_override_by_type(slave_base_sequence::get_type(), slave_reactive_sequence::get_type());
            end else if (seq_type == "normal") begin
                uvm_factory::get().set_type_override_by_type(master_base_sequence::get_type(), master_sequence::get_type());
                uvm_factory::get().set_type_override_by_type(slave_base_sequence::get_type(), slave_sequence::get_type());
            end
        end
    endfunction

    // 虚函数：配置序列参数（由子类重载定制）
    virtual function void configure_sequence_knobs(
        ref uvm_sequence #(fifo_transaction) mst_seq,
        ref uvm_sequence #(fifo_transaction) slv_seq
    );
        master_base_sequence mst_base;
        slave_base_sequence slv_base;

        if ($cast(mst_base, mst_seq)) begin
            mst_base.num_transactions = 20;
        end

        if ($cast(slv_base, slv_seq)) begin
            slv_base.num_transactions = 20;
        end
    endfunction
    
    // 虚函数：配置序列（由子类重载自定义序列）
    virtual function void configure_sequences(
        output uvm_sequence #(fifo_transaction) mst_seq,
        output uvm_sequence #(fifo_transaction) slv_seq
    );
        master_base_sequence mst = master_base_sequence::type_id::create("mst_seq");
        slave_base_sequence slv = slave_base_sequence::type_id::create("slv_seq");
        
        mst_seq = mst;
        slv_seq = slv;

        configure_sequence_knobs(mst_seq, slv_seq);
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
        uvm_sequence #(fifo_transaction) mst_seq, slv_seq;
        
        phase.raise_objection(this);
        
        `uvm_info("TEST", "Starting FIFO test", UVM_LOW)
        
        // 等待复位结束
        #100ns;
        
        // 调用虚函数获取序列（由子类定制）
        configure_sequences(mst_seq, slv_seq);
        
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

// 普通数据测试 - 使用基类的配置
class fifo_normal_test extends fifo_base_test;
    `uvm_component_utils(fifo_normal_test)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
endclass : fifo_normal_test

// 固定数据测试
class fifo_fixed_test extends fifo_base_test;
    `uvm_component_utils(fifo_fixed_test)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void configure_sequence_overrides();
        super.configure_sequence_overrides();
        uvm_factory::get().set_type_override_by_type(master_base_sequence::get_type(), master_fixed_sequence::get_type());
        uvm_factory::get().set_type_override_by_type(slave_base_sequence::get_type(), slave_reactive_sequence::get_type());
    endfunction

    virtual function void configure_sequence_knobs(
        ref uvm_sequence #(fifo_transaction) mst_seq,
        ref uvm_sequence #(fifo_transaction) slv_seq
    );
        slave_reactive_sequence slv;

        if ($cast(slv, slv_seq)) begin
            slv.max_reads = 16;
        end
    endfunction
    
endclass : fifo_fixed_test

// 压力测试 - 大量数据
class fifo_stress_test extends fifo_base_test;
    `uvm_component_utils(fifo_stress_test)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void configure_sequence_overrides();
        super.configure_sequence_overrides();
        uvm_factory::get().set_type_override_by_type(master_base_sequence::get_type(), master_sequence::get_type());
        uvm_factory::get().set_type_override_by_type(slave_base_sequence::get_type(), slave_reactive_sequence::get_type());
    endfunction

    virtual function void configure_sequence_knobs(
        ref uvm_sequence #(fifo_transaction) mst_seq,
        ref uvm_sequence #(fifo_transaction) slv_seq
    );
        master_base_sequence mst;
        slave_reactive_sequence slv;

        if ($cast(mst, mst_seq)) begin
            mst.num_transactions = 100;
        end

        if ($cast(slv, slv_seq)) begin
            slv.max_reads = 100;
        end
    endfunction
    
endclass : fifo_stress_test
