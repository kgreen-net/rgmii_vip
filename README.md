# RGMII UVM Agent (VIP)

A reusable UVM verification IP for the **Reduced Gigabit Media Independent
Interface (RGMII)**. RGMII is the DDR, 4-bit-per-edge interface between an
Ethernet MAC and PHY, supporting 10 / 100 / 1000 Mbps.

The agent can emulate either side of the link (MAC or PHY), generates the
reference clock for the side it transmits, performs DDR nibble serialization,
reconstructs received frames, and collects functional coverage.

## Layout

```
src/
  rgmii_if.sv            Physical interface (TXC/TXD/TX_CTL, RXC/RXD/RX_CTL)
  rgmii_types.svh        Enums: speed, mode; half-period helper
  rgmii_seq_item.sv      Transaction: byte stream + per-byte error + IFG
  rgmii_agent_config.sv  Config: vif, active/passive, mode, speed, coverage
  rgmii_driver.sv        DDR serializer + reference-clock generator
  rgmii_monitor.sv       DDR deserializer -> frame reconstruction -> analysis
  rgmii_sequencer.sv     Standard sequencer
  rgmii_coverage.sv      Functional coverage subscriber
  rgmii_agent.sv         Assembles driver/sequencer/monitor/coverage
  rgmii_seq_lib.sv       Sequences: single/directed/random/error frames
  rgmii_pkg.sv           Package (include this)
tb/
  rgmii_example_env.sv   Example env with one agent
  rgmii_example_test.sv  Example test (1000 Mbps MAC, random + error traffic)
  rgmii_test_pkg.sv      Package bundling the example env/test
  rgmii_tb_top.sv        TB top with loopback (no DUT)
sim/
  rgmii.f                Compile filelist
```

## Signal / protocol model

| Signal         | Direction (MAC→PHY) | Encoding |
|----------------|---------------------|----------|
| `rgmii_txc`    | MAC → PHY           | TX reference clock |
| `rgmii_txd[3:0]`| MAC → PHY          | DDR nibble |
| `rgmii_tx_ctl` | MAC → PHY           | `TX_EN` on rising edge, `TX_EN ^ TX_ERR` on falling |
| `rgmii_rxc`    | PHY → MAC           | RX reference clock |
| `rgmii_rxd[3:0]`| PHY → MAC          | DDR nibble |
| `rgmii_rx_ctl` | PHY → MAC           | `RX_DV` on rising edge, `RX_DV ^ RX_ERR` on falling |

- **1000 Mbps:** one byte per clock cycle — low nibble on the rising edge, high
  nibble on the falling edge.
- **10 / 100 Mbps:** one nibble per cycle, duplicated on both edges (two cycles
  per byte), with the reference clock at 25 MHz / 2.5 MHz.

Data is driven edge-aligned with the clock (RGMII v1.3); the monitor samples at
the centre of the data eye (a quarter period after each edge).

## Using the agent

```systemverilog
// In your test's build_phase:
rgmii_agent_config cfg = rgmii_agent_config::type_id::create("cfg");
cfg.is_active = UVM_ACTIVE;        // or UVM_PASSIVE for monitor-only
cfg.mode      = RGMII_MODE_MAC;    // or RGMII_MODE_PHY
cfg.speed     = RGMII_SPEED_1000;  // _10 / _100 / _1000
uvm_config_db#(virtual rgmii_if)::get(this, "", "vif", cfg.vif);
uvm_config_db#(rgmii_agent_config)::set(this, "env.agent", "cfg", cfg);

// Connect a scoreboard to the agent's analysis port: env.agent.ap

// Drive traffic:
rgmii_random_traffic_seq seq = rgmii_random_traffic_seq::type_id::create("seq");
seq.num_frames = 20;
seq.start(env.agent.sequencer);
```

The **monitor observes the agent's ingress** direction: `RX*` in MAC mode, `TX*`
in PHY mode. To observe the opposite link, instantiate a second (passive) agent
with the other `mode`.

## Compiling / running

Needs a UVM-capable simulator (VCS / Questa / Xcelium). From `sim/`:

```
# VCS
vcs -full64 -sverilog -ntb_opts uvm -f rgmii.f -top rgmii_tb_top && ./simv

# Questa
vlog -sv +incdir+../src+../tb -f rgmii.f && vsim -c rgmii_tb_top -do "run -all; quit"

# Xcelium
xrun -uvm -f rgmii.f -top rgmii_tb_top
```

> Note: Verilator does not support UVM, so it cannot elaborate this VIP.

The example `rgmii_tb_top` loops `TX*` back to `RX*` (no DUT), so the MAC-mode
agent's monitor observes the frames its own driver transmits — useful as a
self-check. Replace the loopback with your DUT instantiation.
