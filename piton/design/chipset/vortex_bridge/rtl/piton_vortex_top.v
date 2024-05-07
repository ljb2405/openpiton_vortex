`include "piton_vortex_define.vh"
`include "./vortex/hw/rtl"
//TODO: find the parameters
// pretty sure xlen depends on the program it runs since i remember fetching that as an argument when i ran the execution command via blackbox.sh
module piton_vortex_top #(
	parameter VORTEX_AXI_DATA_WIDTH = 512,
	parameter VORTEX_AXI_TID_WIDTH 	 = , // L3_MEM_TAG_WIDTH
	parameter VORTEX_AXI_ADDR_WIDTH  = , // XLEN (32 or 64) VX_config.vh
	parameter VORTEX_AXI_NUM_BANKS  = 1
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

// wire sys_rst_n = ~sys_rst;

// // AXI-4 Lite Master Interface
// wire                                    m_axi_ctrl_awvalid;
// wire                                    m_axi_ctrl_awready;
// wire [VORTEX_AXI_CTRL_ADDR_WIDTH-1:0]   m_axi_ctrl_awaddr;
// wire                                    m_axi_ctrl_wvalid;
// wire                                    m_axi_ctrl_wready;
// wire [VORTEX_AXI_CTRL_DATA_WIDTH-1:0]   m_axi_ctrl_wdata;
// wire [VORTEX_AXI_CTRL_DATA_WIDTH/8-1:0] m_axi_ctrl_wstrb;
// wire                                    m_axi_ctrl_arvalid;
// wire                                    m_axi_ctrl_arready;
// wire [VORTEX_AXI_CTRL_ADDR_WIDTH-1:0]   m_axi_ctrl_araddr;
// wire                                    m_axi_ctrl_rvalid;
// wire                                    m_axi_ctrl_rready;
// wire [VORTEX_AXI_CTRL_DATA_WIDTH-1:0]   m_axi_ctrl_rdata;
// wire [1:0]                              m_axi_ctrl_rresp;
// wire                                    m_axi_ctrl_bvalid;
// wire                                    m_axi_ctrl_bready;
// wire [1:0]                              m_axi_ctrl_bresp;
// wires
// TODO: Instantiate core ctrl
// core_ctrl
piton_vortex_core_ctrl ctrl #(
    .VORTEX_AXI_DATA_WIDTH(`VORTEX_AXI_DATA_WIDTH), // `L3_LINE_SIZE * 8
    .VORTEX_AXI_ADDR_WIDTH(`VORTEX_AXI_ADDR_WIDTH), // XLEN
    .VORTEX_AXI_TID_WIDTH(`VORTEX_AXI_TID_WIDTH), // L3_MEM_TAG_WIDTH
    .VORTEX_AXI_NUM_BANKS(`VORTEX_AXI_NUM_BANKS)
)(

);

// fake memory for AFU to the "slave" ports

vortex_axi vortex_axi #(
    .AXI_DATA_WIDTH(`VORTEX_AXI_DATA_WIDTH), // `L3_LINE_SIZE * 8
    .AXI_ADDR_WIDTH(`VORTEX_AXI_ADDR_WIDTH), // XLEN
    .AXI_TID_WIDTH(`VORTEX_AXI_TID_WIDTH), // L3_MEM_TAG_WIDTH
    .AXI_NUM_BANKS(`VORTEX_AXI_NUM_BANKS)
)(
    // Clock
    .clk(sys_clk),
    .reset(sys_rst),

    // AXI write request address channel    
    .m_axi_awvalid(),
    .m_axi_awready(),
    .m_axi_awaddr(),
    .m_axi_awid(),
    .m_axi_awlen(),
    .m_axi_awsize(),
    .m_axi_awburst(),
    .m_axi_awlock(),
    .m_axi_awcache(),
    .m_axi_awprot (),
    .m_axi_awqos(),
    .m_axi_awregion(),

    // AXI write request data channel     
    .m_axi_wvalid(), 
    .m_axi_wready(),
    .m_axi_wdata(),
    .m_axi_wstrb(),    
    .m_axi_wlast(),  

    // AXI write response channel
    .m_axi_bvalid(),
    .m_axi_bready(),
    .m_axi_bid(),
    .m_axi_bres(),
    
    // AXI read request channel
    .m_axi_arvalid(),
    .m_axi_arready(),
    .m_axi_arad(),
    .m_axi_ari(),
    .m_axi_arlen(),
    .m_axi_arsize(),
    .m_axi_arburst(),            
    .m_axi_arlock(),    
    .m_axi_arcache(),
    .m_axi_arpro(),        
    .m_axi_arqos(), 
    .m_axi_arregion(),
    
    // AXI read response channel
    .m_axi_rvalid(),
    .m_axi_rready(),
    .m_axi_rdata ()
    .m_axi_rlast(),
    .m_axi_rid(),
    .m_axi_rresp(),
    
    // DCR write request
    .dcr_wr_valid(),
    .dcr_wr_addr(),
    .dcr_wr_data(),
    // Status
    .busy()
);
endmodule