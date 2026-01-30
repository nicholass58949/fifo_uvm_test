// FIFO Coverage Module
// 覆盖率模块 - 确保FIFO深度和各种场景被测试

class fifo_coverage extends uvm_component;
    `uvm_component_utils(fifo_coverage)
    
    // Virtual interface
    virtual fifo_if vif;
    
    // FIFO参数
    int unsigned fifo_depth = 16;
    
    // 当前FIFO深度计数（近似值，用于覆盖率）
    int unsigned current_depth = 0;
    
    // 用于采样的中间变量
    bit       sampled_wr_en;
    bit       sampled_full;
    bit [7:0] sampled_wr_data;
    bit       sampled_rd_en;
    bit       sampled_empty;
    bit [7:0] sampled_rd_data;
    bit       sampled_wr_rst_n;
    bit       sampled_rd_rst_n;
    
    // ==================== 覆盖组定义 ====================
    
    // 写端口覆盖组
    covergroup cg_write_port;
        option.per_instance = 1;
        option.name = "cg_write_port";
        
        // 写使能覆盖
        cp_wr_en: coverpoint sampled_wr_en {
            bins wr_disabled = {0};
            bins wr_enabled  = {1};
        }
        
        // 满标志覆盖
        cp_full: coverpoint sampled_full {
            bins not_full = {0};
            bins is_full  = {1};
        }
        
        // 写数据覆盖 - 边界值
        cp_wr_data: coverpoint sampled_wr_data {
            bins zero     = {8'h00};
            bins low      = {[8'h01:8'h3F]};
            bins mid      = {[8'h40:8'hBF]};
            bins high     = {[8'hC0:8'hFE]};
            bins max      = {8'hFF};
        }
        
        // 交叉覆盖: 写使能 x 满标志
        cx_wr_full: cross cp_wr_en, cp_full {
            bins valid_write   = binsof(cp_wr_en.wr_enabled) && binsof(cp_full.not_full);
            bins write_blocked = binsof(cp_wr_en.wr_enabled) && binsof(cp_full.is_full);
            bins idle_not_full = binsof(cp_wr_en.wr_disabled) && binsof(cp_full.not_full);
            bins idle_full     = binsof(cp_wr_en.wr_disabled) && binsof(cp_full.is_full);
        }
    endgroup
    
    // 读端口覆盖组
    covergroup cg_read_port;
        option.per_instance = 1;
        option.name = "cg_read_port";
        
        // 读使能覆盖
        cp_rd_en: coverpoint sampled_rd_en {
            bins rd_disabled = {0};
            bins rd_enabled  = {1};
        }
        
        // 空标志覆盖
        cp_empty: coverpoint sampled_empty {
            bins not_empty = {0};
            bins is_empty  = {1};
        }
        
        // 读数据覆盖 - 边界值
        cp_rd_data: coverpoint sampled_rd_data {
            bins zero     = {8'h00};
            bins low      = {[8'h01:8'h3F]};
            bins mid      = {[8'h40:8'hBF]};
            bins high     = {[8'hC0:8'hFE]};
            bins max      = {8'hFF};
        }
        
        // 交叉覆盖: 读使能 x 空标志
        cx_rd_empty: cross cp_rd_en, cp_empty {
            bins valid_read     = binsof(cp_rd_en.rd_enabled) && binsof(cp_empty.not_empty);
            bins read_blocked   = binsof(cp_rd_en.rd_enabled) && binsof(cp_empty.is_empty);
            bins idle_not_empty = binsof(cp_rd_en.rd_disabled) && binsof(cp_empty.not_empty);
            bins idle_empty     = binsof(cp_rd_en.rd_disabled) && binsof(cp_empty.is_empty);
        }
    endgroup
    
    // FIFO深度覆盖组
    covergroup cg_fifo_depth;
        option.per_instance = 1;
        option.name = "cg_fifo_depth";
        
        // FIFO深度覆盖 - 确保所有深度都被测试
        cp_depth: coverpoint current_depth {
            bins empty_state  = {0};
            bins depth_1      = {1};
            bins depth_2_4    = {[2:4]};
            bins depth_5_8    = {[5:8]};
            bins depth_9_12   = {[9:12]};
            bins depth_13_15  = {[13:15]};
            bins full_state   = {16};  // FIFO_DEPTH
        }
        
        // 深度转换覆盖
        cp_depth_trans: coverpoint current_depth {
            bins inc_from_empty = (0 => 1);
            bins inc_low        = ([1:4] => [2:5]);
            bins inc_mid        = ([5:10] => [6:11]);
            bins inc_high       = ([11:14] => [12:15]);
            bins inc_to_full    = (15 => 16);
            bins dec_from_full  = (16 => 15);
            bins dec_high       = ([12:15] => [11:14]);
            bins dec_mid        = ([6:11] => [5:10]);
            bins dec_low        = ([2:5] => [1:4]);
            bins dec_to_empty   = (1 => 0);
        }
    endgroup
    
    // 复位覆盖组
    covergroup cg_reset;
        option.per_instance = 1;
        option.name = "cg_reset";
        
        cp_wr_rst: coverpoint sampled_wr_rst_n {
            bins reset_active   = {0};
            bins reset_inactive = {1};
        }
        
        cp_rd_rst: coverpoint sampled_rd_rst_n {
            bins reset_active   = {0};
            bins reset_inactive = {1};
        }
        
        // 交叉覆盖: 同时复位 vs 独立复位
        cx_reset: cross cp_wr_rst, cp_rd_rst;
    endgroup
    
    // ==================== 构造函数和方法 ====================
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        // 在构造函数中创建覆盖组实例
        cg_write_port = new();
        cg_read_port  = new();
        cg_fifo_depth = new();
        cg_reset      = new();
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("COVERAGE", "Failed to get virtual interface")
        end
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        // 启动深度跟踪和覆盖率采样
        fork
            sample_write_port();
            sample_read_port();
            track_fifo_depth();
        join_none
    endtask
    
    // 采样写端口覆盖组
    virtual task sample_write_port();
        forever begin
            @(posedge vif.wr_clk);
            sampled_wr_en   = vif.wr_en;
            sampled_full    = vif.full;
            sampled_wr_data = vif.wr_data;
            sampled_wr_rst_n = vif.wr_rst_n;
            cg_write_port.sample();
            if (!vif.wr_rst_n) cg_reset.sample();
        end
    endtask
    
    // 采样读端口覆盖组
    virtual task sample_read_port();
        forever begin
            @(posedge vif.rd_clk);
            sampled_rd_en   = vif.rd_en;
            sampled_empty   = vif.empty;
            sampled_rd_data = vif.rd_data;
            sampled_rd_rst_n = vif.rd_rst_n;
            cg_read_port.sample();
            if (!vif.rd_rst_n) cg_reset.sample();
        end
    endtask
    
    // 跟踪FIFO深度（近似）
    virtual task track_fifo_depth();
        forever begin
            @(posedge vif.wr_clk or posedge vif.rd_clk);
            
            // 复位时清零深度
            if (!vif.wr_rst_n || !vif.rd_rst_n) begin
                current_depth = 0;
            end else begin
                // 简化的深度跟踪（不精确但用于覆盖率）
                if (vif.wr_en && !vif.full) begin
                    if (current_depth < fifo_depth) current_depth++;
                end
                
                if (vif.rd_en && !vif.empty) begin
                    if (current_depth > 0) current_depth--;
                end
            end
            
            // 采样深度覆盖组
            cg_fifo_depth.sample();
        end
    endtask
    
    // 报告覆盖率
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        
        `uvm_info("COVERAGE", "========================================", UVM_NONE)
        `uvm_info("COVERAGE", "         COVERAGE REPORT                ", UVM_NONE)
        `uvm_info("COVERAGE", "========================================", UVM_NONE)
        `uvm_info("COVERAGE", $sformatf("Write Port Coverage : %.2f%%", cg_write_port.get_coverage()), UVM_NONE)
        `uvm_info("COVERAGE", $sformatf("Read Port Coverage  : %.2f%%", cg_read_port.get_coverage()), UVM_NONE)
        `uvm_info("COVERAGE", $sformatf("FIFO Depth Coverage : %.2f%%", cg_fifo_depth.get_coverage()), UVM_NONE)
        `uvm_info("COVERAGE", $sformatf("Reset Coverage      : %.2f%%", cg_reset.get_coverage()), UVM_NONE)
        `uvm_info("COVERAGE", "========================================", UVM_NONE)
    endfunction
    
endclass : fifo_coverage
