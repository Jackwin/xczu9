///////////////////////////////////////////////////////////////////////////////
//  
//    Version: 1.0
//    Filename:  tlk2711_dma.v
//    Date Created: 2021-06-27
// 
//   
// Project: TLK2711
// Device: zu9eg
// Purpose: dma transfer
// Author: Zhu Lin
// Reference:  
// Revision History:
//   Rev 1.0 - First created, zhulin, 2021-06-27
//   
// Email: 
////////////////////////////////////////////////////////////////////////////////

module  tlk2711_dma
#(
	parameter AXI_RDATA_WIDTH = 64,
	parameter AXI_WDATA_WIDTH = 64, 
    parameter AXI_WBYTE_WIDTH = 8,

    parameter STREAM_RDATA_WIDTH = 64,
	parameter STREAM_WDATA_WIDTH = 64, 
    parameter STREAM_WBYTE_WIDTH = 8,

    parameter ADDR_WIDTH = 32,
	parameter DLEN_WIDTH = 16    
)
(
    input                               clk,
    input                               rst,
    
    //read cmd interface
    input [DLEN_WIDTH+ADDR_WIDTH-1:0]   i_rd_cmd_data, //high for saddr, low for byte len
    input                               i_rd_cmd_req,
    output                              o_rd_cmd_ack,
    
    //write cmd interface
    input  [DLEN_WIDTH+ADDR_WIDTH-1:0]  i_wr_cmd_data, //high for saddr, low for byte len
    input                               i_wr_cmd_req,
    output                              o_wr_cmd_ack,
    
    //read data interface 
    input                               i_dma_rd_ready,
    output                              o_dma_rd_valid,
    output                              o_dma_rd_last,
    output [STREAM_RDATA_WIDTH-1:0]     o_dma_rd_data,
    
    //write data interface
    input                               i_dma_wr_valid,
    input  [STREAM_WBYTE_WIDTH-1:0]     i_dma_wr_keep,
    input  [STREAM_WDATA_WIDTH-1:0]     i_dma_wr_data,
    output                              o_dma_wr_ready,

    output  reg                         o_wr_finish,

    //PS interface  
    //AXI4 Memory Mapped Read Address Interface Signals
    input                               m_axi_arready,
    output                              m_axi_arvalid,
    output [3:0]                        m_axi_arid,
    output [ADDR_WIDTH-1:0]             m_axi_araddr,
    output [7:0]                        m_axi_arlen,
    output [2:0]                        m_axi_arsize,
    output [1:0]                        m_axi_arburst,
    output [2:0]                        m_axi_arprot,
    output [3:0]                        m_axi_arcache,
    output [3:0]                        m_axi_aruser,
   
    //AXI4 Memory Mapped Read Data Interface Signals
    input [AXI_RDATA_WIDTH-1:0]         m_axi_rdata,
    input [1:0]                         m_axi_rresp,
    input                               m_axi_rlast,
    input                               m_axi_rvalid,
    output                              m_axi_rready,

    //AXI4 Memory Mapped Write Address Interface Signals
    input                               m_axi_awready,
    output                              m_axi_awvalid,
    output [3:0]                        m_axi_awid,
    output [ADDR_WIDTH-1:0]             m_axi_awaddr,
    output [7:0]                        m_axi_awlen,
    output [2:0]                        m_axi_awsize,
    output [1:0]                        m_axi_awburst,
    output [2:0]                        m_axi_awprot,
    output [3:0]                        m_axi_awcache,
    output [3:0]                        m_axi_awuser,   

    //AXI4 Memory Mapped Write Data Interface Signals
    output [AXI_WDATA_WIDTH-1:0]        m_axi_wdata,
    output [AXI_WBYTE_WIDTH-1:0]        m_axi_wstrb,
    output                              m_axi_wlast,
    output                              m_axi_wvalid,
    input                               m_axi_wready,

    input [1:0]                         m_axi_bresp,
    input                               m_axi_bvalid,
    output                              m_axi_bready
);
    
    wire [40+ADDR_WIDTH-1:0]  mm2s_cmd_tdata;   
    wire [40+ADDR_WIDTH-1:0]  s2mm_cmd_tdata;   
    wire [ADDR_WIDTH-1:0] rd_saddr, wr_saddr;
    wire [22:0] rd_bbt, wr_bbt;

    wire         s2mm_sts_tvalid, s2mm_sts_tkeep;
    wire [7:0]   s2mm_sts_tdata;

    wire        mm2s_sts_tvalid;
    wire [7:0]  mm2s_sts_tdata;
    wire        mm2s_sts_tkeep;
    wire        mm2s_sts_tlast;
    
    localparam   WR_EOF_VAL = 4'b1010;
    
    assign rd_saddr = i_rd_cmd_data[DLEN_WIDTH+ADDR_WIDTH-1:DLEN_WIDTH];
    assign wr_saddr = i_wr_cmd_data[DLEN_WIDTH+ADDR_WIDTH-1:DLEN_WIDTH];
    
    assign rd_bbt[DLEN_WIDTH-1:0] = i_rd_cmd_data[DLEN_WIDTH-1:0];
    assign rd_bbt[22:DLEN_WIDTH] = 'd0;
    assign wr_bbt[DLEN_WIDTH-1:0] = i_wr_cmd_data[DLEN_WIDTH-1:0];
    assign wr_bbt[22:DLEN_WIDTH] = 'd0;
    
    assign mm2s_cmd_tdata = {8'd0, rd_saddr, 2'd1, 7'd1, rd_bbt}; 
    assign s2mm_cmd_tdata = {4'd0, WR_EOF_VAL, wr_saddr, 2'd0, 7'd1, wr_bbt};
    
    always@(posedge clk)
    begin 
    	if (rst)
    	begin
    		  o_wr_finish <= 1'b0;
    	end
    	else
    	begin
    		  if (o_wr_finish)
    		      o_wr_finish <= 1'b0;
    		  else if ((s2mm_sts_tvalid) & (s2mm_sts_tdata[3:0] == WR_EOF_VAL) & s2mm_sts_tkeep)
    		      o_wr_finish <= 1'b1;
    		     
    	end
    end	
    
    wire rd_last;
    assign o_dma_rd_last = rd_last & o_dma_rd_valid & i_dma_rd_ready;
    
    tlk2711_datamover tlk2711_datamover(
        .m_axi_mm2s_aclk             (clk),
        .m_axi_mm2s_aresetn          (~rst),
        .mm2s_err                    (),
        .m_axis_mm2s_cmdsts_aclk     (clk),
        .m_axis_mm2s_cmdsts_aresetn  (~rst),
    
        .m_axi_mm2s_arid             (m_axi_arid   ),
        .m_axi_mm2s_araddr           (m_axi_araddr ),
        .m_axi_mm2s_arlen            (m_axi_arlen  ),
        .m_axi_mm2s_arsize           (m_axi_arsize ),
        .m_axi_mm2s_arburst          (m_axi_arburst),
        .m_axi_mm2s_arprot           (m_axi_arprot ),
        .m_axi_mm2s_arcache          (m_axi_arcache),
        .m_axi_mm2s_aruser           (m_axi_aruser ),
        .m_axi_mm2s_arvalid          (m_axi_arvalid ),
        .m_axi_mm2s_arready          (m_axi_arready),

        .m_axi_mm2s_rdata            (m_axi_rdata  ),
        .m_axi_mm2s_rresp            (m_axi_rresp  ),
        .m_axi_mm2s_rlast            (m_axi_rlast  ),
        .m_axi_mm2s_rvalid           (m_axi_rvalid ),
        .m_axi_mm2s_rready           (m_axi_rready ),
        .m_axis_mm2s_tdata           (o_dma_rd_data    ),

        // User Interface
        .s_axis_mm2s_cmd_tvalid      (i_rd_cmd_req  ),
        .s_axis_mm2s_cmd_tready      (o_rd_cmd_ack  ),
        .s_axis_mm2s_cmd_tdata       (mm2s_cmd_tdata),

        

        .m_axis_mm2s_tkeep           (),
        .m_axis_mm2s_tlast           (rd_last      ),
        .m_axis_mm2s_tvalid          (o_dma_rd_valid   ),
        .m_axis_mm2s_tready          (i_dma_rd_ready   ),
      

        .m_axis_mm2s_sts_tvalid      (mm2s_sts_tvalid),
        .m_axis_mm2s_sts_tready      (1'b1),
        .m_axis_mm2s_sts_tdata       (mm2s_sts_tdata),
        .m_axis_mm2s_sts_tkeep       (mm2s_sts_tkeep),
        .m_axis_mm2s_sts_tlast       (mm2s_sts_tlast),

        // AXI data interface-> HP interface

        .m_axi_s2mm_aclk             (clk),
        .m_axi_s2mm_aresetn          (~rst),
        .s2mm_err                    (),
        .m_axis_s2mm_cmdsts_awclk    (clk),
        .m_axis_s2mm_cmdsts_aresetn  (~rst),

        .m_axi_s2mm_awid             (m_axi_awid   ),
        .m_axi_s2mm_awaddr           (m_axi_awaddr ),
        .m_axi_s2mm_awlen            (m_axi_awlen  ),
        .m_axi_s2mm_awsize           (m_axi_awsize ),
        .m_axi_s2mm_awburst          (m_axi_awburst),
        .m_axi_s2mm_awprot           (m_axi_awprot ),
        .m_axi_s2mm_awcache          (m_axi_awcache),
        .m_axi_s2mm_awuser           (m_axi_awuser ),
        .m_axi_s2mm_awvalid          (m_axi_awvalid),
        .m_axi_s2mm_awready          (m_axi_awready),
        
        
        .m_axi_s2mm_wdata            (m_axi_wdata  ),
        .m_axi_s2mm_wstrb            (m_axi_wstrb  ),
        .m_axi_s2mm_wlast            (m_axi_wlast  ),
        .m_axi_s2mm_wvalid           (m_axi_wvalid ),
        .m_axi_s2mm_wready           (m_axi_wready ),

        .m_axi_s2mm_bresp            (m_axi_bresp  ),
        .m_axi_s2mm_bvalid           (m_axi_bvalid ),
        .m_axi_s2mm_bready           (m_axi_bready ),

        // User Interface

        .m_axis_s2mm_sts_tvalid      (s2mm_sts_tvalid),
        .m_axis_s2mm_sts_tready      (1'b1),
        .m_axis_s2mm_sts_tdata       (s2mm_sts_tdata ),
        .m_axis_s2mm_sts_tkeep       (s2mm_sts_tkeep ),
        .m_axis_s2mm_sts_tlast       (),

        .s_axis_s2mm_cmd_tvalid      (i_wr_cmd_req   ),
        .s_axis_s2mm_cmd_tready      (o_wr_cmd_ack   ),
        .s_axis_s2mm_cmd_tdata       (s2mm_cmd_tdata ),

        .s_axis_s2mm_tdata           (i_dma_wr_data    ),
        .s_axis_s2mm_tkeep           (i_dma_wr_keep    ),
        .s_axis_s2mm_tlast           ('b0),
        .s_axis_s2mm_tvalid          (i_dma_wr_valid   ),
        .s_axis_s2mm_tready          (o_dma_wr_ready   )
    );
 
endmodule 
         
         
         
         
         
         
         
