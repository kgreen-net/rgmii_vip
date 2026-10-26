//------------------------------------------------------------------------------
// rgmii_example_env.sv
//
// Minimal example environment instantiating a single RGMII agent. In a real
// setup you would add a scoreboard connected to agent.ap, and likely a second
// (passive or PHY-mode) agent on the far side of the DUT.
//------------------------------------------------------------------------------
class rgmii_example_env extends uvm_env;
  `uvm_component_utils(rgmii_example_env)

  rgmii_agent        agent;
  rgmii_agent_config cfg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Config may be supplied by the test; otherwise build a default here.
    if (!uvm_config_db#(rgmii_agent_config)::get(this, "", "cfg", cfg)) begin
      cfg = rgmii_agent_config::type_id::create("cfg");
      if (!uvm_config_db#(virtual rgmii_if)::get(this, "", "vif", cfg.vif))
        `uvm_fatal(get_type_name(), "No virtual rgmii_if set")
    end

    uvm_config_db#(rgmii_agent_config)::set(this, "agent", "cfg", cfg);
    agent = rgmii_agent::type_id::create("agent", this);
  endfunction

endclass : rgmii_example_env
