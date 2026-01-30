// Master Agent - 写端口代理
class master_agent extends uvm_agent;
    `uvm_component_utils(master_agent)
    
    master_sequencer    sequencer;
    master_driver       driver;
    master_monitor      monitor;
    
    // Analysis port - 转发monitor的数据
    uvm_analysis_port #(fifo_transaction) ap;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // 创建analysis port
        ap = new("ap", this);
        
        // 总是创建monitor
        monitor = master_monitor::type_id::create("monitor", this);
        
        // 如果是active模式，创建sequencer和driver
        if (is_active == UVM_ACTIVE) begin
            sequencer = master_sequencer::type_id::create("sequencer", this);
            driver    = master_driver::type_id::create("driver", this);
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
    
endclass : master_agent
