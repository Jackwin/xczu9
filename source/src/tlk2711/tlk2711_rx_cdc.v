///////////////////////////////////////////////////////////////////////////////
// Project: TLK2711
// Device: zu9eg
// Purpose: tlk2711 rx clock domain cross
// Author: Chunjie Wang
// Reference:  
// Revision History:
//   Rev 1.0 - First created, chunjie, 2021-12-17
//   
// Email: 
///////////////////////////////////////////////////////////////////////////////

module tlk2711_rx_cdc # (
    parameter DATAWIDTH = 16
)
(
    input                   tlk2711_rx_clk,
    input [DATAWIDTH-1:0]   i_tlk2711_data,

    input                   clk,
    input                   rst,
    input                   i_soft_rst,
    output [DATAWIDTH-1:0]  o_tlk2711_data
);

wire        empty;
wire        full;

fifo_fwft_18_1024 fifo_rx_cdc (
    .rst(rst | i_soft_rst),
    .wr_clk(tlk2711_rx_clk),
    .din(i_tlk2711_data),
    .wr_en(1'b1),
    .full(full),

    .rd_clk(clk),
    .dout(o_tlk2711_data),
    .rd_en(~empty),
    .empty(empty)

);

ila_fifo_cdc ila_fifo_cdc_inst (
	.clk(clk), 
	.probe0(i_tlk2711_data),  
	.probe1(o_tlk2711_data), 
	.probe2(empty),
    .probe3(full)
);


endmodule