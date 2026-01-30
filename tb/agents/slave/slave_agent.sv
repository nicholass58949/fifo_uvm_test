// Slave Agent - 读端口代理
class slave_agent extends uvm_agent;
    `uvm_component_utils(slave_agent)
    
    slave_sequencer    sequencer;
    slave_driver       driver;
    slave_monitor      monitor;
    
    // Analysis port - 转发monitor的数据到scoreboard
    uvm_analysis_port #(fifo_transaction) ap;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // 创建analysis port
        ap = new("ap", this);
        
        // 总是创建monitor
        monitor = slave_monitor::type_id::create("monitor", this);
        
        // 如果是active模式，创建sequencer和driver
        if (is_active == UVM_ACTIVE) begin
            sequencer = slave_sequencer::type_id::create("sequencer", this);
            driver    = slave_driver::type_id::create("driver", this);
        end
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // 连接monitor的analysis port到agent的analysis port
        monitor.ap.connect(ap);
        
        // 如果是active模式，连接driver和sequencer
        if (is_active == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction
    
endclass : slave_agent
