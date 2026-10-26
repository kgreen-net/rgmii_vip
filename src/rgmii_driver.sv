//------------------------------------------------------------------------------
// rgmii_driver.sv
//
// Drives RGMII transactions onto the bus. Sources the reference clock for the
// side being emulated (TXC for MAC mode, RXC for PHY mode) and performs the
// DDR nibble serialization:
//
//   1000 Mbps : one byte per clock cycle.
//                 rising edge  -> data[3:0], ctl = EN/DV
//                 falling edge -> data[7:4], ctl = EN^ERR / DV^ERR
//
//   10/100    : one nibble per clock cycle, the nibble duplicated on both
//               edges (two cycles per byte: low nibble then high nibble).
//------------------------------------------------------------------------------
class rgmii_driver extends uvm_driver #(rgmii_seq_item);

  `uvm_component_utils(rgmii_driver)

  rgmii_agent_config cfg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(rgmii_agent_config)::get(this, "", "cfg", cfg))
      `uvm_fatal(get_type_name(), "rgmii_agent_config not set for driver")
  endfunction

  task run_phase(uvm_phase phase);
    rgmii_seq_item item;

    // Start the sourced reference clock for this side/speed, then idle.
    fork gen_clock(); join_none
    drive_idle();

    forever begin
      seq_item_port.get_next_item(item);
      item.speed = cfg.speed;
      `uvm_info(get_type_name(), $sformatf("Driving %s", item.convert2string()),
                UVM_HIGH)
      drive_frame(item);
      seq_item_port.item_done();
    end
  endtask

  // -------------------------------------------------------------------------
  // Clock / idle helpers
  // -------------------------------------------------------------------------
  // Generate the free-running reference clock for the sourced direction. The
  // transmitting side owns the clock in RGMII.
  task gen_clock();
    time half = rgmii_half_period(cfg.speed);
    if (cfg.mode == RGMII_MODE_MAC) cfg.vif.rgmii_txc = 1'b0;
    else                            cfg.vif.rgmii_rxc = 1'b0;
    forever begin
      #(half);
      if (cfg.mode == RGMII_MODE_MAC) cfg.vif.rgmii_txc = ~cfg.vif.rgmii_txc;
      else                            cfg.vif.rgmii_rxc = ~cfg.vif.rgmii_rxc;
    end
  endtask

  // Wait for the next active clock edge of the sourced clock.
  task wait_posedge();
    if (cfg.mode == RGMII_MODE_MAC) @(posedge cfg.vif.rgmii_txc);
    else                            @(posedge cfg.vif.rgmii_rxc);
  endtask

  task wait_negedge();
    if (cfg.mode == RGMII_MODE_MAC) @(negedge cfg.vif.rgmii_txc);
    else                            @(negedge cfg.vif.rgmii_rxc);
  endtask

  // Drive one (data, ctl) pair onto the sourced direction. Data is driven
  // edge-aligned with the reference clock (RGMII v1.3 convention); blocking
  // assignment keeps a single, well-ordered driver for these signals.
  function void drive_pins(bit [3:0] d, bit ctl);
    if (cfg.mode == RGMII_MODE_MAC) begin
      cfg.vif.rgmii_txd    = d;
      cfg.vif.rgmii_tx_ctl = ctl;
    end else begin
      cfg.vif.rgmii_rxd    = d;
      cfg.vif.rgmii_rx_ctl = ctl;
    end
  endfunction

  task drive_idle();
    drive_pins(4'h0, 1'b0);
  endtask

  // -------------------------------------------------------------------------
  // Frame transmission
  // -------------------------------------------------------------------------
  task drive_frame(rgmii_seq_item item);
    // Inter-frame gap: hold idle for the requested number of cycles.
    repeat (item.ifg_cycles) begin
      wait_posedge();
      drive_idle();
    end

    foreach (item.data[i]) begin
      drive_byte(item.data[i], item.byte_has_err(i), item.speed);
    end

    // Return to idle after the frame.
    wait_posedge();
    drive_idle();
  endtask

  task drive_byte(byte unsigned b, bit e, rgmii_speed_e speed);
    bit [3:0] lo = b[3:0];
    bit [3:0] hi = b[7:4];

    if (speed == RGMII_SPEED_1000) begin
      // DDR: low nibble on rising edge, high nibble on falling edge.
      wait_posedge();
      drive_pins(lo, 1'b1);        // EN asserted on rising edge
      wait_negedge();
      drive_pins(hi, 1'b1 ^ e);    // EN ^ ERR on falling edge
    end else begin
      // 10/100: one nibble per cycle, duplicated across both edges.
      // Low nibble cycle
      wait_posedge();
      drive_pins(lo, 1'b1);
      wait_negedge();
      drive_pins(lo, 1'b1 ^ e);
      // High nibble cycle
      wait_posedge();
      drive_pins(hi, 1'b1);
      wait_negedge();
      drive_pins(hi, 1'b1 ^ e);
    end
  endtask

endclass : rgmii_driver
