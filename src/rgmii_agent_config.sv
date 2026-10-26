//------------------------------------------------------------------------------
// rgmii_agent_config.sv
//
// Configuration object for the RGMII agent. Holds the virtual interface handle
// plus knobs controlling active/passive behaviour, which side is emulated, and
// link speed.
//------------------------------------------------------------------------------
class rgmii_agent_config extends uvm_object;

  // Virtual interface handle (set by the test/env before build).
  virtual rgmii_if vif;

  // UVM_ACTIVE instantiates a driver + sequencer; UVM_PASSIVE monitor-only.
  uvm_active_passive_enum is_active = UVM_ACTIVE;

  // Which side of the link this agent emulates.
  rgmii_mode_e mode = RGMII_MODE_MAC;

  // Link speed (sets clock rate and DDR encoding).
  rgmii_speed_e speed = RGMII_SPEED_1000;

  // Enable functional coverage collection in the monitor.
  bit coverage_enable = 1;

  `uvm_object_utils_begin(rgmii_agent_config)
    `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
    `uvm_field_enum(rgmii_mode_e,  mode,  UVM_ALL_ON)
    `uvm_field_enum(rgmii_speed_e, speed, UVM_ALL_ON)
    `uvm_field_int (coverage_enable, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "rgmii_agent_config");
    super.new(name);
  endfunction

endclass : rgmii_agent_config
