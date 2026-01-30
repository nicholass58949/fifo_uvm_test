// FIFO Environment - 集成所有组件
class fifo_env extends uvm_env;
    `uvm_component_utils(fifo_env)
    
    // Agents
    master_agent          mst_agent;    // 写端口代理
    slave_agent           slv_agent;    // 读端口代理
    
    // Reference Model
    fifo_reference_model  ref_model;
    
    // Scoreboard
    fifo_scoreboard       scoreboard;
    
    // Coverage
    fifo_coverage         coverage;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // 创建Master Agent (写端口)
        mst_agent = master_agent::type_id::create("mst_agent", this);
        mst_agent.is_active = UVM_ACTIVE;
        
        // 创建Slave Agent (读端口)
        slv_agent = slave_agent::type_id::create("slv_agent", this);
        slv_agent.is_active = UVM_ACTIVE;
        
        // 创建Reference Model
        ref_model = fifo_reference_model::type_id::create("ref_model", this);
        
        // 创建Scoreboard
        scoreboard = fifo_scoreboard::type_id::create("scoreboard", this);
        
        // 创建Coverage
        coverage = fifo_coverage::type_id::create("coverage", this);
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // 连接Master Monitor -> Reference Model (使用uvm_analysis_port和imp)
        // Master monitor采集写数据，发送给参考模型
        mst_agent.ap.connect(ref_model.analysis_imp);
        
        // 连接Reference Model -> Scoreboard (通过uvm_tlm_analysis_fifo)
        // 参考模型发送期望数据给计分板
        ref_model.exp_port.connect(scoreboard.exp_fifo.analysis_export);
        
        // 连接Slave Monitor -> Scoreboard (通过uvm_tlm_analysis_fifo)
        // Slave monitor采集实际读数据，发送给计分板
        slv_agent.ap.connect(scoreboard.act_fifo.analysis_export);
    endfunction
    
endclass : fifo_env
