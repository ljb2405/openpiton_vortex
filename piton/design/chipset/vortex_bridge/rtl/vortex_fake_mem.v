`include "piton_vortex_define.vh"
// TODO: fill out this fake memory
module vortex_fake_mem #(
    parameter C_M_AXI_MEM_ID_WIDTH 	  = `VORTEX_AXI_MEM_ID_WIDTH,
	parameter C_M_AXI_MEM_ADDR_WIDTH  = `VORTEX_AXI_MEM_ADDR_WIDTH,
	parameter C_M_AXI_MEM_DATA_WIDTH  = `VORTEX_AXI_MEM_DATA_WIDTH,
    parameter AXI_NUM_BANKS           = 1
)(
    input wire clk,
    input wire rst,
    input [C_M_AXI_MEM_ADDR_WIDTH-1:0] wire addr,
    input wire wr,
    input wire rd,
    output [C_M_AXI_MEM_DATA_WIDTH-1:0]wire rdata,
    input [C_M_AXI_MEM_DATA_WIDTH-1:0] wire wdata
);
// Memory Declaration
reg []

always @(posedge clk or posedge rst) begin

end
endmodule