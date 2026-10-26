//------------------------------------------------------------------------------
// rgmii_agent.sv
//
// RGMII UVM agent. Assembles the monitor (always), plus the sequencer/driver
// and coverage collector when configured active / coverage-enabled.
//------------------------------------------------------------------------------
class rgmii_agent extends uvm_agent;

  `uvm_component_utils(rgmii_agent)

  rgmii_agent_config cfg;

  rgmii_driver    driver;
  rgmii_sequencer sequencer;
  rgmii_monitor   monitor;
  rgmii_coverage  coverage;

  // Re-exported so a scoreboard can connect without reaching into the monitor.
  uvm_analysis_port #(rgmii_seq_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Fetch config; fall back to a default if none provided.
    if (!uvm_config_db#(rgmii_agent_config)::get(this, "", "cfg", cfg)) begin
      `uvm_warning(get_type_name(),
                   "No rgmii_agent_config found; creating a default (ACTIVE/MAC)")
      cfg = rgmii_agent_config::type_id::create("cfg");
    end

    // Make the config visible to children.
    uvm_config_db#(rgmii_agent_config)::set(this, "*", "cfg", cfg);

    // Keep the base-class is_active in sync for standard UVM queries.
    is_active = cfg.is_active;

    monitor = rgmii_monitor::type_id::create("monitor", this);

    if (cfg.coverage_enable)
      coverage = rgmii_coverage::type_id::create("coverage", this);

    if (cfg.is_active == UVM_ACTIVE) begin
      driver    = rgmii_driver::type_id::create("driver", this);
      sequencer = rgmii_sequencer::type_id::create("sequencer", this);
      sequencer.cfg = cfg;
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    ap = monitor.ap;

    if (cfg.coverage_enable)
      monitor.ap.connect(coverage.analysis_export);

    if (cfg.is_active == UVM_ACTIVE)
      driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction

endclass : rgmii_agent
