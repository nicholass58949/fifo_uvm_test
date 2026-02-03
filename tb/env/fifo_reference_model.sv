// Reference Model - 简单FIFO参考模型
// 接收master monitor的写数据，转发期望数据给scoreboard
class fifo_reference_model extends uvm_component;
    `uvm_component_utils(fifo_reference_model)
    
    // Analysis imp - 接收master monitor的数据 (使用uvm_analysis_imp)
    uvm_analysis_imp #(fifo_transaction, fifo_reference_model) analysis_imp;
    
    // Analysis port - 发送期望数据给scoreboard (通过uvm_tlm_analysis_fifo)
    uvm_analysis_port #(fifo_transaction) exp_port;
    
    // 发送计数
    int unsigned tx_count = 0;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        analysis_imp = new("analysis_imp", this);
        exp_port = new("exp_port", this);
    endfunction
    
    // 接收写数据并发送期望数据给scoreboard
    virtual function void write(fifo_transaction tx);
        fifo_transaction tx_clone;
        
        if (tx.wr_en) begin
            // 克隆transaction
            if (!$cast(tx_clone, tx.clone())) begin
                `uvm_error("REF_MODEL", "Failed to clone transaction")
                return;
            end
            
            tx_count++;
            `uvm_info("REF_MODEL", $sformatf("Forwarding expected3 data[%0d]: %0h", tx_count, tx_clone.data), UVM_HIGH)
            
            // 通过exp_port发送期望数据给scoreboard
            exp_port.write(tx_clone);
        end
    endfunction
    
    // 报告阶段
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("REF_MODEL", $sformatf("Reference model forwarded %0d transactions", tx_count), UVM_LOW)
    endfunction
    
endclass : fifo_reference_model
