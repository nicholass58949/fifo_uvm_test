// FIFO Testbench Top Module
`timescale 1ns/1ps

module tb_top;
    
    import uvm_pkg::*;
    import fifo_pkg::*;
    `include "uvm_macros.svh"
    
    // Parameters
    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 4;
    
    // Clock and Reset signals
    logic wr_clk;
    logic rd_clk;
    logic wr_rst_n;
    logic rd_rst_n;
    
    // Clock periods (异步时钟，不同频率)
    parameter WR_CLK_PERIOD = 10;  // 100MHz
    parameter RD_CLK_PERIOD = 15;  // 66.67MHz
    
    // Interface instantiation
    fifo_if #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) vif (
        .wr_clk(wr_clk),
        .rd_clk(rd_clk),
        .wr_rst_n(wr_rst_n),
        .rd_rst_n(rd_rst_n)
    );
    
    // DUT instantiation
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        // Write port
        .wr_clk   (wr_clk),
        .wr_rst_n (wr_rst_n),
        .wr_en    (vif.wr_en),
        .wr_data  (vif.wr_data),
        .full     (vif.full),
        
        // Read port
        .rd_clk   (rd_clk),
        .rd_rst_n (rd_rst_n),
        .rd_en    (vif.rd_en),
        .rd_data  (vif.rd_data),
        .empty    (vif.empty)
    );
    
    // Assertions instantiation
    fifo_assertions #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) assertions (
        // Write port
        .wr_clk   (wr_clk),
        .wr_rst_n (wr_rst_n),
        .wr_en    (vif.wr_en),
        .wr_data  (vif.wr_data),
        .full     (vif.full),
        
        // Read port
        .rd_clk   (rd_clk),
        .rd_rst_n (rd_rst_n),
        .rd_en    (vif.rd_en),
        .rd_data  (vif.rd_data),
        .empty    (vif.empty)
    );
    
    // Write clock generation
    initial begin
        wr_clk = 0;
        forever #(WR_CLK_PERIOD/2) wr_clk = ~wr_clk;
    end
    
    // Read clock generation
    initial begin
        rd_clk = 0;
        forever #(RD_CLK_PERIOD/2) rd_clk = ~rd_clk;
    end
    
    // Reset generation
    initial begin
        wr_rst_n = 0;
        rd_rst_n = 0;
        
        // Assert reset for a few cycles
        repeat (5) @(posedge wr_clk);
        wr_rst_n = 1;
        
        repeat (5) @(posedge rd_clk);
        rd_rst_n = 1;
    end
    
    // Interface configuration
    initial begin
        // Set virtual interface in config_db
        uvm_config_db#(virtual fifo_if)::set(null, "*", "vif", vif);
    end
    
    // Start UVM test
    initial begin
        run_test();
    end
    
    // Waveform dumping
    initial begin
        $dumpfile("fifo_tb.vcd");
        $dumpvars(0, tb_top);
    end
    
    // Timeout watchdog
    initial begin
        #100000;
        `uvm_fatal("TB_TOP", "Test timeout!")
    end
    
endmodule : tb_top
