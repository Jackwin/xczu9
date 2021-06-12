

module tlk2711_tx_cmd (
    input logic         i_clk,
    input logic         i_soft_rst,

    input logic [31:0]  i_reg_wdata,
    input logic [11:0]  i_reg_waddr,
    input logic         i_reg_wen,

    input logic         i_reg_ren,
    input logic [11:0]  i_reg_raddr,
    output logic [31:0] o_reg_rdata,
    output logic        o_reg_valid,
    // mode setting interface
    output logic [2:0]  o_mode,
    output logic        o_mode_set,
    output logic        o_mode_rst,
    input logic [2:0]   i_mode,
    // DMA cmd interface
    input logic         i_dma_rdcmd_ready,
    output logic [71:0] o_dma_rdcmd_data,
    output logic        o_dma_rdcmd_valid,
    
    output logic [31:0] o_packet_body,
    output logic [9:0]  o_packet_tail,
    output logic        o_send_start
);
    
endmodule