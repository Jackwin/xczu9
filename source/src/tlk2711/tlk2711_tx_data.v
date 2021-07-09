///////////////////////////////////////////////////////////////////////////////
//  
//    Version: 1.0
//    Filename:  tlk2711_tx_data.v
//    Date Created: 2021-06-27
// 
//   
// Project: TLK2711
// Device: zu9eg
// Purpose: TX data control
// Author: Zhu Lin
// Reference:  
// Revision History:
//   Rev 1.0 - First created, zhulin, 2021-06-27
//   
// Email: jewel122410@163.com
////////////////////////////////////////////////////////////////////////////////

module  tlk2711_tx_data
#(
	parameter DATA_WIDTH = 64 
)
(
    input                   clk,
    input                   rst,

    input                   i_soft_reset,
    input [3:0]             i_tx_mode,
    input                   i_tx_start,
    input [15:0]            i_tx_packet_body, //body length in byte, 870B here for fixed value
    input [15:0]            i_tx_packet_tail, //tail length in byte
    input [15:0]            i_tx_body_num,
    
    //dma data interface 
    input                   i_dma_rd_valid,
    input                   i_dma_rd_last,
    input [DATA_WIDTH-1:0]  i_dma_rd_data,
    output                  o_dma_rd_ready,
    output reg              o_tx_interrupt,

    output reg              o_2711_tkmsb,
    output reg              o_2711_tklsb,
    output reg              o_2711_enable,
    output reg              o_2711_loopen,
    output reg              o_2711_lckrefn,
    output reg [15:0]       o_2711_txd
   
);
   
    localparam NORM_MODE = 4'd0;
    localparam LOOPBACK_MODE = 4'd1;
    localparam KCODE_MODE = 4'd2;
 
    //sync code
    localparam K28_5 = 8'hBC;
    localparam D5_6  = 8'hC5; 
    //frame start
    localparam K27_7 = 8'hFB; 
    localparam K28_2 = 8'h5C;
    //frame end
    localparam K30_7 = 8'hFE;
    localparam K29_7 = 8'hFD;

    //frame header
    localparam HEAD_0 = 8'h16;
    localparam HEAD_1 = 8'hE1;
    localparam HEAD_2 = 8'h90;
    localparam HEAD_3 = 8'hEB;

    //data type
    localparam TX_IND = 8'h81;
    //file end sign
    localparam FILE_END = 8'h01;

    reg       [3:0]           tx_state;
    localparam                tx_idle = 4'd0;
    localparam                tx_begin = 4'd1;
    localparam                tx_sync = 4'd2;
    localparam                tx_start_frame = 4'd3;
    localparam                tx_frame_head = 4'd4;
    localparam                tx_file_sign = 4'd5;
    localparam                tx_frame_num = 4'd6;
    localparam                tx_vld_dlen = 4'd7;
    localparam                tx_vld_data = 4'd8;
    localparam                tx_frame_tail = 4'd9;
    localparam                tx_end_frame = 4'd10;
    localparam                tx_backward = 4'd11;

    reg  fifo_enable;
    wire fifo_full, fifo_wren, fifo_rden;
    wire [15:0] fifo_rdata;

    assign o_dma_rd_ready = ~fifo_full;

    always@(posedge clk)
    begin
        if (rst | i_soft_reset) 
            fifo_enable <= 'b0;
        else if (i_tx_start && i_tx_mode == NORM_MODE)
            fifo_enable <= 'b1;
    end
    
    assign fifo_wren = i_dma_rd_valid & o_dma_rd_ready & fifo_enable;
    assign fifo_rden = tx_state == tx_vld_data;
    
    fifo_fwft_16_2048 fifo_fwft_tx (
        .clk(clk),
        .srst(rst | i_soft_reset),
        .din(i_dma_rd_data),
        .wr_en(fifo_wren),
        .rd_en(fifo_rden),
        .dout(fifo_rdata),
        .full(fifo_full),
        .empty()
    );

//    fifo_async_fwft #(
//        .WR_DEPTH(2048),
//        .RD_WIDTH(16),
//        .WR_WIDTH(16)
//    ) fifo_async_fwft (
//        .wr_clk(clk),
//        .rd_clk(clk),
//        .rst(rst | i_soft_reset),
//        .wr_en(fifo_wren),
//        .din(i_dma_rd_data), 
//        .rd_en(fifo_rden),
//        .dout(fifo_rdata),
//        .empty(),
//        .full(fifo_full)
//    );

    reg [15:0] frame_cnt = 'd0;
    reg [15:0] valid_dlen = 'd0; 
    reg [15:0] verif_dcnt = 'd0;

    always@(posedge clk)
    begin
        if (i_soft_reset)
            frame_cnt <= 'd0;
        else if (tx_state == tx_end_frame)   
            frame_cnt <= frame_cnt + 1;

        if (i_soft_reset)
            valid_dlen <= 'd0;
        else if (tx_state == tx_start_frame)    
            valid_dlen <= frame_cnt == i_tx_body_num ? i_tx_packet_tail : i_tx_packet_body;

        if (i_soft_reset | tx_state == tx_start_frame)
            verif_dcnt <= 'd0;
        else if (tx_state == tx_file_sign | tx_state == tx_frame_num | tx_state == tx_vld_dlen | tx_state == tx_vld_data)  
            verif_dcnt <= verif_dcnt + 2;
    end

    reg [3:0] tx_mode;

    always@(posedge clk)
    begin
        if (rst)
        begin
            o_2711_enable  <= 'b0;
            o_2711_loopen  <= 'b0;
            o_2711_lckrefn <= 'b0;
        end else
        begin
            if (i_soft_reset)
                tx_mode <= 'd0; 
            else if (i_tx_start)
                tx_mode <= i_tx_mode; 

            if (tx_mode == LOOPBACK_MODE)
            begin
                o_2711_loopen  <= 'b1;
                o_2711_lckrefn <= 'b1;
                o_2711_enable  <= 'b1;
            end 
            else if (tx_mode == KCODE_MODE)
            begin
                o_2711_loopen  <= 'b0;
                o_2711_lckrefn <= 'b1;
                o_2711_enable  <= 'b1;
            end 
            else 
            begin
                o_2711_loopen  <= 'b0;
                o_2711_lckrefn <= 'b1;
                o_2711_enable  <= 'b1;
            end
        end
    end


    reg [16:0] sync_cnt; //for 1ms in 100MHz clk, count 100000 cycles
    reg        head_cnt; //frame head counter, count 2 cycles
    reg [8:0]  vld_data_cnt; //valid data counter, count 435 cycles
    reg [8:0]  backward_cnt; //backward counter between frames, count 257 cycles

    always@(posedge clk)
    begin
        if (tx_state == tx_begin)
            sync_cnt <= 'd0;
        else if (tx_state == tx_sync)
            sync_cnt <= sync_cnt + 1;

        if (tx_state == tx_start_frame)
            head_cnt <= 'd0;
        else if (tx_state == tx_frame_head)
            head_cnt <= ~head_cnt;   

        if (tx_state == tx_start_frame)
            vld_data_cnt <= 'd0;
        else if (tx_state == tx_vld_data)
            vld_data_cnt <= vld_data_cnt + 1;     

        if (tx_state == tx_start_frame)
            backward_cnt <= 'd0;
        else if (tx_state == tx_backward)
            backward_cnt <= backward_cnt + 1;      
    end
    
    reg tail_frame;
    
    always@(posedge clk)
    begin
        if(rst)
        begin
            tx_state     <= tx_idle;
            o_2711_tkmsb <= 'b0;
            o_2711_tklsb <= 'b0;
            o_2711_txd   <= 'd0;
            tail_frame   <= 'b0;
            o_tx_interrupt <= 'b0;
        end 
        else 
        begin
            if (tx_mode == LOOPBACK_MODE)
            begin
                o_2711_tkmsb <= 'b1;
                o_2711_tklsb <= 'b1;
                o_2711_txd   <= o_2711_txd + 1;
            end
            else if (tx_mode == KCODE_MODE)
            begin
                o_2711_tkmsb <= 'b1;
                o_2711_tklsb <= 'b1;
                o_2711_txd   <= {D5_6, K28_5};
            end 
            else
            begin
                case(tx_state)
                    tx_idle:
                    begin
                        o_2711_tkmsb <= 'b0;
                        o_2711_tklsb <= 'b0;
                        o_2711_txd   <= 'd0;
                        if (i_tx_start)
                            tx_state <= tx_begin;  
                    end        
                    tx_begin:
                    begin
                        o_2711_tkmsb <= 'b0;
                        o_2711_tklsb <= 'b0;
                        o_2711_txd   <= 'd0;
                        if (i_soft_reset)
                            tx_state <= tx_idle;
                        else       
                            tx_state <= tx_sync;
                    end       
                    tx_sync:
                    begin
                        o_2711_tkmsb <= 'b0;
                        o_2711_tklsb <= 'b1;
                        o_2711_txd   <= {D5_6, K28_5};
                        if (i_soft_reset)
                            tx_state <= tx_idle; 
                        else if (sync_cnt == 'd99999)
                            tx_state <= tx_start_frame; 
                    end        
                    tx_start_frame:
                    begin
                        o_2711_tkmsb <= 'b1;
                        o_2711_tklsb <= 'b1;
                        o_2711_txd   <= {K28_2, K27_7};
                        if (i_soft_reset)
                            tx_state <= tx_idle;
                        else                  
                            tx_state <= tx_frame_head;
                    end        
                    tx_frame_head:
                    begin
                        o_2711_tkmsb <= 'b0;
                        o_2711_tklsb <= 'b0;
                        o_2711_txd   <= head_cnt ? {HEAD_3, HEAD_2} : {HEAD_1, HEAD_0};
                        if (i_soft_reset)
                            tx_state <= tx_idle;
                        else if (head_cnt)                 
                            tx_state <= tx_file_sign;
                    end        
                    tx_file_sign:
                    begin
                        o_2711_tkmsb <= 'b0;
                        o_2711_tklsb <= 'b0;
                        o_2711_txd   <= frame_cnt == i_tx_body_num ? {FILE_END, TX_IND} : {8'b0, TX_IND};
                        if (i_soft_reset)
                            tx_state <= tx_idle;
                        else
                            tx_state <= tx_frame_num;
                    end        
                    tx_frame_num:
                    begin
                        o_2711_tkmsb <= 'b0;
                        o_2711_tklsb <= 'b0;
                        o_2711_txd   <= frame_cnt;
                        if (i_soft_reset)
                            tx_state <= tx_idle;
                        else
                            tx_state <= tx_vld_dlen;
                    end        
                    tx_vld_dlen:
                    begin
                        o_2711_tkmsb <= 'b0;
                        o_2711_tklsb <= 'b0;
                        o_2711_txd   <= valid_dlen;
                        if (i_soft_reset)
                            tx_state <= tx_idle;
                        else
                            tx_state <= tx_vld_data;
                    end        
                    tx_vld_data:
                    begin
                        o_2711_tkmsb <= 'b0;
                        o_2711_tklsb <= 'b0;
                        o_2711_txd   <= fifo_rdata;
                        if (i_soft_reset)
                            tx_state <= tx_idle;
                        else if (vld_data_cnt == 'd434)
                            tx_state <= tx_frame_tail;
                    end        
                    tx_frame_tail:
                    begin
                        o_2711_tkmsb <= 'b0;
                        o_2711_tklsb <= 'b0;
                        o_2711_txd   <= verif_dcnt;
                        if (i_soft_reset)
                            tx_state <= tx_idle;
                        else
                            tx_state <= tx_end_frame;
                    end        
                    tx_end_frame:
                    begin
                        o_2711_tkmsb <= 'b1;
                        o_2711_tklsb <= 'b1;
                        o_2711_txd   <= {K29_7, K30_7};
                        if (i_soft_reset)
                            tx_state <= tx_idle;
                        else
                            tx_state <= tx_backward;
                    end        
                    tx_backward:
                    begin
                        o_2711_tkmsb <= 'b0;
                        o_2711_tklsb <= 'b1;
                        o_2711_txd   <= {D5_6, K28_5};
                        if (i_soft_reset)
                            tx_state <= tx_idle;
                        else if (backward_cnt == 'd256)
                            tx_state <= tail_frame ? tx_idle : tx_start_frame;
                    end        
                endcase
                
                if (tx_state == tx_end_frame && frame_cnt == i_tx_body_num)
                    tail_frame <= 'b1;
                else if (o_tx_interrupt)
                    tail_frame <= 'b0;
                o_tx_interrupt <= (tx_state == tx_backward) & (backward_cnt == 'd256) & tail_frame;
            end    
        end
    end
    
 
endmodule