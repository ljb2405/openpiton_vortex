`include "openpiton_vortex/piton/design/chipset/vortex_bridge/rtl/piton_vortex_define.vh"
`include "vortex_fake_mem.v"

module vortex_fake_mem_ctrl #(
    parameter C_M_AXI_MEM_ID_WIDTH 	  = `VORTEX_AXI_MEM_ID_WIDTH,
	parameter C_M_AXI_MEM_ADDR_WIDTH  = `VORTEX_AXI_MEM_ADDR_WIDTH,
	parameter C_M_AXI_MEM_DATA_WIDTH  = `VORTEX_AXI_MEM_DATA_WIDTH,
    parameter AXI_NUM_BANKS           = 1
)(
    input wire clk,
    input wire rst,
    input wire                         s_axi_awvalid [AXI_NUM_BANKS],
    output reg                          s_axi_awready [AXI_NUM_BANKS],
    input wire [C_M_AXI_MEM_ADDR_WIDTH-1:0]    s_axi_awaddr [AXI_NUM_BANKS],
    input wire [C_M_AXI_MEM_ID_WIDTH-1:0]     s_axi_awid [AXI_NUM_BANKS],
    input wire [7:0]                   s_axi_awlen [AXI_NUM_BANKS],
    input wire [2:0]                   s_axi_awsize [AXI_NUM_BANKS],
    input wire [1:0]                   s_axi_awburst [AXI_NUM_BANKS],
    input wire [1:0]                   s_axi_awlock [AXI_NUM_BANKS],
    input wire [3:0]                   s_axi_awcache [AXI_NUM_BANKS],
    input wire [2:0]                   s_axi_awprot [AXI_NUM_BANKS],
    input wire [3:0]                   s_axi_awqos [AXI_NUM_BANKS],
    input wire [3:0]                   s_axi_awregion [AXI_NUM_BANKS],

    // AXI write request data channel     
    input wire                         s_axi_wvalid [AXI_NUM_BANKS], 
    output reg                          s_axi_wready [AXI_NUM_BANKS],
    input wire [C_M_AXI_MEM_DATA_WIDTH-1:0]    s_axi_wdata [AXI_NUM_BANKS],
    input wire [C_M_AXI_MEM_DATA_WIDTH/8-1:0]  s_axi_wstrb [AXI_NUM_BANKS],    
    input wire                         s_axi_wlast [AXI_NUM_BANKS],  

    // AXI write response channel
    output wire                          s_axi_bvalid [AXI_NUM_BANKS],
    input wire                         s_axi_bready [AXI_NUM_BANKS],
    output reg [C_M_AXI_MEM_ID_WIDTH-1:0]      s_axi_bid [AXI_NUM_BANKS],
    output wire [1:0]                    s_axi_bresp [AXI_NUM_BANKS],
    
    // AXI read request channel
    input wire                         s_axi_arvalid [AXI_NUM_BANKS],
    output reg                          s_axi_arready [AXI_NUM_BANKS],
    input wire [C_M_AXI_MEM_ADDR_WIDTH-1:0]    s_axi_araddr [AXI_NUM_BANKS],
    input wire [C_M_AXI_MEM_ID_WIDTH-1:0]     s_axi_arid [AXI_NUM_BANKS],
    input wire [7:0]                   s_axi_arlen [AXI_NUM_BANKS],
    input wire [2:0]                   s_axi_arsize [AXI_NUM_BANKS],
    input wire [1:0]                   s_axi_arburst [AXI_NUM_BANKS],            
    input wire [1:0]                   s_axi_arlock [AXI_NUM_BANKS],    
    input wire [3:0]                   s_axi_arcache [AXI_NUM_BANKS],
    input wire [2:0]                   s_axi_arprot [AXI_NUM_BANKS],        
    input wire [3:0]                   s_axi_arqos [AXI_NUM_BANKS], 
    input wire [3:0]                   s_axi_arregion [AXI_NUM_BANKS],
    
    // AXI read response channel
    output reg                          s_axi_rvalid [AXI_NUM_BANKS],
    input wire                         s_axi_rready [AXI_NUM_BANKS],
    output wire [C_M_AXI_MEM_DATA_WIDTH-1:0]     s_axi_rdata [AXI_NUM_BANKS],
    output reg                          s_axi_rlast [AXI_NUM_BANKS],
    output reg [C_M_AXI_MEM_ID_WIDTH-1:0]      s_axi_rid [AXI_NUM_BANKS],
    output reg [1:0]                    s_axi_rresp [AXI_NUM_BANKS]
);
// local states
localparam RST    0;
localparam IDLE   1;
localparam READ_1 2;
localparam READ_2 3;
localparam READ_3 4;
localparam READ_4 5;
localparam WRITE_1 6;
localparam WRITE_2 7;
localparam WRITE_3 8;
localparam WRITE_4 9;
localparam WRITE_RESP 10;


// Memory declaration variables
// TODO: fill out the declarations

// Fake memory Declaration
// 1 cycle read latency
vortex_fake_mem fake #(
    .C_M_AXI_MEM_ID_WIDTH (`VORTEX_AXI_MEM_ID_WIDTH),
	.C_M_AXI_MEM_ADDR_WIDTH (`VORTEX_AXI_MEM_ADDR_WIDTH),
	.C_M_AXI_MEM_DATA_WIDTH (`VORTEX_AXI_MEM_DATA_WIDTH),
    .AXI_NUM_BANKS           (1)
) (
    .clk (clk),
    .rst (rst),
    .addr(addr),
    .wr  (wr),
    .rd  (rd),
    .rdata(s_axi_rdata),
    .wdata(s_axi_wdata),
);

// local variables
// wires
wire [C_M_AXI_MEM_ADDR_WIDTH-1:0] addr = rd ? s_axi_araddr : wr ? waddr_reg : 0;
wire wr = (state == WRITE_4) && s_axi_wvalid;
wire rd = (state == READ_3) || (state == READ_4);
// regs
reg [4:0] state;
reg [4:0] next_state;
reg [C_M_AXI_MEM_ID_WIDTH-1:0] rid_reg;
reg [C_M_AXI_MEM_ID_WIDTH-1:0] wid_reg;
reg [C_M_AXI_MEM_ADDR_WIDTH-1:0] waddr_reg;

// general single item read/write case
// Sequential Logic
always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= RST;
        rid_reg <= 0;
        wid_reg <= 0;
        waddr_reg <= 0;
    end
    else begin
        state <= next_state;

        if (s_axi_arvalid) begin
            rid_reg <= s_axi_arid;
        end
        if (s_axi_awvalid) begin
            wid_reg <= s_axi_awid;
        end
        if (s_axi_awready && s_axi_awvalid) begin
            waddr_reg <= s_axi_awaddr;
        end
    end
end

// FSM Transitions
always @(*) begin
    next_state = 0;
    case (state)
        RST: begin
            next_state = IDLE;
        end
        IDLE: begin
            if (s_axi_arvalid) begin
                next_state = READ_1;
            end
            else if (s_axi_awvalid) begin
                next_state = WRITE_1;
            end
        end
        READ_1: begin
            next_state = READ_2;
        end
        READ_2: begin
            if (s_axi_rready) begin
                next_state = READ_3;
            end
        end
        READ_3: begin
            next_state = READ_4;
        end
        READ_4: begin
            next_state = IDLE;
        end
        WRITE_1: begin
            next_state = WRITE_2;
        end
        WRITE_2: begin
            if (s_axi_wready) begin
            next_state = WRITE_3;
            end
        end
        WRITE_3: begin
            next_state = WRITE_4;
        end
        WRITE_4: begin
            if (s_axi_wvalid && s_axi_wlast && s_axi_wready) begin
                next_state = WRITE_RESP;
            end
        end
        WRITE_RESP: begin
            if (s_axi_bready && s_axi_bvalid) begin
                next_state = IDLE;
            end
        end
    endcase
end

// Outputs
always @(*) begin
    s_axi_rready = 0;
    s_axi_rresp = 2'b00;
    s_axi_rvalid = 1'b0;
    s_axi_rdata  = 0;
    s_axi_rlast  = 1'b0;
    s_axi_rid    = 0;
    s_axi_awready = 0;
    s_axi_wready = 1'b0;
    s_axi_bresp = 2'b00;
    s_axi_bvalid = 0;
    s_axi_bid = 0;

    case (state)
        READ_1: begin
            s_axi_arready = 1'b1;
        end
        READ_4: begin
            s_axi_rresp = 2'b00;
            s_axi_rvalid = 1'b1;
            s_axi_rlast  = 1'b1;
            s_axi_rid    = rid_reg;
        end
        WRITE_1: begin
            s_axi_awready = 1'b1;
        end
        WRITE_2: begin
            s_axi_wready = 1'b1;
        end
        WRITE_3: begin
            s_axi_wready = 1'b1;
        end
        WRITE_4: begin
            s_axi_wready = 1'b1;
        end
        WRITE_RESP: begin
            s_axi_bresp = 2'b00;
            s_axi_bvalid = 1'b1;
            s_axi_bid = wid_reg;
        end
        default: begin
            s_axi_rready = 0;
            s_axi_rresp = 2'b00;
            s_axi_rvalid = 1'b0;
            s_axi_rdata  = 0;
            s_axi_rlast  = 1'b0;
            s_axi_rid    = 0;
            s_axi_awready = 0;
            s_axi_wready = 1'b0;
            s_axi_bresp = 2'b00;
            s_axi_bvalid = 0;
            s_axi_bid = 0;
        end
    endcase
end
endmodule