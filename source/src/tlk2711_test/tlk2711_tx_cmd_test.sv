

module tlk2711_tx_cmd_test (
    input logic         i_clk,
    input logic         i_rst;
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

    input logic         i_dma_tranfer_done,
    
    output logic [21:0] o_packet_body,
    output logic [9:0]  o_packet_tail,
    output logic        o_send_start
);

localparam TX_CTR_ADDR = 12'h04;
localparam TX_PAC_ADDR = 12'h08;
localparam TX_TAIL_ADDR = 12'h0A;
localparam TX_DDR_ADDR = 12'h10;

logic [21:0]    packet_body;
logic [9:0]     packet_tail;
logic           send_start;
logic           send_start_r;

logic [31:0]    ddr_rd_addr;

logic [71:0]    dma_rdcmd_data;
logic           dma_rdcmd_valid;
logic           dma_rdcmd_ready;

always_ff @(i_clk) begin : blk_packet
    if (i_soft_rst | i_rst) begin
        packet_body <= 'h0;
        packet_tail <= 'h0;
        ddr_rd_addr <= 'h0;
    end else begin
        if (i_reg_wen & (i_reg_waddr == TX_PAC_ADDR)) begin
            packet_body <= i_reg_wdata[31:10];
            packet_tail <= i_reg_wdata[9:0];
        end

        if (i_reg_wen & (i_reg_waddr == TX_DDR_ADDR)) begin
            ddr_rd_addr <= i_reg_wdata;
        end
    end
end

always_ff @(i_clk) begin : blk_start
    if (i_soft_rst | i_rst) begin
        send_start <= 'h0;
    end else begin
        if (i_reg_wen & (i_reg_waddr == TX_CTR_ADDR)) begin
            send_start <= i_reg_wdata[0];
        end else begin
            send_start <= 'h0;
        end
    end
end

always_ff @(i_clk) begin
    send_start_r <= send_start;
end

always_comb begin
    o_send_start = send_start_r;
    o_packet_body = packet_body;
    o_packet_tail = packet_tail;
end

always_ff @(i_clk) begin
    if (i_soft_rst | i_rst) begin
        dma_rdcmd_valid <= 'h0;
    end else begin
        if (send_start) begin
            dma_rdcmd_valid <= 1'b1;
        end else if (i_dma_rdcmd_ready) begin
            dma_rdcmd_valid <= 1'b0;
        end
    end
end

// TODO DMA fetching times, control by CPU?
always_comb begin : blockName
    dma_rdcmd_data = {8'd0, ddr_rd_addr, 1'b0, 1'b1, 7'd1, 14'd0, s2mm_rd_length};
end

/*
less than 256
256

cmd issue times

fifo depth

one packet 820

tx data issue read cmd 


issue: body body发4次
DMA address alignment
*/

enum logic [1:0] {
    CMD_IDLE_s = 2'd0,
    CMD_ISSUE_s = 2'd1，
    CMD_WAIT_s = 2'd2,
    CMD_END_s = 2'd3
}cmd_cs, cmd_ns;

logic [31:0]    rd_saddr;
logic [9:0]     rd_length;
logic [15:0]    dma_rd_cmd_num;
logic [15:0]    dma_rd_cmd_cnt;

always_ff @(i_clk) begin
    if (i_rst | i_sys_rst) begin
        cmd_cs <= CMD_IDLE_s
    end else begin
        cmd_cs <= cmd_ns;
    end
end

always_comb begin
    cmd_ns <= cmd_cs;

    case(cmd_cs)
    CMD_IDLE_s: begin
        if (send_start) begin
            cmd_ns = CMD_ISSUE_s;
        end
    end
    CMD_ISSUE_s: begin
        if (i_dma_rdcmd_ready) begin
            cmd_ns = CMD_WAIT_s;
        end
    end
    CMD_WAIT_s: begin
        if ((dma_rd_cmd_cnt == dma_rd_cmd_num - 1) & i_dma_tranfer_done) begin
            cmd_ns <= CMD_END_s;
        end else if (i_dma_tranfer_done) begin
             cmd_ns = CMD_ISSUE_s;
        end
    end
    CMD_END_s: begin
        cmd_ns <= CMD_IDLE_s;
    end
    default: begin
        cmd_ns <= CMD_IDLE_s;
    end
    endcase
end

always_ff @(i_clk) begin
    if (i_rst | i_soft_rst) begin
        dma_rd_cmd_cnt <= 'h0;
        dma_rd_cmd_num <= 'h0;
    end else begin
        case(cmd_cs)
        CMD_IDLE_s: begin
            dma_rd_cmd_num <= 'h0;
            dma_rd_cmd_cnt <= 'h0;
        end
        CMD_ISSUE_s: begin
            
        end

    end
    
end


always_ff @(i_clk) begin
    if (i_rst | i_sys_rst) begin
        dma_rd_cmd_num <= 'h0;
        dma_rd_cmd_num <= 'h0
    end else begin
        if 
    end
    
end

    
endmodule