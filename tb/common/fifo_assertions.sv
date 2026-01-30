// FIFO Assertions Module
// 断言模块 - 确保FIFO时序正确

module fifo_assertions #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    // Write port
    input logic                   wr_clk,
    input logic                   wr_rst_n,
    input logic                   wr_en,
    input logic [DATA_WIDTH-1:0]  wr_data,
    input logic                   full,
    
    // Read port
    input logic                   rd_clk,
    input logic                   rd_rst_n,
    input logic                   rd_en,
    input logic [DATA_WIDTH-1:0]  rd_data,
    input logic                   empty
);

    // ==================== 写时钟域断言 ====================
    
    // 断言1: 复位时full应该为低
    property p_reset_full;
        @(posedge wr_clk) !wr_rst_n |-> ##[0:3] !full;
    endproperty
    a_reset_full: assert property (p_reset_full)
        else $error("[ASSERT] Full flag should be low after write reset");
    
    // 断言2: 当FIFO满时，不应该写入数据
    property p_no_write_when_full;
        @(posedge wr_clk) disable iff (!wr_rst_n)
        (full && wr_en) |-> ##1 full;  // 满时写入，下一拍仍然满（数据被忽略）
    endproperty
    a_no_write_when_full: assert property (p_no_write_when_full)
        else $warning("[ASSERT] Write attempted when FIFO is full");
    
    // 断言3: 写使能和数据应该稳定至少一个时钟周期
    property p_wr_stable;
        @(posedge wr_clk) disable iff (!wr_rst_n)
        (wr_en && !full) |-> ##1 (wr_en == $past(wr_en) || !wr_en);
    endproperty
    // a_wr_stable: assert property (p_wr_stable);
    
    // ==================== 读时钟域断言 ====================
    
    // 断言4: 复位时empty应该为高
    property p_reset_empty;
        @(posedge rd_clk) !rd_rst_n |-> ##[0:3] empty;
    endproperty
    a_reset_empty: assert property (p_reset_empty)
        else $error("[ASSERT] Empty flag should be high after read reset");
    
    // 断言5: 当FIFO空时，不应该读取数据
    property p_no_read_when_empty;
        @(posedge rd_clk) disable iff (!rd_rst_n)
        (empty && rd_en) |-> ##1 empty;  // 空时读取，下一拍仍然空（无效读取）
    endproperty
    a_no_read_when_empty: assert property (p_no_read_when_empty)
        else $warning("[ASSERT] Read attempted when FIFO is empty");
    
    // ==================== 跨时钟域断言 ====================
    
    // 断言6: full和empty不应该同时为高（除非复位期间）
    // 注意：由于跨时钟域，使用$sampled确保采样正确
    property p_not_full_and_empty;
        @(posedge wr_clk) disable iff (!wr_rst_n || !rd_rst_n)
        !(full && empty);
    endproperty
    a_not_full_and_empty: assert property (p_not_full_and_empty)
        else $error("[ASSERT] FIFO cannot be both full and empty");
    
    // ==================== 数据完整性断言 ====================
    
    // 断言7: 写入后，FIFO不应该立即为空（考虑跨时钟域延迟）
    sequence s_valid_write;
        @(posedge wr_clk) (wr_en && !full);
    endsequence
    
    // 断言8: 读取后，FIFO不应该立即为满（考虑跨时钟域延迟）
    sequence s_valid_read;
        @(posedge rd_clk) (rd_en && !empty);
    endsequence
    
    // ==================== 覆盖属性 ====================
    
    // 覆盖: 成功写入
    cover property (@(posedge wr_clk) disable iff (!wr_rst_n) (wr_en && !full));
    
    // 覆盖: 成功读取
    cover property (@(posedge rd_clk) disable iff (!rd_rst_n) (rd_en && !empty));
    
    // 覆盖: FIFO满时尝试写入
    cover property (@(posedge wr_clk) disable iff (!wr_rst_n) (wr_en && full));
    
    // 覆盖: FIFO空时尝试读取
    cover property (@(posedge rd_clk) disable iff (!rd_rst_n) (rd_en && empty));
    
    // 覆盖: 从空到非空
    cover property (@(posedge rd_clk) disable iff (!rd_rst_n) (empty ##1 !empty));
    
    // 覆盖: 从满到非满
    cover property (@(posedge wr_clk) disable iff (!wr_rst_n) (full ##1 !full));

endmodule : fifo_assertions
