`include "openpiton_vortex/piton/design/chipset/vortex_bridge/rtl/piton_vortex_define.vh"
//TODO: implement buffer_full logic

module piton_vortex_core_ctrl #(
    parameter VX_DCR_ADDR_WIDTH = 8,
	parameter VX_DCR_DATA_WIDTH = 32
)(
    // Clock + Reset
    input  wire                         clk,
    input  wire                         rst,

    // NOC interface
    // From NOC2(mem-req)
    input  wire                         splitter_bridge_val,
    input  wire [`NOC_DATA_BITS]        splitter_bridge_data,
    output reg                          bridge_splitter_rdy,
    // Goes to NOC3(mem-resp)
    output reg                          bridge_splitter_val,
    output reg  [`NOC_DATA_BITS]        bridge_splitter_data,
    input  wire                         splitter_bridge_rdy,

    // Output to DCR Buffer
    output wire                             buffer_wr_valid,
    output reg [`VX_DCR_ADDR_WIDTH-1:0]     buffer_wr_addr,
    output reg [`VX_DCR_DATA_WIDTH-1:0]     buffer_wr_data,

    input wire                              buffer_full;
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
    // TODO: Mem-Response prob not needed since there isn't any reading/loading into the memory
    localparam  NOC_OUT_DATA            = 4'h7;

    // ------ Signals Declarations ------ //
    reg [3:0]   state;
    reg [3:0]   state_next;

    reg [`MSG_TYPE]                     msg_type;
    reg [`MSG_LENGTH]                   payload;
    reg [`MSG_MSHRID]                   mshr;
    reg [`VX_DCR_ADDR_WIDTH-1:0]        addr;
    reg [`MSG_DATA_SIZE_]               data_sz;
    reg [`MSG_SRC_CHIPID_]              chipid;
    reg [`MSG_SRC_X_]                   srcx;
    reg [`MSG_SRC_Y_]                   srcy;

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
        wire    [7:0]   resp_payload = wr       ? 8'd0 // this should be hitting
            : (data_sz == `MSG_DATA_SIZE_1B)    ? 8'd1
            : (data_sz == `MSG_DATA_SIZE_2B)    ? 8'd1
            : (data_sz == `MSG_DATA_SIZE_4B)    ? 8'd1
            : (data_sz == `MSG_DATA_SIZE_8B)    ? 8'd1
            : (data_sz == `MSG_DATA_SIZE_16B)   ? 8'd2
            : (data_sz == `MSG_DATA_SIZE_32B)   ? 8'd4
            : (data_sz == `MSG_DATA_SIZE_64B)   ? 8'd8
            :                                     8'd0;
    `endif /* `ifndef VORTEXCTRL_TEST */

    wire    [2:0]   actual_resp_payload_mask    =   wr  ?   3'h0 // this should be hitting
        : (data_sz  ==  `MSG_DATA_SIZE_1B)              ?   3'h0
        : (data_sz  ==  `MSG_DATA_SIZE_2B)              ?   3'h0
        : (data_sz  ==  `MSG_DATA_SIZE_4B)              ?   3'h0
        : (data_sz  ==  `MSG_DATA_SIZE_8B)              ?   3'h0
        : (data_sz  ==  `MSG_DATA_SIZE_16B)             ?   3'h1
        : (data_sz  ==  `MSG_DATA_SIZE_32B)             ?   3'h3
        : (data_sz  ==  `MSG_DATA_SIZE_64B)             ?   3'h7 
        :                                                   3'h0;

    wire    [7:0]   resp_msg_type   = store   ? `MSG_TYPE_STORE_MEM_ACK
                                    : ncstore ? `MSG_TYPE_NC_STORE_MEM_ACK
                                    : load    ? `MSG_TYPE_LOAD_MEM_ACK // shouldnt hit
                                    : ncload  ? `MSG_TYPE_NC_LOAD_MEM_ACK // shouldnt hit for the time being
                                    :           `MSG_TYPE_ERROR;

    `ifndef VORTEXCTRL_TEST
        wire    [3:0]   resp_fbits  =   4'h0;
    `else /* `ifndef VORTEXCTRL_TEST */
        wire    [3:0]   resp_fbits  =   4'ha;
    `endif /* `ifndef VORTEXCTRL_TEST */

    // Response to the NOC
    wire    [`NOC_DATA_BITS]    resp_header =
        {chipid, srcx, srcy, resp_fbits,
            resp_payload,   resp_msg_type,  mshr,   6'h0};

    wire    [`VX_DCR_ADDR_WIDTH-1:0]    addr_remapped   = splitter_bridge_data[23:16];

    // ------ Sequential Logic ------ //
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state               <=  NOC_RST;
            offset              <=  0;
            msg_type            <=  0;
            payload             <=  0;
            mshr                <=  0;
            addr                <=  0;
            data_sz             <=  0;
            chipid              <=  0;
            srcx                <=  0;
            srcy                <=  0;

            buffer_wr_addr      <=  0;
            buffer_wr_data      <=  0;
        end
        else begin
            state   <=  state_next;

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
                buffer_wr_data  <=  splitter_bridge_data;

            end
            else if (state  ==  NOC_IDLE) begin

            end

            else if (state == NOC_OUT_HEADER) begin

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
                        state_next  =   NOC_WAITING;
                    end
                end
            end
            NOC_IN_DATA: begin
                // Transitions to the next state assuming DCR received the signal properly
                // Plus the first two are original conditions from NOC_SD_BRIDGE
                if (splitter_bridge_go /*&& counter == payload - 3*/) begin
                    state_next  =   NOC_OUT_HEADER;
                end
            end
            NOC_WAITING: begin
                // if (cache_lock_status && cache_core_rdy) begin

                // Only transitions to the next state if the write response is valid
                // and the response is 2'b00 which means OKAY
                // Plus the first two are original conditions from NOC_SD_BRIDGE
                // if ((wr  &&   offset  ==  payload - 3 && m_axi_ctrl_bvalid && m_axi_ctrl_bresp == 2'b00)) begin
                //     state_next  =   NOC_OUT_HEADER;
                //  end
                // else 
                //if (rd) begin
                state_next =  NOC_OUT_HEADER;
                //end
            end
            
            NOC_THROWING: begin
                if (splitter_bridge_go) begin
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
                if (bridge_splitter_go) begin
                    state_next  =   NOC_IDLE;
                end
            end
        endcase
    end

    /* FSM State Control Logic */
    always @* begin
        bridge_splitter_rdy     =   1'b0;
        bridge_splitter_val     =   1'b0;
        bridge_splitter_data    =   0;

        case    (state)
            NOC_IDLE: begin
                bridge_splitter_rdy =   1'b1;
            end
            NOC_IN_HEADER_1: begin
                bridge_splitter_rdy =   rd || wr;
            end
            NOC_IN_HEADER_2: begin
                bridge_splitter_rdy =   1'b1;
            end
            NOC_IN_DATA: begin
                bridge_splitter_rdy =   1'b1;

            end
            NOC_WAITING: begin
            end
            NOC_THROWING: begin
                bridge_splitter_rdy =   1'b1;
            end
            NOC_OUT_HEADER: begin
                bridge_splitter_val     =   1'b1;
                bridge_splitter_data    =   resp_header;
            end
            NOC_OUT_DATA: begin
                bridge_splitter_val     =   1'b1;
                bridge_splitter_data    =   0;
                counter_en              =   bridge_splitter_go;
            end
        endcase
    end

endmodule