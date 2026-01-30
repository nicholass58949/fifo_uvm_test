// Slave Driver - 驱动读端口，根据empty和full信号发送激励
class slave_driver extends uvm_driver #(fifo_transaction);
    `uvm_component_utils(slave_driver)
    
    // Virtual interface
    virtual fifo_if vif;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("SLAVE_DRV", "Failed to get virtual interface")
        end
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        fifo_transaction tx;
        
        // 初始化信号
        vif.rd_cb.rd_en <= 1'b0;
        
        // 等待复位结束
        wait(vif.rd_rst_n == 1'b1);
        @(vif.rd_cb);
        
        forever begin
            seq_item_port.get_next_item(tx);
            drive_transaction(tx);
            seq_item_port.item_done();
        end
    endtask
    
    virtual task drive_transaction(fifo_transaction tx);
        // 等待FIFO不空才读取
        while (vif.rd_cb.empty) begin
            vif.rd_cb.rd_en <= 1'b0;
            @(vif.rd_cb);
        end
        
        // 发送读使能
        vif.rd_cb.rd_en <= 1'b1;
        `uvm_info("SLAVE_DRV", "Asserting rd_en", UVM_HIGH)
        
        @(vif.rd_cb);
        vif.rd_cb.rd_en <= 1'b0;
    endtask
    
endclass : slave_driver
