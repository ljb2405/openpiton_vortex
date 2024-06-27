`include "openpiton_vortex/piton/design/chipset/vortex_bridge/rtl/piton_vortex_define.vh"

module piton_dcr_buffer #(
    parameter VX_DCR_ADDR_WIDTH = 8,
	parameter VX_DCR_DATA_WIDTH = 32
)(
    // Clock + Reset
    input  wire                                 clk,
    input  wire                                 rst,

    // Input from Piton Buffer
    input wire                                  dcr_buffer_wr_valid,
    input wire [`VX_DCR_ADDR_WIDTH-1:0]         dcr_buffer_wr_addr,
    input wire [`VX_DCR_DATA_WIDTH-1:0]         dcr_buffer_wr_data,

    // Output to Vortex 
    output wire                                 dcr_wr_valid,
    output wire [`VX_DCR_ADDR_WIDTH-1:0]        dcr_wr_addr,
    output wire [`VX_DCR_DATA_WIDTH-1:0]        dcr_wr_data,
    
    // Handshake protocol to send valid data to Vortex
    // Valid signal replaced with dcr_buffer_wr_valid
    input wire                                  dcr_busy,
    // Ready Signal to Piton buffer
    output wire                                 vx_buffer_rdy;
);

/* Variables */
reg [`VX_DCR_ADDR_WIDTH-1:0] msg_vx_addr_buf [7:0];
reg [`VX_DCR_DATA_WIDTH-1:0] msg_vx_data_buf [7:0];

reg [2:0] input_pointer;
reg [2:0] output_pointer;

wire buffer_empty;
wire buffer_full;
wire buf_receive;

reg piton_buffer_valid_req_sync_0;
reg piton_buffer_valid_req_sync_1;

/* Sequential Logic */

always (posedge rst or posedge clk) begin
    if (rst) begin
        input_pointer <= 0;
        output_pointer <= 0;

        msg_vx_addr_buf[1] <= 0;
        msg_vx_addr_buf[0] <= 0;
        msg_vx_addr_buf[2] <= 0;
        msg_vx_addr_buf[3] <= 0;
        msg_vx_addr_buf[4] <= 0;
        msg_vx_addr_buf[5] <= 0;
        msg_vx_addr_buf[6] <= 0;
        msg_vx_addr_buf[7] <= 0;

        msg_vx_data_buf[0] <= 0;
        msg_vx_data_buf[1] <= 0;
        msg_vx_data_buf[2] <= 0;
        msg_vx_data_buf[3] <= 0;
        msg_vx_data_buf[4] <= 0;
        msg_vx_data_buf[5] <= 0;
        msg_vx_data_buf[6] <= 0;
        msg_vx_data_buf[7] <= 0;

        piton_buffer_valid_req_sync_0 <= 0;
        piton_buffer_valid_req_sync_1 <= 0;
    end
    else begin
        if (buf_receive) begin
            msg_vx_addr_buf[input_pointer] <= buffer_wr_addr;
            msg_vx_data_buf[input_pointer] <= buffer_wr_data;

             input_pointer <= input_pointer + 1;
        end

        // TODO: improve the logic on when to increase the output pointer
        // Seems fishy to just do it for one cycle as it crosses clock domain
        // Check clock freq of Piton to ensure if its going lower to higher or vice versa
        if (dcr_wr_valid) begin
             output_pointer <= output_pointer + 1;
        end

        // Valid Signal Synchronization
        piton_buffer_valid_req_sync_0 <= dcr_buffer_wr_valid;
        piton_buffer_valid_req_sync_1 <= piton_buffer_valid_req_sync_0;
    end
end

/* Combinational Logic */
assign buffer_empty = (input_pointer == output_pointer);
assign buffer_full = (input_pointer == output_pointer + 1);

assign buf_receive = (piton_buffer_valid_req_sync_1 && vx_buffer_rdy);

assign vx_buffer_rdy = ~buffer_full ? 1'b1 : 1'b0;

assign dcr_wr_valid = (~dcr_busy && ~buffer_empty);
assign dcr_wr_addr = msg_vx_addr_buf[output_pointer];
assign dcr_wr_data = msg_vx_data_buf[output_pointer];
endmodule
