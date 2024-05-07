`include "piton_vortex_define.vh"
`include "./vortex/hw/rtl"
// TODO: wire/reg management

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

// AXI-4 Lite Master Interface Wires
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

// AXI4 Master Interface Wires
wire                         m_axi_awvalid;
wire                          m_axi_awready;
wire [VORTEX_AXI_MEM_ADDR_WIDTH-1:0]    m_axi_awaddr;
wire [VORTEX_AXI_MEM_ID_WIDTH-1:0]     m_axi_awid;
wire [7:0]                   m_axi_awlen;
wire [2:0]                   m_axi_awsize;
wire [1:0]                   m_axi_awburst;
wire [1:0]                   m_axi_awlock;
wire [3:0]                   m_axi_awcache;
wire [2:0]                   m_axi_awprot;
wire [3:0]                   m_axi_awqos;
wire [3:0]                   m_axi_awregion;

// AXI write request data channel     
wire                         m_axi_wvalid;
wire                         m_axi_wready;
wire [VORTEX_AXI_MEM_DATA_WIDTH-1:0]    m_axi_wdata;
wire [VORTEX_AXI_MEM_DATA_WIDTH/8-1:0]  m_axi_wstrb;  
wire                         m_axi_wlast; 

// AXI write response channel
wire                          m_axi_bvali;
wire                         m_axi_bready;
wire [VORTEX_AXI_MEM_ID_WIDTH-1:0]      m_axi_bid;
wire [1:0]                    m_axi_bresp;

// AXI read request channel
wire                         m_axi_arvalid;
wire                          m_axi_arready;
wire [VORTEX_AXI_MEM_ADDR_WIDTH-1:0]    m_axi_araddr;
wire [VORTEX_AXI_MEM_ID_WIDTH-1:0]     m_axi_arid;
wire [7:0]                   m_axi_arlen;
wire [2:0]                   m_axi_arsize;
wire [1:0]                   m_axi_arburst;            
wire [1:0]                   m_axi_arlock;    
wire [3:0]                   m_axi_arcache;
wire [2:0]                   m_axi_arprot;        
wire [3:0]                   m_axi_arqos; 
wire [3:0]                   m_axi_arregion;

// AXI read response channel
wire                          m_axi_rvalid;
wire                         m_axi_rready;
wire [VORTEX_AXI_MEM_DATA_WIDTH-1:0]     m_axi_rdat;,
wire                          m_axi_rlast;
wire [VORTEX_AXI_MEM_ID_WIDTH-1:0]      m_axi_rid;
wire [1:0]                    m_axi_rresp;

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

    // // Buffer
    // output reg  [31:0]                  core_buffer_addr,
    // output reg                          core_buffer_ce,
    // output reg                          core_buffer_wr,
    // output reg  [1:0]                   core_buffer_sz,
    // input  wire [`NOC_DATA_BITS]        buffer_core_data,
    // output reg  [`NOC_DATA_BITS]        core_buffer_data

    // Master AXI-4 Lite Interface
	.m_axi_ctrl_awvalid(m_axi_ctrl_awvalid),
	.m_axi_ctrl_awready(m_axi_ctrl_awready),
	.m_axi_ctrl_awaddr(m_axi_ctrl_awaddr),
	.m_axi_ctrl_wvalid(m_axi_ctrl_wvalid),
	.m_axi_ctrl_wready(m_axi_ctrl_wready),
	.m_axi_ctrl_wdata(m_axi_ctrl_wdata),
	.m_axi_ctrl_wstrb(m_axi_ctrl_wstrb),
	.m_axi_ctrl_arvalid(m_axi_ctrl_arvalid),
	.m_axi_ctrl_arready(m_axi_ctrl_arready),
	.m_axi_ctrl_araddr(m_axi_ctrl_araddr),
	.m_axi_ctrl_rvalid(m_axi_ctrl_rvalid),
	.m_axi_ctrl_rready(m_axi_ctrl_rready),
	.m_axi_ctrl_rdata(m_axi_ctrl_rdata),
	.m_axi_ctrl_rresp(m_axi_ctrl_rresp),
	.m_axi_ctrl_bvalid(m_axi_ctrl_bvalid),
	.m_axi_ctrl_bready(m_axi_ctrl_bready),
	.m_axi_ctrl_bresp(m_axi_ctrl_bresp)
);

// master port logic / buffer?

// fake memory for AFU to the "slave" ports
vortex_fake_mem_ctrl vortex_fake_mem_ctrl #(
    .C_M_AXI_MEM_ID_WIDTH 	 (VORTEX_AXI_MEM_ID_WIDTH),
	.C_M_AXI_MEM_ADDR_WIDTH  (VORTEX_AXI_MEM_ADDR_WIDTH),
	.C_M_AXI_MEM_DATA_WIDTH  (VORTEX_AXI_MEM_DATA_WIDTH),
    .AXI_NUM_BANKS           (1)  
)(
    .clk(sys_clk),
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
	// TODO: Do proper instantiation
	// AXI4 master interface
	`REPEAT (1, GEN_AXI_MEM, REPEAT_COMMA),

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
    
    .interrupt (1'b0) // Not sure what to do with this
);
endmodule