// Slave Sequencer - 用于读端口
class slave_sequencer extends uvm_sequencer #(fifo_transaction);
    `uvm_component_utils(slave_sequencer)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
endclass : slave_sequencer
