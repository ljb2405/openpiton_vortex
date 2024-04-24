// include statements to come
`include "/home/jae/openpiton_vortex/vortex/hw/rtl/afu/xrt/vortex_afu.v"


module system_vortex_wrap (
`ifndef PITON_FPGA_SYNTH
    // I/O settings
    input                                       chip_io_slew,
    input [1:0]                                 chip_io_impsel,
`endif // endif PITON_FPGA_SYNTH

    // Clocks and resets
`ifdef PITON_CLKS_SIM
    input                                       core_ref_clk,
    input                                       io_clk,
`endif // endif PITON_CLKS_SIM

`ifdef PITONSYS_INC_PASSTHRU
`ifdef PITON_PASSTHRU_CLKS_GEN
    input                                       passthru_clk_osc_p,
    input                                       passthru_clk_osc_n,
`else // ifndef PITON_PASSTHRU_CLKS_GEN
    input                                       passthru_chipset_clk_p,
    input                                       passthru_chipset_clk_n,
`endif // endif PITON_PASSTHRU_CLKS_GEN
`endif // endif PITON_SYS_INC_PASSTHRU

`ifndef F1_BOARD
`ifdef PITON_CHIPSET_CLKS_GEN
`ifdef PITON_CHIPSET_DIFF_CLK
    input                                       chipset_clk_osc_p,
    input                                       chipset_clk_osc_n,
`else // ifndef PITON_CHIPSET_DIFF_CLK
    input                                       chipset_clk_osc,
`endif // endif PITON_CHIPSET_DIFF_CLK

// 250MHz(VCU118) or 100 MHz(XUPP3R) diff input ref clock for DDR4 memory controller
`ifdef PITONSYS_DDR4
    input                                       mc_clk_p,
    input                                       mc_clk_n,
`endif // PITONSYS_DDR4

`else // ifndef PITON_CHIPSET_CLKS_GEN
    input                                       chipset_clk,
`ifndef PITONSYS_NO_MC
`ifdef PITON_FPGA_MC_DDR3
    input                                       mc_clk,
`endif // endif PITON_FPGA_MC_DDR3
`endif // endif PITONSYS_NO_MC
`ifdef PITONSYS_SPI
    input                                       sd_sys_clk,
`endif // endif PITONSYS_SPI
`ifdef PITONSYS_INC_PASSTHRU
    input                                       chipset_passthru_clk_p,
    input                                       chipset_passthru_clk_n,
`endif // endif PITONSYS_INC_PASSTHRU
`endif // endif PITON_CHIPSET_CLKS_GEN
`else //F1_BOARD
    input sys_clk,
`endif

    input                                       sys_rst_n,

`ifndef PITON_FPGA_SYNTH
    input                                       pll_rst_n,
`endif // endif PITON_FPGA_SYNTH

    // Chip-level clock enable
`ifndef PITON_FPGA_SYNTH
    input                                       clk_en,
`endif // endif PITON_FPGA_SYNTH

    // Chip PLL settings
`ifndef PITON_FPGA_SYNTH
    input                                       pll_bypass,
    input [4:0]                                 pll_rangea,
    output                                      pll_lock,
`endif // endif PITON_FPGA_SYNTH

    // Chip clock mux selection (bypass PLL or not)
`ifndef PITON_FPGA_SYNTH
    input [1:0]                                 clk_mux_sel,
`endif // endif PITON_FPGA_SYNTH

    // Chip JTAG
`ifndef PITON_NO_JTAG
    input                                       jtag_clk,
    input                                       jtag_rst_l,
    input                                       jtag_modesel,
    input                                       jtag_datain,
    output                                      jtag_dataout,
`endif  // endif PITON_NO_JTAG

`ifdef PITON_FPGA_SYNTH
`ifdef PITON_RV64_DEBUGUNIT
`ifndef VC707_BOARD
`ifndef VCU118_BOARD
`ifndef NEXYSVIDEO_BOARD
`ifndef XUPP3R_BOARD
`ifndef F1_BOARD
  input                                         tck_i,
  input                                         tms_i,
  input                                         trst_ni,
  input                                         td_i,
  output                                        td_o,
`endif//F1_BOARD
`endif//XUPP3R_BOARD
`endif //NEXYSVIDEO_BOARD
`endif //VCU118_BOARD
`endif  //VC707_BOARD
`endif //PITON_RV64_DEBUGUNIT
`endif //PITON_FPGA_SYNTH

    // Asynchronous FIFOs enable
    // for off-chip link (core<->io_clk)
`ifndef PITON_NO_CHIP_BRIDGE
`ifndef PITON_FPGA_SYNTH
    input                                       async_mux,
`endif // endif PITON_FPGA_SYNTH
`endif // endif PITON_NO_CHIP_BRIDGE

    // DRAM and I/O interfaces
`ifndef PITONSYS_NO_MC
`ifdef PITON_FPGA_MC_DDR3
`ifndef F1_BOARD
    // Generalized interface for any FPGA board we support.
    // Not all signals will be used for all FPGA boards (see constraints)
    `ifdef PITONSYS_DDR4
    output                                      ddr_act_n,
    output [`DDR3_BG_WIDTH-1:0]                 ddr_bg,
    `else // PITONSYS_DDR4
    output                                      ddr_cas_n,
    output                                      ddr_ras_n,
    output                                      ddr_we_n,
    `endif

    output [`DDR3_ADDR_WIDTH-1:0]               ddr_addr,
    output [`DDR3_BA_WIDTH-1:0]                 ddr_ba,
    output [`DDR3_CK_WIDTH-1:0]                 ddr_ck_n,
    output [`DDR3_CK_WIDTH-1:0]                 ddr_ck_p,
    output [`DDR3_CKE_WIDTH-1:0]                ddr_cke,
    output                                      ddr_reset_n,
    inout  [`DDR3_DQ_WIDTH-1:0]                 ddr_dq,
    inout  [`DDR3_DQS_WIDTH-1:0]                ddr_dqs_n,
    inout  [`DDR3_DQS_WIDTH-1:0]                ddr_dqs_p,
    `ifndef NEXYSVIDEO_BOARD
        output [`DDR3_CS_WIDTH-1:0]             ddr_cs_n,
    `endif // endif NEXYSVIDEO_BOARD
    `ifdef PITONSYS_DDR4
    `ifdef XUPP3R_BOARD
    output                                      ddr_parity,
    `else
    inout [`DDR3_DM_WIDTH-1:0]                  ddr_dm,
    `endif // XUPP3R_BOARD
    `else // PITONSYS_DDR4
    output [`DDR3_DM_WIDTH-1:0]                 ddr_dm,
    `endif // PITONSYS_DDR4
    output [`DDR3_ODT_WIDTH-1:0]                ddr_odt,
`else //ifndef F1_BOARD 
    input                                        mc_clk,
    // AXI Write Address Channel Signals
    output wire [`AXI4_ID_WIDTH     -1:0]    m_axi_awid,
    output wire [`AXI4_ADDR_WIDTH   -1:0]    m_axi_awaddr,
    output wire [`AXI4_LEN_WIDTH    -1:0]    m_axi_awlen,
    output wire [`AXI4_SIZE_WIDTH   -1:0]    m_axi_awsize,
    output wire [`AXI4_BURST_WIDTH  -1:0]    m_axi_awburst,
    output wire                                  m_axi_awlock,
    output wire [`AXI4_CACHE_WIDTH  -1:0]    m_axi_awcache,
    output wire [`AXI4_PROT_WIDTH   -1:0]    m_axi_awprot,
    output wire [`AXI4_QOS_WIDTH    -1:0]    m_axi_awqos,
    output wire [`AXI4_REGION_WIDTH -1:0]    m_axi_awregion,
    output wire [`AXI4_USER_WIDTH   -1:0]    m_axi_awuser,
    output wire                                  m_axi_awvalid,
    input  wire                                  m_axi_awready,

    // AXI Write Data Channel Signals
    output wire  [`AXI4_ID_WIDTH     -1:0]    m_axi_wid,
    output wire  [`AXI4_DATA_WIDTH   -1:0]    m_axi_wdata,
    output wire  [`AXI4_STRB_WIDTH   -1:0]    m_axi_wstrb,
    output wire                                   m_axi_wlast,
    output wire  [`AXI4_USER_WIDTH   -1:0]    m_axi_wuser,
    output wire                                   m_axi_wvalid,
    input  wire                                   m_axi_wready,

    // AXI Read Address Channel Signals
    output wire  [`AXI4_ID_WIDTH     -1:0]    m_axi_arid,
    output wire  [`AXI4_ADDR_WIDTH   -1:0]    m_axi_araddr,
    output wire  [`AXI4_LEN_WIDTH    -1:0]    m_axi_arlen,
    output wire  [`AXI4_SIZE_WIDTH   -1:0]    m_axi_arsize,
    output wire  [`AXI4_BURST_WIDTH  -1:0]    m_axi_arburst,
    output wire                                   m_axi_arlock,
    output wire  [`AXI4_CACHE_WIDTH  -1:0]    m_axi_arcache,
    output wire  [`AXI4_PROT_WIDTH   -1:0]    m_axi_arprot,
    output wire  [`AXI4_QOS_WIDTH    -1:0]    m_axi_arqos,
    output wire  [`AXI4_REGION_WIDTH -1:0]    m_axi_arregion,
    output wire  [`AXI4_USER_WIDTH   -1:0]    m_axi_aruser,
    output wire                                   m_axi_arvalid,
    input  wire                                   m_axi_arready,

    // AXI Read Data Channel Signals
    input  wire  [`AXI4_ID_WIDTH     -1:0]    m_axi_rid,
    input  wire  [`AXI4_DATA_WIDTH   -1:0]    m_axi_rdata,
    input  wire  [`AXI4_RESP_WIDTH   -1:0]    m_axi_rresp,
    input  wire                                   m_axi_rlast,
    input  wire  [`AXI4_USER_WIDTH   -1:0]    m_axi_ruser,
    input  wire                                   m_axi_rvalid,
    output wire                                   m_axi_rready,

    // AXI Write Response Channel Signals
    input  wire  [`AXI4_ID_WIDTH     -1:0]    m_axi_bid,
    input  wire  [`AXI4_RESP_WIDTH   -1:0]    m_axi_bresp,
    input  wire  [`AXI4_USER_WIDTH   -1:0]    m_axi_buser,
    input  wire                                   m_axi_bvalid,
    output wire                                   m_axi_bready,

    input  wire                                   ddr_ready,
`endif // endif F1_BOARD
`endif // endif PITON_FPGA_MC_DDR3
`endif // endif PITONSYS_NO_MC

`ifdef PITONSYS_IOCTRL
`ifdef PITONSYS_UART
    output                                      uart_tx,
    input                                       uart_rx,
`ifdef VCU118_BOARD
		input                                       uart_cts,
		output                                      uart_rts,
`endif // VCU118_BOARD
`endif // endif PITONSYS_UART

`ifdef PITONSYS_SPI
    `ifndef VC707_BOARD
    input                                       sd_cd,
    `ifndef VCU118_BOARD
    output                                      sd_reset,
    `endif
    `endif
    output                                      sd_clk_out,
    inout                                       sd_cmd,
    inout   [3:0]                               sd_dat,
`endif // endif PITONSYS_SPI

`ifdef PITON_FPGA_ETHERNETLITE
    // Emaclite interface
    `ifdef GENESYS2_BOARD
        output                                          net_phy_txc,
        output                                          net_phy_txctl,
        output      [3:0]                               net_phy_txd,
        input                                           net_phy_rxc,
        input                                           net_phy_rxctl,
        input       [3:0]                               net_phy_rxd,
        output                                          net_phy_rst_n,
        inout                                           net_phy_mdio_io,
        output                                          net_phy_mdc,
    `elsif NEXYSVIDEO_BOARD
        output                                          net_phy_txc,
        output                                          net_phy_txctl,
        output      [3:0]                               net_phy_txd,
        input                                           net_phy_rxc,
        input                                           net_phy_rxctl,
        input       [3:0]                               net_phy_rxd,
        output                                          net_phy_rst_n,
        inout                                           net_phy_mdio_io,
        output                                          net_phy_mdc,
    `endif
`endif // PITON_FPGA_ETHERNETLITE
`endif // endif PITONSYS_IOCTRL

`ifdef GENESYS2_BOARD
    input                                       btnl,
    input                                       btnr,
    input                                       btnu,
    input                                       btnd,

    output                                      oled_sclk,
    output                                      oled_dc,
    output                                      oled_data,
    output                                      oled_vdd_n,
    output                                      oled_vbat_n,
    output                                      oled_rst_n,
`elsif NEXYSVIDEO_BOARD
    input                                       btnl,
    input                                       btnr,
    input                                       btnu,
    input                                       btnd,

    output                                      oled_sclk,
    output                                      oled_dc,
    output                                      oled_data,
    output                                      oled_vdd_n,
    output                                      oled_vbat_n,
    output                                      oled_rst_n,
`elsif VCU118_BOARD
    input                                       btnl,
    input                                       btnr,
    input                                       btnu,
    input                                       btnd,
    input                                       btnc,
`endif

`ifdef VCU118_BOARD
    // we only have 4 gpio dip switches on this board
    input  [3:0]                                sw,
`elsif XUPP3R_BOARD
    // no switches :(
`else
    input  [7:0]                                sw,
`endif

`ifdef XUPP3R_BOARD
    output [3:0]                                leds
`else 
    output [7:0]                                leds
`endif
);

system system(
    `ifndef PITON_FPGA_SYNTH
        // I/O settings
        .chip_io_slew (chip_io_slew),
        .chip_io_impsel (chip_io_impsel),
    `endif // endif PITON_FPGA_SYNTH

        // Clocks and resets
    `ifdef PITON_CLKS_SIM
        .core_ref_clk (core_ref_clk),
        .io_clk (io_clk),
    `endif // endif PITON_CLKS_SIM

    `ifdef PITONSYS_INC_PASSTHRU
    `ifdef PITON_PASSTHRU_CLKS_GEN
        .passthru_clk_osc_p (passthru_clk_osc_p),
        .passthru_clk_osc_n (passthru_clk_osc_n),
    `else // ifndef PITON_PASSTHRU_CLKS_GEN
        .passthru_chipset_clk_p (passthru_chipset_clk_p),
        .passthru_chipset_clk_n (passthru_chipset_clk_n),
    `endif // endif PITON_PASSTHRU_CLKS_GEN
    `endif // endif PITON_SYS_INC_PASSTHRU

    `ifndef F1_BOARD
    `ifdef PITON_CHIPSET_CLKS_GEN
    `ifdef PITON_CHIPSET_DIFF_CLK
        .chipset_clk_osc_p (chipset_clk_osc_p),
        .chipset_clk_osc_n (chipset_clk_osc_n),
    `else // ifndef PITON_CHIPSET_DIFF_CLK
        .chipset_clk_osc(chipset_clk_osc),
    `endif // endif PITON_CHIPSET_DIFF_CLK

    // 250MHz(VCU118) or 100 MHz(XUPP3R) diff input ref clock for DDR4 memory controller
    `ifdef PITONSYS_DDR4
        .mc_clk_p(mc_clk_p),
        .mc_clk_n(mc_clk_n),
    `endif // PITONSYS_DDR4

    `else // ifndef PITON_CHIPSET_CLKS_GEN
        .chipset_clk(chipset_clk),
    `ifndef PITONSYS_NO_MC
    `ifdef PITON_FPGA_MC_DDR3
        .mc_clk(mc_clk),
    `endif // endif PITON_FPGA_MC_DDR3
    `endif // endif PITONSYS_NO_MC
    `ifdef PITONSYS_SPI
        .sd_sys_clk(sd_sys_clk),
    `endif // endif PITONSYS_SPI
    `ifdef PITONSYS_INC_PASSTHRU
        .chipset_passthru_clk_p(chipset_passthru_clk_p),
        .chipset_passthru_clk_n(chipset_passthru_clk_n),
    `endif // endif PITONSYS_INC_PASSTHRU
    `endif // endif PITON_CHIPSET_CLKS_GEN
    `else //F1_BOARD
        .sys_clk(sys_clk),
    `endif

        .sys_rst_n(sys_rst_n),

    `ifndef PITON_FPGA_SYNTH
        .pll_rst_n(pll_rst_n),
    `endif // endif PITON_FPGA_SYNTH

        // Chip-level clock enable
    `ifndef PITON_FPGA_SYNTH
        .clk_en(clk_en),
    `endif // endif PITON_FPGA_SYNTH

        // Chip PLL settings
    `ifndef PITON_FPGA_SYNTH
        .pll_bypass(pll_bypass),
        .pll_rangea(pll_rangea),
        .pll_lock(pll_lock),
    `endif // endif PITON_FPGA_SYNTH

        // Chip clock mux selection (bypass PLL or not)
    `ifndef PITON_FPGA_SYNTH
        .clk_mux_sel(clk_mux_sel),
    `endif // endif PITON_FPGA_SYNTH

        // Chip JTAG
    `ifndef PITON_NO_JTAG
        .jtag_clk(jtag_clk),
        .jtag_rst_l(jtag_rst_l),
        .jtag_modesel(jtag_modesel),
        .jtag_datain(jtag_datain),
        .jtag_dataout(jtag_dataout),
    `endif  // endif PITON_NO_JTAG

    `ifdef PITON_FPGA_SYNTH
    `ifdef PITON_RV64_DEBUGUNIT
    `ifndef VC707_BOARD
    `ifndef VCU118_BOARD
    `ifndef NEXYSVIDEO_BOARD
    `ifndef XUPP3R_BOARD
    `ifndef F1_BOARD
        .tck_i(tck_i),
        .tms_i(tms_i),
        .trst_ni(trst_ni),
        .td_i(td_i),
        .td_o(td_o),
    `endif//F1_BOARD
    `endif//XUPP3R_BOARD
    `endif //NEXYSVIDEO_BOARD
    `endif //VCU118_BOARD
    `endif  //VC707_BOARD
    `endif //PITON_RV64_DEBUGUNIT
    `endif //PITON_FPGA_SYNTH

        // Asynchronous FIFOs enable
        // for off-chip link (core<->io_clk)
    `ifndef PITON_NO_CHIP_BRIDGE
    `ifndef PITON_FPGA_SYNTH
        .async_mux(async_mux),
    `endif // endif PITON_FPGA_SYNTH
    `endif // endif PITON_NO_CHIP_BRIDGE

        // DRAM and I/O interfaces
    `ifndef PITONSYS_NO_MC
    `ifdef PITON_FPGA_MC_DDR3
    `ifndef F1_BOARD
        // Generalized interface for any FPGA board we support.
        // Not all signals will be used for all FPGA boards (see constraints)
        `ifdef PITONSYS_DDR4
        .ddr_act_n(ddr_act_n),
        .ddr_bg(ddr_bg),
        `else // PITONSYS_DDR4
        .ddr_cas_n(ddr_cas_n),
        .ddr_ras_n(ddr_ras_n),
        .ddr_we_n(ddr_we_n),
        `endif

        .ddr_addr(ddr_addr),
        .ddr_ba(ddr_ba),
        .ddr_ck_n(ddr_ck_n),
        .ddr_ck_p(ddr_ck_p),
        .ddr_cke(ddr_cke),
        .ddr_reset_n(ddr_reset_n),
        .ddr_dq(ddr_dq),
        .ddr_dqs_n(ddr_dqs_n),
        .ddr_dqs_p(ddr_dqs_p),
        `ifndef NEXYSVIDEO_BOARD
            .ddr_cs_n(ddr_cs_n),
        `endif // endif NEXYSVIDEO_BOARD
        `ifdef PITONSYS_DDR4
        `ifdef XUPP3R_BOARD
        .ddr_parity(ddr_parity),
        `else
        .ddr_dm(ddr_dm),
        `endif // XUPP3R_BOARD
        `else // PITONSYS_DDR4
        .ddr_dm(ddr_dm),
        `endif // PITONSYS_DDR4
        .ddr_odt(ddr_odt),
    `else //ifndef F1_BOARD 
        .mc_clk(mc_clk),
        // AXI Write Address Channel Signals
        .m_axi_awid(m_axi_awid),
        .m_axi_awaddr(m_axi_awaddr),
        .m_axi_awlen(m_axi_awlen),
        .m_axi_awsize(m_axi_awsize),
        .m_axi_awburst(m_axi_awburst),
        .m_axi_awlock(m_axi_awlock),
        .m_axi_awcache(m_axi_awcache),
        .m_axi_awprot(m_axi_awprot),
        .m_axi_awqos(m_axi_awqos),
        .m_axi_awregion(m_axi_awregion),
        .m_axi_awuser(m_axi_awuser),
        .m_axi_awvalid(m_axi_awvalid),
        .m_axi_awready(m_axi_awready),

        // AXI Write Data Channel Signals
        .m_axi_wid(m_axi_wid),
        .m_axi_wdata(m_axi_wdata),
        .m_axi_wstrb(m_axi_wstrb),
        .m_axi_wlast(m_axi_wlast),
        .m_axi_wuser(m_axi_wuser),
        .m_axi_wvalid(m_axi_wvalid),
        .m_axi_wready(m_axi_wready),

        // AXI Read Address Channel Signals
        .m_axi_arid(m_axi_arid),
        .m_axi_araddr(m_axi_araddr),
        .m_axi_arlen(m_axi_arlen),
        .m_axi_arsize(m_axi_arsize),
        .m_axi_arburst(m_axi_arburst),
        .m_axi_arlock(m_axi_arlock),
        .m_axi_arcache(m_axi_arcache),
        .m_axi_arprot(m_axi_arprot),
        .m_axi_arqos(m_axi_arqos),
        .m_axi_arregion(m_axi_arregion),
        .m_axi_aruser(m_axi_aruser),
        .m_axi_arvalid(m_axi_arvalid),
        .m_axi_arready(m_axi_arready),

        // AXI Read Data Channel Signals
        .m_axi_rid(m_axi_rid),
        .m_axi_rdata(m_axi_rdata),
        .m_axi_rresp(m_axi_rresp),
        .m_axi_rlast(m_axi_rlast),
        .m_axi_ruser(m_axi_ruser),
        .m_axi_rvalid(m_axi_rvalid),
        .m_axi_rready(m_axi_rready),

        // AXI Write Response Channel Signals
        .m_axi_bid(m_axi_bid),
        .m_axi_bresp(m_axi_bresp),
        .m_axi_buser(m_axi_buser),
        .m_axi_bvalid(m_axi_bvalid),
        .m_axi_bready(m_axi_bready),
        .ddr_ready(ddr_ready),
    `endif // endif F1_BOARD
    `endif // endif PITON_FPGA_MC_DDR3
    `endif // endif PITONSYS_NO_MC

    `ifdef PITONSYS_IOCTRL
    `ifdef PITONSYS_UART
        .uart_tx(uart_tx),
        .uart_rx(uart_rx),
    `ifdef VCU118_BOARD
            .uart_cts(uart_cts),
            .uart_rts(uart_rts),
    `endif // VCU118_BOARD
    `endif // endif PITONSYS_UART

    `ifdef PITONSYS_SPI
        `ifndef VC707_BOARD
        .sd_cd(sd_cd),
        `ifndef VCU118_BOARD
        .sd_reset(sd_reset),
        `endif
        `endif
        .sd_clk_out(sd_clk_out),
        .sd_cmd(sd_cmd),
        .sd_dat(sd_dat),
    `endif // endif PITONSYS_SPI

    `ifdef PITON_FPGA_ETHERNETLITE
        // Emaclite interface
        `ifdef GENESYS2_BOARD
            .net_phy_txc(net_phy_txc),
            .net_phy_txctl(net_phy_txctl),
            .net_phy_txd(net_phy_txd),
            .net_phy_rxc(net_phy_rxc),
            .net_phy_rxctl(net_phy_rxctl),
            .net_phy_rxd(net_phy_rxd),
            .net_phy_rst_n(net_phy_rst_n),
            .net_phy_mdio_io(net_phy_mdio_io),
            .net_phy_mdc(net_phy_mdc),
        `elsif NEXYSVIDEO_BOARD
            .net_phy_txc(net_phy_txc),
            .net_phy_txctl(net_phy_txctl),
            .net_phy_txd(net_phy_txd),
            .net_phy_rxc(net_phy_rxc),
            .net_phy_rxctl(net_phy_rxctl),
            .net_phy_rxd(net_phy_rxd),
            .net_phy_rst_n(net_phy_rst_n),
            .net_phy_mdio_io(net_phy_mdio_io),
            .net_phy_mdc(net_phy_mdc),
        `endif
    `endif // PITON_FPGA_ETHERNETLITE
    `endif // endif PITONSYS_IOCTRL

    `ifdef GENESYS2_BOARD
        .btnl(btnl),
        .btnr(btnr),
        .btnu(btnu),
        .btnd(btnd),

        .oled_sclk(oled_sclk),
        .oled_dc(oled_dc),
        .oled_data(oled_data),
        .oled_vdd_n(oled_vdd_n),
        .oled_vbat_n(oled_vbat_n),
        .oled_rst_n(oled_rst_n),
    `elsif NEXYSVIDEO_BOARD
        .btnl(btnl),
        .btnr(btnr),
        .btnu(btnu),
        .btnd(btnd),

        .oled_sclk(oled_sclk),
        .oled_dc(oled_dc),
        .oled_data(oled_data),
        .oled_vdd_n(oled_vdd_n),
        .oled_vbat_n(oled_vbat_n),
        .oled_rst_n(oled_rst_n),
    `elsif VCU118_BOARD
        .btnl(btnl),
        .btnr(btnr),
        .btnu(btnu),
        .btnd(btnd),
        .btnc(btnc),
    `endif

    `ifdef VCU118_BOARD
        // we only have 4 gpio dip switches on this board
        .sw(sw),
    `elsif XUPP3R_BOARD
        // no switches :(
    `else
        .sw(sw),
    `endif

    `ifdef XUPP3R_BOARD
        .leds(leds)
    `else 
        .leds(leds)
    `endif

);

wire interrupt;

vortex_afu #(
    .C_S_AXI_CTRL_ADDR_WIDTH (8),
	.C_S_AXI_CTRL_DATA_WIDTH	(32),
	.C_M_AXI_MEM_ID_WIDTH    (16),
	.C_M_AXI_MEM_ADDR_WIDTH  (64),
	.C_M_AXI_MEM_DATA_WIDTH  (512)
)

vortex_afu (
    // System signals
    input wire ap_clk,
    input wire ap_rst_n,

    // AXI4 master interface
	`REPEAT (`M_AXI_MEM_NUM_BANKS, GEN_AXI_MEM, REPEAT_COMMA),

    // AXI4-Lite slave interface
    .s_axi_ctrl_awvalid(m_axi_awvalid),
    .s_axi_ctrl_awready(m_axi_awready),
    input  wire [C_S_AXI_CTRL_ADDR_WIDTH-1:0]   .s_axi_ctrl_awaddr(m_axi_awaddr), // 8 // 64 - piton
    .s_axi_ctrl_wvalid(m_axi_wvalid),
    .s_axi_ctrl_wready(m_axi_wready),
    input  wire [C_S_AXI_CTRL_DATA_WIDTH-1:0]   .s_axi_ctrl_wdata(m_axi_wdata), // 32 // 512 - piton
    input  wire [C_S_AXI_CTRL_DATA_WIDTH/8-1:0] .s_axi_ctrl_wstrb(m_axi_wstrb), // 4 // 64 - piton
    .s_axi_ctrl_arvalid(m_axi_arvalid),
    .s_axi_ctrl_arready(m_axi_arready),
    input  wire [C_S_AXI_CTRL_ADDR_WIDTH-1:0]   .s_axi_ctrl_araddr(m_axi_araddr),
    .s_axi_ctrl_rvalid(m_axi_rvalid),
    .s_axi_ctrl_rready(m_axi_rready),
    output wire [C_S_AXI_CTRL_DATA_WIDTH-1:0]   .s_axi_ctrl_rdata(m_axi_rdata),
    .s_axi_ctrl_rresp(m_axi_rresp),
    .s_axi_ctrl_bvalid(m_axi_bvalid),
    .s_axi_ctrl_bready(m_axi_bready),
    .s_axi_ctrl_bresp(m_axi_bresp),
    
    output wire                                 .interrupt(interrupt)
); 

endmodule