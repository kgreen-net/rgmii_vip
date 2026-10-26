// -----------------------------------------------------------------------------
// rgmii.f - compile filelist for the RGMII VIP + example testbench.
// Usage (examples):
//   VCS:       vcs -sverilog -ntb_opts uvm -f sim/rgmii.f -top rgmii_tb_top
//   Questa:    vlog -sv +incdir+... -f sim/rgmii.f ; vsim rgmii_tb_top
//   Xcelium:   xrun -uvm -f sim/rgmii.f -top rgmii_tb_top
// -----------------------------------------------------------------------------

// Include search paths (package uses `include of the class files).
+incdir+../src
+incdir+../tb

// Interface (compiled outside the package).
../src/rgmii_if.sv

// VIP package (pulls in all agent classes via `include).
../src/rgmii_pkg.sv

// Example environment / test package / top.
../tb/rgmii_test_pkg.sv
../tb/rgmii_tb_top.sv
