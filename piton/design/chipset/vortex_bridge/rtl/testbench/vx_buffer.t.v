`include "openpiton_vortex/piton/design/chipset/vortex_bridge/rtl/piton_vortex_define.vh"
//`include "openpiton_vortex/piton/design/chipset/vortex_bridge/rtl/piton_vortex_tb_define.vh"
`timescale 1ns / 1ps 

// Loads memory of test inputs from the vmh file
`define LOAD_MEMORY(NAME)                                                   \
    begin                                                                   \
        $display("\nLoading Memory: %s", (NAME));                           \
        $display("----------------------------");                           \
        #1;                                                                 \
        $readmemh({"openpiton_vortex/piton/design/chipset/vortex_bridge/rtl/testbench/memory/", \
        (NAME), ".vmh"}, data_mem, 0, 7);                                   \
    end #0

// Inputs one entry into the buffer
`define INPUT_BUFFER(VAL)                                                   \
    begin                                                                   \
        #10; \
        // while (!output_rdy) begin \
        // #1; \
        // end                                                                 \
        input_valid = 1;                                                    \
        addr_input = {5'b0, counter};                                       \
        data_input = data_mem[counter];                                     \
        #1;                                                                 \
        input_valid = 0;                                                    \
        counter = counter + 1;                                              \
        //$display("OUTPUT POINTER: %h", debug_output_pointer); \
    end #0

// Outputs and asserts one entry out of the buffer
`define OUTPUT_BUFFER(VAL)                                                  \
    begin                                                                   \
        #10;                                                                \
        input_busy = 0; \
        // #1; \
        // #1; \                                                              \
        // #1;                                                                   \
        //$display("OUTPUT POINTER: %h", debug_output_pointer); \
        if (data_mem[out_counter] !== data_output) begin                     \
            $display("\tBUFFER OUTPUT ASSERTION DATA FAILED: %h != %h",     \
            data_mem[out_counter], data_output);                            \
        end                                                                 \
        if (out_counter !== addr_output) begin                               \
            $display("\tBUFFER OUTPUT ASSERTION ADDR FAILED: %h != %h",     \
            out_counter, addr_output);                                      \
        end                                                                 \
        #1;                                                                  \
        input_busy = 1; \
        #1; \
        #1; \
        if (output_valid !== 0) begin                                        \
            $display("\tBUFFER OUTPUT VALID DIDN'T GO LOW");                \
        end                                                                 \
        out_counter = out_counter + 1;                                      \                                                                
    end #0

// Asserts value
`define ASSERT(SIGNAL, VAL)                                                 \
    begin                                                                   \
        if ((SIGNAL) != (VAL)) begin                                        \
            $display("\tASSERTION FAILED: %h != %h", SIGNAL, VAL);          \
        end                                                                 \
    end #0

module tb_piton_dcr_buffer ();

// Variable Declarations
reg clk;
reg rst;
reg [2:0] counter;
reg [2:0] out_counter;
reg [`VX_DCR_DATA_WIDTH-1:0] data_mem [7:0];
wire [2:0] debug_output_pointer;

reg input_valid;
reg [`VX_DCR_ADDR_WIDTH-1:0] addr_input;
reg [`VX_DCR_DATA_WIDTH-1:0] data_input;

reg input_busy;

wire output_rdy;
wire output_valid;
wire [`VX_DCR_ADDR_WIDTH-1:0] addr_output;
wire [`VX_DCR_DATA_WIDTH-1:0] data_output;
wire buf_full;

vx_dcr_buffer dut (
    // Clock + Reset
    .clk(clk),
    .rst(rst),

    // Input from core control of DCR messages to Vortex
    .dcr_buffer_wr_valid(input_valid),
    .dcr_buffer_wr_addr(addr_input),
    .dcr_buffer_wr_data(data_input),

    // Output to Vortex Buffer
    .dcr_wr_valid(output_valid),
    .dcr_wr_addr(addr_output),
    .dcr_wr_data(data_output),

    // Handshake protocol to send valid data to Vortex
    // Valid signal replaced with buffer_dcr_wr_valid
    .dcr_busy(input_busy),

    // Control Signal to core_ctrl
    .vx_buffer_rdy(output_rdy)
);

always begin
    #0.5 clk = ~clk;
end

initial begin
    $dumpfile("vx_buf_test.vcd");
    $dumpvars;
    clk = 0;
    counter = 0;
    out_counter = 0;
    rst = 0;
    input_busy = 1;
    input_valid = 0;

    `LOAD_MEMORY("buffer_data");

    // Reset
    rst = 1;
    #10000 rst = 0;

    // Test Cases
    // Test Case: Verify Initial State
    $display("\nTest Case: Verify Initial State");
    `ASSERT(output_valid, 0);
    `ASSERT(data_output, 0);
    `ASSERT(addr_output, 0);
    `ASSERT(output_rdy, 1);

    // Test Case: Input and Output 1 value
    $display("\nTest Case: Input and Output 1 value");
    `INPUT_BUFFER();
    `OUTPUT_BUFFER();

    counter = 0;
    out_counter = 0;

    // Test Case: Full Buffer Condition
    $display("\nTest Case: Full Buffer Condition");
    `INPUT_BUFFER();
    `INPUT_BUFFER();
    `INPUT_BUFFER();
    `INPUT_BUFFER();
    `INPUT_BUFFER();
    `INPUT_BUFFER();
    `INPUT_BUFFER();
    `INPUT_BUFFER();
    `ASSERT(buf_full, 1);

    // Test Case: Verify Buffer Empties Correctly
    $display("\nTest Case: Verify Buffer Empties Correctly");
    `OUTPUT_BUFFER();
    `OUTPUT_BUFFER();
    `OUTPUT_BUFFER();
    `OUTPUT_BUFFER();
    `OUTPUT_BUFFER();
    `OUTPUT_BUFFER();
    `OUTPUT_BUFFER();
    `OUTPUT_BUFFER();

    // Test Case: Full Use Case
    // 4 inputs, 2 outputs, 3 inputs, 5 outputs
    $display("\n Test Case: Full Use Case");
    `INPUT_BUFFER();
    `INPUT_BUFFER();
    `INPUT_BUFFER();
    `INPUT_BUFFER();

    `OUTPUT_BUFFER();
    `OUTPUT_BUFFER();

    `INPUT_BUFFER();
    `INPUT_BUFFER();
    `INPUT_BUFFER();

    `OUTPUT_BUFFER();
    `OUTPUT_BUFFER();
    `OUTPUT_BUFFER();
    `OUTPUT_BUFFER();
    `OUTPUT_BUFFER();

    `INPUT_BUFFER();
    `OUTPUT_BUFFER();
    `INPUT_BUFFER();
    `OUTPUT_BUFFER();
    $finish;
end

endmodule
