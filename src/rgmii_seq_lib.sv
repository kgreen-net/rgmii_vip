//------------------------------------------------------------------------------
// rgmii_seq_lib.sv
//
// Reusable RGMII sequences.
//------------------------------------------------------------------------------

// Base sequence: common handle/typing.
class rgmii_base_seq extends uvm_sequence #(rgmii_seq_item);
  `uvm_object_utils(rgmii_base_seq)
  function new(string name = "rgmii_base_seq");
    super.new(name);
  endfunction
endclass : rgmii_base_seq


// Send a single frame with a fully-randomized payload.
class rgmii_single_frame_seq extends rgmii_base_seq;
  `uvm_object_utils(rgmii_single_frame_seq)

  rand int unsigned len = 64;

  function new(string name = "rgmii_single_frame_seq");
    super.new(name);
  endfunction

  task body();
    rgmii_seq_item item = rgmii_seq_item::type_id::create("item");
    start_item(item);
    if (!item.randomize() with { data.size() == len; err.size() == 0; })
      `uvm_error(get_type_name(), "randomize failed")
    finish_item(item);
  endtask
endclass : rgmii_single_frame_seq


// Send a directed frame from a supplied byte array (e.g. a crafted Ethernet
// frame including preamble/SFD/FCS).
class rgmii_directed_frame_seq extends rgmii_base_seq;
  `uvm_object_utils(rgmii_directed_frame_seq)

  byte unsigned payload[];
  int unsigned  ifg = 12;

  function new(string name = "rgmii_directed_frame_seq");
    super.new(name);
  endfunction

  task body();
    rgmii_seq_item item = rgmii_seq_item::type_id::create("item");
    start_item(item);
    item.data       = payload;
    item.err        = new[0];
    item.ifg_cycles = ifg;
    finish_item(item);
  endtask
endclass : rgmii_directed_frame_seq


// Send N random frames back-to-back.
class rgmii_random_traffic_seq extends rgmii_base_seq;
  `uvm_object_utils(rgmii_random_traffic_seq)

  rand int unsigned num_frames = 10;
  constraint c_num { num_frames inside {[1:100]}; }

  function new(string name = "rgmii_random_traffic_seq");
    super.new(name);
  endfunction

  task body();
    repeat (num_frames) begin
      rgmii_seq_item item = rgmii_seq_item::type_id::create("item");
      start_item(item);
      if (!item.randomize())
        `uvm_error(get_type_name(), "randomize failed")
      finish_item(item);
    end
  endtask
endclass : rgmii_random_traffic_seq


// Send a frame that carries a data error (RX_ERR/TX_ERR asserted mid-frame).
class rgmii_error_frame_seq extends rgmii_base_seq;
  `uvm_object_utils(rgmii_error_frame_seq)

  rand int unsigned len = 64;

  function new(string name = "rgmii_error_frame_seq");
    super.new(name);
  endfunction

  task body();
    int idx;
    rgmii_seq_item item = rgmii_seq_item::type_id::create("item");
    start_item(item);
    if (!item.randomize() with { data.size() == len; err.size() == len; })
      `uvm_error(get_type_name(), "randomize failed")
    // Guarantee at least one errored byte.
    idx = $urandom_range(0, len - 1);
    item.err[idx] = 1'b1;
    finish_item(item);
  endtask
endclass : rgmii_error_frame_seq
