`include "piton_sd_define.vh"

module noc_vortex_buffer #(
    parameter VORTEX_AXI_CTRL_ADDR_WIDTH = 8,
	parameter VORTEX_AXI_CTRL_DATA_WIDTH = 32,
	parameter VORTEX_AXI_MEM_ID_WIDTH 	 = 32,
	parameter VORTEX_AXI_MEM_ADDR_WIDTH  = 64,
	parameter VORTEX_AXI_MEM_DATA_WIDTH  = 512
) (
	// Shared SYSCON signals.
    input               clk,
    input               rst,

    // Master AXI-4 Lite Interface
	output wire                                    m_axi_ctrl_awvalid,
	output wire                                    m_axi_ctrl_awready,
	output wire [VORTEX_AXI_CTRL_ADDR_WIDTH-1:0]   m_axi_ctrl_awaddr,
	output wire                                    m_axi_ctrl_wvalid,
	output wire                                    m_axi_ctrl_wready,
	output wire [VORTEX_AXI_CTRL_DATA_WIDTH-1:0]   m_axi_ctrl_wdata,
	output wire [VORTEX_AXI_CTRL_DATA_WIDTH/8-1:0] m_axi_ctrl_wstrb,
	output wire                                    m_axi_ctrl_arvalid,
	output wire                                    m_axi_ctrl_arready,
	output wire [VORTEX_AXI_CTRL_ADDR_WIDTH-1:0]   m_axi_ctrl_araddr,
	output wire                                    m_axi_ctrl_rvalid,
	output wire                                    m_axi_ctrl_rready,
	output wire [VORTEX_AXI_CTRL_DATA_WIDTH-1:0]   m_axi_ctrl_rdata,
	output wire [1:0]                              m_axi_ctrl_rresp,
	output wire                                    m_axi_ctrl_bvalid,
	output wire                                    m_axi_ctrl_bready,
	output wire [1:0]                              m_axi_ctrl_bresp,

    // Buffer read/write for SD card bridge.
    input       [31:0]              buf_addr_i, // address of the 8-byte
    input       [`NOC_DATA_BITS]    buf_data_i, // 8-byte per data input
                    // unit in the 512-byte block
    input                           buf_ce_i,   // request enable
    input                           buf_we_i,   // write enable
    input       [1:0]               buf_data_sz,
    output  reg [`NOC_DATA_BITS]    buf_data_o
    );

    // ------ Signals Declaration ------ //
    reg             buf_rd_f;
    reg             wb_rd_f;
    reg             wb_wsel_f;
  
    // ------ Combinational Logic ------ //
    always @* begin

        s_wb_ack_o  =   wb_rd_f;
        s_wb_dat_o  =   bram_dout[{wb_wsel_f,   5'b0}   +:  32];
        buf_data_o  =   bram_dout;

        if (buf_ce_i) begin
            bram_ena    =   1'b1;
            bram_addr   =   buf_addr_i[11:3];
            if (buf_we_i) begin
                case (buf_data_sz)
                    2'd0:   begin
                        bram_wea[buf_addr_i[2:0]]                   =   1'h1;
                        bram_din[{buf_addr_i[2:0],  3'b0}   +:  8]  =   buf_data_i[7:0];
                    end
                    2'd1:   begin
                        bram_wea[{buf_addr_i[2:1],  1'b0}   +:  2]  =   2'h3;
                        bram_din[{buf_addr_i[2:1],  4'b0}   +:  16] =   buf_data_i[15:0];
                    end
                    2'd2:   begin
                        bram_wea[{buf_addr_i[2],    2'b0}   +:  4]  =   4'hf;
                        bram_din[{buf_addr_i[2],    5'b0}   +:  32] =   buf_data_i[31:0];
                    end
                    2'd3:   begin
                        bram_wea                                    =   8'hff;
                        bram_din                                    =   buf_data_i;
                    end
                endcase
            end
        end
        else if (s_wb_cyc_i && s_wb_stb_i && ~wb_rd_f) begin
            bram_ena    =   1'b1;
            bram_addr   =   s_wb_adr_i[11:3];
            if (s_wb_we_i) begin
                bram_wea[{s_wb_adr_i[2],    2'b0}   +:  4]  =   4'hf;
                bram_din[{s_wb_adr_i[2],    5'b0}   +:  32] =   s_wb_dat_i;
            end
        end
    end

    // ------ Sequential Logic ------ //
    always @(posedge clk or posedge rst) begin
        if (rst)    begin
            buf_rd_f    <=  1'b0;
            wb_rd_f     <=  1'b0;
            wb_wsel_f   <=  1'b0;
        end
        else begin
            if (buf_ce_i)   begin
                buf_rd_f    <=  1'b1;
                wb_rd_f     <=  1'b0;
            end
            else if (s_wb_cyc_i && s_wb_stb_i && ~wb_rd_f) begin
                buf_rd_f    <=  1'b0;
                wb_rd_f     <=  1'b1;
                wb_wsel_f   <=  s_wb_adr_i[2];
            end
            else begin
                buf_rd_f    <=  1'b0;
                wb_rd_f     <=  1'b0;
            end
        end
    end
endmodule