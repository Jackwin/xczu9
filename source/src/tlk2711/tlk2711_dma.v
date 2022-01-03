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

    wire                        s2mm_sts_tvalid, s2mm_sts_tkeep;
    wire [7:0]                  s2mm_sts_tdata;

    wire                        mm2s_sts_tvalid;
    wire [7:0]                  mm2s_sts_tdata;
    wire                        mm2s_sts_tkeep;
    wire                        mm2s_sts_tlast;

// --------------------- signals for DMA validation begin-------------------------
    wire                        dm_start;
    reg [15:0]                  dm_length;
    wire                        dm_start_vio;
    reg                         dm_start_vio_r0;
    reg                         dm_start_vio_p;
    wire [15:0]                 dm_length_vio;
    reg                         dm_start_gpio;
    reg                         gpio_r0;

    reg [ADDR_WIDTH-1:0]        dm_start_addr;
    wire [ADDR_WIDTH-1:0]       dm_start_addr_vio;

    reg [ADDR_WIDTH-1:0]        dm_start_rd_addr;
    wire [ADDR_WIDTH-1:0]       dm_start_rd_addr_vio;

    reg [15:0]                  dm_rd_length;
    wire [15:0]                 dm_rd_length_vio;

    wire                        user_mm2s_rd_cmd_tvalid;
    wire                        user_mm2s_rd_cmd_tready;
    wire [39+ADDR_WIDTH:0]      user_mm2s_rd_cmd_tdata;
    wire [127:0]                user_mm2s_rd_tdata;
    wire [15:0]                 user_mm2s_rd_tkeep;
    wire                        user_mm2s_rd_tlast;
    wire                        user_mm2s_rd_tready;

    wire                        user_s2mm_wr_cmd_tready;
    wire                        user_s2mm_wr_cmd_tvalid;
    wire [39+ADDR_WIDTH:0]      user_s2mm_wr_cmd_tdata;
    wire                        user_s2mm_wr_tvalid;
    wire [63:0]                 user_s2mm_wr_tdata;
    wire                        user_s2mm_wr_tready;
    wire [7:0]                  user_s2mm_wr_tkeep;
    wire                        user_s2mm_wr_tlast;

    wire                        user_s2mm_sts_tvalid;
    wire [7:0]                  user_s2mm_sts_tdata;
    wire                        user_s2mm_sts_tkeep;
    wire                        user_s2mm_sts_tlast;

    wire [7:0]                  m_axis_mm2s_sts_tdata;  
    wire                        m_axis_mm2s_sts_tkeep;
    wire                        m_axis_mm2s_sts_tlast;

    wire                        s2mm_error;
    wire                        mm2s_error;

// --------------------- signals for DMA validation end-------------------------

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
        .mm2s_err                    (mm2s_error),
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

        .m_axis_mm2s_sts_tvalid      (mm2s_sts_tvalid),
        .m_axis_mm2s_sts_tready      (1'b1),
        .m_axis_mm2s_sts_tdata       (mm2s_sts_tdata),
        .m_axis_mm2s_sts_tkeep       (mm2s_sts_tkeep),
        .m_axis_mm2s_sts_tlast       (mm2s_sts_tlast),

        // User Interface

        // .m_axis_mm2s_tdata           (o_dma_rd_data),
        // .m_axis_mm2s_tkeep           (),
        // .m_axis_mm2s_tlast           (rd_last      ),
        // .m_axis_mm2s_tvalid          (o_dma_rd_valid   ),
        // .m_axis_mm2s_tready          (i_dma_rd_ready   ),
      
        // .s_axis_mm2s_cmd_tvalid      (i_rd_cmd_req  ),
        // .s_axis_mm2s_cmd_tready      (o_rd_cmd_ack  ),
        // .s_axis_mm2s_cmd_tdata       (mm2s_cmd_tdata),

        .s_axis_mm2s_cmd_tvalid(user_mm2s_rd_cmd_tvalid),        
        .s_axis_mm2s_cmd_tready(user_mm2s_rd_cmd_tready),       
        .s_axis_mm2s_cmd_tdata(user_mm2s_rd_cmd_tdata),         

        .m_axis_mm2s_tdata(user_mm2s_rd_tdata),
        .m_axis_mm2s_tkeep(user_mm2s_rd_tkeep),
        .m_axis_mm2s_tlast(user_mm2s_rd_tlast),
        .m_axis_mm2s_tvalid(user_mm2s_rd_tvalid),
        .m_axis_mm2s_tready(user_mm2s_rd_tready),

        // AXI data interface-> HP interface

        .m_axi_s2mm_aclk             (clk),
        .m_axi_s2mm_aresetn          (~rst),
        .s2mm_err                    (s2mm_error),
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

        // .m_axis_s2mm_sts_tvalid      (s2mm_sts_tvalid),
        // .m_axis_s2mm_sts_tready      (1'b1),
        // .m_axis_s2mm_sts_tdata       (s2mm_sts_tdata ),
        // .m_axis_s2mm_sts_tkeep       (s2mm_sts_tkeep ),
        // .m_axis_s2mm_sts_tlast       (),

        // .s_axis_s2mm_cmd_tvalid      (i_wr_cmd_req   ),
        // .s_axis_s2mm_cmd_tready      (o_wr_cmd_ack   ),
        // .s_axis_s2mm_cmd_tdata       (s2mm_cmd_tdata ),

        // .s_axis_s2mm_tdata           (i_dma_wr_data    ),
        // .s_axis_s2mm_tkeep           (i_dma_wr_keep    ),
        // .s_axis_s2mm_tlast           ('b0),
        // .s_axis_s2mm_tvalid          (i_dma_wr_valid   ),
        // .s_axis_s2mm_tready          (o_dma_wr_ready   )

        .m_axis_s2mm_sts_tvalid(user_s2mm_sts_tvalid),          // output wire m_axis_s2mm_sts_tvalid
        .m_axis_s2mm_sts_tready(1'b1),          // input wire m_axis_s2mm_sts_tready
        .m_axis_s2mm_sts_tdata(user_s2mm_sts_tdata),            // output wire [7 : 0] m_axis_s2mm_sts_tdata
        .m_axis_s2mm_sts_tkeep(user_s2mm_sts_tkeep),            // output wire [0 : 0] m_axis_s2mm_sts_tkeep
        .m_axis_s2mm_sts_tlast(user_s2mm_sts_tlast),            // output wire m_axis_s2mm_sts_tlast

        .s_axis_s2mm_cmd_tvalid(user_s2mm_wr_cmd_tvalid), 
        .s_axis_s2mm_cmd_tready(user_s2mm_wr_cmd_tready), 
        .s_axis_s2mm_cmd_tdata(user_s2mm_wr_cmd_tdata), 

        .s_axis_s2mm_tdata({user_s2mm_wr_tdata, user_s2mm_wr_tdata}), 
        .s_axis_s2mm_tkeep({user_s2mm_wr_tkeep, user_s2mm_wr_tkeep}),
        .s_axis_s2mm_tlast(user_s2mm_wr_tlast),           
        .s_axis_s2mm_tvalid(user_s2mm_wr_tvalid),         
        .s_axis_s2mm_tready(user_s2mm_wr_tready)          
    );

// always @(posedge clk) begin
//     gpio_r0 <= gpio;
//     dm_start_gpio <= ~gpio_r0 & gpio;
// end

vio_datamover vio_datamover_inst (
  .clk(clk),                // input wire clk
  .probe_out0(dm_start_vio),  // output wire [0 : 0] probe_out0
  .probe_out1(dm_length_vio),  // output wire [8 : 0] probe_out1
  .probe_out2(dm_start_addr_vio),  // output wire [31 : 0] probe_out2
  .probe_out3(dm_rd_length_vio),
  .probe_out4(dm_start_rd_addr_vio)
);

assign dm_start = dm_start_vio;

always @(posedge clk) begin
    dm_start_vio_r0 <= dm_start_vio;
    dm_start_vio_p <= ~dm_start_vio_r0 & dm_start_vio;
end

always @(posedge clk) begin
    if (rst) begin
        dm_length <= 'h0;
        dm_start_addr <= 'h0;
    end else begin
        // if (dm_start_gpio) begin
        //     dm_length <= 9'h080;
        //     dm_start_addr <= 32'h3000_0000;
        //     dm_rd_length <= 9'h080;
        //     dm_start_rd_addr <= 32'h4000_0000;
        // end else if (dm_start_vio_p) begin
        if (dm_start_vio_p) begin
            dm_length <= dm_length_vio;
            dm_start_addr<= dm_start_addr_vio;
            dm_rd_length <= dm_rd_length_vio;
            dm_start_rd_addr<= dm_start_rd_addr_vio;
        end
    end
    
end

datamover_validation  # (
    .DDR_ADDR_WIDTH(ADDR_WIDTH),
    .INIT_DATA(64'h0706050403020100)
    )datamover_validation_inst(
    .clk(clk),
    .rst(rst),

    .i_start(dm_start),
    .i_length(dm_length),
    .i_start_addr(dm_start_addr),
    .i_rd_length(dm_rd_length),
    .i_start_rd_addr(dm_start_rd_addr),

    // FPGA -> CPU
    .i_s2mm_wr_cmd_tready(user_s2mm_wr_cmd_tready),
    .o_s2mm_wr_cmd_tdata(user_s2mm_wr_cmd_tdata),
    .o_s2mm_wr_cmd_tvalid(user_s2mm_wr_cmd_tvalid),

    .o_s2mm_wr_tdata(user_s2mm_wr_tdata),
    .o_s2mm_wr_tkeep(user_s2mm_wr_tkeep),
    .o_s2mm_wr_tvalid(user_s2mm_wr_tvalid),
    .o_s2mm_wr_tlast(user_s2mm_wr_tlast),
    .i_s2mm_wr_tready(user_s2mm_wr_tready),

    .s2mm_sts_tdata(user_s2mm_sts_tdata),
    .s2mm_sts_tvalid(user_s2mm_sts_tvalid),
    .s2mm_sts_tkeep(user_s2mm_sts_tkeep),
    .s2mm_sts_tlast(user_s2mm_sts_tlast),

    // CPU -> FPGA
    .i_mm2s_rd_cmd_tready(user_mm2s_rd_cmd_tready),
    .o_mm2s_rd_cmd_tdata(user_mm2s_rd_cmd_tdata),
    .o_mm2s_rd_cmd_tvalid(user_mm2s_rd_cmd_tvalid),

    .i_mm2s_rd_tdata(user_mm2s_rd_tdata),
    .i_mms2_rd_tkeep(user_mm2s_rd_tkeep),
    .i_mm2s_rd_tvalid(user_mm2s_rd_tvalid),
    .i_mm2s_rd_tlast(user_mm2s_rd_tlast),
    .o_mm2s_rd_tready(user_mm2s_rd_tready)
);

ila_datamover ila_datamover_inst (
	.clk(clk), // input wire clk

	.probe0(user_s2mm_wr_cmd_tready), // input wire [0:0]  probe0  
	.probe1(user_s2mm_wr_cmd_tdata), // input wire [71:0]  probe1 
	.probe2(user_s2mm_wr_cmd_tvalid), // input wire [0:0]  probe2 
	.probe3(user_s2mm_wr_tdata), // input wire [63:0]  probe3 
	.probe4(user_s2mm_wr_tkeep), // input wire [7:0]  probe4 
	.probe5(user_s2mm_wr_tlast), // input wire [0:0]  probe5 
	.probe6(user_s2mm_wr_tvalid), // input wire [0:0]  probe6 
	.probe7(user_s2mm_wr_tready), // input wire [0:0]  probe7 
	.probe8(user_s2mm_sts_tvalid), // input wire [0:0]  probe8 
	.probe9(user_s2mm_sts_tdata), // input wire [3:0]  probe9 
	.probe10(user_s2mm_sts_tlast), // input wire [0:0]  probe10 
	.probe11(user_mm2s_rd_tdata), // input wire [63:0]  probe11 
	.probe12(user_mm2s_rd_tkeep), // input wire [7:0]  probe12 
	.probe13(user_mm2s_rd_tlast), // input wire [0:0]  probe13 
	.probe14(user_mm2s_rd_tvalid), // input wire [0:0]  probe14 
	.probe15(user_mm2s_rd_cmd_tvalid), // input wire [0:0]  probe15 
	.probe16(user_mm2s_rd_cmd_tdata), // input wire [71:0]  probe16 
	.probe17(user_mm2s_rd_cmd_tready), // input wire [0:0]  probe17
	.probe18(mm2s_error),
    .probe19(mm2s_sts_tkeep), // input wire [0:0]  probe19 
	.probe20(mm2s_sts_tlast), // input wire [0:0]  probe20 
	.probe21(mm2s_sts_tvalid), // input wire [0:0]  probe21 
	.probe22(mm2s_sts_tdata), // input wire [7:0]  probe22
	.probe23(s2mm_error),
    .probe24(m_axi_wdata),
    .probe25(m_axi_wstrb),
    .probe26(m_axi_wlast),
    .probe27(m_axi_wvalid),
    .probe28(m_axi_wready)

);

endmodule 
         
         
         
         
         
         
         
