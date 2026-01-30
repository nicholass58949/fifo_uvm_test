// Scoreboard - 比较期望数据和实际数据
class fifo_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(fifo_scoreboard)
    
    // uvm_tlm_analysis_fifo - 接收slave monitor的实际数据
    uvm_tlm_analysis_fifo #(fifo_transaction) act_fifo;
    
    // uvm_tlm_analysis_fifo - 接收reference model的期望数据
    uvm_tlm_analysis_fifo #(fifo_transaction) exp_fifo;
    
    // 统计计数器
    int unsigned match_count;
    int unsigned mismatch_count;
    int unsigned total_count;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        match_count    = 0;
        mismatch_count = 0;
        total_count    = 0;
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        act_fifo = new("act_fifo", this);
        exp_fifo = new("exp_fifo", this);
    endfunction
    
    // 在run_phase中比较数据
    virtual task run_phase(uvm_phase phase);
        fifo_transaction act_tx, exp_tx;
        
        forever begin
            // 从act_fifo获取实际数据
            act_fifo.get(act_tx);
            
            total_count++;
            
            // 从exp_fifo获取期望数据
            if (exp_fifo.try_get(exp_tx)) begin
                // 比较数据
                if (act_tx.data == exp_tx.data) begin
                    match_count++;
                    `uvm_info("SCOREBOARD", $sformatf("MATCH [%0d]: Expected=%0h, Actual=%0h", 
                              total_count, exp_tx.data, act_tx.data), UVM_MEDIUM)
                end else begin
                    mismatch_count++;
                    `uvm_error("SCOREBOARD", $sformatf("MISMATCH [%0d]: Expected=%0h, Actual=%0h", 
                               total_count, exp_tx.data, act_tx.data))
                end
            end else begin
                `uvm_error("SCOREBOARD", $sformatf("No expected data for actual data: %0h", act_tx.data))
                mismatch_count++;
            end
        end
    endtask
    
    // 报告阶段 - 输出统计信息
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        
        `uvm_info("SCOREBOARD", "========================================", UVM_NONE)
        `uvm_info("SCOREBOARD", "         SCOREBOARD REPORT              ", UVM_NONE)
        `uvm_info("SCOREBOARD", "========================================", UVM_NONE)
        `uvm_info("SCOREBOARD", $sformatf("Total Comparisons : %0d", total_count), UVM_NONE)
        `uvm_info("SCOREBOARD", $sformatf("Matches           : %0d", match_count), UVM_NONE)
        `uvm_info("SCOREBOARD", $sformatf("Mismatches        : %0d", mismatch_count), UVM_NONE)
        `uvm_info("SCOREBOARD", "========================================", UVM_NONE)
        
        if (mismatch_count == 0 && total_count > 0) begin
            `uvm_info("SCOREBOARD", "TEST PASSED", UVM_NONE)
        end else if (total_count == 0) begin
            `uvm_warning("SCOREBOARD", "No data was compared")
        end else begin
            `uvm_error("SCOREBOARD", "TEST FAILED")
        end
    endfunction
    
endclass : fifo_scoreboard
