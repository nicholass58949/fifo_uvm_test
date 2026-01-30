// Asynchronous FIFO DUT
// 异步FIFO设计 - 使用格雷码处理跨时钟域指针同步

module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4   // FIFO深度 = 2^ADDR_WIDTH = 16
)(
    // Write port
    input  logic                   wr_clk,
    input  logic                   wr_rst_n,
    input  logic                   wr_en,
    input  logic [DATA_WIDTH-1:0]  wr_data,
    output logic                   full,
    
    // Read port
    input  logic                   rd_clk,
    input  logic                   rd_rst_n,
    input  logic                   rd_en,
    output logic [DATA_WIDTH-1:0]  rd_data,
    output logic                   empty
);

    // FIFO深度
    localparam FIFO_DEPTH = 1 << ADDR_WIDTH;
    
    // 存储器
    logic [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];
    
    // 写指针 (二进制和格雷码)
    logic [ADDR_WIDTH:0] wr_ptr_bin;
    logic [ADDR_WIDTH:0] wr_ptr_gray;
    logic [ADDR_WIDTH:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2;
    
    // 读指针 (二进制和格雷码)
    logic [ADDR_WIDTH:0] rd_ptr_bin;
    logic [ADDR_WIDTH:0] rd_ptr_gray;
    logic [ADDR_WIDTH:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2;
    
    // 二进制转格雷码
    function automatic logic [ADDR_WIDTH:0] bin2gray(input logic [ADDR_WIDTH:0] bin);
        return bin ^ (bin >> 1);
    endfunction
    
    // 格雷码转二进制
    function automatic logic [ADDR_WIDTH:0] gray2bin(input logic [ADDR_WIDTH:0] gray);
        logic [ADDR_WIDTH:0] bin;
        bin[ADDR_WIDTH] = gray[ADDR_WIDTH];
        for (int i = ADDR_WIDTH-1; i >= 0; i--) begin
            bin[i] = bin[i+1] ^ gray[i];
        end
        return bin;
    endfunction
    
    // ==================== 写时钟域 ====================
    
    // 写指针更新
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_ptr_bin  <= '0;
            wr_ptr_gray <= '0;
        end else if (wr_en && !full) begin
            wr_ptr_bin  <= wr_ptr_bin + 1'b1;
            wr_ptr_gray <= bin2gray(wr_ptr_bin + 1'b1);
        end
    end
    
    // 写数据到存储器
    always_ff @(posedge wr_clk) begin
        if (wr_en && !full) begin
            mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= wr_data;
        end
    end
    
    // 读指针同步到写时钟域 (两级同步)
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            rd_ptr_gray_sync1 <= '0;
            rd_ptr_gray_sync2 <= '0;
        end else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end
    end
    
    // 满标志生成
    // 格雷码满条件: 高两位相反，其余位相同
    assign full = (wr_ptr_gray == {~rd_ptr_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1], 
                                    rd_ptr_gray_sync2[ADDR_WIDTH-2:0]});
    
    // ==================== 读时钟域 ====================
    
    // 读指针更新
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_ptr_bin  <= '0;
            rd_ptr_gray <= '0;
        end else if (rd_en && !empty) begin
            rd_ptr_bin  <= rd_ptr_bin + 1'b1;
            rd_ptr_gray <= bin2gray(rd_ptr_bin + 1'b1);
        end
    end
    
    // 读数据
    assign rd_data = mem[rd_ptr_bin[ADDR_WIDTH-1:0]];
    
    // 写指针同步到读时钟域 (两级同步)
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            wr_ptr_gray_sync1 <= '0;
            wr_ptr_gray_sync2 <= '0;
        end else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end
    end
    
    // 空标志生成
    // 格雷码空条件: 读写指针相同
    assign empty = (rd_ptr_gray == wr_ptr_gray_sync2);

endmodule : async_fifo
