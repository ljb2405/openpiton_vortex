`include "piton_sd_define.vh"

module piton_vortex_core_ctrl #(
    parameter VORTEX_AXI_CTRL_ADDR_WIDTH = 8,
	parameter VORTEX_AXI_CTRL_DATA_WIDTH = 32
)(
    // Clock + Reset
    input  wire                         clk,
    input  wire                         rst,

    // NOC interface
    // Goes to NOC2(mem-req)
    input  wire                         splitter_bridge_val,
    input  wire [`NOC_DATA_BITS]        splitter_bridge_data,
    output reg                          bridge_splitter_rdy,
    // Goes to NOC3(mem-resp)
    output reg                          bridge_splitter_val,
    output reg  [`NOC_DATA_BITS]        bridge_splitter_data,
    input  wire                         splitter_bridge_rdy,

    // // Buffer
    // output reg  [31:0]                  core_buffer_addr,
    // output reg                          core_buffer_ce,
    // output reg                          core_buffer_wr,
    // output reg  [1:0]                   core_buffer_sz,
    // input  wire [`NOC_DATA_BITS]        buffer_core_data,
    // output reg  [`NOC_DATA_BITS]        core_buffer_data

    // Master AXI-4 Lite Interface
	output wire                                    m_axi_ctrl_awvalid,
	input  wire                                    m_axi_ctrl_awready,
	output reg [VORTEX_AXI_CTRL_ADDR_WIDTH-1:0]   m_axi_ctrl_awaddr,
	output reg                                    m_axi_ctrl_wvalid,
	input  wire                                    m_axi_ctrl_wready,
	output wire [VORTEX_AXI_CTRL_DATA_WIDTH-1:0]   m_axi_ctrl_wdata,
	output reg [VORTEX_AXI_CTRL_DATA_WIDTH/8-1:0] m_axi_ctrl_wstrb,
	output reg                                    m_axi_ctrl_arvalid,
	input  wire                                    m_axi_ctrl_arready,
	output wire [VORTEX_AXI_CTRL_ADDR_WIDTH-1:0]   m_axi_ctrl_araddr,
	input  wire                                    m_axi_ctrl_rvalid,
	output reg                                    m_axi_ctrl_rready,
	input wire  [VORTEX_AXI_CTRL_DATA_WIDTH-1:0]   m_axi_ctrl_rdata,
	input wire  [1:0]                              m_axi_ctrl_rresp,
	input wire                                     m_axi_ctrl_bvalid,
	output reg                                    m_axi_ctrl_bready,
	input wire  [1:0]                              m_axi_ctrl_bresp

    // // Cache Manager
    // output reg                          cache_lock_acquire,
    // output reg                          cache_lock_release,
    // input  wire                         cache_lock_status,

    // output reg                          core_cache_we,
    // output reg  [`PHY_BLOCK_BITS]       core_cache_addr,
    // input  wire                         cache_core_rdy,
    // input  wire [`CACHE_ENTRY_BITS]     cache_core_entry
);
// ------ Local Parameters ------ //
    // NOC states
    localparam  NOC_RST                 = 4'hf;
    localparam  NOC_IDLE                = 4'h0;

    localparam  NOC_IN_HEADER_1         = 4'h1;
    localparam  NOC_IN_HEADER_2         = 4'h2;
    localparam  NOC_IN_DATA             = 4'h3;

    localparam  NOC_WAITING             = 4'h4;
    localparam  NOC_THROWING            = 4'h5;

    localparam  NOC_OUT_HEADER          = 4'h6;
    localparam  NOC_OUT_DATA            = 4'h7;
    localparam  AXI_READ_DATA           = 4'h8;

    // ------ Signals Declarations ------ //
    reg [3:0]   state;
    reg [3:0]   state_next;

    reg [7:0]   counter;
    reg         counter_en;
    reg         counter_rst;

    reg [2:0]   offset;
    reg         offset_en;
    reg         offset_rst;

    reg [7:0]                   msg_data_val;
    // reg [`NOC_DATA_BITS]        msg_data_buf    [7:0];

    // reg                         cache_re_f;
    // reg [2:0]                   offset_f;

    reg [`MSG_TYPE]             msg_type;
    reg [`MSG_LENGTH]           payload;
    reg [`MSG_MSHRID]           mshr;
    reg [`C_S_AXI_CTRL_ADDR_WIDTH-1:0]        addr;
    reg [`MSG_DATA_SIZE_]       data_sz;
    reg [`MSG_SRC_CHIPID_]      chipid;
    reg [`MSG_SRC_X_]           srcx;
    reg [`MSG_SRC_Y_]           srcy;

    // AXI Read data register
    reg [`C_S_AXI_CTRL_DATA_WIDTH-1:0] axi_read_data_reg;

    // ------ Static Logic ------ //
    // Mem requests out of NOC
    wire    splitter_bridge_go  =   bridge_splitter_rdy && splitter_bridge_val;
    // Mem responses into NOC
    wire    bridge_splitter_go  =   splitter_bridge_rdy && bridge_splitter_val;

    wire    store       =   (msg_type == `MSG_TYPE_STORE_REQ) ||
                            (msg_type == `MSG_TYPE_STORE_MEM);
    wire    ncstore     =   (msg_type == `MSG_TYPE_NC_STORE_REQ);
    wire    wr          =   store || ncstore;
    wire    load        =   (msg_type == `MSG_TYPE_LOAD_REQ) ||
                            (msg_type == `MSG_TYPE_LOAD_MEM);
    wire    ncload      =   (msg_type == `MSG_TYPE_NC_LOAD_REQ);
    wire    rd          =   load || ncload;

    `ifndef VORTEXCTRL_TEST
    // Now we have a bug. Always return 64 bytes when read.
        wire    [7:0]   resp_payload    =   wr  ? 8'd0 : 8'd8;
    `else /* `ifndef VORTEXCTRL_TEST */
        wire    [7:0]   resp_payload = wr       ? 8'd0
            : (data_sz == `MSG_DATA_SIZE_1B)    ? 8'd1
            : (data_sz == `MSG_DATA_SIZE_2B)    ? 8'd1
            : (data_sz == `MSG_DATA_SIZE_4B)    ? 8'd1
            : (data_sz == `MSG_DATA_SIZE_8B)    ? 8'd1
            : (data_sz == `MSG_DATA_SIZE_16B)   ? 8'd2
            : (data_sz == `MSG_DATA_SIZE_32B)   ? 8'd4
            : (data_sz == `MSG_DATA_SIZE_64B)   ? 8'd8
            :                                     8'd0;
    `endif /* `ifndef VORTEXCTRL_TEST */

    wire    [2:0]   actual_resp_payload_mask    =   wr  ?   3'h0
        : (data_sz  ==  `MSG_DATA_SIZE_1B)              ?   3'h0
        : (data_sz  ==  `MSG_DATA_SIZE_2B)              ?   3'h0
        : (data_sz  ==  `MSG_DATA_SIZE_4B)              ?   3'h0
        : (data_sz  ==  `MSG_DATA_SIZE_8B)              ?   3'h0
        : (data_sz  ==  `MSG_DATA_SIZE_16B)             ?   3'h1
        : (data_sz  ==  `MSG_DATA_SIZE_32B)             ?   3'h3
        : (data_sz  ==  `MSG_DATA_SIZE_64B)             ?   3'h7 // this should be hitting
        :                                                   3'h0;

    wire    [7:0]   resp_msg_type   = store   ? `MSG_TYPE_STORE_MEM_ACK
                                    : ncstore ? `MSG_TYPE_NC_STORE_MEM_ACK
                                    : load    ? `MSG_TYPE_LOAD_MEM_ACK
                                    : ncload  ? `MSG_TYPE_NC_LOAD_MEM_ACK
                                    :           `MSG_TYPE_ERROR;

    `ifndef VORTEXCTRL_TEST
        wire    [3:0]   resp_fbits  =   4'h0;
    `else /* `ifndef VORTEXCTRL_TEST */
        wire    [3:0]   resp_fbits  =   4'ha;
    `endif /* `ifndef VORTEXCTRL_TEST */

    // Response to the NOC
    // Edit resp_payload and resp_msg_type
    wire    [`NOC_DATA_BITS]    resp_header =
        {chipid, srcx, srcy, resp_fbits,
            resp_payload,   resp_msg_type,  mshr,   6'h0};

    wire    [`C_S_AXI_CTRL_ADDR_WIDTH-1:0]    addr_remapped   = splitter_bridge_data[23:16];
        // (splitter_bridge_data[51:44] ==  8'hff)   ?
        // {12'h0, splitter_bridge_data[43:16]}    :
        // {4'h0, splitter_bridge_data[51:16]};

    // ------ Sequential Logic ------ //
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state               <=  NOC_RST;
            counter             <=  0;
            offset              <=  0;
            msg_type            <=  0;
            payload             <=  0;
            mshr                <=  0;
            addr                <=  0;
            data_sz             <=  0;
            chipid              <=  0;
            srcx                <=  0;
            srcy                <=  0;
            
            msg_data_val        <=  0;
            // msg_data_buf[0]     <=  0;
            // msg_data_buf[1]     <=  0;
            // msg_data_buf[2]     <=  0;
            // msg_data_buf[3]     <=  0;
            // msg_data_buf[4]     <=  0;
            // msg_data_buf[5]     <=  0;
            // msg_data_buf[6]     <=  0;
            // msg_data_buf[7]     <=  0;
            axi_read_data_reg   <= 0;
        end
        else begin
            state   <=  state_next;

            if (counter_rst) begin
                counter <=  0;
            end
            else if (counter_en) begin
                counter <=  counter + 1;
            end

            if (offset_rst) begin
                offset <=  0;
            end
            else if (offset_en) begin
                offset <=  offset + 1;
            end

            if (state   ==  NOC_IDLE && splitter_bridge_go) begin
                msg_type    <=  splitter_bridge_data[`MSG_TYPE];
                payload <=  splitter_bridge_data[`MSG_LENGTH];
                mshr    <=  splitter_bridge_data[`MSG_MSHRID];
            end

            if (state   ==  NOC_IN_HEADER_1 && splitter_bridge_go && (rd || wr)) begin
                addr    <=  addr_remapped;
                data_sz <=  splitter_bridge_data[`MSG_DATA_SIZE_];
            end

            if (state   ==  NOC_IN_HEADER_2 && splitter_bridge_go) begin
                chipid  <=  splitter_bridge_data[`MSG_SRC_CHIPID_];
                srcx    <=  splitter_bridge_data[`MSG_SRC_X_];
                srcy    <=  splitter_bridge_data[`MSG_SRC_Y_];
            end

            if (state   ==  NOC_IN_DATA && splitter_bridge_go) begin
                msg_data_val[counter[2:0]]  <=  1'b1;
                msg_data_buf[counter[2:0]]  <=  splitter_bridge_data;
            end
            // else if (cache_re_f) begin
            //     msg_data_val[offset_f]      <=  1'b1;
            //     msg_data_buf[offset_f]      <=  buffer_core_data;
            // end
            else if (state  ==  NOC_IDLE) begin
                msg_data_val                <=  0;
            end

            if (state == AXI_READ_DATA) begin
                axi_read_data_reg <= m_axi_ctrl_rdata;
            end
        end
    end

    // ------ FSM Transitions ------ //
    // 
    always @* begin
        state_next  =   state;

        case    (state)
            NOC_RST: begin
                state_next  =   NOC_IDLE;
            end
            NOC_IDLE: begin
                if (splitter_bridge_go) begin
                    state_next  =   NOC_IN_HEADER_1;
                    // Do not know if it's a valid MSG yet.
                end
            end
            NOC_IN_HEADER_1: begin
                // Check if it's a valid LOAD/STORE request.
                if (rd || wr) begin
                    if (splitter_bridge_go) begin
                        state_next  =   NOC_IN_HEADER_2;
                    end
                end
                else begin
                    if (payload == 8'd0) begin
                        state_next  =   NOC_IDLE;
                    end
                    else begin
                        state_next  =   NOC_THROWING;
                    end
                end
            end
            NOC_IN_HEADER_2: begin
                if (splitter_bridge_go) begin
                    if (wr) begin
                        state_next  =   NOC_IN_DATA;
                    end
                    else begin
                        // if (cache_lock_status && cache_core_rdy) begin
                        //     state_next  =   NOC_OUT_HEADER;
                        // end
                        // else begin
                            state_next  =   NOC_WAITING;
                        // end
                    end
                end
            end
            // Write on AXI-4 Lite Protocol happens
            NOC_IN_DATA: begin
                // Transitions to the next state only if the AXI follower 
                // sends awready and wready signal high
                // Plus the first two are original conditions from NOC_SD_BRIDGE
                if (splitter_bridge_go && counter == payload - 3 && m_axi_ctrl_awready && m_axi_ctrl_wready) begin
                    state_next  =   NOC_WAITING;
                end
            end
            NOC_WAITING: begin
                // if (cache_lock_status && cache_core_rdy) begin

                // Only transitions to the next state if the write response is valid
                // and the response is 2'b00 which means OKAY
                // Plus the first two are original conditions from NOC_SD_BRIDGE
                if ((wr  &&   offset  ==  payload - 3 && m_axi_ctrl_bvalid && m_axi_ctrl_bresp == 2'b00)) begin
                    state_next  =   NOC_OUT_HEADER;
                end
                else if ((rd && m_axi_ctrl_arready)) begin
                    state_next =    AXI_READ_DATA;
                end
                // TODO: Figure out a better way to handle non-okay write responses
                // If not a valid response, re-try to send the signal?
                else if (wr  &&   offset  ==  payload - 3 && m_axi_ctrl_bvalid && m_axi_ctrl_bresp != 2'b00) begin
                    state = NOC_IN_DATA;
                end
                // end
            end
            AXI_READ_DATA: begin
                if (rd && m_axi_ctrl_rvalid && m_axi_ctrl_rresp == 2'b00) begin
                    state_next = NOC_OUT_HEADER;
                end
                // If the response is NOT valid, re-requests read data
                else if ((rd && m_axi_ctrl_rvalid && m_axi_ctrl_rresp != 2'b00)) begin
                    state_next = NOC_WAITING;
                end
            end
            NOC_THROWING: begin
                if (splitter_bridge_go && counter == payload - 1) begin
                    state_next  =   NOC_IDLE;
                end
            end
            NOC_OUT_HEADER: begin
                if (bridge_splitter_go) begin
                    if (resp_payload    ==  0) begin
                        state_next  =   NOC_IDLE;
                    end
                    else begin
                        state_next  =   NOC_OUT_DATA;
                    end
                end
            end
            NOC_OUT_DATA: begin
                if (bridge_splitter_go && counter == resp_payload - 1) begin
                    state_next  =   NOC_IDLE;
                end
            end
        endcase
    end

    always @* begin
        bridge_splitter_rdy     =   1'b0;
        bridge_splitter_val     =   1'b0;
        bridge_splitter_data    =   0;
        // core_cache_we           =   wr;
        // core_cache_addr         =   addr[`PHY_BLOCK_BITS];
        counter_en              =   1'b0;
        counter_rst             =   1'b0;
        m_axi_ctrl_awaddr       =   0;
        m_axi_ctrl_awvalid      =   1'b0;
        m_axi_ctrl_wdata        =   0;
        m_axi_ctrl_wvalid       =   0;
        m_axi_ctrl_wstrb        =   0;
        m_axi_ctrl_bready       =   1'b0;
        m_axi_ctrl_araddr       =   0;
        m_axi_ctrl_arvalid      =   1'b0;
        m_axi_ctrl_rready       =   1'b0;
        case    (state)
            NOC_IDLE: begin
                bridge_splitter_rdy =   1'b1;
                counter_rst         =   1'b1;
            end
            NOC_IN_HEADER_1: begin
                bridge_splitter_rdy =   rd || wr;
                counter_rst         =   1'b1;
                //core_cache_addr     =   addr_remapped[`PHY_BLOCK_BITS];
            end
            NOC_IN_HEADER_2: begin
                bridge_splitter_rdy =   1'b1;
                counter_rst         =   1'b1;
            end
            NOC_IN_DATA: begin
                bridge_splitter_rdy =   1'b1;
                counter_en          =   splitter_bridge_go;
                // Write Address Channel
                m_axi_ctrl_awaddr   = addr;
                m_axi_ctrl_awvalid  = 1'b1;
                // Write Data Channel
                m_axi_ctrl_wdata    = payload;
                m_axi_ctrl_wvalid   = 1'b1;
                m_axi_ctrl_wstrb    = {`VORTEX_AXI_CTRL_DATA_WIDTH/8{1'b1}};
                // Write Response Channel
                m_axi_ctrl_bready   = 1'b1;
            end
            NOC_WAITING: begin
                if (wr) begin
                    m_axi_ctrl_bready   = 1'b1;
                end
                // Read signals set here so that data can be built in OUT_HEADER
                // And the data is sent back to the NoC at NOC_OUT_DATA
                else if (rd) begin
                    // Read Address Channel
                    m_axi_ctrl_araddr  = addr;
                    m_axi_ctrl_arvalid = 1'b1;
                    // Read Data Channel
                    m_axi_ctrl_rready  = 1'b1;
                end
                counter_rst            =   1'b1;
            end
            // NEW STATE FOR RDATA COLLECTION
            AXI_READ_DATA: begin
                m_axi_ctrl_rready      = 1'b1;
                
            end
            NOC_THROWING: begin
                bridge_splitter_rdy =   1'b1;
                counter_en          =   splitter_bridge_go;
            end
            NOC_OUT_HEADER: begin
                bridge_splitter_val     =   1'b1;
                counter_rst             =   1'b1;
                bridge_splitter_data    =   resp_header;
            end
            NOC_OUT_DATA: begin
                bridge_splitter_val     =   msg_data_val[counter[2:0] & actual_resp_payload_mask];
                bridge_splitter_data    =   msg_data_buf[counter[2:0] & actual_resp_payload_mask];
                counter_en              =   bridge_splitter_go;
            end
        endcase
    end

    // // ------ Cache & Buffer ------ //
    // localparam  CB_IDLE         =   3'h0;
    // localparam  CB_BUFFER2CACHE =   3'h1;
    // localparam  CB_CACHE2BUFFER =   3'h2;
    // localparam  CB_UNLOCK       =   3'h3;

    // reg     [2:0]   cb_state;
    // reg     [2:0]   cb_state_next;

    // always @(posedge clk or posedge rst) begin
    //     if (rst) begin
    //         cb_state    <=  CB_IDLE;
    //         cache_re_f  <=  1'b0;
    //         offset_f    <=  0;
    //     end
    //     else begin
    //         cb_state    <=  cb_state_next;
    //         cache_re_f  <=  core_buffer_ce &&  ~core_buffer_wr;
    //         offset_f    <=  offset;
    //     end
    // end

    // always @* begin
    //     cb_state_next   =   cb_state;

    //     case (cb_state)
    //         CB_IDLE:    begin
    //             if (cache_lock_acquire) begin
    //                 if (wr) begin
    //                     cb_state_next   =   CB_BUFFER2CACHE;
    //                 end
    //                 else begin
    //                     cb_state_next   =   CB_CACHE2BUFFER;
    //                 end
    //             end
    //         end
    //         CB_BUFFER2CACHE:    begin
    //             if (offset  ==  payload - 3 && core_buffer_ce) begin
    //                 cb_state_next   =   CB_UNLOCK;
    //             end
    //         end
    //         CB_CACHE2BUFFER:    begin
    //             if (offset  ==  actual_resp_payload_mask && core_buffer_ce) begin
    //                 cb_state_next   =   CB_UNLOCK;
    //             end
    //         end
    //         CB_UNLOCK:  begin
    //             if (cache_lock_release    &&  ~cache_lock_status) begin
    //                 cb_state_next   =   CB_IDLE;
    //             end
    //         end
    //     endcase
    // end

    // always @* begin
    //     core_buffer_ce          =   1'b0;
    //     core_buffer_wr          =   1'b0;
    //     core_buffer_data        =   0;
    //     // cache_lock_acquire      =   1'b0;
    //     // cache_lock_release      =   1'b0;
    //     offset_en               =   1'b0;
    //     offset_rst              =   1'b0;

    //     case (cb_state)
    //         CB_IDLE:    begin
    //             cache_lock_acquire  =   (state  ==  NOC_IN_HEADER_1)    &&  splitter_bridge_go;
    //             offset_rst          =   1'b1;
    //         end
    //         CB_BUFFER2CACHE:    begin
    //             cache_lock_acquire  =   ~cache_lock_status;
    //             if (cache_lock_status   &&  cache_core_rdy) begin
    //                 core_buffer_ce      =   msg_data_val[offset];
    //                 core_buffer_wr      =   1'b1;
    //                 core_buffer_data    =   msg_data_buf[offset];
    //                 offset_en           =   msg_data_val[offset];
    //             end
    //         end
    //         CB_CACHE2BUFFER:    begin
    //             cache_lock_acquire  =   ~cache_lock_status;
    //             if (cache_lock_status   &&  cache_core_rdy) begin
    //                 core_buffer_ce      =   1'b1;
    //                 core_buffer_wr      =   1'b0;
    //                 offset_en           =   1'b1;
    //             end
    //         end
    //         CB_UNLOCK:  begin
    //             cache_lock_release  =   1'b1;
    //         end
    //     endcase
    // end

    // always @* begin
    //     core_buffer_addr    =   
    //         {{(32 - `SD_BLOCK_OFFSET_WIDTH - `CACHE_ENTRY_WIDTH){1'b0}},
    //             cache_core_entry, addr[`SD_BLOCK_OFFSET_WIDTH-1:0]};

    //     case (data_sz)
    //         `MSG_DATA_SIZE_1B: begin
    //             core_buffer_sz          =   2'd0;
    //         end
    //         `MSG_DATA_SIZE_2B: begin
    //             core_buffer_sz          =   2'd1;
    //             core_buffer_addr[0]     =   1'b0;
    //         end
    //         `MSG_DATA_SIZE_4B: begin
    //             core_buffer_sz          =   2'd2;
    //             core_buffer_addr[1:0]   =   2'b0;
    //         end
    //         `MSG_DATA_SIZE_8B: begin
    //             core_buffer_sz          =   2'd3;
    //             core_buffer_addr[2:0]   =   3'b0;
    //         end
    //         `MSG_DATA_SIZE_16B: begin
    //             core_buffer_sz          =   2'd3;
    //             core_buffer_addr[3:0]   =   {offset[0],         3'b0};
    //         end
    //         `MSG_DATA_SIZE_32B: begin
    //             core_buffer_sz          =   2'd3;
    //             core_buffer_addr[4:0]   =   {offset[1:0],       3'b0};
    //         end
    //         `MSG_DATA_SIZE_64B: begin
    //             core_buffer_sz          =   2'd3;
    //             core_buffer_addr[5:0]   =   {offset[2:0],       3'b0};
    //         end
    //         default: begin
    //             core_buffer_sz          =   2'd3;
    //             core_buffer_addr[5:0]   =   {offset[2:0],       3'b0};
    //         end
    //     endcase
    // end
endmodule