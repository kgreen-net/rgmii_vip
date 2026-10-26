//------------------------------------------------------------------------------
// rgmii_tb_top.sv
//
// Testbench top. Instantiates the RGMII interface, publishes it to the config
// DB, and starts UVM. There is no DUT here — for a self-check you can wire
// the MAC-sourced TX signals back to the RX inputs (loopback) so the monitor
// observes the driven traffic.
//------------------------------------------------------------------------------
`include "uvm_macros.svh"

module rgmii_tb_top;

  import uvm_pkg::*;
  import rgmii_pkg::*;
  import rgmii_test_pkg::*;

  rgmii_if vif();

  // Simple loopback so an active MAC-mode agent's monitor (which watches RX)
  // observes what the driver transmits on TX. Replace with a real DUT.
  assign vif.rgmii_rxc    = vif.rgmii_txc;
  assign vif.rgmii_rxd    = vif.rgmii_txd;
  assign vif.rgmii_rx_ctl = vif.rgmii_tx_ctl;

  initial begin
    uvm_config_db#(virtual rgmii_if)::set(null, "uvm_test_top", "vif", vif);
    run_test("rgmii_example_test");
  end

  // Global watchdog.
  initial begin
    #1ms;
    `uvm_fatal("TB_TOP", "Global timeout reached")
  end

endmodule : rgmii_tb_top
