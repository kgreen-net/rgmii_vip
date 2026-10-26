//------------------------------------------------------------------------------
// rgmii_example_test.sv
//
// Example test: configures a 1000 Mbps MAC-mode agent and drives random
// traffic plus an errored frame.
//------------------------------------------------------------------------------
class rgmii_example_test extends uvm_test;
  `uvm_component_utils(rgmii_example_test)

  rgmii_example_env  env;
  rgmii_agent_config cfg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    cfg = rgmii_agent_config::type_id::create("cfg");
    cfg.is_active       = UVM_ACTIVE;
    cfg.mode            = RGMII_MODE_MAC;
    cfg.speed           = RGMII_SPEED_1000;
    cfg.coverage_enable = 1;

    if (!uvm_config_db#(virtual rgmii_if)::get(this, "", "vif", cfg.vif))
      `uvm_fatal(get_type_name(), "No virtual rgmii_if set at test level")

    uvm_config_db#(rgmii_agent_config)::set(this, "env", "cfg", cfg);
    env = rgmii_example_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    rgmii_random_traffic_seq rnd;
    rgmii_error_frame_seq    errs;

    phase.raise_objection(this);

    rnd = rgmii_random_traffic_seq::type_id::create("rnd");
    rnd.num_frames = 5;
    rnd.start(env.agent.sequencer);

    errs = rgmii_error_frame_seq::type_id::create("errs");
    errs.len = 64;
    errs.start(env.agent.sequencer);

    // Allow the last frame to drain through the monitor.
    #1us;
    phase.drop_objection(this);
  endtask

endclass : rgmii_example_test
