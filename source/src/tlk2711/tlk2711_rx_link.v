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
// Email: 
////////////////////////////////////////////////////////////////////////////////

module  tlk2711_rx_link
#(
    parameter DEBUG_ENA = "TRUE", 
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

    input [2:0]                         i_tx_mode,

    input                               i_rx_start,
    input  [ADDR_WIDTH-1:0]             i_rx_base_addr,
    input  [23:0]                       i_rx_line_num_per_intr,
    input  [15:0]                       i_rx_intr_width,
    input  [15:0]                       i_link_intr_width,

    input                               i_link_loss_detect_ena,
    input                               i_sync_loss_detect_ena,
    input                               i_check_ena,
    input                               i_loopback_ena,
    input                               i_rx_length_unit,

    // To read the remained data in FIFO when link/sync loss happens
    input                               i_rx_fifo_rd,

    input                               i_dma_wr_ready,
    input                               i_wr_finish,
    output                              o_dma_wr_valid,
    output [WBYTE_WIDTH-1:0]            o_dma_wr_keep,
    output [DATA_WIDTH-1:0]             o_dma_wr_data,

    output                              o_rx_interrupt,
    output [15:0]                       o_rx_frame_length, 
    output [23:0]                       o_rx_frame_num,
    output [3:0]                        o_rx_data_type,
    output                              o_rx_file_end_flag,
    output                              o_rx_checksum_flag,
    output [1:0]                        o_rx_channel_id,

    input                               i_2711_rkmsb,
    input                               i_2711_rklsb,
    input  [15:0]                       i_2711_rxd,

    output [10:0]                       o_rx_status,
    output [3:0]                        o_rx_test_error,
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

    reg [1:0]               file_end_flag;
    reg [1:0]               channel_id;
    reg [3:0]               data_type;

    reg [23:0]              line_number;
    reg [15:0]              data_length;
    reg [1:0]               to_align64;
    reg [15:0]              checksum;
    reg [23:0]              line_cnt;
    reg [15:0]              rx_intr_width_cnt;
    reg [15:0]              link_intr_width_cnt;
    reg                     rx_intr_gen;
    reg                     rx_intr_width_cnt_ena;
   
    reg [15:0]              rx_frame_cnt = 'd0;
    reg [DLEN_WIDTH-1:0]    valid_byte = 'd0;
    reg [DLEN_WIDTH-1:0]    wr_bbt = 'd0;
    reg [ADDR_WIDTH-1:0]    wr_addr = 'd0;
    reg [15:0]              tlk2711_rxd;
    reg                     checksum_error;
    reg [15:0]              frame_length;

    reg                     fifo_wren;
    wire                    fifo_empty, fifo_full;
    wire                    fifo_rden;
    wire                    [15:0] fifo_din;
    wire                    [DATA_WIDTH-1:0] fifo_dout;

    reg                     wr_finish_1r;
    wire                    wr_finish_extend;

    reg                     rx_start_1r;
    reg                     rx_start_p;

    // assign o_rx_interrupt = one_frame_done & i_wr_finish & 
    //                         line_cnt == i_rx_line_num_per_intr;

    assign o_rx_frame_num = line_number;
    assign o_rx_frame_length = data_length;

    assign o_rx_data_type = data_type;
    assign o_rx_file_end_flag = file_end_flag[0];
    assign o_rx_checksum_flag = checksum_error;
    assign o_rx_channel_id = channel_id;

    assign o_wr_cmd_data = {wr_addr, wr_bbt};

    reg     frame_end, frame_valid;
    reg     frame_end_2711_r1, frame_end_2711_r2;
    wire    frame_end_2711_comb;
    reg     frame_end_r1, frame_end_r2, frame_end_p;
    // TODO modify the bit length to adapt to the 5120 pixels
    reg [15:0] frame_data_cnt, valid_data_num, trans_data_num;

    always @(posedge clk) begin
        wr_finish_1r <= i_wr_finish;
    end

    assign wr_finish_extend = wr_finish_1r | i_wr_finish;

    always @(posedge i_2711_rx_clk) begin
         if (rst | i_soft_rst) begin
             rx_intr_gen <= 1'b0;
         end else begin
            rx_intr_gen <= one_frame_done & wr_finish_extend & 
                            line_cnt == i_rx_line_num_per_intr;
         end
    end

    // Generate the specified width interrupt
    
    always @(posedge i_2711_rx_clk) begin
        if (rst | i_soft_rst) begin
            rx_intr_width_cnt <= 16'h0;
            rx_intr_width_cnt_ena <= 'h0;
        end else begin
            if (rx_intr_gen) begin
                rx_intr_width_cnt_ena <= 1'b1;
            end

            if (rx_intr_width_cnt_ena) begin
                if (rx_intr_width_cnt == (i_rx_intr_width - 1'd1)) begin
                    rx_intr_width_cnt <= 1'b0;
                    rx_intr_width_cnt_ena <= 1'b0;
                end else begin
                    rx_intr_width_cnt <= rx_intr_width_cnt + 1'd1;
                end
            end
        end
    end

    assign o_rx_interrupt = rx_intr_width_cnt_ena;
    // calculate the number of input lines

    always @(posedge i_2711_rx_clk) begin
        if (rst | i_soft_rst) begin
            line_cnt <= 'h0;
        end else begin
            if (cs == LINE_INFOR_s) begin
                line_cnt <= line_cnt + 1'd1;
            end else if (rx_intr_width_cnt_ena) begin
                line_cnt <= 0;
            end
        end
    end
    // todo line_cnt

    // Rx state

    always @(posedge i_2711_rx_clk) begin
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
            $display("%t (rx_link.v)rx state at SYNC_s", $time);
            if (i_2711_rkmsb & i_2711_rklsb & (i_2711_rxd == {K28_2, K27_7})) begin
                ns <= FRAME_HEAD_s;
            end
        end
        FRAME_HEAD_s: begin
            $display("%t (rx_link.v)rx state at FRAME_HEAD_s", $time);
            if ({tlk2711_rxd, i_2711_rxd} == FRAME_HEAD_FLAG) begin
                ns <= DATA_TYPE_s;
            end
        end
        DATA_TYPE_s: begin
            $display("%t (rx_link.v)rx state at DATA_TYPE_s", $time);
            ns <= LINE_INFOR_s;
        end
        LINE_INFOR_s: begin
            $display("%t (rx_link.v)rx state at LINE_INFOR_s", $time);
            ns <= DATA_LENGTH_s;
        end
        DATA_LENGTH_s: begin
            $display("%t (rx_link.v)rx state at DATA_LENGTH_s", $time);
            ns <= RECV_DATA_s;
        end
        RECV_DATA_s: begin
            
            // data length must be larger than or equal to 2
            if (i_rx_length_unit) begin
                if (frame_data_cnt == data_length - 1) begin // Unit in 2Byte
                    ns <= CHECK_DATA_s;
                end
            end else begin
                if (frame_data_cnt == data_length[15:1] - 1) begin
                    ns <= CHECK_DATA_s;
                    $display("%t (rx_link.v)rx state at RECV_DATA_s DONE", $time);
                end
            end
        end
        CHECK_DATA_s: begin
            $display("%t (rx_link.v)rx state at CHECK_DATA_s", $time);
            ns <= FRAME_END1_s;
        end
        FRAME_END1_s:  begin
            ns <= FRAME_END2_s;
        end
        FRAME_END2_s:  begin
            ns <= IDLE_s;
        end
        endcase 
    end

    // When the check is enabled, the rx will check the received data automatically
    wire        check_error;
    reg         check_ena;
    wire [3:0]  error_status;
    //reg [15:0] data_gen;

    always @(posedge i_2711_rx_clk) begin
        check_ena <= i_check_ena;
    end

    // always @(posedge clk) begin
    //     if (rst | i_soft_rst) begin
    //         check_error <= 1'b0;
    //         data_gen <= 16'h0;
    //     end else begin
    //         if (check_ena) begin
    //             if (cs == RECV_DATA_s) begin
    //                 data_gen <= data_gen + 1'd1;
    //                 check_error <= data_gen != i_2711_rxd;
    //             end else begin
    //                 data_gen <= 16'h0;
    //             end
    //         end else begin
    //             check_error <= 'h0;
    //             data_gen <= 16'h0;
    //         end
    //     end
    // end

    // Check the data from tlk2711 directly
    tlk2711_rx_validation #(
        .DEBUG_ENA(DEBUG_ENA)
    )tlk2711_rx_validation_inst (
        .clk(i_2711_rx_clk),
        .rst(rst),
        .i_soft_rst(i_soft_rst),
        .i_2711_rkmsb(i_2711_rkmsb),
        .i_2711_rklsb(i_2711_rklsb),
        .i_2711_rxd(i_2711_rxd),

        .i_check_ena(i_check_ena),
        .o_check_error(check_error),
        .o_error_status(error_status)
    );

    // check the data from FIFO
    wire                fifo_rd_check_error;
    tlk2711_rx_fifo_validation  # (
        .DEBUG_ENA(DEBUG_ENA)
    )tlk2711_rx_fifo_validation_inst (
        .clk(clk),
        .rst(rst),
        .i_soft_rst(i_soft_rst),

        .i_valid(fifo_rden),
        .i_data(fifo_dout),

        .i_check_ena(i_check_ena),
        .o_check_error(fifo_rd_check_error)
);

    
    // Calculate the checksum
    // TODO check not an integrated frame 9-10
    always @(posedge i_2711_rx_clk) begin
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

    always @(posedge i_2711_rx_clk) begin
        if (rst | i_soft_rst) begin
            data_type <= 0;
            file_end_flag <= 'h0;
            line_number <='h0;
            data_length <= 'h0;
            to_align64 <= 'h0;
        end else begin
           // if (cs == DATA_TYPE_s) {data_type, file_end_flag} <= i_2711_rxd;
            if (cs == DATA_TYPE_s) 
                {file_end_flag, channel_id, data_type, line_number[23:16]} <= i_2711_rxd;
            if (cs == LINE_INFOR_s) line_number[15:0] <= i_2711_rxd;
            if (cs == DATA_LENGTH_s) begin
                // The received data length is even.
                data_length <= i_2711_rxd;
                // Add more data to align to 64bit in FIFO
                to_align64 <= |i_2711_rxd[2:1] ? (3'd4 - i_2711_rxd[2:1]) : 'h0;
            end
        end
    end

    always @(posedge i_2711_rx_clk) begin
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

    always @(posedge i_2711_rx_clk) begin
        frame_end_2711_r1 <= frame_end;
        frame_end_2711_r2 <= frame_end_2711_r1;
    end

    assign frame_end_2711_comb = frame_end | frame_end_2711_r1 | 
                                frame_end_2711_r2;

    always @(posedge i_2711_rx_clk) begin
        tlk2711_rxd <= i_2711_rxd;
    end

    reg                     wr_cmd_req;
    reg                     wr_cmd_req_1r;
    reg                     wr_cmd_req_2r;
    wire                    wr_cmd_ack_2711;
    reg                     wr_cmd_ack_2711_1q;
    reg [DLEN_WIDTH-1:0]    wr_bbt_1r;

    // tlk2711 clock domain
    reg [DLEN_WIDTH-1:0]    wr_bbt_2711 = 'd0;
    reg [ADDR_WIDTH-1:0]    wr_addr_2711 = 'd0;
    reg [15:0]              frame_length_2711;
    reg                     wr_cmd_req_2711;
    reg                     wr_cmd_req_2711_r;

    always @(posedge i_2711_rx_clk) begin
        if (rst | i_soft_rst) begin
            wr_cmd_req_2711 <= 'b0;
            wr_bbt_2711 <= 'd0;
            frame_length_2711 <= 'h0;
        end else begin
            if (cs == DATA_LENGTH_s) begin
                // Recv data length is 882B, 10752B, 4608B. When write data to 
                // DDR, the unit number is 8byte, so the software needs to
                // tailor the correct number. For example, the received data
                // is 882 bytes, but 888 bytes data will be written to DDR.
                wr_bbt_2711[DLEN_WIDTH-1:3] <= i_2711_rxd[15:3] + |i_2711_rxd[2:0]; 
                wr_bbt_2711[2:0]  <= 'd0;
                wr_cmd_req_2711 <= 1'b1;
                frame_length_2711 <= i_2711_rxd;
            end else if (wr_cmd_ack_2711) begin
                wr_cmd_req_2711 <= 1'b0;
            end
        end
    end

     // cmd_req delay more than wr_bbt and wr_addr to ensure wr_bbt and wr_addr stable
     // undeterminde which clock is faster, so all posibilities are considered
    always @(posedge clk) begin
        wr_cmd_req_2711_r <= wr_cmd_req_2711;
    end

    always @(posedge clk) begin
        wr_cmd_req_1r <= wr_cmd_req_2711 | wr_cmd_req_2711_r;
        wr_cmd_req_2r <= wr_cmd_req_1r;
        o_wr_cmd_req <= ~wr_cmd_req_2r & wr_cmd_req_1r;

        wr_bbt <= wr_bbt_2711;
    end
   // assign wr_bbt = wr_bbt_1r;

    always @(posedge i_2711_rx_clk) begin
        wr_cmd_ack_2711_1q <= i_wr_cmd_ack;

    end
    assign wr_cmd_ack_2711 = wr_cmd_ack_2711_1q | i_wr_cmd_ack;

    // FPGA logic clock domain

    always @(posedge clk) begin
        frame_end_r1 <= frame_end_2711_comb;
        frame_end_r2 <= frame_end_r1;
        frame_end_p <= ~frame_end_r2 & frame_end_r1;
    end

    always @(posedge clk) begin
        rx_start_1r <= i_rx_start;
        rx_start_p <= ~i_rx_start & rx_start_1r;
    end

    always @(posedge clk) begin
        if (rst | i_soft_rst) begin
            wr_addr <= 'h50000000;
        end else begin
            if (rx_start_p)
                wr_addr <= i_rx_base_addr;
            // REVIEW: Get the wr_addr from the fpga_mgt?
            else if (frame_end_p) begin
                // In tx test mode or rx validation, keep the addr unchanged
                if ((i_tx_mode == 2'd2 & i_loopback_ena) | check_ena) begin
                    wr_addr <= wr_addr;
                end else begin 
                    wr_addr <= wr_addr + wr_bbt;
                end
            end
        end
    end

    // always @(posedge i_2711_rx_clk) begin
    //     if (rst | i_soft_rst) begin
    //         wr_addr      <= 'h50000000;
    //         wr_cmd_req <= 'b0;
    //         wr_bbt       <= 'd0;
    //         frame_length <= 'h0;
    //     end else begin
    //         if (cs == DATA_LENGTH_s) begin
    //             // Recv data length is 882B, 10752B, 4608B. When write data to 
    //             // DDR, the unit number is 8byte, so the software needs to
    //             // tailor the correct number. For example, the received data
    //             // is 882 bytes, but 888 bytes data will be written to DDR.
    //             wr_bbt[DLEN_WIDTH-1:3] <= i_2711_rxd[15:3] + |i_2711_rxd[2:0]; 
    //             wr_bbt[2:0]  <= 'd0;
    //             wr_cmd_req <= 1'b1;
    //             frame_length <= i_2711_rxd;
    //         end else if (wr_cmd_ack) begin
    //             wr_cmd_req <= 1'b0;
    //         end
    //         if (i_rx_start)
    //             wr_addr <= i_rx_base_addr;
    //         // REVIEW: Get the wr_addr from the fpga_mgt?
    //         else if (frame_end) begin
    //             // In tx test mode or rx validation, keep the addr unchanged
    //             if ((i_tx_mode == 2'd2 & i_loopback_ena) | check_ena) begin
    //                 wr_addr <= wr_addr;
    //             end else begin 
    //                 wr_addr <= wr_addr + wr_bbt;
    //             end
    //         end
    //     end
    // end

    assign o_dma_wr_valid = ~fifo_empty & i_dma_wr_ready;
    assign o_dma_wr_keep = {WBYTE_WIDTH{1'b1}};

    always @(posedge i_2711_rx_clk) begin
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

    // always@(posedge clk)begin
    //     if (rst | i_soft_rst) begin
    //         valid_data_num <= 'd0;
    //         trans_data_num <= 'd0;
    //     end else begin
    //         trans_data_num <= wr_bbt[15:1] + 4;
    //         valid_data_num <= valid_byte[15:1] + 4;
    //     end
    // end

    // Generate interrupt.
    // Note the DMA trans

    reg     one_frame_done;

    always @(posedge i_2711_rx_clk) begin
        if (rst | i_soft_rst) begin
            one_frame_done <= 1'b0;
        end else begin
            if (cs == FRAME_END1_s) begin
                one_frame_done <= 1'b1;
            end else if (rx_intr_gen) begin
                one_frame_done <= 1'b0;
            end
        end
    end

    assign fifo_rden = o_dma_wr_valid | i_rx_fifo_rd;
    assign o_dma_wr_data = fifo_dout;
    assign fifo_din = tlk2711_rxd;

    assign o_fifo_status = fifo_empty;
    // TODO Add more data to ensure the valid data are readout
    // fifo_fwft_16_2048 fifo_fwft_rx (
    //     .clk(clk),
    //     .srst(rst | i_soft_rst),
    //     .din(fifo_din),
    //     .wr_en(fifo_wren),
    //     .rd_en(fifo_rden),
    //     .dout(fifo_dout),
    //     .full(fifo_full),
    //     .empty(fifo_empty)
    // );

    fifo_fwft_16_2048 fifo_fwft_rx (
        
        .wr_clk(i_2711_rx_clk),
        .rst(rst | i_soft_rst),
        .din(fifo_din),
        .wr_en(fifo_wren),
        .full(fifo_full),

        .rd_clk(clk),
        .rd_en(fifo_rden),
        .dout(fifo_dout),
        .empty(fifo_empty)
    );

    always@(posedge i_2711_rx_clk) begin
        if (rst | i_soft_rst) begin
            rx_frame_cnt  <= 'd0;
        end else begin
            if (o_rx_interrupt)
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

    always@(posedge i_2711_rx_clk) begin
        if (rst | i_soft_rst) begin
            link_loss_flag <= 1'b0;
            link_loss <= 1'b0;
            link_loss_timer <= 'h0;
        end else begin
            if (i_link_loss_detect_ena) begin
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
            end else begin
                link_loss <= 1'b0;
                link_loss_timer <= 'h0;
                link_loss_flag <= 'h0;
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
                            cs == CHECK_DATA_s;

    // When sync loss happens, the host issues the soft reset
    always@(posedge i_2711_rx_clk) begin
        if (rst | i_soft_rst) begin
            sync_loss <= 1'b0;
            sync_loss_timer <= 'h0;
            sync_loss_flag <= 1'b0;
        end else begin
            // TODO Add k-code determination
            if (i_sync_loss_detect_ena) begin
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
            end else begin
                sync_loss <= 1'b0;
                sync_loss_timer <= 'h0;
                sync_loss_flag <= 1'b0;
            end
        end
    end

    assign o_sync_loss = sync_loss;

    // Output the status to the host
    // data_type, file_end_flag
    assign o_rx_status = {error_status, check_error, fifo_empty, fifo_full, cs};

// TODO debug rx

reg [15:0]  rd_cnt;
always@(posedge clk) begin
    if (rst | i_soft_rst) begin
        rd_cnt <= 'h0;
    end else begin
        if (o_dma_wr_valid) begin
            rd_cnt <= rd_cnt + 2;
            if (rd_cnt == frame_length - 2)
                rd_cnt <= 'h0;
        end
    end
end


if (DEBUG_ENA == "TRUE" || DEBUG_ENA == "true") 
    ila_tlk2711_rx ila_tlk2711_rx_i(
        .clk(i_2711_rx_clk),
        .probe0(i_2711_rkmsb),
        .probe1(i_2711_rklsb),
        .probe2(i_2711_rxd),
        .probe3(o_loss_interrupt),
        .probe4(i_rx_start),
        .probe5(i_rx_base_addr),
        .probe6(link_loss),
        .probe7(frame_data_cnt),
        .probe8(rx_frame_cnt),
        .probe9(i_wr_cmd_ack),
        .probe10(o_rx_interrupt),
        .probe11(link_loss_timer),
        .probe12(link_loss_flag),
        .probe13(link_loss),
        .probe14(fifo_wren),
        .probe15(wr_bbt),
        .probe16(cs),
        .probe17(sync_loss_timer),
        .probe18(sync_loss_flag),
        .probe19(sync_loss),
        .probe20(recv_data_flag),
        .probe21(frame_end),
        .probe22(checksum),
        .probe23(checksum_error),
        .probe24(one_frame_done),
        .probe25(i_wr_finish),
        .probe26(wr_addr),
        .probe27(o_wr_cmd_req),
        .probe28(i_rx_start),
        .probe29(o_dma_wr_valid),
        .probe30(fifo_empty),
        .probe31(fifo_full),
        .probe32(fifo_rden),
        .probe33(i_dma_wr_ready),
        .probe34(rd_cnt),
        .probe35(o_dma_wr_data),
        .probe36(check_ena),
        .probe37(check_error),
        .probe38(rx_intr_width_cnt),
        .probe39(line_cnt),
        .probe40(i_rx_line_num_per_intr),
        .probe41(fifo_rd_check_error),
        .probe42(rx_intr_gen),
        .probe43(data_length)

    );

endmodule 
         
         
         
         
         
         
         
