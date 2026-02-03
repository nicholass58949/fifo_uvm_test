// Master Driver - 驱动写端口
class master_driver extends uvm_driver #(fifo_transaction);
    `uvm_component_utils(master_driver)
    
    // Virtual interface
    virtual fifo_if vif;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("MASTER_DRV", "Failed to get virtual interface")
        end
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        fifo_transaction tx;
        
        // 初始化信号
        vif.wr_cb.wr_en   <= 1'b0;
        vif.wr_cb.wr_data <= 8'h0;
        
        // 等待复位结束
        wait(vif.wr_rst_n == 1'b1);
        @(vif.wr_cb);
        
        forever begin
            seq_item_port.get_next_item(tx);
            drive_transaction(tx);
            seq_item_port.item_done();
        end
    endtask
    
    virtual task drive_transaction(fifo_transaction tx);
        // 等待FIFO不满才写入
        while (vif.wr_cb.full) begin
            vif.wr_cb.wr_en <= 1'b0;
            @(vif.wr_cb);
        end
        
        // 写数据
        vif.wr_cb.wr_en   <= 1'b1;
        vif.wr_cb.wr_data <= tx.data;
        `uvm_info("MASTER_DRV", $sformatf("Master Writing FIFO data is expected1: %0h", tx.data), UVM_HIGH)
        
        @(vif.wr_cb);
        vif.wr_cb.wr_en <= 1'b0;
    endtask
    
endclass : master_driver
