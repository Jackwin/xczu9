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
    output [15:0]                       o_rx_frame_length, 
    output [15:0]                       o_rx_frame_num,

    input                               i_2711_rkmsb,
    input                               i_2711_rklsb,
    input  [15:0]                       i_2711_rxd,

    output                              o_fifo_status,
    output                              o_loss_interrupt,
    output                              o_sync_loss,
    output                              o_link_loss
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
    localparam FRAME_HEAD_s = 4'd2;
    localparam DATA_TYPE_s = 4'd3;
    localparam LINE_INFOR_s = 4'd4;
    localparam DATA_LENGTH_s = 4'd5;
    localparam RECV_DATA_s = 4'd6;
    localparam CHECK_DATA_s = 4'd7;
    localparam FRAME_END1_s = 4'd8;
    localparam FRAME_END2_s = 4'd9;


    localparam FRAME_HEAD_FLAG = 32'heb90_e116;

    reg [3:0]   cs;
    reg [3:0]   ns;

    // Store the frame inform

    reg [7:0]   data_mode;
    reg [7:0]   data_end_flag;
    reg [15:0]  line_number;
    reg [15:0]  data_length;
    reg [1:0]   to_align64;
    reg [15:0]  checksum;


    reg [15:0]              rx_frame_cnt = 'd0;
    reg [DLEN_WIDTH-1:0]    valid_byte = 'd0;
    reg [DLEN_WIDTH-1:0]    wr_bbt = 'd0;
    reg [ADDR_WIDTH-1:0]    wr_addr = 'd0;
    reg [15:0]              tlk2711_rxd;
    reg                     checksum_error;

    assign o_wr_cmd_data = {wr_addr, wr_bbt};

    reg frame_end, frame_valid;
    // TODO modify the bit length to adapt to the 5120 pixels
    reg [15:0] frame_data_cnt, valid_data_num, trans_data_num;

    // Rx state

    always @(posedge clk) begin
        if (rst | i_soft_rst) begin
            cs <= IDLE_s;
        end else begin
            cs <= ns;
        end
    end

    always @(*) begin
        ns <= cs;
        case(cs)
        IDLE_s: begin
            if (~i_2711_rkmsb & i_2711_rklsb & (i_2711_rxd == {D5_6, K28_5})) begin
                ns <= SYNC_s;
            end
        end
        SYNC_s: begin
            if (i_2711_rkmsb & i_2711_rklsb & (i_2711_rxd == {K28_2, K27_7})) begin
                ns <= FRAME_HEAD_s;
            end
        end
        FRAME_HEAD_s: begin
            if ({tlk2711_rxd, i_2711_rxd} == FRAME_HEAD_FLAG) begin
                ns <= DATA_TYPE_s;
            end
        end
        DATA_TYPE_s: ns <= LINE_INFOR_s;
        LINE_INFOR_s: ns <= DATA_LENGTH_s;
        DATA_LENGTH_s: ns <= RECV_DATA_s;
        RECV_DATA_s: begin
            // data length must be larger than or equal to 2
            if (frame_data_cnt == data_length[15:1] - 1) begin
                ns <= CHECK_DATA_s;
            end
        end
        CHECK_DATA_s: ns <= FRAME_END1_s;
        FRAME_END1_s:  begin
            ns <= FRAME_END2_s;
        end
        FRAME_END2_s:  begin
            ns <= IDLE_s;
        end
        endcase 
    end

    // Calculate the checksum
    // TODO check not an integrated frame 9-10
    always @(posedge clk) begin
        if (rst | i_soft_rst) begin
            checksum <= 'h0; 
            checksum_error <= 1'b0;
        end else begin
            case(cs)
            IDLE_s, SYNC_s, FRAME_HEAD_s: begin
                checksum <= 'h0;
                checksum_error <= 1'b0;
            end
            DATA_TYPE_s, LINE_INFOR_s, DATA_LENGTH_s, RECV_DATA_s: begin
                checksum <= checksum + i_2711_rxd;
            end
            CHECK_DATA_s: begin
                if (checksum != i_2711_rxd) begin
                    checksum_error <= 1'b1;
                end else begin
                    checksum_error <= 1'b0;
                end
            end
            FRAME_END1_s, FRAME_END2_s: begin
                checksum_error <= checksum_error;
            end
            default: begin
                checksum_error <= checksum_error;
            end
            endcase
        end
    end

    always @(posedge clk) begin
        if (rst | i_soft_rst) begin
            data_mode <= 0;
            data_end_flag <= 'h0;
            line_number <='h0;
            data_length <= 'h0;
            to_align64 <= 'h0;
        end else begin
            if (cs == DATA_TYPE_s) {data_mode, data_end_flag} <= i_2711_rxd;
            if (cs == LINE_INFOR_s) line_number <= i_2711_rxd;
            if (cs == DATA_LENGTH_s) begin
                // The received data length is even.
                data_length <= i_2711_rxd;
                // Add more data to align to 64bit in FIFO
                to_align64 <= |i_2711_rxd[2:1] ? (3'd4 - i_2711_rxd[2:1]) : 'h0;
            end
        end
    end

    always @(posedge clk) begin
        if (rst | i_soft_rst) begin
            frame_data_cnt <= 'h0;
            frame_valid <= 'h0;
            frame_end <= 'h0;
        end else begin
            if (cs == RECV_DATA_s) begin
                frame_data_cnt <= frame_data_cnt + 1'd1;
                frame_valid <= 1'b1;
            end else if (cs == CHECK_DATA_s) begin
                frame_data_cnt <= 'h0;
                frame_valid <= 1'b0;
            end

            if (cs == FRAME_END1_s) frame_end <= 1'b1;
            else frame_end <= 1'b0;
        end
    end

    always @(posedge clk) begin
        tlk2711_rxd <= i_2711_rxd;
    end

    always @(posedge clk) begin
        if (rst | i_soft_rst) begin
            wr_addr      <= 'd0;
            o_wr_cmd_req <= 'b0;
            wr_bbt       <= 'd0;
        end else begin
            if (cs == DATA_LENGTH_s) begin
                // Recv data length is 882B, 10752B, 4608B. When write data to 
                // DDR, the unit number is 8byte, so the software needs to
                // tailor the correct number. For example, the received data
                // is 882 bytes, but 888 bytes data will be written to DDR.
                wr_bbt[DLEN_WIDTH-1:3] <= i_2711_rxd[15:3] + |i_2711_rxd[2:0]; 
                wr_bbt[2:0]  <= 'd0;
                o_wr_cmd_req <= 1'b1;
            end else if (i_wr_cmd_ack) begin
                o_wr_cmd_req <= 1'b0;
            end
            if (i_rx_start)
                wr_addr <= i_rx_base_addr;
            // REVIEW: Get the wr_addr from the fpga_mgt?
            else if (frame_end)
                wr_addr <= wr_addr + wr_bbt;
        end
    end

    reg  fifo_wren;
    wire fifo_empty, fifo_full;
    wire fifo_rden;
    wire [15:0] fifo_din;
    wire [DATA_WIDTH-1:0] fifo_dout;

    assign o_dma_wr_valid = ~fifo_empty & i_dma_wr_ready;
    assign o_dma_wr_keep = {WBYTE_WIDTH{1'b1}};

    always @(posedge clk) begin
        if (rst | i_soft_rst) begin
            fifo_wren <= 1'b0;
        end else begin
            if (cs == RECV_DATA_s) begin
                fifo_wren <= 1'b1;
            end else begin
                case(to_align64)
                    2'd0: fifo_wren <= 'h0;
                    2'd1: begin
                        if (cs == CHECK_DATA_s) fifo_wren <= 1'b1;
                        else fifo_wren <= 1'b0;
                    end
                    2'd2: begin
                        if (cs == CHECK_DATA_s | cs == FRAME_END1_s) begin
                            fifo_wren <= 1'b1;
                        end else begin
                            fifo_wren <= 1'b0;
                        end
                    end
                    2'd3: begin
                        if (cs == CHECK_DATA_s | cs == FRAME_END1_s | cs == FRAME_END2_s) begin
                            fifo_wren <= 1'b1;
                        end else 
                            fifo_wren <= 1'b0;
                    end
                endcase
            end
        end
    end

    always@(posedge clk)begin
        if (rst) begin
            valid_data_num <= 'd0;
            trans_data_num <= 'd0;
        end else begin
            trans_data_num <= wr_bbt[15:1] + 4;
            valid_data_num <= valid_byte[15:1] + 4;
        end
    end

    // Generate interrupt.
    // Note the DMA trans

    reg     one_frame_done;

    always @(posedge clk) begin
        if (rst | i_soft_rst) begin
            one_frame_done <= 1'b0;
        end else begin
            if (cs == FRAME_END1_s) begin
                one_frame_done <= 1'b1;
            end else if (i_wr_finish) begin
                one_frame_done <= 1'b0;
            end
        end
    end

    assign o_rx_interrupt = one_frame_done & i_wr_finish;
    assign o_rx_frame_num = line_number;
    assign o_rx_frame_length = data_length;

    assign fifo_rden = o_dma_wr_valid;
    assign o_dma_wr_data = fifo_dout;
    assign fifo_din = tlk2711_rxd;

    assign o_fifo_status = fifo_empty;
    // TODO Add more data to ensure the valid data are readout
    fifo_fwft_16_2048 fifo_fwft_rx (
        .clk(clk),
        .srst(rst | i_soft_rst),
        .din(fifo_din),
        .wr_en(fifo_wren),
        .rd_en(fifo_rden),
        .dout(fifo_dout),
        .full(fifo_full),
        .empty(fifo_empty)
    );

    always@(posedge clk) begin
        if (rst | i_soft_rst) begin
            rx_frame_cnt      <= 'd0;
        end else begin
            if (i_rx_start & o_rx_interrupt)
                rx_frame_cnt <= 'd0;
            else if (frame_end)      
                rx_frame_cnt <= rx_frame_cnt + 1;
        end    
    end

    // TODO Add logics to ensure the fifo data is read out when link/sync loss happens 9-14

    assign o_loss_interrupt = link_loss | sync_loss;

    reg [23:0]  link_loss_timer;
    reg         link_loss_flag;
    reg         link_loss;

    // After the link loss happends, another detection will be launched after 100ms to avoid 
    // frequent interrups to the host.

    always@(posedge clk) begin
        if (rst | i_soft_rst) begin
            link_loss_flag <= 1'b0;
            link_loss <= 1'b0;
            link_loss_timer <= 'h0;
        end else begin
            if (i_2711_rkmsb & i_2711_rklsb & (i_2711_rxd == 16'hFFFF) & ~link_loss_flag) begin
                link_loss <= 1'b1;
            end else begin
                link_loss <= 1'b0;
            end

            if (link_loss) begin
                link_loss_flag <= 1'b1;
            end else if (link_loss_timer == 24'd10000000) begin
                link_loss_flag <= 1'b0;
            end

            if (link_loss_flag) begin
                link_loss_timer <= link_loss_timer + 1'd1;
            end else begin
                link_loss_timer <= 'h0;
            end
        end
    end

    assign o_link_loss = link_loss;

    reg         sync_loss;
    reg         sync_loss_flag;
    reg [23:0]  sync_loss_timer;
    wire        recv_data_flag;
    assign recv_data_flag = cs == DATA_TYPE_s | cs == LINE_INFOR_s | 
                            cs == DATA_LENGTH_s | cs == RECV_DATA_s |
                            cs == CHECK_DATA_s | cs == FRAME_END1_s;

    // When sync loss happens, the host issues the soft reset
    always@(posedge clk) begin
        if (rst | i_soft_rst) begin
            sync_loss <= 1'b0;
            sync_loss_timer <= 'h0;
            sync_loss_flag <= 1'b0;
        end else begin
            if ((i_2711_rkmsb | i_2711_rklsb) & recv_data_flag & ~sync_loss_flag) begin
                sync_loss <= 1'b1;
            end else begin
                sync_loss <= 1'b0;
            end

            if (sync_loss) begin
                sync_loss_flag <= 1'b1;
            end else if (sync_loss_timer == 24'd10000000) begin
                sync_loss_flag <= 1'b0;
            end
                
            if (sync_loss_flag) begin
                sync_loss_timer <= sync_loss_timer + 1'b1;
            end else begin
                sync_loss_timer <= 'h0;
            end
        end
    end

    assign o_sync_loss = sync_loss;

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
         
         
         
         
         
         
         
