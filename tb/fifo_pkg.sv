// FIFO Package - 包含所有UVM组件
package fifo_pkg;
    
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
    // Transaction
    `include "common/fifo_transaction.sv"
    
    // Coverage
    `include "common/fifo_coverage.sv"
    
    // Master Agent components
    `include "agents/master/master_sequencer.sv"
    `include "agents/master/master_driver.sv"
    `include "agents/master/master_monitor.sv"
    `include "agents/master/master_sequence.sv"
    `include "agents/master/master_agent.sv"
    
    // Slave Agent components
    `include "agents/slave/slave_sequencer.sv"
    `include "agents/slave/slave_driver.sv"
    `include "agents/slave/slave_monitor.sv"
    `include "agents/slave/slave_sequence.sv"
    `include "agents/slave/slave_agent.sv"
    
    `include "agents/reset_sequence.sv"
    // Reference Model and Scoreboard
    `include "env/fifo_reference_model.sv"
    `include "env/fifo_scoreboard.sv"
    
    // Environment
    `include "env/fifo_env.sv"

    // Tests
    `include "tests/fifo_test.sv"

    // Reset Sequences
    `include "tests/fifo_reset_test.sv"


    
endpackage : fifo_pkg
