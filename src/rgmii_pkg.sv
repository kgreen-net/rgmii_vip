//------------------------------------------------------------------------------
// rgmii_pkg.sv
//
// RGMII UVM agent / VIP package. Include this package and the rgmii_if.sv
// interface in your compile.
//------------------------------------------------------------------------------
`ifndef RGMII_PKG_SV
`define RGMII_PKG_SV

package rgmii_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "rgmii_types.svh"
  `include "rgmii_seq_item.sv"
  `include "rgmii_agent_config.sv"
  `include "rgmii_driver.sv"
  `include "rgmii_monitor.sv"
  `include "rgmii_sequencer.sv"
  `include "rgmii_coverage.sv"
  `include "rgmii_agent.sv"
  `include "rgmii_seq_lib.sv"

endpackage : rgmii_pkg

`endif // RGMII_PKG_SV
