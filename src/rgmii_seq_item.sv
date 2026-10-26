//------------------------------------------------------------------------------
// rgmii_seq_item.sv
//
// RGMII transaction. Models one frame transferred across the interface as a
// byte stream (including preamble/SFD if the sequence chooses to supply them),
// plus a per-byte error flag and an inter-frame gap specified in clock cycles.
//------------------------------------------------------------------------------
class rgmii_seq_item extends uvm_sequence_item;

  // Frame payload, byte-ordered as transmitted on the wire. Typically this is
  // [preamble x7][SFD][dst mac][src mac][len/type][payload][FCS], but the agent
  // is byte-agnostic and transfers whatever is supplied.
  rand byte unsigned data[];

  // Per-byte error indication. Asserts TX_ERR/RX_ERR on the corresponding byte.
  // Empty or shorter than data[] means "no error".
  rand bit           err[];

  // Inter-frame gap preceding this frame, in reference-clock cycles.
  rand int unsigned  ifg_cycles;

  // Captured link speed (set by driver/monitor context; not randomized here).
  rgmii_speed_e      speed;

  constraint c_size   { data.size() inside {[1:1600]}; }
  constraint c_err    { err.size() == 0 || err.size() == data.size(); }
  constraint c_ifg    { ifg_cycles inside {[12:32]}; }  // 802.3 min IFG = 12 bytes

  `uvm_object_utils_begin(rgmii_seq_item)
    `uvm_field_array_int(data,  UVM_ALL_ON | UVM_NOPACK)
    `uvm_field_array_int(err,   UVM_ALL_ON | UVM_NOPACK)
    `uvm_field_int       (ifg_cycles, UVM_ALL_ON | UVM_DEC)
    `uvm_field_enum      (rgmii_speed_e, speed, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "rgmii_seq_item");
    super.new(name);
  endfunction

  // Convenience: is byte i flagged as errored?
  function bit byte_has_err(int i);
    return (i < err.size()) ? err[i] : 1'b0;
  endfunction

  function string convert2string();
    string s;
    s = $sformatf("RGMII frame: %0d bytes, ifg=%0d, speed=%s",
                  data.size(), ifg_cycles, speed.name());
    return s;
  endfunction

endclass : rgmii_seq_item
