//------------------------------------------------------------------------------
// rgmii_types.svh
//
// Shared enums / typedefs for the RGMII VIP. Included inside rgmii_pkg.
//------------------------------------------------------------------------------

// Link speed. Determines reference-clock rate and whether a data byte is sent
// as one DDR clock (1000 Mbps) or replicated across edges (10/100 Mbps).
typedef enum bit [1:0] {
  RGMII_SPEED_10   = 2'b00,  // 2.5 MHz  reference clock
  RGMII_SPEED_100  = 2'b01,  // 25  MHz  reference clock
  RGMII_SPEED_1000 = 2'b10   // 125 MHz  reference clock
} rgmii_speed_e;

// Which side of the RGMII link the agent emulates. A MAC-mode agent sources
// the TX clock/data and receives on RX; a PHY-mode agent is the mirror image.
typedef enum bit {
  RGMII_MODE_MAC = 1'b0,
  RGMII_MODE_PHY = 1'b1
} rgmii_mode_e;

// Half-period (in ps) for each supported speed.
function automatic time rgmii_half_period(rgmii_speed_e speed);
  case (speed)
    RGMII_SPEED_10   : return 200ns;  // 2.5 MHz -> 400ns period
    RGMII_SPEED_100  : return 20ns;   // 25  MHz -> 40ns  period
    RGMII_SPEED_1000 : return 4ns;    // 125 MHz -> 8ns   period
    default          : return 4ns;
  endcase
endfunction
