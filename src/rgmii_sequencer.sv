//------------------------------------------------------------------------------
// rgmii_sequencer.sv
//
// Standard UVM sequencer for RGMII transactions.
//------------------------------------------------------------------------------
class rgmii_sequencer extends uvm_sequencer #(rgmii_seq_item);

  `uvm_component_utils(rgmii_sequencer)

  rgmii_agent_config cfg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass : rgmii_sequencer
