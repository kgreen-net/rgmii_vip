//------------------------------------------------------------------------------
// rgmii_monitor.sv
//
// Passive observer. Samples the DDR bus on both clock edges, reconstructs
// frames (delimited by the CTL/DV signal), and publishes rgmii_seq_item
// transactions on an analysis port.
//
// The monitor watches the agent's *ingress* direction — i.e. the traffic the
// DUT sources into this agent:
//     MAC mode -> observes RXC / RXD / RX_CTL
//     PHY mode -> observes TXC / TXD / TX_CTL
// A passive agent can be configured either way to tap whichever link is of
// interest.
//
// CTL encoding recovered:
//     DV  = ctl sampled on rising edge
//     ERR = (ctl rising) ^ (ctl falling)
//------------------------------------------------------------------------------
class rgmii_monitor extends uvm_monitor;

  `uvm_component_utils(rgmii_monitor)

  rgmii_agent_config cfg;

  uvm_analysis_port #(rgmii_seq_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(rgmii_agent_config)::get(this, "", "cfg", cfg))
      `uvm_fatal(get_type_name(), "rgmii_agent_config not set for monitor")
  endfunction

  // -------------------------------------------------------------------------
  // Ingress-signal sampling helpers
  //
  // Data is edge-aligned with the reference clock, so sample at the centre of
  // the data eye (a quarter period after each edge) to avoid the drive/sample
  // delta race and to model a receiver's delayed sampling clock.
  // -------------------------------------------------------------------------
  function time quarter();
    return rgmii_half_period(cfg.speed) / 2;
  endfunction

  task sample_posedge();
    if (cfg.mode == RGMII_MODE_MAC) @(posedge cfg.vif.rgmii_rxc);
    else                            @(posedge cfg.vif.rgmii_txc);
    #(quarter());
  endtask

  task sample_negedge();
    if (cfg.mode == RGMII_MODE_MAC) @(negedge cfg.vif.rgmii_rxc);
    else                            @(negedge cfg.vif.rgmii_txc);
    #(quarter());
  endtask

  function bit [3:0] cur_data();
    return (cfg.mode == RGMII_MODE_MAC) ? cfg.vif.rgmii_rxd : cfg.vif.rgmii_txd;
  endfunction

  function bit cur_ctl();
    return (cfg.mode == RGMII_MODE_MAC) ? cfg.vif.rgmii_rx_ctl
                                        : cfg.vif.rgmii_tx_ctl;
  endfunction

  // -------------------------------------------------------------------------
  // Collection
  // -------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    forever collect_frame();
  endtask

  task collect_frame();
    rgmii_seq_item item;
    bit [3:0] lo, hi;
    bit dv_r, ctl_f;
    byte unsigned bytes[$];
    bit           errs[$];

    // Wait for the start of a frame: DV asserted on a rising edge.
    do sample_posedge(); while (cur_ctl() !== 1'b1);

    item = rgmii_seq_item::type_id::create("mon_item");
    item.speed = cfg.speed;

    // First rising edge already has DV=1; process this byte then continue
    // while DV remains asserted on subsequent rising edges.
    forever begin
      if (cfg.speed == RGMII_SPEED_1000) begin
        // Rising edge: low nibble + DV. (we are already at the rising edge)
        lo   = cur_data();
        dv_r = cur_ctl();
        // Falling edge: high nibble + (DV^ERR)
        sample_negedge();
        hi    = cur_data();
        ctl_f = cur_ctl();
        bytes.push_back({hi, lo});
        errs.push_back(dv_r ^ ctl_f);
      end else begin
        // 10/100: low-nibble cycle then high-nibble cycle, nibble duplicated
        // on both edges. ERR is recovered from the rising/falling CTL of the
        // low-nibble cycle.
        bit err_lo;
        lo    = cur_data();
        dv_r  = cur_ctl();
        sample_negedge();
        ctl_f = cur_ctl();
        err_lo = dv_r ^ ctl_f;
        // High-nibble cycle
        sample_posedge();
        hi = cur_data();
        sample_negedge();
        bytes.push_back({hi, lo});
        errs.push_back(err_lo);
      end

      // Advance to next rising edge and test DV for frame continuation.
      sample_posedge();
      if (cur_ctl() !== 1'b1) break;
    end

    // Pack collected data into the transaction.
    item.data = new[bytes.size()];
    item.err  = new[errs.size()];
    foreach (bytes[i]) item.data[i] = bytes[i];
    foreach (errs[i])  item.err[i]  = errs[i];

    `uvm_info(get_type_name(), $sformatf("Collected %s", item.convert2string()),
              UVM_HIGH)
    ap.write(item);
  endtask

endclass : rgmii_monitor
