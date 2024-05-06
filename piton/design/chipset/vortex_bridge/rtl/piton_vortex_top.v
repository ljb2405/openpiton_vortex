`include "piton_vortex_define.vh"
`include "./vortex/hw/rtl"

module piton_vortex_top #(
    parameter VORTEX_AXI_CTRL_ADDR_WIDTH = 8,
	parameter VORTEX_AXI_CTRL_DATA_WIDTH = 32,
	parameter VORTEX_AXI_MEM_ID_WIDTH 	 = 32,
	parameter VORTEX_AXI_MEM_ADDR_WIDTH  = 64,
	parameter VORTEX_AXI_MEM_DATA_WIDTH  = 512
)(
    // Clock and reset
    input  wire                             sys_clk,
    input  wire                             sys_rst,

    // NOC interface
    input  wire                             splitter_vortex_val,
    input  wire [`NOC_DATA_WIDTH-1:0]       splitter_vortex_data,
    output wire                             vortex_splitter_rdy,

    output wire                             vortex_splitter_val,
    output wire [`NOC_DATA_WIDTH-1:0]       vortex_splitter_data,
    input  wire                             splitter_vortex_rdy

    // not entirely sure comes here?
    // 5/5/24 maybe nothing comes here since entire vortex is under the top
);

wire sys_rst_n = ~sys_rst;

// AXI-4 Lite Master Interface
wire                                    m_axi_ctrl_awvalid;
wire                                    m_axi_ctrl_awready;
wire [VORTEX_AXI_CTRL_ADDR_WIDTH-1:0]   m_axi_ctrl_awaddr;
wire                                    m_axi_ctrl_wvalid;
wire                                    m_axi_ctrl_wready;
wire [VORTEX_AXI_CTRL_DATA_WIDTH-1:0]   m_axi_ctrl_wdata;
wire [VORTEX_AXI_CTRL_DATA_WIDTH/8-1:0] m_axi_ctrl_wstrb;
wire                                    m_axi_ctrl_arvalid;
wire                                    m_axi_ctrl_arready;
wire [VORTEX_AXI_CTRL_ADDR_WIDTH-1:0]   m_axi_ctrl_araddr;
wire                                    m_axi_ctrl_rvalid;
wire                                    m_axi_ctrl_rready;
wire [VORTEX_AXI_CTRL_DATA_WIDTH-1:0]   m_axi_ctrl_rdata;
wire [1:0]                              m_axi_ctrl_rresp;
wire                                    m_axi_ctrl_bvalid;
wire                                    m_axi_ctrl_bready;
wire [1:0]                              m_axi_ctrl_bresp;
// wires
// TODO: Instantiate core ctrl
// core_ctrl
piton_vortex_core_ctrl ctrl #(
    .C_S_AXI_CTRL_ADDR_WIDTH (VORTEX_AXI_CTRL_ADDR_WIDTH),
	.C_S_AXI_CTRL_DATA_WIDTH (VORTEX_AXI_CTRL_DATA_WIDTH)
)(

);

// master port logic / buffer?

// fake memory for AFU to the "slave" ports

vortex_afu vortex_afu #(
    .C_S_AXI_CTRL_ADDR_WIDTH (VORTEX_AXI_CTRL_ADDR_WIDTH),
	.C_S_AXI_CTRL_DATA_WIDTH (VORTEX_AXI_CTRL_DATA_WIDTH),
	.C_M_AXI_MEM_ID_WIDTH 	 (VORTEX_AXI_MEM_ID_WIDTH),
	.C_M_AXI_MEM_ADDR_WIDTH  (VORTEX_AXI_MEM_ADDR_WIDTH),
	.C_M_AXI_MEM_DATA_WIDTH  (VORTEX_AXI_MEM_DATA_WIDTH)  
) (
    // System signals
	.ap_clk (sys_clk),
	.ap_rst_n (sys_rst_n),
	
	// AXI4 master interface
	`REPEAT (`M_AXI_MEM_NUM_BANKS, GEN_AXI_MEM, REPEAT_COMMA),

    // AXI4-Lite slave interface
    .s_axi_ctrl_awvalid (m_axi_ctrl_awvalid),
    .s_axi_ctrl_awready (m_axi_ctrl_awready),
    .s_axi_ctrl_awaddr (m_axi_ctrl_awaddr),
    .s_axi_ctrl_wvalid (m_axi_ctrl_wvalid),
    .s_axi_ctrl_wready (m_axi_ctrl_wready),
    .s_axi_ctrl_wdata (m_axi_ctrl_wdata),
    .s_axi_ctrl_wstrb (m_axi_ctrl_wstrb),
    .s_axi_ctrl_arvalid (m_axi_ctrl_arvalid),
    .s_axi_ctrl_arready (m_axi_ctrl_arready),
    .s_axi_ctrl_araddr (m_axi_ctrl_araddr),
    .s_axi_ctrl_rvalid (m_axi_ctrl_rvalid),
    .s_axi_ctrl_rready (m_axi_ctrl_rready),
    .s_axi_ctrl_rdata (m_axi_ctrl_rdata),
    .s_axi_ctrl_rresp (m_axi_ctrl_rresp),
    .s_axi_ctrl_bvalid (m_axi_ctrl_bvalid),
    .s_axi_ctrl_bready (m_axi_ctrl_bready),
    .s_axi_ctrl_bresp (m_axi_ctrl_bresp),
    
    .interrupt () // Not sure what to do with this
);
endmodule