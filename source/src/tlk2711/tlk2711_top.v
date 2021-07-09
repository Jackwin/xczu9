
///////////////////////////////////////////////////////////////////////////////
//  
//    Version: 1.0
//    Filename:  tlk2711_top.v
//    Date Created: 2021-06-27
// 
//   
// Project: TLK2711
// Device: zu9eg
// Purpose: top file
// Author: Zhu Lin
// Reference:  
// Revision History:
//   Rev 1.0 - First created, zhulin, 2021-07-03
//   
// Email: jewel122410@163.com
////////////////////////////////////////////////////////////////////////////////

module tlk2711_top 
#(       
    parameter ADDR_WIDTH = 32,
    parameter RDATA_WIDTH = 16,
    parameter WDATA_WIDTH = 16,
    parameter WBYTE_WIDTH = 2,   
    parameter DLEN_WIDTH = 16  
)
(  
    input               clk,
    input               rst,
    
    //register config
    input               i_reg_wen,
    input  [15:0]       i_reg_waddr,
    input  [63:0]       i_reg_wdata,
    
    //register status 
    input               i_reg_ren,
    input  [15:0]       i_reg_raddr,
    output [63:0]       o_reg_rdata,
    
    //interrupt
    output              o_tx_irq,
    output              o_rx_irq,
    output              o_loss_irq,
    
    //tlk2711 interface
    input               i_2711_rkmsb,
    input               i_2711_rklsb,
    input   [15:0]      i_2711_rxd,
    output              o_2711_tkmsb,
    output              o_2711_tklsb,
    output              o_2711_enable,
    output              o_2711_loopen,
    output              o_2711_lckrefn,
    output  [15:0]      o_2711_txd,

    //PS interface  
    //AXI4 Memory Mapped Read Address Interface Signals
    input           m_axi_arready,
    output          m_axi_arvalid,
    output [3:0]    m_axi_arid,
    output [ADDR_WIDTH-1:0] m_axi_araddr,
    output [7:0]    m_axi_arlen,
    output [2:0]    m_axi_arsize,
    output [1:0]    m_axi_arburst,
    output [2:0]    m_axi_arprot,
    output [3:0]    m_axi_arcache,
    output [3:0]    m_axi_aruser,
   
    //AXI4 Memory Mapped Read Data Interface Signals
    input [RDATA_WIDTH-1:0]   m_axi_rdata,
    input [1:0]     m_axi_rresp,
    input           m_axi_rlast,
    input           m_axi_rvalid,
    output          m_axi_rready,

    //AXI4 Memory Mapped Write Address Interface Signals
    input           m_axi_awready,
    output          m_axi_awvalid,
    output [3:0]    m_axi_awid,
    output [ADDR_WIDTH-1:0]   m_axi_awaddr,
    output [7:0]    m_axi_awlen,
    output [2:0]    m_axi_awsize,
    output [1:0]    m_axi_awburst,
    output [2:0]    m_axi_awprot,
    output [3:0]    m_axi_awcache,
    output [3:0]    m_axi_awuser,   

    //AXI4 Memory Mapped Write Data Interface Signals
    output [WDATA_WIDTH-1:0]  m_axi_wdata,
    output [WBYTE_WIDTH-1:0]  m_axi_wstrb,
    output          m_axi_wlast,
    output          m_axi_wvalid,
    input           m_axi_wready,

    input [1:0]     m_axi_bresp,
    input           m_axi_bvalid,
    output          m_axi_bready
   
);

    wire [ADDR_WIDTH-1:0]   tx_base_addr;
    wire [31:0]             tx_total_packet;
    wire [15:0]             tx_packet_body;
    wire [15:0]             tx_packet_tail;
    wire [15:0]             tx_body_num;
    wire [3:0]              tx_mode;
    wire                    tx_config_done; 
    wire                    tx_interrupt;

    wire [ADDR_WIDTH-1:0]   rx_base_addr;
    wire                    rx_config_done;
    wire                    rx_interrupt;
    wire [31:0]             rx_total_packet;
    wire [15:0]             rx_packet_body; 
    wire [15:0]             rx_packet_tail;
    wire [15:0]             rx_body_num;

    wire                    loss_interrupt;
    wire                    sync_loss;
    wire                    link_loss;
    wire                    soft_rst;

    wire [DLEN_WIDTH+ADDR_WIDTH-1:0]   rd_cmd_data;
    wire                    rd_cmd_req;
    wire                    rd_cmd_ack;
    wire [DLEN_WIDTH+ADDR_WIDTH-1:0]   wr_cmd_data;
    wire                    wr_cmd_req;
    wire                    wr_cmd_ack;
    
    wire                    dma_rd_ready;
    wire                    dma_rd_valid;
    wire                    dma_rd_last;
    wire [RDATA_WIDTH-1:0]  dma_rd_data;

    wire                    dma_wr_valid;
    wire [WBYTE_WIDTH-1:0]  dma_wr_keep;
    wire [WDATA_WIDTH-1:0]  dma_wr_data;
    wire                    dma_wr_ready;
    wire                    wr_finish;

   reg_mgt #(       
       .ADDR_WIDTH(ADDR_WIDTH)
   ) reg_mgt (  
       .clk(clk),
       .rst(rst),
       .i_reg_wen(i_reg_wen),
       .i_reg_waddr(i_reg_waddr),
       .i_reg_wdata(i_reg_wdata),
       .i_reg_ren(i_reg_ren),
       .i_reg_raddr(i_reg_raddr),
       .o_reg_rdata(o_reg_rdata),
       .o_tx_irq(o_tx_irq),
       .o_rx_irq(o_rx_irq),
       .o_loss_irq(o_loss_irq),
       .o_tx_base_addr(tx_base_addr), 
       .o_tx_total_packet(tx_total_packet), 
       .o_tx_packet_body(tx_packet_body), 
       .o_tx_packet_tail(tx_packet_tail), 
       .o_tx_body_num(tx_body_num),  
       .o_tx_mode(tx_mode), 
       .o_tx_config_done(tx_config_done),  
       .i_tx_interrupt(tx_interrupt), 
       .o_rx_base_addr(rx_base_addr), 
       .o_rx_config_done(rx_config_done),
       .i_rx_interrupt(rx_interrupt), 
       .i_rx_total_packet(rx_total_packet),
       .i_rx_packet_body(rx_packet_body), 
       .i_rx_packet_tail(rx_packet_tail),
       .i_rx_body_num(rx_body_num),
       .i_loss_interrupt(loss_interrupt),
       .i_sync_loss(sync_loss),
       .i_link_loss(link_loss),
       .o_soft_rst(soft_rst) 
    );
 
    tlk2711_dma #(
        .RDATA_WIDTH(RDATA_WIDTH),
        .WDATA_WIDTH(WDATA_WIDTH), 
        .WBYTE_WIDTH(WBYTE_WIDTH),   
        .ADDR_WIDTH(ADDR_WIDTH),
        .DLEN_WIDTH(DLEN_WIDTH)  
    ) tlk2711_dma (
        .clk(clk),
        .rst(rst),
        .i_rd_cmd_data(rd_cmd_data), 
        .i_rd_cmd_req(rd_cmd_req),
        .o_rd_cmd_ack(rd_cmd_ack),
        .i_wr_cmd_data(wr_cmd_data), 
        .i_wr_cmd_req(wr_cmd_req),
        .o_wr_cmd_ack(wr_cmd_ack),
        .i_dma_rd_ready(dma_rd_ready),
        .o_dma_rd_valid(dma_rd_valid),
        .o_dma_rd_last(dma_rd_last),
        .o_dma_rd_data(dma_rd_data),
        .i_dma_wr_valid(dma_wr_valid),
        .i_dma_wr_keep(dma_wr_keep),
        .i_dma_wr_data(dma_wr_data),
        .o_dma_wr_ready(dma_wr_ready),
        .o_wr_finish(wr_finish),
        .m_axi_arready(m_axi_arready),
        .m_axi_arvalid(m_axi_arvalid),
        .m_axi_arid(m_axi_arid),
        .m_axi_araddr(m_axi_araddr),
        .m_axi_arlen(m_axi_arlen),
        .m_axi_arsize(m_axi_arsize),
        .m_axi_arburst(m_axi_arburst),
        .m_axi_arprot(m_axi_arprot),
        .m_axi_arcache(m_axi_arcache),
        .m_axi_aruser(m_axi_aruser),
        .m_axi_rdata(m_axi_rdata),
        .m_axi_rresp(m_axi_rresp),
        .m_axi_rlast(m_axi_rlast),
        .m_axi_rvalid(m_axi_rvalid),
        .m_axi_rready(m_axi_rready),
        .m_axi_awready(m_axi_awready),
        .m_axi_awvalid(m_axi_awvalid),
        .m_axi_awid(m_axi_awid),
        .m_axi_awaddr(m_axi_awaddr),
        .m_axi_awlen(m_axi_awlen),
        .m_axi_awsize(m_axi_awsize),
        .m_axi_awburst(m_axi_awburst),
        .m_axi_awprot(m_axi_awprot),
        .m_axi_awcache(m_axi_awcache),
        .m_axi_awuser(m_axi_awuser),   
        .m_axi_wdata(m_axi_wdata),
        .m_axi_wstrb(m_axi_wstrb),
        .m_axi_wlast(m_axi_wlast),
        .m_axi_wvalid(m_axi_wvalid),
        .m_axi_wready(m_axi_wready),
        .m_axi_bresp(m_axi_bresp),
        .m_axi_bvalid(m_axi_bvalid),
        .m_axi_bready(m_axi_bready)
    );

    tlk2711_tx_cmd #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DLEN_WIDTH(DLEN_WIDTH) 
    ) tlk2711_tx_cmd (
        .clk(clk),
        .rst(rst),
        .i_soft_rst(soft_rst),
        .i_rd_cmd_ack(rd_cmd_ack),
        .o_rd_cmd_req(rd_cmd_req),
        .o_rd_cmd_data(rd_cmd_data), 
        .i_dma_rd_last(dma_rd_last), 
        .i_tx_start(tx_config_done),
        .i_tx_base_addr(tx_base_addr),
        .i_tx_packet_body(tx_packet_body), 
        .i_tx_packet_tail(tx_packet_tail), 
        .i_tx_body_num(tx_body_num)
    );

    tlk2711_tx_data #(
        .DATA_WIDTH(RDATA_WIDTH)
    ) tlk2711_tx_data (
        .clk(clk),
        .rst(rst),
        .i_soft_reset(soft_rst),
        .i_tx_mode(tx_mode),
        .i_tx_start(tx_config_done),
        .i_tx_packet_body(tx_packet_body), 
        .i_tx_packet_tail(tx_packet_tail),
        .i_tx_body_num(tx_body_num),
        .i_dma_rd_valid(dma_rd_valid),
        .i_dma_rd_last(dma_rd_last),
        .i_dma_rd_data(dma_rd_data),
        .o_dma_rd_ready(dma_rd_ready),
        .o_tx_interrupt(tx_interrupt),
        .o_2711_tkmsb(o_2711_tkmsb),
        .o_2711_tklsb(o_2711_tklsb),
        .o_2711_enable(o_2711_enable),
        .o_2711_loopen(o_2711_loopen),
        .o_2711_lckrefn(o_2711_lckrefn),
        .o_2711_txd(o_2711_txd)
    );

    tlk2711_rx_link #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DLEN_WIDTH(DLEN_WIDTH), 
        .DATA_WIDTH(WDATA_WIDTH),
        .WBYTE_WIDTH(WBYTE_WIDTH)
    ) tlk2711_rx_link (
        .clk(clk),
        .rst(rst),
        .i_soft_rst(soft_rst),
        .i_wr_cmd_ack(wr_cmd_ack),
        .o_wr_cmd_req(wr_cmd_req),
        .o_wr_cmd_data(wr_cmd_data), 
        .i_rx_start(rx_config_done),
        .i_rx_base_addr(rx_base_addr),
        .i_dma_wr_ready(dma_wr_ready),
        .i_wr_finish(wr_finish),
        .o_dma_wr_valid(dma_wr_valid),
        .o_dma_wr_keep(dma_wr_keep),
        .o_dma_wr_data(dma_wr_data),
        .o_rx_interrupt(rx_interrupt),
        .o_rx_total_packet(rx_total_packet),
        .o_rx_packet_tail(rx_packet_tail),
        .o_rx_body_num(rx_body_num),
        .i_2711_rkmsb(i_2711_rkmsb),
        .i_2711_rklsb(i_2711_rklsb),
        .i_2711_rxd(i_2711_rxd),
        .o_loss_interrupt(loss_interrupt),
        .o_sync_loss(sync_loss),
        .o_link_loss(link_loss)
    );

endmodule

    

    




