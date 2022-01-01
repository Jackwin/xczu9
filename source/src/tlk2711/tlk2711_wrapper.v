///////////////////////////////////////////////////////////////////////////////
//  
// Version: 1.0
// Filename:  tlk2711_wrapper.v
// Date Created: 2021-10-5
// 
//   
// Project: xczu9
// Device: zu9eg
// Purpose: top file
// Author: Chunjie
// Reference:  
// Revision History:
//   Rev 1.0 - First created, chunjie, 2021-10-05
//   
// Email: 
////////////////////////////////////////////////////////////////////////////////

module tlk2711_wrapper
#(
    parameter DEBUG_ENA = "TRUE",
    parameter ADDR_WIDTH = 48,
    parameter AXI_RDATA_WIDTH = 64,
    parameter AXI_WDATA_WIDTH = 64,
    parameter AXI_WBYTE_WIDTH = 8,
    parameter STREAM_RDATA_WIDTH = 64,
    parameter STREAM_WDATA_WIDTH = 64,
    parameter STREAM_WBYTE_WIDTH = 8,
    parameter DLEN_WIDTH = 16,

    parameter TLK2711B_ADDR_MASK = 16'h00ff,
    parameter TLK2711B_ADDR_BASE = 16'h0000,
    parameter TLK2711A_ADDR_MASK = 16'h00ff,
    parameter TLK2711A_ADDR_BASE = 16'h0100
)(
    input                           ps_clk,
    input                           ps_rst,

    //tlk2711 interface         
    input                           clk,
    input                           rst,

     //register config          
    input                           i_reg_wen,
    input  [15:0]                   i_reg_waddr,
    input  [63:0]                   i_reg_wdata,

    //register status           
    input                           i_reg_ren,
    input  [15:0]                   i_reg_raddr,
    output [63:0]                   o_reg_rdata,

    // ------------------------ tlk2711b ----------------------------
    
    //interrupt
    output                          o_2711b_tx_irq,
    output                          o_2711b_rx_irq,
    output                          o_2711b_loss_irq,

    input                           i_2711b_rx_clk,
    input                           i_2711b_rkmsb,
    input                           i_2711b_rklsb,
    input   [15:0]                  i_2711b_rxd,
    output                          o_2711b_tkmsb,
    output                          o_2711b_tklsb,
    output                          o_2711b_enable,
    output                          o_2711b_loopen,
    output                          o_2711b_lckrefn,
    output                          o_2711b_testen,
    output                          o_2711b_prbsen,
    output                          o_2711b_pre,
    output  [15:0]                  o_2711b_txd,

    //PS interface  
    //AXI4 Memory Mapped Read Address Interface Signals
    input                           tlk2711b_m_axi_arready,
    output                          tlk2711b_m_axi_arvalid,
    output [3:0]                    tlk2711b_m_axi_arid,
    output [ADDR_WIDTH-1:0]         tlk2711b_m_axi_araddr,
    output [7:0]                    tlk2711b_m_axi_arlen,
    output [2:0]                    tlk2711b_m_axi_arsize,
    output [1:0]                    tlk2711b_m_axi_arburst,
    output [2:0]                    tlk2711b_m_axi_arprot,
    output [3:0]                    tlk2711b_m_axi_arcache,
    output                          tlk2711b_m_axi_aruser,
   
    //AXI4 Memory Mapped Read Data Interface Signals
    input [AXI_RDATA_WIDTH-1:0]     tlk2711b_m_axi_rdata,
    input [1:0]                     tlk2711b_m_axi_rresp,
    input                           tlk2711b_m_axi_rlast,
    input                           tlk2711b_m_axi_rvalid,
    output                          tlk2711b_m_axi_rready,

    //AXI4 Memory Mapped Write Address Interface Signals
    input                           tlk2711b_m_axi_awready,
    output                          tlk2711b_m_axi_awvalid,
    output [3:0]                    tlk2711b_m_axi_awid,
    output [ADDR_WIDTH-1:0]         tlk2711b_m_axi_awaddr,
    output [7:0]                    tlk2711b_m_axi_awlen,
    output [2:0]                    tlk2711b_m_axi_awsize,
    output [1:0]                    tlk2711b_m_axi_awburst,
    output [2:0]                    tlk2711b_m_axi_awprot,
    output [3:0]                    tlk2711b_m_axi_awcache,
    output [3:0]                    tlk2711b_m_axi_awuser,   

    //AXI4 Memory Mapped Write Data Interface Signals
    output [AXI_WDATA_WIDTH-1:0]    tlk2711b_m_axi_wdata,
    output [AXI_WBYTE_WIDTH-1:0]    tlk2711b_m_axi_wstrb,
    output                          tlk2711b_m_axi_wlast,
    output                          tlk2711b_m_axi_wvalid,
    input                           tlk2711b_m_axi_wready,
    
    input [1:0]                     tlk2711b_m_axi_bresp,
    input                           tlk2711b_m_axi_bvalid,
    output                          tlk2711b_m_axi_bready,

    // ------------------------ tlk2711a ----------------------------
    
    //interrupt
    output                          o_2711a_tx_irq,
    output                          o_2711a_rx_irq,
    output                          o_2711a_loss_irq,

    input                           i_2711a_rx_clk,
    input                           i_2711a_rkmsb,
    input                           i_2711a_rklsb,
    input   [15:0]                  i_2711a_rxd,
    output                          o_2711a_tkmsb,
    output                          o_2711a_tklsb,
    output                          o_2711a_enable,
    output                          o_2711a_loopen,
    output                          o_2711a_lckrefn,
    output                          o_2711a_testen,
    output                          o_2711a_prbsen,
    output                          o_2711a_pre,
    output  [15:0]                  o_2711a_txd,

    //PS interface  
    //AXI4 Memory Mapped Read Address Interface Signals
    input                           tlk2711a_m_axi_arready,
    output                          tlk2711a_m_axi_arvalid,
    output [3:0]                    tlk2711a_m_axi_arid,
    output [ADDR_WIDTH-1:0]         tlk2711a_m_axi_araddr,
    output [7:0]                    tlk2711a_m_axi_arlen,
    output [2:0]                    tlk2711a_m_axi_arsize,
    output [1:0]                    tlk2711a_m_axi_arburst,
    output [2:0]                    tlk2711a_m_axi_arprot,
    output [3:0]                    tlk2711a_m_axi_arcache,
    output                          tlk2711a_m_axi_aruser,
   
    //AXI4 Memory Mapped Read Data Interface Signals
    input [AXI_RDATA_WIDTH-1:0]     tlk2711a_m_axi_rdata,
    input [1:0]                     tlk2711a_m_axi_rresp,
    input                           tlk2711a_m_axi_rlast,
    input                           tlk2711a_m_axi_rvalid,
    output                          tlk2711a_m_axi_rready,

    //AXI4 Memory Mapped Write Address Interface Signals
    input                           tlk2711a_m_axi_awready,
    output                          tlk2711a_m_axi_awvalid,
    output [3:0]                    tlk2711a_m_axi_awid,
    output [ADDR_WIDTH-1:0]         tlk2711a_m_axi_awaddr,
    output [7:0]                    tlk2711a_m_axi_awlen,
    output [2:0]                    tlk2711a_m_axi_awsize,
    output [1:0]                    tlk2711a_m_axi_awburst,
    output [2:0]                    tlk2711a_m_axi_awprot,
    output [3:0]                    tlk2711a_m_axi_awcache,
    output [3:0]                    tlk2711a_m_axi_awuser,   

    //AXI4 Memory Mapped Write Data Interface Signals
    output [AXI_WDATA_WIDTH-1:0]    tlk2711a_m_axi_wdata,
    output [AXI_WBYTE_WIDTH-1:0]    tlk2711a_m_axi_wstrb,
    output                          tlk2711a_m_axi_wlast,
    output                          tlk2711a_m_axi_wvalid,
    input                           tlk2711a_m_axi_wready,
    
    input [1:0]                     tlk2711a_m_axi_bresp,
    input                           tlk2711a_m_axi_bvalid,
    output                          tlk2711a_m_axi_bready
);

wire [63:0]    a_reg_rdata;
wire [63:0]    b_reg_rdata;

assign o_reg_rdata = a_reg_rdata | b_reg_rdata;

tlk2711_top #(
    .DEBUG_ENA(DEBUG_ENA),
    .ADDR_WIDTH(ADDR_WIDTH),
    .AXI_RDATA_WIDTH(AXI_RDATA_WIDTH), 
    .AXI_WDATA_WIDTH(AXI_WDATA_WIDTH), 
    .AXI_WBYTE_WIDTH(AXI_WDATA_WIDTH/8),  
    .STREAM_RDATA_WIDTH(STREAM_RDATA_WIDTH), 
    .STREAM_WDATA_WIDTH(STREAM_WDATA_WIDTH),
    .STREAM_WBYTE_WIDTH(STREAM_WBYTE_WIDTH),  
    .DLEN_WIDTH(DLEN_WIDTH),
    .ADDR_MASK(TLK2711B_ADDR_MASK),
    .ADDR_BASE(TLK2711B_ADDR_BASE)
) tlk2711b_top (
    .ps_clk(ps_clk),
    .ps_rst(ps_rst),

    .i_reg_wen(i_reg_wen),
    .i_reg_waddr(i_reg_waddr),
    .i_reg_wdata(i_reg_wdata),    
    .i_reg_ren(i_reg_ren),
    .i_reg_raddr(i_reg_raddr),
    .o_reg_rdata(b_reg_rdata), 

    .clk(clk),
    .rst(rst),
    //interrupt
    .o_tx_irq(o_2711b_tx_irq),
    .o_rx_irq(o_2711b_rx_irq),
    .o_loss_irq(o_2711b_loss_irq),

    //tlk2711 interface
    // TODO rx should use rx_clk
    .i_2711_rx_clk(i_2711b_rx_clk),
    .i_2711_rkmsb(i_2711b_rkmsb),
    .i_2711_rklsb(i_2711b_rklsb),
    .i_2711_rxd(i_2711b_rxd),

    .o_2711_tkmsb(o_2711b_tkmsb),
    .o_2711_tklsb(o_2711b_tklsb),
    .o_2711_enable(o_2711b_enable),
    .o_2711_loopen(o_2711b_loopen),
    .o_2711_lckrefn(o_2711b_lckrefn),
    .o_2711_testen(o_2711b_testen),
    .o_2711_prbsen(o_2711b_prbsen),
    .o_2711_pre(o_2711b_pre),
    .o_2711_txd(o_2711b_txd),

    .m_axi_arready(tlk2711b_m_axi_arready),
    .m_axi_arvalid(tlk2711b_m_axi_arvalid),
    .m_axi_arid   (tlk2711b_m_axi_arid   ),
    .m_axi_araddr (tlk2711b_m_axi_araddr ),
    .m_axi_arlen  (tlk2711b_m_axi_arlen  ),
    .m_axi_arsize (tlk2711b_m_axi_arsize ),
    .m_axi_arburst(tlk2711b_m_axi_arburst),
    .m_axi_arprot (tlk2711b_m_axi_arprot ),
    .m_axi_arcache(tlk2711b_m_axi_arcache),
    .m_axi_aruser (tlk2711b_m_axi_aruser ),  

    .m_axi_rdata  (tlk2711b_m_axi_rdata  ),
    .m_axi_rresp  (tlk2711b_m_axi_rresp  ),
    .m_axi_rlast  (tlk2711b_m_axi_rlast  ),
    .m_axi_rvalid (tlk2711b_m_axi_rvalid ),
    .m_axi_rready (tlk2711b_m_axi_rready ),

    .m_axi_awready(tlk2711b_m_axi_awready),
    .m_axi_awvalid(tlk2711b_m_axi_awvalid),
    .m_axi_awid   (tlk2711b_m_axi_awid   ),
    .m_axi_awaddr (tlk2711b_m_axi_awaddr ),
    .m_axi_awlen  (tlk2711b_m_axi_awlen  ),
    .m_axi_awsize (tlk2711b_m_axi_awsize ),
    .m_axi_awburst(tlk2711b_m_axi_awburst),
    .m_axi_awprot (tlk2711b_m_axi_awprot ),
    .m_axi_awcache(tlk2711b_m_axi_awcache),
    .m_axi_awuser (tlk2711b_m_axi_awuser ),   

    .m_axi_wdata  (tlk2711b_m_axi_wdata  ),
    .m_axi_wstrb  (tlk2711b_m_axi_wstrb  ),
    .m_axi_wlast  (tlk2711b_m_axi_wlast  ),
    .m_axi_wvalid (tlk2711b_m_axi_wvalid ),
    .m_axi_wready (tlk2711b_m_axi_wready ),
    .m_axi_bresp  (tlk2711b_m_axi_bresp  ),
    .m_axi_bvalid (tlk2711b_m_axi_bvalid ),
    .m_axi_bready (tlk2711b_m_axi_bready )
);

tlk2711_top #(    
    .ADDR_WIDTH(ADDR_WIDTH),
    .AXI_RDATA_WIDTH(AXI_RDATA_WIDTH), 
    .AXI_WDATA_WIDTH(AXI_WDATA_WIDTH), 
    .AXI_WBYTE_WIDTH(AXI_WDATA_WIDTH/8),  
    .STREAM_RDATA_WIDTH(STREAM_RDATA_WIDTH), 
    .STREAM_WDATA_WIDTH(STREAM_WDATA_WIDTH),
    .STREAM_WBYTE_WIDTH(STREAM_WBYTE_WIDTH),  
    .DLEN_WIDTH(DLEN_WIDTH),
    .ADDR_MASK(TLK2711A_ADDR_MASK),
    .ADDR_BASE(TLK2711A_ADDR_BASE)
) tlk2711a_top (
    .ps_clk(ps_clk),
    .ps_rst(ps_rst),

    .i_reg_wen(i_reg_wen),
    .i_reg_waddr(i_reg_waddr),
    .i_reg_wdata(i_reg_wdata),    
    .i_reg_ren(i_reg_ren),
    .i_reg_raddr(i_reg_raddr),
    .o_reg_rdata(a_reg_rdata), 

    .clk(clk),
    .rst(rst),
    //interrupt
    .o_tx_irq(o_2711a_tx_irq),
    .o_rx_irq(o_2711a_rx_irq),
    .o_loss_irq(o_2711a_loss_irq),

    //tlk2711 interface
    // TODO rx should use rx_clk
    .i_2711_rx_clk(i_2711a_rx_clk),
    .i_2711_rkmsb(i_2711a_rkmsb),
    .i_2711_rklsb(i_2711a_rklsb),
    .i_2711_rxd(i_2711a_rxd),

    .o_2711_tkmsb(o_2711a_tkmsb),
    .o_2711_tklsb(o_2711a_tklsb),
    .o_2711_enable(o_2711a_enable),
    .o_2711_loopen(o_2711a_loopen),
    .o_2711_lckrefn(o_2711a_lckrefn),
    .o_2711_testen(o_2711a_testen),
    .o_2711_prbsen(o_2711a_prbsen),
    .o_2711_pre(o_2711a_pre),
    .o_2711_txd(o_2711a_txd),

    .m_axi_arready(tlk2711a_m_axi_arready),
    .m_axi_arvalid(tlk2711a_m_axi_arvalid),
    .m_axi_arid   (tlk2711a_m_axi_arid   ),
    .m_axi_araddr (tlk2711a_m_axi_araddr ),
    .m_axi_arlen  (tlk2711a_m_axi_arlen  ),
    .m_axi_arsize (tlk2711a_m_axi_arsize ),
    .m_axi_arburst(tlk2711a_m_axi_arburst),
    .m_axi_arprot (tlk2711a_m_axi_arprot ),
    .m_axi_arcache(tlk2711a_m_axi_arcache),
    .m_axi_aruser (tlk2711a_m_axi_aruser ),  

    .m_axi_rdata  (tlk2711a_m_axi_rdata  ),
    .m_axi_rresp  (tlk2711a_m_axi_rresp  ),
    .m_axi_rlast  (tlk2711a_m_axi_rlast  ),
    .m_axi_rvalid (tlk2711a_m_axi_rvalid ),
    .m_axi_rready (tlk2711a_m_axi_rready ),

    .m_axi_awready(tlk2711a_m_axi_awready),
    .m_axi_awvalid(tlk2711a_m_axi_awvalid),
    .m_axi_awid   (tlk2711a_m_axi_awid   ),
    .m_axi_awaddr (tlk2711a_m_axi_awaddr ),
    .m_axi_awlen  (tlk2711a_m_axi_awlen  ),
    .m_axi_awsize (tlk2711a_m_axi_awsize ),
    .m_axi_awburst(tlk2711a_m_axi_awburst),
    .m_axi_awprot (tlk2711a_m_axi_awprot ),
    .m_axi_awcache(tlk2711a_m_axi_awcache),
    .m_axi_awuser (tlk2711a_m_axi_awuser ),   

    .m_axi_wdata  (tlk2711a_m_axi_wdata  ),
    .m_axi_wstrb  (tlk2711a_m_axi_wstrb  ),
    .m_axi_wlast  (tlk2711a_m_axi_wlast  ),
    .m_axi_wvalid (tlk2711a_m_axi_wvalid ),
    .m_axi_wready (tlk2711a_m_axi_wready ),
    .m_axi_bresp  (tlk2711a_m_axi_bresp  ),
    .m_axi_bvalid (tlk2711a_m_axi_bvalid ),
    .m_axi_bready (tlk2711a_m_axi_bready )
);

endmodule