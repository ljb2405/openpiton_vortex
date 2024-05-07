`include "openpiton_vortex/piton/design/chipset/vortex_bridge/rtl/piton_vortex_define.vh"
// TODO: fix the fake memory to its full capacity
// TODO: most likely to hook it up to Xilinx BRAM IP or smth
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
    output [C_M_AXI_MEM_DATA_WIDTH-1:0] wire rdata,
    input [C_M_AXI_MEM_DATA_WIDTH-1:0] wire wdata
);
localparam CACHE_ELEMENTS = $pow(10, 2);
localparam CACHE_TAG  = 54 
// Memory Declaration
// for testing and only uses first ten bits to minimize bulky memory for functional simulation
reg [C_M_AXI_MEM_DATA_WIDTH-1:0] test_memory [CACHE_ELEMENTS:0];

always @(posedge clk or posedge rst) begin
    if (rst) begin
        for (integer i = 0; i < CACHE_ELEMENTS; i = i + 1) begin
            test_memory[i] <= 0;
        end
    end
    else begin
        if (wr) begin
             test_memory[addr[9:0]] <= wdata;
        end
    end
end
rdata = rd ? test_memory[addr[9:0]] : 0;
// rdata = (test_memory[addr[9:0]][C_M_AXI_MEM_DATA_WIDTH+CACHE_TAG-1:C_M_AXI_MEM_DATA_WIDTH] == addr[C_M_AXI_MEM_ADDR_WIDTH-1:C_M_AXI_MEM_ADDR_WIDTH-CACHE_TAG-1])
//       ? test_memory[addr[9:0]][C_M_AXI_MEM_DATA_WIDTH+CACHE_TAG-1:C_M_AXI_MEM_DATA_WIDTH] : 0;
endmodule