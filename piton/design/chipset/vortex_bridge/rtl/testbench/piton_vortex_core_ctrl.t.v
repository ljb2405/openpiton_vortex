`include "openpiton_vortex/piton/design/chipset/vortex_bridge/rtl/piton_vortex_define.vh"
`include "openpiton_vortex/piton/design/chipset/vortex_bridge/rtl"

`timescale 1ns / 1ps 

module tb_piton_vortex_core_ctrl ();

reg clk;

initial begin
clk = 0;


end

always 
#0.5 clk = ~clk;

piton_vortex_core_ctrl dut #()
();

endmodule