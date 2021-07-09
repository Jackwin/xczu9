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
    input [31:0]               i_tx_base_addr,
    input [15:0]               i_tx_packet_body, //body length in byte, 870B here for fixed value
    input [15:0]               i_tx_packet_tail, //tail length in byte
    input [15:0]               i_tx_body_num
);

    reg [15:0] tx_frame_cnt = 'd0;
    reg [DLEN_WIDTH-1:0] rd_bbt = 'd0;
    reg [ADDR_WIDTH-1:0] rd_addr = 'd0;

    assign o_rd_cmd_data = {rd_addr, rd_bbt};

    always@(posedge clk)
    begin
        if (rst) 
            tx_frame_cnt <= 'd0;
        else if (i_tx_start | i_soft_rst)
            tx_frame_cnt <= 'd0;
        else if (i_dma_rd_last & tx_frame_cnt == i_tx_body_num)    
            tx_frame_cnt <= 'd0;
        else if (i_dma_rd_last)
            tx_frame_cnt <= tx_frame_cnt + 1; 
    end

    reg rd_cmd_req;
    
    always@(posedge clk)
    begin
        if (rst)
        begin
            rd_cmd_req   <= 'b0;
            o_rd_cmd_req <= 'b0;
            rd_bbt  <= 'd0;
            rd_addr <= 'd0;
        end
        else
        begin
            rd_cmd_req <= i_dma_rd_last & tx_frame_cnt != i_tx_body_num;

            if (rd_cmd_req | i_tx_start)
                o_rd_cmd_req <= 'b1;    
            else if (i_rd_cmd_ack)  
                o_rd_cmd_req <= 'b0;

            if (i_tx_start | i_soft_rst)
                rd_addr <= i_tx_base_addr;
            else if (rd_cmd_req)    
                rd_addr <= rd_addr + i_tx_packet_body;
            
            rd_bbt <= tx_frame_cnt == i_tx_body_num ? i_tx_packet_tail : i_tx_packet_body;
        end
    end
   
 
endmodule 
         
         
         
         
         
         
         
