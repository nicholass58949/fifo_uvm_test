// FIFO Transaction Class
class fifo_transaction extends uvm_sequence_item;
    
    // Data fields
    rand bit [7:0] data;      // FIFO数据宽度8位
    rand bit       wr_en;     // 写使能
    rand bit       rd_en;     // 读使能
    
    // Status signals (for monitoring)
    bit            full;      // FIFO满标志
    bit            empty;     // FIFO空标志
    
    // Constraints
    constraint wr_rd_c {
        // 写和读不能同时为1（在各自的agent中会单独控制）
        !(wr_en && rd_en);
    }
    
    constraint data_c {
        data inside {[0:255]};
    }
    
    `uvm_object_utils_begin(fifo_transaction)
        `uvm_field_int(data,  UVM_ALL_ON)
        `uvm_field_int(wr_en, UVM_ALL_ON)
        `uvm_field_int(rd_en, UVM_ALL_ON)
        `uvm_field_int(full,  UVM_ALL_ON)
        `uvm_field_int(empty, UVM_ALL_ON)
    `uvm_object_utils_end
    
    function new(string name = "fifo_transaction");
        super.new(name);
    endfunction
    
    function void display(string prefix = "");
        $display("%s Transaction - Data: %0h, WR_EN: %0b, RD_EN: %0b, FULL: %0b, EMPTY: %0b", 
                 prefix, data, wr_en, rd_en, full, empty);
    endfunction
    
endclass : fifo_transaction
