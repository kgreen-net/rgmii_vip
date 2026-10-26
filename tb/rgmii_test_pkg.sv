//------------------------------------------------------------------------------
// rgmii_test_pkg.sv
//
// Package bundling the example environment and tests for the RGMII VIP.
//------------------------------------------------------------------------------
`ifndef RGMII_TEST_PKG_SV
`define RGMII_TEST_PKG_SV

package rgmii_test_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import rgmii_pkg::*;

  `include "rgmii_example_env.sv"
  `include "rgmii_example_test.sv"

endpackage : rgmii_test_pkg

`endif // RGMII_TEST_PKG_SV
