//------------------------------------------------------------------------------
// rgmii_coverage.sv
//
// Functional coverage subscriber. Connects to the monitor's analysis port and
// samples frame-level attributes.
//------------------------------------------------------------------------------
class rgmii_coverage extends uvm_subscriber #(rgmii_seq_item);

  `uvm_component_utils(rgmii_coverage)

  rgmii_agent_config cfg;
  rgmii_seq_item     item;

  covergroup cg_frame;
    option.per_instance = 1;

    cp_speed : coverpoint item.speed {
      bins spd_10   = {RGMII_SPEED_10};
      bins spd_100  = {RGMII_SPEED_100};
      bins spd_1000 = {RGMII_SPEED_1000};
    }

    cp_size : coverpoint item.data.size() {
      bins runt    = {[1:63]};
      bins min     = {64};
      bins typical = {[65:1022]};
      bins max     = {[1023:1518]};
      bins jumbo   = {[1519:1600]};
    }

    cp_has_err : coverpoint item.err.or() {
      bins no_err   = {0};
      bins with_err = {1};
    }

    x_speed_size : cross cp_speed, cp_size;
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg_frame = new();
  endfunction

  function void write(rgmii_seq_item t);
    item = t;
    cg_frame.sample();
  endfunction

endclass : rgmii_coverage
