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
    input                   i_stop_test,
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

    output                  o_2711_tkmsb,
    output                  o_2711_tklsb,
    output                  o_2711_enable,
    output                  o_2711_loopen,
    output                  o_2711_lckrefn,
    output                  o_2711_testen,
    output                  o_2711_prbsen,
    output [15:0]           o_2711_txd
   
);

    localparam NORM_MODE = 4'd0;
    localparam LOOPBACK_MODE = 4'd1; // Internal chip loopback test
    localparam KCODE_MODE = 4'd2;
    localparam TEST_MODE = 4'd3; // chip to chip test
 
    //sync code
    localparam K28_5 = 8'hBC;
    localparam D5_6  = 8'hC5;
    localparam D11_5 = 8'b1010_1011; //101_01011 
    //frame start
    localparam K27_7 = 8'hFB; 
    localparam K28_2 = 8'h5C;
    //frame end
    localparam K30_7 = 8'hFE;
    localparam K29_7 = 8'hFD;

    //frame header
    localparam HEAD_0 = 16'hEB90;
    localparam HEAD_1 = 16'hE116;

    //data type
    localparam TX_IND = 8'h81;
    //file end sign
    localparam FILE_END = 8'h01;

    // FSM for testing 
    localparam COMMA1_s = 2'd0;
    localparam COMMA2_s = 2'd1;
    localparam SOF_s = 2'd2;
    localparam DATA_s = 2'd3;
	
	parameter BODY_LENGTH = 16'd870;

    reg       [3:0]           tx_state;
    localparam                tx_pwr_sync= 4'd0;
    localparam                tx_idle = 4'd1;
    localparam                tx_begin = 4'd2;
    localparam                tx_sync = 4'd3;
    localparam                tx_start_frame = 4'd4;
    localparam                tx_frame_head = 4'd5;
    localparam                tx_file_sign = 4'd6;
    localparam                tx_frame_num = 4'd7;
    localparam                tx_vld_dlen = 4'd8;
    localparam                tx_vld_data = 4'd9;
    localparam                tx_frame_tail = 4'd10;
    localparam                tx_end_frame = 4'd11;
    localparam                tx_backward = 4'd12;

    reg         tlk2711_tkmsb;
    reg         tlk2711_tklsb;
    reg         tlk2711_enable;
    reg         tlk2711_loopen;
    reg         tlk2711_lckrefn;
    reg         tlk2711_testen;
    reg         tlk2711_prbsen;
    reg [15:0]  tlk2711_txd;

    reg         tlk2711_tkmsb_1r;
    reg         tlk2711_tklsb_1r;
    reg [15:0]  tlk2711_txd_1r;

    reg         fifo_enable;
    wire        fifo_full, fifo_wren, fifo_rden;
    wire [15:0] fifo_rdata;
    wire        fifo_empty;

    assign o_2711_tkmsb = tlk2711_tkmsb_1r;
    assign o_2711_tklsb = tlk2711_tklsb_1r;
    assign o_2711_enable = tlk2711_enable;
    assign o_2711_loopen = tlk2711_loopen;
    assign o_2711_lckrefn = tlk2711_lckrefn;
    assign o_2711_testen = tlk2711_testen;
    assign o_2711_prbsen = tlk2711_prbsen;
    assign o_2711_txd = tlk2711_txd_1r;

    always @(posedge clk) begin
        tlk2711_tkmsb_1r <= tlk2711_tkmsb;
        tlk2711_tklsb_1r <= tlk2711_tklsb;
        if (tx_state == tx_end_frame)
            tlk2711_txd_1r <= checksum;
        else
            tlk2711_txd_1r <= tlk2711_txd;
    end

    assign o_dma_rd_ready = ~fifo_full;

    always@(posedge clk) begin
        if (rst | i_soft_reset) 
            fifo_enable <= 'b0;
        else if (i_tx_start && i_tx_mode == NORM_MODE)
            fifo_enable <= 'b1;
    end
    
    assign fifo_wren = i_dma_rd_valid & o_dma_rd_ready & fifo_enable;
    assign fifo_rden = (tx_state == tx_vld_data | tx_state == tx_frame_tail); //cmd request 872B and only transfer 870B, the last data will be ignored
    
    // TODO The data loaded from DMA is larger than the to-send, which cause bubles.
    fifo_fwft_64_512 fifo_fwft_tx (
        .clk(clk),
        .srst(rst | i_soft_reset),
        .din(i_dma_rd_data),
        .wr_en(fifo_wren),
        .rd_en(fifo_rden),
        .dout(fifo_rdata),
        .full(fifo_full),
        .empty(fifo_empty)
    );

    reg [15:0] frame_cnt = 'd0;
    reg [15:0] valid_dlen = 'd0; 
    reg [15:0] verif_dcnt = 'd0;

    reg [15:0] checksum = 'h0;

    always@(posedge clk) begin
        if (i_soft_reset)
            frame_cnt <= 'd0;
        // REVIEW 
        else if (tx_state == tx_end_frame && frame_cnt == i_tx_body_num)
            frame_cnt <= 'h0;
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

    // Calculate the checksum
    always @(posedge clk) begin
        if (i_soft_reset)
            checksum <= 'd0;
        else begin
            case(tx_state)
                tx_idle, tx_begin, tx_sync, tx_start_frame: begin
                    checksum <= 'h0;
                end
                tx_frame_num, tx_vld_dlen, tx_vld_data, tx_frame_tail: begin
                     checksum <= checksum + tlk2711_txd;
                 end
                 default: checksum <= 'h0;
            endcase
        end
    end

    reg [3:0] tx_mode;

    always@(posedge clk) begin
        if (rst)
        begin
            tlk2711_enable  <= 'b0;
            tlk2711_loopen  <= 'b0;
            tlk2711_lckrefn <= 'b0;
            tlk2711_testen <= 'b0;
            tlk2711_prbsen <= 'b0;
        end else
        begin
            if (i_soft_reset)
                tx_mode <= 'd0; 
            else if (i_tx_start)                          
                tx_mode <= i_tx_mode; 
            // TODO Add stop control signal to switch to IDLE
            if (tx_mode == LOOPBACK_MODE) begin
                tlk2711_loopen  <= 'b1;
                tlk2711_lckrefn <= 'b1;
                tlk2711_enable  <= 'b1;
            end else if (tx_mode == KCODE_MODE) begin
                tlk2711_loopen  <= 'b0;
                tlk2711_lckrefn <= 'b1;
                tlk2711_enable  <= 'b1;
            end else if (tx_mode == TEST_MODE) begin
                tlk2711_loopen  <= 'b0;
                tlk2711_lckrefn <= 'b1;
                tlk2711_enable  <= 'b1;
            end else begin
                tlk2711_loopen  <= 'b0;
                tlk2711_lckrefn <= 'b1;
                tlk2711_enable  <= 'b1;
            end
        end
    end


    reg [16:0] sync_cnt; //for 1ms in 100MHz clk, count 100000 cycles
    reg [16:0] pwr_sync_cnt; //for 1ms in 100MHz clk, count 100000 cycles
    reg        head_cnt; //frame head counter, count 2 cycles
    reg [8:0]  vld_data_cnt; //valid data counter, count 435 cycles
    reg [8:0]  backward_cnt; //backward counter between frames, count 257 cycles

    always@(posedge clk) begin
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
    
    reg         tail_frame;
    reg [2:0]   state_cnt;
    reg [7:0]   test_data_cnt;
    reg         test_mode_stop_flag;

    always @(posedge clk) begin
        if (rst | i_soft_reset) begin
            test_mode_stop_flag <= 1'b0;
        end else begin
            if (i_stop_test) begin
                test_mode_stop_flag <= 1'b1;
            end 
            if (test_mode_stop_flag & state_cnt == DATA_s & (&test_data_cnt))
                test_mode_stop_flag <= 1'b0;
        end
    end

    reg  tx_cfg_flag;

    always @(clk) begin
        if (rst | i_soft_reset) begin
            tx_cfg_flag <= 1'b0;
        end else begin
            if (i_tx_start) begin
                tx_cfg_flag <= 1'b1;
            end else if (tx_state == tx_backward) begin
                tx_cfg_flag <= 1'b0;
            end
        end
    end

    // power-up 1ms sync
    always @(posedge clk) begin
        if (rst) begin
            pwr_sync_cnt <= 'h0;
        end else if (tx_state == tx_pwr_sync) begin
            pwr_sync_cnt <= pwr_sync_cnt + 1;
        end else begin
            pwr_sync_cnt <= 'h0;
        end
    end
    
    always@(posedge clk)
    begin
        if(rst)
        begin
            tx_state     <= tx_idle;
            tlk2711_tkmsb <= 'b0;
            tlk2711_tklsb <= 'b0;
            tlk2711_txd   <= 'd0;
            tail_frame   <= 'b0;
            o_tx_interrupt <= 'b0;
            state_cnt <= 'h0;
            test_data_cnt <= 'h0;
        end 
        else 
        begin
            state_cnt <= 'h0;
            state_cnt <= 'h0;
            // TODO: Add a power-up state to send the 1ms sync code
            if (tx_mode == LOOPBACK_MODE || tx_mode == TEST_MODE)
            begin
                if (i_soft_reset) begin
                    state_cnt <= 'h0;
                    test_data_cnt <= 'h0;
                end
                case(state_cnt)
                // TODO Add an idle state
                COMMA1_s: begin // send K-code to sync the link
                    tlk2711_tkmsb <= 'b0;
                    tlk2711_tklsb <= 'b1;
                    tlk2711_txd <= {D5_6, K28_5};
                    state_cnt <= state_cnt + 1'd1;
                    test_data_cnt <= 'h0;
                end

                COMMA2_s: begin
                    tlk2711_tkmsb <= 'b0;
                    tlk2711_tklsb <= 'b1;
                    tlk2711_txd <= {D5_6, K28_5};
                    state_cnt <= state_cnt + 1'd1;
                end
                SOF_s: begin
                    tlk2711_tkmsb <= 'b1;
                    tlk2711_tklsb <= 'b1;
                    tlk2711_txd <= {K28_2, K27_7};
                    state_cnt <= state_cnt + 1'd1;
                end
                DATA_s: begin
                    tlk2711_tkmsb <= 'b0;
                    tlk2711_tklsb <= 'b1;
                    tlk2711_txd <= {2{test_data_cnt}};
                    tlk2711_tkmsb <= 'b0;
                    tlk2711_tklsb <= 'b0;
                    if (&test_data_cnt) begin
                        test_data_cnt <= 'h0;
                        state_cnt <= 'h0;
                    end
                    else test_data_cnt <= test_data_cnt + 16'h0101;
                end
                default: test_data_cnt <= 'h0;
                endcase
            end else if (tx_mode == KCODE_MODE) begin
                tlk2711_tkmsb <= 'b1;
                tlk2711_tklsb <= 'b1;
                tlk2711_txd   <= {K28_2, K27_7};
            end else begin
                case(tx_state)
                    tx_pwr_sync: begin
                        //if (pwr_sync_cnt == 16'd9999) tx_state <= tx_idle
                        if (pwr_sync_cnt == 16'd99) tx_state <= tx_idle;
                    end
                    tx_idle: begin
                        tlk2711_tkmsb <= 'b0;
                        tlk2711_tklsb <= 'b0;
                        tlk2711_txd   <= 'd0;
                        // REVIEW: Here not fifo_empty means the to-read data has been in the FIFO, 
                        // so the send can be kicked off. But, need to confirm that the fifo should
                        // be empty after every round of sending.
                        // During the process of sending data, i_tx_start is asserted to be '1' all
                        // the time. When the sendin is done, it is dis-asserted by the software.
                       //if (i_tx_start & ~fifo_empty)
                       // For every sending, it's required to config the tx register
                       if (tx_cfg_flag & ~fifo_empty)
                            tx_state <= tx_begin;  
                    end        
                    tx_begin: begin
                        tlk2711_tkmsb <= 'b0;
                        tlk2711_tklsb <= 'b0;
                        tlk2711_txd   <= 'd0;
                        if (i_soft_reset)
                            tx_state <= tx_idle;
                        else       
                            tx_state <= tx_sync;
                    end       
                    tx_sync: begin
                        tlk2711_tkmsb <= 'b0;
                        tlk2711_tklsb <= 'b1;
                        tlk2711_txd   <= {D5_6, K28_5};
                        if (i_soft_reset)
                            tx_state <= tx_idle; 
                       // else if (sync_cnt == 'd99999) // The sync period is 1ms, and the clock is 100MHz
                       else if (sync_cnt == 'd5) // The sync period is 1ms, and the clock is 100MHz
                            tx_state <= tx_start_frame; 
                    end        
                    tx_start_frame: begin
                        tlk2711_tkmsb <= 'b1;
                        tlk2711_tklsb <= 'b1;
                        tlk2711_txd   <= {K28_2, K27_7};
                        if (i_soft_reset)
                            tx_state <= tx_idle;
                        else                  
                            tx_state <= tx_frame_head;
                    end        
                    tx_frame_head: begin
                        tlk2711_tkmsb <= 'b0;
                        tlk2711_tklsb <= 'b0;
                        tlk2711_txd   <= head_cnt ? HEAD_1 : HEAD_0;
                        if (i_soft_reset)
                            tx_state <= tx_idle;
                        else if (head_cnt)                 
                            tx_state <= tx_file_sign;
                    end        
                    tx_file_sign:begin
                        tlk2711_tkmsb <= 'b0;
                        tlk2711_tklsb <= 'b0;
                        tlk2711_txd   <= (frame_cnt == i_tx_body_num) ? {TX_IND, FILE_END} : {TX_IND, 8'b0};
                        if (i_soft_reset)
                            tx_state <= tx_idle;
                        else
                            tx_state <= tx_frame_num;
                    end        
                    tx_frame_num:begin
                        tlk2711_tkmsb <= 'b0;
                        tlk2711_tklsb <= 'b0;
                        tlk2711_txd   <= frame_cnt;
                        if (i_soft_reset)
                            tx_state <= tx_idle;
                        else
                            tx_state <= tx_vld_dlen;
                    end        
                    tx_vld_dlen:begin
                        tlk2711_tkmsb <= 'b0;
                        tlk2711_tklsb <= 'b0;
                        tlk2711_txd   <= valid_dlen;
                        if (i_soft_reset)
                            tx_state <= tx_idle;
                        else
                            tx_state <= tx_vld_data;
                    end        
                    tx_vld_data:begin
                        tlk2711_tkmsb <= 'b0;
                        tlk2711_tklsb <= 'b0;
                        tlk2711_txd   <= fifo_rdata;
                        if (i_soft_reset)
                            tx_state <= tx_idle;
                        else if (vld_data_cnt == (i_tx_packet_body[15:1] - 1))
                            tx_state <= tx_frame_tail;
                    end        
                    tx_frame_tail:begin
                        tlk2711_tkmsb <= 'b0;
                        tlk2711_tklsb <= 'b0;
                       // tlk2711_txd   <= verif_dcnt;
                        tlk2711_txd <= checksum;
                        if (i_soft_reset)
                            tx_state <= tx_idle;
                        else
                            tx_state <= tx_end_frame;
                    end        
                    tx_end_frame:begin
                        tlk2711_tkmsb <= 'b1;
                        tlk2711_tklsb <= 'b1;
                        tlk2711_txd   <= {K29_7, K30_7};
                        if (i_soft_reset)
                            tx_state <= tx_idle;
                        else
                            tx_state <= tx_backward;
                    end        
                    tx_backward:begin
                        tlk2711_tkmsb <= 'b0;
                        tlk2711_tklsb <= 'b1;
                        tlk2711_txd   <= {D5_6, K28_5};
                        if (i_soft_reset)
                            tx_state <= tx_idle;
                        else if (backward_cnt == 'd255)
                            tx_state <= tail_frame ? tx_idle : tx_start_frame;
                    end        
                endcase

                if (tx_state == tx_end_frame && frame_cnt == i_tx_body_num) begin
                    tail_frame <= 'b1;
                end else if (o_tx_interrupt)
                    tail_frame <= 'b0;
                o_tx_interrupt <= (tx_state == tx_backward) & (backward_cnt == 'd255) & tail_frame;
            end    
        end
    end

// TODO  debug the port

tlk2711_tx_data_ila tlk2711_tx_data_ila_inst(
    .clk(clk),
    .probe0(i_tx_mode),
    .probe1(i_soft_reset),
    .probe2(i_tx_start),
    .probe3(tx_state),
    .probe4(state_cnt),
    .probe5(test_data_cnt),
    .probe6(tlk2711_txd),
    .probe7(tlk2711_tkmsb),
    .probe8(tlk2711_tklsb),
    .probe9(o_tx_interrupt),
    .probe10(sync_cnt),
    .probe11(head_cnt),
    .probe12(vld_data_cnt),
    .probe13(backward_cnt),
    .probe14(tlk2711_enable),
    .probe15(tlk2711_loopen),
    .probe16(i_tx_packet_body),
    .probe17(i_tx_packet_tail),
    .probe18(i_tx_body_num),
    .probe19(i_dma_rd_valid),
    .probe20(i_dma_rd_last),
    .probe21(i_dma_rd_data),
    .probe22(o_dma_rd_ready),
    .probe23(o_tx_interrupt),
    .probe24(checksum)
);


endmodule