

module tlk2711_tx_data_test (

    input logic         clk,
    input logic         rst,
    output logic [15:0] o_txd,

    output logic        o_tkmsb,
    output logic        o_tklsb,
    output logic        o_loopen,
    output logic        o_prbsen,
    output logic        o_enable,
    output logic        o_lckrefn, // 1 -> track received data
    output logic        o_testen,

    // DMA interface
    input logic [63:0]  i_dma_data,
    input logic         i_dma_valid,
    input logic [7:0]   i_dma_keep,
    input logic         i_dma_last,
    output logic        o_dma_ready,

    // tlk2711 mode setting interface
    input logic         i_mode_set,
    input logic         i_mode_rst,
    input logic [2:0]   i_mode,
    input logic [2:0]   o_mode,
    
    // cmd interface
    input logic [31:0]  i_packet_body,
    input logic [9:0]   i_packet_tail,
    input logic         i_send_start
);

localparam K28_5 = 8'b1011_1100;
localparam D5_6 = 8'b11000101; // 110_00101
localparam D11_5 = 8'b1010_1011; //101_01011

enum logic[2:0] {
    IDLE_s = 3'd0,
    NORM_s = 3'd1,
    LOOP_s = 3'd2,
    KCODE_s = 3'd3,
    PRBS_s = 3'd4
}current_mode, next_mode;

enum logic[2:0] {
    IDLE_s = 3'd0,
    FRAME_HEAD_s = 3'd1,
    FRAME_TYPE_s = 3'd2,
    FRAME_END_FLAG_s = 3'd3,
    FRAME_COUNT_s = 3'd4,
    FRAME_LENGTH_s = 3'd5,
    FRAME_DATA_s = 3'd6,
    FRMAE_END_s = 3'd7
}frame_state_cs, frame_state_ns;
    
endmodule