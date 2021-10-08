`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/10/09 07:45:36
// Design Name: 
// Module Name: fifo_36kb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fifo_36kb #(
    parameter CLOCK_DOMAIN="COMMON",

    parameter WR_DATA_WIDTH = 16,
    parameter RD_DATA_WIDTH = 16,
    parameter FIFO_DEPTH_WIDTH = 2

)(
   

);

localparam FIFO_DEPTH_WIDTH = 2^FIFO_DEPTH_WIDTH;


FIFO36E2 #(
    .CASCADE_ORDER("NONE"),            // FIRST, LAST, MIDDLE, NONE, PARALLEL
    .CLOCK_DOMAINS("INDEPENDENT"),     // COMMON, INDEPENDENT
    .EN_ECC_PIPE("FALSE"),             // ECC pipeline register, (FALSE, TRUE)
    .EN_ECC_READ("FALSE"),             // Enable ECC decoder, (FALSE, TRUE)
    .EN_ECC_WRITE("FALSE"),            // Enable ECC encoder, (FALSE, TRUE)
    .FIRST_WORD_FALL_THROUGH("FALSE"), // FALSE, TRUE
    .INIT(72'h000000000000000000),     // Initial values on output port
    .PROG_EMPTY_THRESH(256),           // Programmable Empty Threshold
    .PROG_FULL_THRESH(256),            // Programmable Full Threshold
    // Programmable Inversion Attributes: Specifies the use of the built-in programmable inversion
    .IS_RDCLK_INVERTED(1'b0),          // Optional inversion for RDCLK
    .IS_RDEN_INVERTED(1'b0),           // Optional inversion for RDEN
    .IS_RSTREG_INVERTED(1'b0),         // Optional inversion for RSTREG
    .IS_RST_INVERTED(1'b0),            // Optional inversion for RST
    .IS_WRCLK_INVERTED(1'b0),          // Optional inversion for WRCLK
    .IS_WREN_INVERTED(1'b0),           // Optional inversion for WREN
    .RDCOUNT_TYPE("RAW_PNTR"),         // EXTENDED_DATACOUNT, RAW_PNTR, SIMPLE_DATACOUNT, SYNC_PNTR
    .READ_WIDTH(4),                    // 18-9
    .REGISTER_MODE("UNREGISTERED"),    // DO_PIPELINED, REGISTERED, UNREGISTERED
    .RSTREG_PRIORITY("RSTREG"),        // REGCE, RSTREG
    .SLEEP_ASYNC("FALSE"),             // FALSE, TRUE
    .SRVAL(72'h000000000000000000),    // SET/reset value of the FIFO outputs
    .WRCOUNT_TYPE("RAW_PNTR"),         // EXTENDED_DATACOUNT, RAW_PNTR, SIMPLE_DATACOUNT, SYNC_PNTR
    .WRITE_WIDTH(4)                    // 18-9
)
FIFO36E2_inst (
    // Cascade Signals outputs: Multi-FIFO cascade signals
    .CASDOUT(CASDOUT),             // 64-bit output: Data cascade output bus
    .CASDOUTP(CASDOUTP),           // 8-bit output: Parity data cascade output bus
    .CASNXTEMPTY(CASNXTEMPTY),     // 1-bit output: Cascade next empty
    .CASPRVRDEN(CASPRVRDEN),       // 1-bit output: Cascade previous read enable
    // ECC Signals outputs: Error Correction Circuitry ports
    .DBITERR(DBITERR),             // 1-bit output: Double bit error status
    .ECCPARITY(ECCPARITY),         // 8-bit output: Generated error correction parity
    .SBITERR(SBITERR),             // 1-bit output: Single bit error status
    // Read Data outputs: Read output data
    .DOUT(DOUT),                   // 64-bit output: FIFO data output bus
    .DOUTP(DOUTP),                 // 8-bit output: FIFO parity output bus.
    // Status outputs: Flags and other FIFO status outputs
    .EMPTY(EMPTY),                 // 1-bit output: Empty
    .FULL(FULL),                   // 1-bit output: Full
    .PROGEMPTY(PROGEMPTY),         // 1-bit output: Programmable empty
    .PROGFULL(PROGFULL),           // 1-bit output: Programmable full
    .RDCOUNT(RDCOUNT),             // 14-bit output: Read count
    .RDERR(RDERR),                 // 1-bit output: Read error
    .RDRSTBUSY(RDRSTBUSY),         // 1-bit output: Reset busy (sync to RDCLK)
    .WRCOUNT(WRCOUNT),             // 14-bit output: Write count
    .WRERR(WRERR),                 // 1-bit output: Write Error
    .WRRSTBUSY(WRRSTBUSY),         // 1-bit output: Reset busy (sync to WRCLK)
    // Cascade Signals inputs: Multi-FIFO cascade signals
    .CASDIN(CASDIN),               // 64-bit input: Data cascade input bus
    .CASDINP(CASDINP),             // 8-bit input: Parity data cascade input bus
    .CASDOMUX(CASDOMUX),           // 1-bit input: Cascade MUX select input
    .CASDOMUXEN(CASDOMUXEN),       // 1-bit input: Enable for cascade MUX select
    .CASNXTRDEN(CASNXTRDEN),       // 1-bit input: Cascade next read enable
    .CASOREGIMUX(CASOREGIMUX),     // 1-bit input: Cascade output MUX select
    .CASOREGIMUXEN(CASOREGIMUXEN), // 1-bit input: Cascade output MUX select enable
    .CASPRVEMPTY(CASPRVEMPTY),     // 1-bit input: Cascade previous empty
    // ECC Signals inputs: Error Correction Circuitry ports
    .INJECTDBITERR(INJECTDBITERR), // 1-bit input: Inject a double bit error
    .INJECTSBITERR(INJECTSBITERR), // 1-bit input: Inject a single bit error
    // Read Control Signals inputs: Read clock, enable and reset input signals
    .RDCLK(RDCLK),                 // 1-bit input: Read clock
    .RDEN(RDEN),                   // 1-bit input: Read enable
    .REGCE(REGCE),                 // 1-bit input: Output register clock enable
    .RSTREG(RSTREG),               // 1-bit input: Output register reset
    .SLEEP(SLEEP),                 // 1-bit input: Sleep Mode
    // Write Control Signals inputs: Write clock and enable input signals
    .RST(RST),                     // 1-bit input: Reset
    .WRCLK(WRCLK),                 // 1-bit input: Write clock
    .WREN(WREN),                   // 1-bit input: Write enable
    // Write Data inputs: Write input data
    .DIN(DIN),                     // 64-bit input: FIFO data input bus
    .DINP(DINP)                    // 8-bit input: FIFO parity input bus
);
endmodule
