///////////////////////////////////////////////////////////////////////////////
//  
//    Version: 1.0
//    Filename:  tlk2711_rx_link.v
//    Date Created: 2021-07-02
// 
//   
// Project: TLK2711
// Device: zu9eg
// Purpose: RX detection and data link to DDR
// Author: Zhu Lin
// Reference:  
// Revision History:
//   Rev 1.0 - First created, zhulin, 2021-07-02
//   
// Email: jewel122410@163.com
////////////////////////////////////////////////////////////////////////////////

module  tlk2711_rx_link
#(
    parameter ADDR_WIDTH = 32,
    parameter DLEN_WIDTH = 16,
	  parameter DATA_WIDTH = 64,
    parameter WBYTE_WIDTH = 8
)
(
    input                               clk,
    input                               rst,
    input                               i_soft_rst,

    input                               i_2711_rx_clk,

    //dma cmd interface         
    input                               i_wr_cmd_ack,
    output reg                          o_wr_cmd_req,
    output [ADDR_WIDTH+DLEN_WIDTH-1:0]  o_wr_cmd_data, //high for saddr, low for byte len

    input                               i_rx_start,
    input  [ADDR_WIDTH-1:0]             i_rx_base_addr,

    input                               i_dma_wr_ready,
    input                               i_wr_finish,
    output                              o_dma_wr_valid,
    output [WBYTE_WIDTH-1:0]            o_dma_wr_keep,
    output [DATA_WIDTH-1:0]             o_dma_wr_data,

    output                              o_rx_interrupt,
    output reg [31:0]                   o_rx_total_packet, //total packet len in byte
    output reg [15:0]                   o_rx_packet_tail, //tail length in byte
    output [15:0]                       o_rx_body_num,

    input                               i_2711_rkmsb,
    input                               i_2711_rklsb,
    input  [15:0]                       i_2711_rxd,
    output reg                          o_loss_interrupt,
    output reg                          o_sync_loss,
    output reg                          o_link_loss
);
    
    //frame start
    localparam K27_7 = 8'hFB; 
    localparam K28_2 = 8'h5C;
    //frame end
    localparam K30_7 = 8'hFE;
    localparam K29_7 = 8'hFD;
    //sync code
    localparam K28_5 = 8'hBC;
    localparam D5_6  = 8'hC5;

    // Rx Lenght
    // 882 byte used for the test.
    // There are 3-type lengths, uint of byte, for the application.
    localparam TEST_LENGTH = 16'd882;
    localparam TDI_IMAGE_LENGTH = 16'd10752;
    localparam TDI_VIDEO_LENGTH = 16'd4608;
    localparam IMAGE_LENGTH = 16'd10752;

    localparam IDLE_s = 4'd0;
    localparam SYNC_s = 4'd1;
    localparam FRAME_START_s = 4'd2;
    localparam FRAME_HEAD_s = 4'd3;
    localparam DATA_TYPE_s = 4'd4;
    localparam END_FLAG_s = 4'd5;
    localparam LINE_INFOR_s = 4'd6;
    localparam DATA_LENGTH_s = 4'd7;
    localparam RECV_DATA_s = 4'd8;
    localparam CHECK_DATA_s = 4'd9;
    localparam FRAME_END_s = 4'd10;

    localparam FRAME_HEAD_FLAG = 32'heb90_e116;

    reg [3:0] cs;
    reg [3:0] ns;

    // Store the frame inform

    reg [7:0]   data_mode;
    reg [7:0]   data_end_flag;
    reg [15:0]  line_number;
    reg [15:0]  data_length;

    reg [15:0] rx_frame_cnt = 'd0;
    reg [DLEN_WIDTH-1:0] valid_byte = 'd0;
    reg [DLEN_WIDTH-1:0] wr_bbt = 'd0;
    reg [ADDR_WIDTH-1:0] wr_addr = 'd0;
    reg [15:0]   tlk2711_rxd;

    assign o_wr_cmd_data = {wr_addr, wr_bbt};

    reg frame_start, frame_end, frame_valid;
    // TODO modify the bit length to adapt to the 5120 pixels
    reg [15:0] frame_data_cnt, valid_data_num, trans_data_num;

    always@(posedge clk)
    begin
        if (rst) 
        begin
            frame_start    <= 'b0;
            frame_end      <= 'b0;
            frame_valid    <= 'b0;
            frame_data_cnt <= 'd0;
        end    
        else 
        begin
            frame_start <= i_2711_rkmsb & i_2711_rklsb & (i_2711_rxd == {K28_2, K27_7});
            frame_end   <= i_2711_rkmsb & i_2711_rklsb & (i_2711_rxd == {K29_7, K30_7});
            tlk2711_rxd <= i_2711_rxd;

            if (frame_start)begin
                frame_valid    <= 'b1;
                frame_data_cnt <= 'd0; 
            end    
            // Rx mode case
            // 1. 882Byte 2. (5120clk+256clk)*2B = 10752Byte 3. (2048clk+256clk)*2B = 4608Byte
            else if (frame_valid && frame_data_cnt == ((TEST_LENGTH - 2) / 2)) begin
                frame_valid    <= 'b0;
                frame_data_cnt <= 'd0;    
            end else if (frame_valid)
                frame_data_cnt <= frame_data_cnt + 1;
        end 
    end

    // Rx state

    always @(posedge clk) begin
        if (rst | i_soft_rst) begin
            cs <= IDLE_s;
        end else begin
            cs <= ns;
        end
    end

    always @(*) begin
        ns = cs;
        case(cs)
        IDLE_s: begin
            if (~i_2711_rkmsb & i_2711_rklsb & (i_2711_rxd == {D5_6, K28_5})) begin
                ns = SYNC_s;
            end
        end
        SYNC_s: begin
            if (i_2711_rkmsb & i_2711_rklsb & (i_2711_rxd == {K28_2, K27_7})) begin
                ns = FRAME_START_s;
            end
        end
        FRAME_START_s: begin
            if ({tlk2711_rxd, i_2711_rxd} == FRAME_HEAD_FLAG) begin
                ns = DATA_TYPE_s;
            end
        end
        DATA_TYPE_s: ns = END_FLAG_s;
        END_FLAG_s: ns = LINE_INFOR_s;
        LINE_INFOR_s: ns = RECV_DATA_s;
        DATA_LENGTH_s: ns = RECV_DATA_s;
        RECV_DATA_s: begin
            if (frame_data_cnt == data_length[15:1] - 1) begin
                ns = CHECK_DATA_s;
            end
        end
        CHECK_DATA_s: ns = FRAME_END_s;
        FRAME_END_s: if (i_2711_rkmsb & i_2711_rklsb & (i_2711_rxd == {K29_7, K30_7})) begin
            ns = IDLE_s;
        end
        endcase 
    end

    always@(posedge clk)
    begin
        if (rst) 
        begin
            wr_bbt       <= 'd0;
            valid_byte   <= 'd0;
            wr_addr      <= 'd0;
            o_wr_cmd_req <= 'b0;
        end    
        else 
        begin           
            if (frame_valid && frame_data_cnt == 'd4)  
            begin
                o_wr_cmd_req <= 'b1;
                wr_bbt[DLEN_WIDTH-1:3] <= tlk2711_rxd[15:3] + |tlk2711_rxd[2:0]; 
                wr_bbt[2:0]  <= 'd0;
                valid_byte   <= tlk2711_rxd;
            end    
            else if (i_wr_cmd_ack)
                o_wr_cmd_req <= 'b0;

            if (i_rx_start)
                wr_addr <= i_rx_base_addr;
            else if (frame_end)
                wr_addr <= wr_addr + wr_bbt;
        end 
    end

    reg  fifo_wren, valid_data_ind;
    wire fifo_empty;

    assign o_dma_wr_valid = ~fifo_empty & i_dma_wr_ready;
    assign o_dma_wr_keep = {WBYTE_WIDTH{1'b1}};

    always@(posedge clk)
    begin
        if (rst) 
        begin
            fifo_wren      <= 'b0;
            valid_data_num <= 'd0;
            trans_data_num <= 'd0;
            valid_data_ind <= 'b0;
        end    
        else
        begin
            trans_data_num <= wr_bbt[15:1] + 4;
            valid_data_num <= valid_byte[15:1] + 4;

            if (frame_valid && frame_data_cnt == 'd4)
            begin
                fifo_wren <= 'b1;
                valid_data_ind <= 'b1;
            end  
            else if (frame_valid && frame_data_cnt == valid_data_num)   
                valid_data_ind <= 'b0;
            else if (frame_valid && frame_data_cnt == trans_data_num)    
                fifo_wren <= 'b0;
  
        end
    end
    
    fifo_fwft_16_2048 fifo_fwft_rx (
        .clk(clk),
        .srst(rst | i_soft_rst),
        .din(tlk2711_rxd),
        .wr_en(fifo_wren),
        .rd_en(o_dma_wr_valid),
        .dout(o_dma_wr_data),
        .full(),
        .empty(fifo_empty)
    );

    reg tail_frame_ind;

    assign o_rx_interrupt = tail_frame_ind & i_wr_finish;
    assign o_rx_body_num  = rx_frame_cnt;

    always@(posedge clk)
    begin
        if (rst) 
        begin
            tail_frame_ind    <= 'b0;
            o_rx_total_packet <= 'd0;
            o_rx_packet_tail  <= 'd0;
            rx_frame_cnt      <= 'd0;
        end
        else
        begin
            if (frame_valid & frame_data_cnt == 'd2 & tlk2711_rxd[15:8] == 'd1)
                tail_frame_ind <= 'b1;
            else if (i_wr_finish) 
                tail_frame_ind <= 'b0;

            if (i_rx_start & o_rx_interrupt)
                rx_frame_cnt <= 'd0;
            else if (frame_end)      
                rx_frame_cnt <= rx_frame_cnt + 1;

            if (i_rx_start & o_rx_interrupt)
                o_rx_total_packet <= 'd0;
            else if (valid_data_ind)      
                o_rx_total_packet <= o_rx_total_packet + 2;    

            if (tail_frame_ind & o_wr_cmd_req && i_wr_cmd_ack)    
                o_rx_packet_tail  <= valid_byte;
        end    
    end 

    always@(posedge clk)
    begin
        if (rst | i_soft_rst)
        begin
            o_sync_loss      <= 'b0;
            o_link_loss      <= 'b0;
            o_loss_interrupt <= 'b0;
        end
        else 
        begin
        	  if (~i_2711_rkmsb & ~i_2711_rklsb & (i_2711_rxd == 16'hC5BC))
                o_sync_loss <= 'b1;
            else if (o_loss_interrupt)
                o_sync_loss <= 'b0;
                
            if (i_2711_rkmsb & i_2711_rklsb & (i_2711_rxd == 16'hFFFF))    
                o_link_loss <= 'b1;
            else if (o_loss_interrupt)
                o_link_loss <= 'b0;
                
            if (o_loss_interrupt)
                o_loss_interrupt <= 'b0;
            else if (o_sync_loss | o_link_loss)
                o_loss_interrupt <= 'b1;
        end
    end    

// TODO debug rx
/*
 ila_tlk2711_rx ila_tlk2711_rx_i(
    .clk(clk),
    .probe0(i_2711_rkmsb),
    .probe1(i_2711_rklsb),
    .probe2(i_2711_rxd),
    .probe3(o_loss_interrupt),
    .probe4(i_rx_start),
    .probe5(i_rx_base_addr),
    .probe6(frame_start),
    .probe7(frame_data_cnt),
    .probe8(rx_frame_cnt),
    .probe9(i_wr_cmd_ack),
    .probe10(o_rx_interrupt),
    .probe11(o_rx_total_packet),
    .probe12(o_rx_packet_tail),
    .probe13(o_rx_body_num),
    .probe14(fifo_wren),
    .probe15(wr_bbt)
    
);
*/
endmodule 
         
         
         
         
         
         
         
