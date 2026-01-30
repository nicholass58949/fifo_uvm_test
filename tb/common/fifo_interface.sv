// FIFO Interface Definition
interface fifo_if #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input logic wr_clk,
    input logic rd_clk,
    input logic wr_rst_n,
    input logic rd_rst_n
);

    // Write port signals
    logic                   wr_en;
    logic [DATA_WIDTH-1:0]  wr_data;
    logic                   full;
    
    // Read port signals
    logic                   rd_en;
    logic [DATA_WIDTH-1:0]  rd_data;
    logic                   empty;
    
    // Write port clocking block (Master Agent)
    clocking wr_cb @(posedge wr_clk);
        default input #1ns output #1ns;
        output  wr_en;
        output  wr_data;
        input   full;
    endclocking
    
    // Write port monitor clocking block
    clocking wr_mon_cb @(posedge wr_clk);
        default input #1ns output #1ns;
        input   wr_en;
        input   wr_data;
        input   full;
    endclocking
    
    // Read port clocking block (Slave Agent)
    clocking rd_cb @(posedge rd_clk);
        default input #1ns output #1ns;
        output  rd_en;
        input   rd_data;
        input   empty;
    endclocking
    
    // Read port monitor clocking block
    clocking rd_mon_cb @(posedge rd_clk);
        default input #1ns output #1ns;
        input   rd_en;
        input   rd_data;
        input   empty;
    endclocking
    
    // Master (Write) modport
    modport master_drv (
        clocking wr_cb,
        input wr_clk, wr_rst_n
    );
    
    modport master_mon (
        clocking wr_mon_cb,
        input wr_clk, wr_rst_n
    );
    
    // Slave (Read) modport
    modport slave_drv (
        clocking rd_cb,
        input rd_clk, rd_rst_n
    );
    
    modport slave_mon (
        clocking rd_mon_cb,
        input rd_clk, rd_rst_n
    );

endinterface : fifo_if
