`include "openpiton_vortex/piton/design/chipset/vortex_bridge/rtl/piton_vortex_define.vh"
`include "openpiton_vortex/piton/design/chipset/vortex_bridge/rtl/vortex/hw/rtl"
// TODO: wire/reg management

module piton_vortex_top #(
    parameter VORTEX_DCR_ADDR_WIDTH = 8,
	parameter VORTEX_DCR_DATA_WIDTH = 32,
	parameter VORTEX_AXI_MEM_ID_WIDTH 	 = 32,
	parameter VORTEX_AXI_MEM_ADDR_WIDTH  = 64,
	parameter VORTEX_AXI_MEM_DATA_WIDTH  = 512
)(
    // Clock and reset
    input  wire                             sys_clk,
    input  wire                             ap_clk, // separate clock for Vortex since Vortex runs on different clk
    input  wire                             sys_rst,

    // NOC interface
    input  wire                             splitter_vortex_val,
    input  wire [`NOC_DATA_WIDTH-1:0]       splitter_vortex_data,
    output wire                             vortex_splitter_rdy,

    output wire                             vortex_splitter_val,
    output wire [`NOC_DATA_WIDTH-1:0]       vortex_splitter_data,
    input  wire                             splitter_vortex_rdy
);
// Control Signals
wire                                    sys_rst_n = ~sys_rst;
wire                                    dcr_busy;

// Piton Buffer Signals
wire                                    noc_piton_buffer_valid;
wire [`VORTEX_DCR_ADDR_WIDTH-1:0]       noc_piton_buffer_addr;
wire [`VORTEX_DCR_DATA_WIDTH-1:0]       noc_piton_buffer_data;   
wire                                    piton_buffer_full;

// Vortex Buffer Signals
wire                                    piton_vx_buffer_valid;
wire [`VORTEX_DCR_ADDR_WIDTH-1:0]       piton_vx_buffer_addr;
wire [`VORTEX_DCR_DATA_WIDTH-1:0]       piton_vx_buffer_data;   
wire                                    vx_buffer_rdy;
// DCR Signals
wire                                    dcr_wr_valid,
wire [`VORTEX_DCR_ADDR_WIDTH-1:0]       dcr_wr_addr,
wire [`VORTEX_DCR_DATA_WIDTH-1:0]       dcr_wr_data,
// AXI4 Master Interface Wires
wire                                    m_axi_awvalid;
wire                                    m_axi_awready;
wire [VORTEX_AXI_MEM_ADDR_WIDTH-1:0]    m_axi_awaddr;
wire [VORTEX_AXI_MEM_ID_WIDTH-1:0]      m_axi_awid;
wire [7:0]                              m_axi_awlen;
wire [2:0]                              m_axi_awsize;
wire [1:0]                              m_axi_awburst;
wire [1:0]                              m_axi_awlock;
wire [3:0]                              m_axi_awcache;
wire [2:0]                              m_axi_awprot;
wire [3:0]                              m_axi_awqos;
wire [3:0]                              m_axi_awregion;

// AXI write request data channel     
wire                                    m_axi_wvalid;
wire                                    m_axi_wready;
wire [VORTEX_AXI_MEM_DATA_WIDTH-1:0]    m_axi_wdata;
wire [VORTEX_AXI_MEM_DATA_WIDTH/8-1:0]  m_axi_wstrb;  
wire                                    m_axi_wlast; 

// AXI write response channel
wire                                    m_axi_bvali;
wire                                    m_axi_bready;
wire [VORTEX_AXI_MEM_ID_WIDTH-1:0]      m_axi_bid;
wire [1:0]                              m_axi_bresp;

// AXI read request channel
wire                                    m_axi_arvalid;
wire                                    m_axi_arready;
wire [VORTEX_AXI_MEM_ADDR_WIDTH-1:0]    m_axi_araddr;
wire [VORTEX_AXI_MEM_ID_WIDTH-1:0]      m_axi_arid;
wire [7:0]                              m_axi_arlen;
wire [2:0]                              m_axi_arsize;
wire [1:0]                              m_axi_arburst;            
wire [1:0]                              m_axi_arlock;    
wire [3:0]                              m_axi_arcache;
wire [2:0]                              m_axi_arprot;        
wire [3:0]                              m_axi_arqos; 
wire [3:0]                              m_axi_arregion;

// AXI read response channel
wire                                    m_axi_rvalid;
wire                                    m_axi_rready;
wire [VORTEX_AXI_MEM_DATA_WIDTH-1:0]    m_axi_rdat;,
wire                                    m_axi_rlast;
wire [VORTEX_AXI_MEM_ID_WIDTH-1:0]      m_axi_rid;
wire [1:0]                              m_axi_rresp;

piton_vortex_core_ctrl ctrl #(
    .C_S_AXI_CTRL_ADDR_WIDTH (VORTEX_AXI_CTRL_ADDR_WIDTH),
	.C_S_AXI_CTRL_DATA_WIDTH (VORTEX_AXI_CTRL_DATA_WIDTH)
)(
    // Clock + Reset
    .clk(sys_clk),
    .rst(sys_rst),

    // NOC interface
    // Goes to NOC2(mem-req)
    .splitter_bridge_val(splitter_vortex_val),
    .splitter_bridge_data(splitter_vortex_data),
    .bridge_splitter_rdy(vortex_splitter_rdy),
    // Goes to NOC3(mem-resp)
    .bridge_splitter_val(vortex_splitter_val),
    .bridge_splitter_data(vortex_splitter_data),
    .splitter_bridge_rdy(splitter_vortex_rdy),

    // Output to Piton DCR Buffer
    .buffer_wr_valid(noc_piton_buffer_valid),
    .buffer_wr_addr(noc_piton_buffer_addr),
    .buffer_wr_data(noc_piton_buffer_data),

    .buffer_full(piton_buffer_full);
);

// TODO: DCR buffer needed to fit into Vortex clk freq
piton_dcr_buffer piton_buffer #(
    .VX_DCR_ADDR_WIDTH(8),
    .VX_DCR_DATA_WIDTH(32)
)(  
    // Clock + Reset
    .clk(sys_clk),
    .rst(sys_rst),

    // Input from core control of DCR messages to Vortex
    .buffer_wr_valid(noc_piton_buffer_valid),
    .buffer_wr_addr(noc_piton_buffer_addr),
    .buffer_wr_data(noc_piton_buffer_data),

    // Output to Vortex Buffer
    .buffer_dcr_wr_valid(piton_vx_buffer_valid),
    .buffer_dcr_wr_addr(piton_vx_buffer_addr),
    .buffer_dcr_wr_data(piton_vx_buffer_data),

    // Handshake protocol to send valid data to Vortex
    // Valid signal replaced with buffer_dcr_wr_valid
    .vx_buffer_rdy(vx_buffer_rdy),

    // Control Signal to core_ctrl
    .buffer_full(piton_buffer_full)
);

vx_dcr_buffer vx_buffer #(
    .VX_DCR_ADDR_WIDTH(8),
    .VX_DCR_DATA_WIDTH(32)
)(
    // Clock + Reset
    .clk(ap_clk),
    .rst(sys_rst),

    // Input from Piton Buffer
    .dcr_buffer_wr_valid(piton_vx_buffer_valid),
    .dcr_buffer_wr_addr(piton_vx_buffer_addr),
    .dcr_buffer_wr_data(piton_vx_buffer_data),

    // Output to Vortex 
    .dcr_wr_valid(dcr_wr_valid),
    .dcr_wr_addr(dcr_wr_addr),
    .dcr_wr_data(dcr_wr_data),
    
    // Handshake protocol to send valid data to Vortex
    // Valid signal replaced with dcr_buffer_wr_valid
    .dcr_busy(dcr_busy),
    // Ready Signal to Piton buffer
    .vx_buffer_rdy(vx_buffer_busy);
);

Vortex_axi vortex #(
    .AXI_DATA_WIDTH (`VORTEX_AXI_MEM_DATA_WIDTH),
    .AXI_ADDR_WIDTH (`VORTEX_AXI_MEM_ADDR_WIDTH),
    .AXI_TID_WIDTH (`VX_MEM_TAG_WIDTH), // todo: change this
    .AXI_NUM_BANKS (1)
)(
    // Clock
    .clk(ap_clk),
    .reset(sys_rst_n),

    // AXI write request address channel
    .m_axi_awvalid(m_axi_awvalid),
    .m_axi_awready(m_axi_awready),
    .m_axi_awaddr(m_axi_awaddr),
    .m_axi_awid(m_axi_awid),
    .m_axi_awlen(m_axi_awlen),
    .m_axi_awsize(m_axi_awsize),
    .m_axi_awburst(m_axi_awburst),
    .m_axi_awlock(m_axi_awlock),
    .m_axi_awcache(m_axi_awcache),
    .m_axi_awprot(m_axi_awprot),
    .m_axi_awqos(m_axi_awqos),
    .m_axi_awregion(m_axi_awregion),

    // AXI write request data channel
    .m_axi_wvalid(m_axi_wvalid),
    .m_axi_wready(m_axi_wready),
    .m_axi_wdata(m_axi_wdata),
    .m_axi_wstrb(m_axi_wstrb),
    .m_axi_wlast(m_axi_wlast),

    // AXI write response channel
    .m_axi_bvalid(m_axi_bvalid),
    .m_axi_bready(m_axi_bready),
    .m_axi_bid(m_axi_bid),
    .m_axi_bresp(m_axi_bresp),

    // AXI read request channel
    .m_axi_arvalid(m_axi_arvalid),
    .m_axi_arready(m_axi_arready),
    .m_axi_araddr(m_axi_araddr),
    .m_axi_arid(m_axi_arid),
    .m_axi_arlen(m_axi_arlen),
    .m_axi_arsize(m_axi_arsize),
    .m_axi_arburst(m_axi_arburst),
    .m_axi_arlock(m_axi_arlock),
    .m_axi_arcache(m_axi_arcache),
    .m_axi_arprot(m_axi_arprot),
    .m_axi_arqos(m_axi_arqos),
    .m_axi_arregion(m_axi_arregion),

    // AXI read response channel
    .m_axi_rvalid(m_axi_rvalid),
    .m_axi_rready(m_axi_rready),
    .m_axi_rdata(m_axi_rdata),
    .m_axi_rlast(m_axi_rlast),
    .m_axi_rid(m_axi_rid),
    .m_axi_rresp(m_axi_rresp),

    // DCR write request
    .dcr_wr_valid(dcr_wr_valid),
    .dcr_wr_addr(dcr_wr_addr),
    .dcr_wr_data(dcr_wr_data),

    // Status
  dcr.busy(dcr_busy)
);

// fake memory for AFU to the "slave" ports
vortex_fake_mem_ctrl vortex_fake_mem_ctrl #(
    .C_M_AXI_MEM_ID_WIDTH 	 (VORTEX_AXI_MEM_ID_WIDTH),
	.C_M_AXI_MEM_ADDR_WIDTH  (VORTEX_AXI_MEM_ADDR_WIDTH),
	.C_M_AXI_MEM_DATA_WIDTH  (VORTEX_AXI_MEM_DATA_WIDTH),
    .AXI_NUM_BANKS           (1)  
)(
    .clk(ap_clk),
    .rst(sys_rst),
    .s_axi_awvalid(m_axi_awvalid),
    .s_axi_awready(m_axi_awready),
    .s_axi_awaddr(m_axi_awaddr),
    .s_axi_awid(m_axi_awid),
    .s_axi_awlen(m_axi_awlen),
    .s_axi_awsize(m_axi_awsize)
    .s_axi_awburst(0),
    .s_axi_awlock(0),
    .s_axi_awcache(0),
    .s_axi_awprot(0),
    .s_axi_awqos(0),
    .s_axi_awregion(0),

    // AXI write request data channel     
    .s_axi_wvalid(m_axi_wvalid), 
    .s_axi_wready(m_axi_wready),
    .s_axi_wdata(m_axi_wdata),
    .s_axi_wstrb(m_axi_wstrb),    
    .s_axi_wlast(s_axi_wlast),  

    // AXI write response channel
    .s_axi_bvalid(m_axi_bvalid),
    .s_axi_bready(m_axi_bready),
    .s_axi_bid(m_axi_bid),
    .s_axi_bresp(m_axi_bresp),
    
    // AXI read request channel
    .s_axi_arvalid(m_axi_arvalid),
    .s_axi_arready(m_axi_arready),
    .s_axi_araddr(m_axi_araddr),
    .s_axi_arid(m_axi_arid),
    .s_axi_arlen(0),
    .s_axi_arsize(0),
    .s_axi_arburst(0),            
    .s_axi_arlock(0),    
    .s_axi_arcache(0),
    .s_axi_arprot(0),        
    .s_axi_arqos(0), 
    .s_axi_arregion(m_axi_arregion),
    
    // AXI read response channel
    .s_axi_rvalid(m_axi_rvalid),
    .s_axi_rready(m_axi_rready),
    .s_axi_rdata(m_axi_rdata),
    .s_axi_rlast(m_axi_rlast),
    .s_axi_rid(m_axi_rid),
    .s_axi_rresp(m_axi_rresp)
);

endmodule