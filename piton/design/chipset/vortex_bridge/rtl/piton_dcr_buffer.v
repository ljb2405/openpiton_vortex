`include "openpiton_vortex/piton/design/chipset/vortex_bridge/rtl/piton_vortex_define.vh"

// TODO: Not the most performant version as it does not output the input immediately
module piton_dcr_buffer #(
    parameter VX_DCR_ADDR_WIDTH = 8,
    parameter VX_DCR_DATA_WIDTH = 32
)(
    // Clock + Reset
    input  wire                                 clk,
    input  wire                                 rst,

    // Input from core control of DCR messages to Vortex
    input wire                                  buffer_wr_valid,
    input wire [VX_DCR_ADDR_WIDTH-1:0]          buffer_wr_addr,
    input wire [VX_DCR_DATA_WIDTH-1:0]          buffer_wr_data,

    // Output to Vortex Buffer
    output wire                                 buffer_dcr_wr_valid,
    output wire [VX_DCR_ADDR_WIDTH-1:0]         buffer_dcr_wr_addr,
    output wire [VX_DCR_DATA_WIDTH-1:0]         buffer_dcr_wr_data,
    
    // Handshake protocol to send valid data to Vortex
    // Valid signal replaced with buffer_dcr_wr_valid
    input wire                                  vx_buffer_rdy,
    // Control Signal to core_ctrl
    output wire                                 buffer_full
);

/* Variables */
reg [VX_DCR_ADDR_WIDTH-1:0] msg_addr_buf [7:0];
reg [VX_DCR_DATA_WIDTH-1:0] msg_data_buf [7:0];

reg [3:0] input_pointer;
reg [3:0] output_pointer;
reg [1:0] counter;

reg       vx_buf_rdy_sync_0;
reg       vx_buf_rdy_sync_1;

wire buffer_empty;
wire buf_send;

/* Sequential Logic */

always @(posedge clk or posedge rst) begin
    if (rst) begin
        input_pointer <= 0;
        output_pointer <= 0;

        msg_addr_buf[0] <= 0;
        msg_addr_buf[1] <= 0;
        msg_addr_buf[2] <= 0;
        msg_addr_buf[3] <= 0;
        msg_addr_buf[4] <= 0;
        msg_addr_buf[5] <= 0;
        msg_addr_buf[6] <= 0;
        msg_addr_buf[7] <= 0;

        msg_data_buf[0] <= 0;
        msg_data_buf[1] <= 0;
        msg_data_buf[2] <= 0;
        msg_data_buf[3] <= 0;
        msg_data_buf[4] <= 0;
        msg_data_buf[5] <= 0;
        msg_data_buf[6] <= 0;
        msg_data_buf[7] <= 0;

        vx_buf_rdy_sync_0 <= 0;
        vx_buf_rdy_sync_1 <= 0;

        counter <= 0;
    end
    else begin
        if (buffer_wr_valid) begin
            msg_addr_buf[input_pointer[2:0]] <= buffer_wr_addr;
            msg_data_buf[input_pointer[2:0]] <= buffer_wr_data;

            input_pointer <= input_pointer + 1'b1;
        end

        if (buffer_dcr_wr_valid) begin
            counter <= counter + 1;
            //output_pointer <= output_pointer + 1'b1;
        end

        if (buffer_dcr_wr_valid && counter == 2'b10) begin
            output_pointer <= output_pointer + 1'b1;
            counter <= 0;
        end

        vx_buf_rdy_sync_0 <= vx_buffer_rdy;
        vx_buf_rdy_sync_1 <= vx_buf_rdy_sync_0;
    end
end

/* Combinational Logic */
assign buffer_empty = (input_pointer == output_pointer);
assign buffer_full = (input_pointer[2:0] == output_pointer[2:0]) & (input_pointer[3] != output_pointer[3]);
// assign buf_send = (buffer_dcr_wr_valid && vx_buf_rdy_sync_1);

assign buffer_dcr_wr_valid = (vx_buf_rdy_sync_1 && !buffer_empty) ? 1'b1 : 1'b0;
assign buffer_dcr_wr_addr = msg_addr_buf[(output_pointer[2:0])];
assign buffer_dcr_wr_data = msg_data_buf[(output_pointer[2:0])];
endmodule