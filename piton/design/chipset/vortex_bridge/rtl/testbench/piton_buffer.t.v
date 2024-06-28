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
    end

// Inputs one entry into the buffer
`define INPUT_BUFFER(VAL)                                                   \
    begin                                                                   \
        #10;                                                                \
        input_valid = 1;                                                    \
        addr_input = {5'b0, counter};                                       \
        data_input = data_mem[counter];                                     \
        #1;                                                                 \
        input_valid = 0;                                                    \
        counter = counter + 1;                                              \
    end

// Outputs and asserts one entry out of the buffer
`define OUTPUT_BUFFER(VAL)                                                  \
    begin                                                                   \
        #10;                                                                \
        output_rdy = 1;                                                     \
        while (output_valid != 1) begin                                     \
            #1;                                                             \
        end                                                                 \
        output_rdy = 0;                                                     \
        if (data_mem[out_counter] != data_output) begin                     \
            $display("\tBUFFER OUTPUT ASSERTION DATA FAILED: %h != %h",     \
            data_mem[out_counter], data_output);                            \
        end                                                                 \
        if (out_counter != addr_output) begin                               \
            $display("\tBUFFER OUTPUT ASSERTION ADDR FAILED: %h != %h",     \
            out_counter, addr_output);                                      \
        end                                                                 \
        @(posedge clk);                                                     \
        if (output_valid != 0) begin                                        \
            $display("\tBUFFER OUTPUT VALID DIDN'T GO LOW");                \
        end                                                                 \
        if (data_mem[out_counter] != data_output) begin                     \
            $display("\tBUFFER OUTPUT RE-ASSERTION DATA FAILED: %h != %h",  \
            data_mem[out_counter], data_output);                            \
        end                                                                 \
        if (out_counter != addr_output) begin                               \
            $display("\tBUFFER OUTPUT RE-ASSERTION ADDR FAILED: %h != %h",  \
            out_counter, addr_output);                                      \
        end                                                                 \
        out_counter = out_counter + 1;                                      \
    end

// Asserts value
`define ASSERT(SIGNAL, VAL)                                                 \
    begin                                                                   \
        if ((SIGNAL) != (VAL)) begin                                        \
            $display("\tASSERTION FAILED: %h != %h", SIGNAL, VAL);          \
        end                                                                 \
    end

module tb_piton_dcr_buffer ();

// Variable Declarations
reg clk;
reg rst;
reg [2:0] counter;
reg [2:0] out_counter;
reg [`VX_DCR_DATA_WIDTH-1:0] data_mem [7:0];

reg input_valid;
reg [`VX_DCR_ADDR_WIDTH-1:0] addr_input;
reg [`VX_DCR_DATA_WIDTH-1:0] data_input;
reg output_rdy;

wire output_valid;
wire [`VX_DCR_ADDR_WIDTH-1:0] addr_output;
wire [`VX_DCR_DATA_WIDTH-1:0] data_output;
wire buf_full;

piton_dcr_buffer dut (
    // Clock + Reset
    .clk(clk),
    .rst(rst),

    // Input from core control of DCR messages to Vortex
    .buffer_wr_valid(input_valid),
    .buffer_wr_addr(addr_input),
    .buffer_wr_data(data_input),

    // Output to Vortex Buffer
    .buffer_dcr_wr_valid(output_valid),
    .buffer_dcr_wr_addr(addr_output),
    .buffer_dcr_wr_data(data_output),

    // Handshake protocol to send valid data to Vortex
    // Valid signal replaced with buffer_dcr_wr_valid
    .vx_buffer_rdy(output_rdy),

    // Control Signal to core_ctrl
    .buffer_full(buf_full)
);

always begin
    #0.5 clk = ~clk;
end

initial begin
    $dumpfile("buf_test.vcd");
    $dumpvars(1, tb_piton_dcr_buffer);
    clk = 0;
    counter = 0;
    out_counter = 0;
    output_rdy = 0;

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

    // Test Case: Input and Output 1 value
    $display("\nTest Case: Input and Output 1 value");
    `INPUT_BUFFER();
    `OUTPUT_BUFFER();

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
