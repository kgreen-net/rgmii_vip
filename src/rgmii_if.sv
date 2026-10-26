//------------------------------------------------------------------------------
// rgmii_if.sv
//
// SystemVerilog interface for the Reduced Gigabit Media Independent Interface
// (RGMII). RGMII is a DDR interface: data and control are presented on both
// edges of the reference clock.
//
//   Signal       Dir (MAC->PHY)   Description
//   ----------   --------------   -----------------------------------------
//   rgmii_txc    MAC  -> PHY      TX reference clock (125/25/2.5 MHz)
//   rgmii_txd    MAC  -> PHY      TX data nibble [3:0], DDR
//   rgmii_tx_ctl MAC  -> PHY      TX control (TX_EN rising, TX_EN^TX_ERR fall)
//   rgmii_rxc    PHY  -> MAC      RX reference clock
//   rgmii_rxd    PHY  -> MAC      RX data nibble [3:0], DDR
//   rgmii_rx_ctl PHY  -> MAC      RX control (RX_DV rising, RX_DV^RX_ERR fall)
//
// The reference clock for each direction is sourced by whichever side is
// transmitting; the RGMII driver component generates it. This interface simply
// carries the physical signals.
//------------------------------------------------------------------------------
interface rgmii_if ();

  // TX path (MAC -> PHY)
  logic        rgmii_txc;
  logic [3:0]  rgmii_txd;
  logic        rgmii_tx_ctl;

  // RX path (PHY -> MAC)
  logic        rgmii_rxc;
  logic [3:0]  rgmii_rxd;
  logic        rgmii_rx_ctl;

endinterface : rgmii_if
