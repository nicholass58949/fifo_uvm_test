// Slave Monitor - 监控读端口，采集实际数据发送给计分板
class slave_monitor extends uvm_monitor;
    `uvm_component_utils(slave_monitor)
    
    // Analysis port - 连接到scoreboard
    uvm_analysis_port #(fifo_transaction) ap;
    
    // Virtual interface
    virtual fifo_if vif;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("SLAVE_MON", "Failed to get virtual interface")
        end
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        fifo_transaction tx;
        
        // 等待复位结束
        wait(vif.rd_rst_n == 1'b1);
        
        forever begin
            @(vif.rd_mon_cb);
            
            // 检测有效的读操作（rd_en为高且非空时读取有效）
            if (vif.rd_mon_cb.rd_en && !vif.rd_mon_cb.empty) begin
                tx = fifo_transaction::type_id::create("tx");
                tx.data  = vif.rd_mon_cb.rd_data;
                tx.rd_en = 1'b1;
                tx.wr_en = 1'b0;
                tx.empty = vif.rd_mon_cb.empty;
                
                `uvm_info("SLAVE_MON", $sformatf("Captured read data: %0h", tx.data), UVM_MEDIUM)
                
                // 发送到scoreboard (实际数据)
                ap.write(tx);
            end
        end
    endtask
    
endclass : slave_monitor
