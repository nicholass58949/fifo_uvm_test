// Master Monitor - 监控写端口，采集数据发送给参考模型
class master_monitor extends uvm_monitor;
    `uvm_component_utils(master_monitor)
    
    // Analysis port - 连接到参考模型
    uvm_analysis_port #(fifo_transaction) ap;
    
    // Virtual interface
    virtual fifo_if vif;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("MASTER_MON", "Failed to get virtual interface")
        end
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        fifo_transaction tx;
        
        // 等待复位结束
        wait(vif.wr_rst_n == 1'b1);
        
        forever begin
            @(vif.wr_mon_cb);
            
            // 检测有效的写操作
            if (vif.wr_mon_cb.wr_en && !vif.wr_mon_cb.full) begin
                tx = fifo_transaction::type_id::create("tx");
                tx.data  = vif.wr_mon_cb.wr_data;
                tx.wr_en = 1'b1;
                tx.rd_en = 1'b0;
                tx.full  = vif.wr_mon_cb.full;
                
                `uvm_info("MASTER_MON", $sformatf("Captured write data: %0h", tx.data), UVM_MEDIUM)
                
                // 发送到参考模型
                ap.write(tx);
            end
        end
    endtask
    
endclass : master_monitor
