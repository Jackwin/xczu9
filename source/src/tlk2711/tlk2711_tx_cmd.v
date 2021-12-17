///////////////////////////////////////////////////////////////////////////////
//  
//    Version: 1.0
//    Filename:  tlk2711_tx_cmd.v
//    Date Created: 2021-06-27
// 
//   
// Project: TLK2711
// Device: zu9eg
// Purpose: TX command control
// Author: Zhu Lin
// Reference:  
// Revision History:
//   Rev 1.0 - First created, zhulin, 2021-06-27
//   
// Email: jewel122410@163.com
////////////////////////////////////////////////////////////////////////////////

module  tlk2711_tx_cmd
#(
    parameter DEBUG_ENA = "TRUE", 
    parameter ADDR_WIDTH = 32,
    parameter DLEN_WIDTH = 16
)
(
    input                      clk,
    input                      rst,
    input                      i_soft_rst,
    
    //dma cmd interface
    input                      i_rd_cmd_ack,
    output reg                 o_rd_cmd_req,
    output [DLEN_WIDTH+ADDR_WIDTH-1:0] o_rd_cmd_data, //high for saddr, low for byte len

    input                      i_dma_rd_last, 
    input                      i_tx_start,
    input [2:0]                i_tx_mode,
    input [ADDR_WIDTH-1:0]     i_tx_base_addr,
    input [15:0]               i_tx_packet_body, //body length in byte, 870B here for fixed value
    input [15:0]               i_tx_packet_tail, //tail length in byte
    input [15:0]               i_tx_body_num
);

    localparam NORM_MODE = 3'd0;
    localparam KCODE_MODE = 3'd1;
    localparam TEST_MODE = 3'd2; // chip to chip test
    localparam SPECIFIC_MODE = 3'd3;

    reg [15:0] tx_frame_cnt = 'd0;
    reg [DLEN_WIDTH-1:0] rd_bbt = 'd0;
    reg [ADDR_WIDTH-1:0] rd_addr = 'd0;
    reg tx_start_r;
    reg tx_start;
    
    always@(posedge clk) begin
        tx_start_r <= i_tx_start & (i_tx_mode == NORM_MODE | 
                        i_tx_mode == SPECIFIC_MODE);
        tx_start <= ~tx_start_r & i_tx_start & (i_tx_mode == NORM_MODE | 
                        i_tx_mode == SPECIFIC_MODE);
    end

    assign o_rd_cmd_data = {rd_addr, rd_bbt};
    
    always@(posedge clk) begin
        if (rst) 
            tx_frame_cnt <= 'd0;
        else if (tx_start | i_soft_rst)
            tx_frame_cnt <= 'd0;
        else if (i_dma_rd_last & tx_frame_cnt == i_tx_body_num)    
            tx_frame_cnt <= 'd0;
        else if (i_dma_rd_last)
            tx_frame_cnt <= tx_frame_cnt + 1; 
    end

    reg rd_cmd_req;
    reg [15:0] packet_body_align8, packet_tail_align8;
    
    always@(posedge clk) begin
        if (rst) begin
            rd_cmd_req         <= 'b0;
            o_rd_cmd_req       <= 'b0;
            packet_body_align8 <= 'd0;
            rd_bbt  <= 'd0;
            rd_addr <= 'd0;
        end else begin
            rd_cmd_req <= i_dma_rd_last & tx_frame_cnt != i_tx_body_num;
            packet_body_align8[15:3] <= i_tx_packet_body[15:3] + |i_tx_packet_body[2:0];
            
            packet_body_align8[2:0]  <= 'd0;
            packet_tail_align8[15:3] <= i_tx_packet_tail[15:3] + |i_tx_packet_tail[2:0];
            
            packet_tail_align8[2:0]  <= 'd0;

            if (rd_cmd_req | tx_start) begin
                o_rd_cmd_req <= 'b1;
                // TODO check the log in the sim
                if (tx_start) begin
                    $display("%t: (tx_cmd.v)tx body length is %d", $time, i_tx_packet_body);
                    $display("%t: (tx_cmd.v)tx tail len is %d", $time, i_tx_packet_tail);
                    $display("%t: (tx_cmd.v)tx body number is %d", $time, i_tx_body_num);
                end
            end
            else if (i_rd_cmd_ack)  
                o_rd_cmd_req <= 'b0;

            if (tx_start | i_soft_rst)
                rd_addr <= i_tx_base_addr;
            else if (rd_cmd_req)    
                //rd_addr <= rd_addr + i_tx_packet_body;
                rd_addr <= rd_addr + packet_body_align8;
            
            rd_bbt <= tx_frame_cnt == i_tx_body_num ? packet_tail_align8 : packet_body_align8;
        end
    end
if (DEBUG_ENA == "TRUE" || DEBUG_ENA == "true") 
    ila_tx_cmd ila_tx_cmd_inst(
        .clk(clk),

        .probe0(i_rd_cmd_ack),
        .probe1(o_rd_cmd_req),
        .probe2(o_rd_cmd_data),
        .probe3(i_dma_rd_last),
        .probe4(tx_start),
        .probe5(i_tx_base_addr),
        .probe6(i_tx_packet_body),
        .probe7(i_tx_packet_tail),
        .probe8(i_tx_body_num),
        .probe9(tx_frame_cnt),
        .probe10(rd_cmd_req),
        .probe11(packet_body_align8),
        .probe12(packet_tail_align8),
        .probe13(rd_addr),
        .probe14(rd_bbt)
    );

 
endmodule 