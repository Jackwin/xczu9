//`define TLK2711_TEST 1
module top (

input           sys_clk_50,
input           sys_rstn,
// tlk2711 B
output [15:0]   tlk2711b_txd,
output          tlk2711b_loopen,
output          tlk2711b_gtx_clk,
output          tlk2711b_tkmsb,
output          tlk2711b_prbsen,
output          tlk2711b_enable,
output          tlk2711b_lckrefn,
output          tlk2711b_tklsb,

input [15:0]    tlk2711b_rxd,
input           tlk2711b_rklsb,
input           tlk2711b_rx_clk,
output          tlk2711b_testen,
input           tlk2711b_rkmsb,
// tlk2711 A
output [15:0]   tlk2711a_txd,
output          tlk2711a_loopen,
output          tlk2711a_gtx_clk,
output          tlk2711a_tkmsb,
output          tlk2711a_prbsen,
output          tlk2711a_enable,
output          tlk2711a_lckrefn,
output          tlk2711a_tklsb,

input [15:0]    tlk2711a_rxd,
input           tlk2711a_rklsb,
input           tlk2711a_rx_clk,
output          tlk2711a_testen,
input           tlk2711a_rkmsb,

output          phy1_resetn,
/*
output          emmc_clk,
inout           emmc_cmd_io,
inout [7:0]     emmc_data_io,
output          emmc_rstn,


output          mdio_phy_mdc,
inout           mdio_phy_mdio_io,
output          phy_resetn,
input [3:0]     rgmii_rd,
input           rgmii_rx_ctl,
input           rgmii_rxc,
output [3:0]    rgmii_td,
output          rgmii_tx_ctl,
output          rgmii_txc,
*/
input           uart_0_rxd,
output          uart_0_txd,

// user led in the network board

output          usr_led

);

parameter DDR_ADDR_WIDTH = 40;
parameter HP0_DATA_WIDTH = 128;
parameter STREAM_DATA_WIDTH = 64;

wire    clk_80;
wire    locked;
wire    rst_80;
wire    clk_375;

wire [3:0]                  m_axi_arid;
wire [DDR_ADDR_WIDTH-1:0]   m_axi_araddr;
wire [7:0]                  m_axi_arlen;
wire [2:0]                  m_axi_arsize;
wire [1:0]                  m_axi_arburst;
wire [2:0]                  m_axi_arprot;
wire [3:0]                  m_axi_arcache;
wire [3:0]                  m_axi_aruser;
wire                        m_axi_arvalid;
wire                        m_axi_arready;
wire [HP0_DATA_WIDTH-1:0]   m_axi_rdata;
wire [1:0]                  m_axi_rresp;
wire                        m_axi_rlast;
wire                        m_axi_rvalid;
wire                        m_axi_rready;
wire [3:0]                  m_axi_awid;
wire [DDR_ADDR_WIDTH-1:0]   m_axi_awaddr;
wire [7:0]                  m_axi_awlen;
wire [2:0]                  m_axi_awsize;
wire [1:0]                  m_axi_awburst;
wire [2:0]                  m_axi_awprot;
wire [3:0]                  m_axi_awcache;
wire [3:0]                  m_axi_awuser;
wire                        m_axi_awvalid;
wire                        m_axi_awready;
wire [HP0_DATA_WIDTH-1:0]   m_axi_wdata;
wire [7:0]                  m_axi_wstrb;
wire                        m_axi_wlast;
wire                        m_axi_wvalid;
wire                        m_axi_wready;
wire [1:0]                  m_axi_bresp;
wire                        m_axi_bvalid;
wire                        m_axi_bready;

wire                        fpga_reg_wen;
wire                        fpga_reg_ren;
wire [15:0]                 fpga_reg_waddr;
wire [15:0]                 fpga_reg_raddr;
wire [63:0]   fpga_reg_wdata;
wire [631:0]   fpga_reg_rdata;

wire                        tlk2711_tx_irq;
wire                        tlk2711_rx_irq;
wire                        tlk2711_loss_irq;

// ------------------ Test DMA -----------------
//wire [5:0]      hp2_bid;
wire [1:0]      hp2_bresp;
wire            hp2_bvalid;

wire [127:0]    hp2_rdata;
//wire [5:0]      hp2_rid;
wire            hp2_rlast;
wire [1:0]      hp2_rresp;
wire            hp2_rvalid;
wire            hp2_rready;
 
wire [DDR_ADDR_WIDTH-1:0]     hp2_araddr;
wire [1:0]      hp2_arburst;
wire [3:0]      hp2_arcache;
wire [3:0]      hp2_arid;
wire [7:0]      hp2_arlen;
wire            hp2_aruser;
wire            hp2_arlock;
wire [2:0]      hp2_arprot;
//wire [3:0]      hp2_arqos;
wire [2:0]      hp2_arsize;
wire            hp2_arvalid;
wire            hp2_arready;

wire [DDR_ADDR_WIDTH-1:0]     hp2_awaddr;
wire [1:0]      hp2_awburst;
wire [3:0]      hp2_awcache;
wire [3:0]      hp2_awid;
wire [7:0]      hp2_awlen;
wire            hp2_awlock;
wire [2:0]      hp2_awprot;
//wire [3:0]      hp2_awqos;
wire [2:0]      hp2_awsize;
wire            hp2_awvalid;
wire            hp2_awuser;
wire            hp2_awready;

wire [127:0]    hp2_wdata;
wire [5:0]      hp2_wid;
wire            hp2_wlast;
wire [15:0]     hp2_wstrb;
wire            hp2_wvalid;

wire            user_mm2s_rd_cmd_tvalid;
wire            user_mm2s_rd_cmd_tready;
wire [39+DDR_ADDR_WIDTH:0]     user_mm2s_rd_cmd_tdata;
wire [63:0]     user_mm2s_rd_tdata;
wire [7:0]      user_mm2s_rd_tkeep;
wire            user_mm2s_rd_tlast;
wire            user_mm2s_rd_tready;

wire            user_s2mm_wr_cmd_tready;
wire            user_s2mm_wr_cmd_tvalid;
wire [39+DDR_ADDR_WIDTH:0]     user_s2mm_wr_cmd_tdata;
wire            user_s2mm_wr_tvalid;
wire [63:0]     user_s2mm_wr_tdata;
wire            user_s2mm_wr_tready;
wire [7:0]      user_s2mm_wr_tkeep;
wire            user_s2mm_wr_tlast;

wire            user_s2mm_sts_tvalid;
wire [7:0]      user_s2mm_sts_tdata;
wire            user_s2mm_sts_tkeep;
wire            user_s2mm_sts_tlast;

 wire [7:0]     m_axis_mm2s_sts_tdata;  
wire            m_axis_mm2s_sts_tkeep;
wire            m_axis_mm2s_sts_tlast;

wire            s2mm_error;
wire            mm2s_error;

wire            gpio;

clk_wiz_0 clk_wiz_inst (
    .clk_in1(sys_clk_50),
    .reset(~sys_rstn), 
    .locked(locked),
    .clk_80(clk_80),
    .clk_375(clk_375)
   
);

reset_bridge reset_80_inst(
    .clk(clk_80),    
    .arst_n(locked),  
    .srst(rst_80)
);

// --------------------- user led --------------------------------

reg [26:0]  led_cnt;

always @(posedge clk_80) begin
    if (rst_80) begin
        led_cnt <= 'h0;
    end else begin
        led_cnt <= led_cnt + 1'd1;
    end
end

assign usr_led = led_cnt[26];

// --------------------- ethernet phy1 ---------------------------
reg [15:0]     eth_rst_cnt;

always @(posedge clk_80) begin
    if (rst_80) begin
        eth_rst_cnt <= 'h0;
    end else if (&eth_rst_cnt != 1'b1) begin
        eth_rst_cnt <= eth_rst_cnt + 1'b1;
    end
end
assign phy1_resetn = &eth_rst_cnt;
assign phy_resetn = &eth_rst_cnt;

//----------------------- emmc ------------------------------------
/*
wire          emmc_buspow;
wire          [2:0]emmc_busvolt;

wire          emmc_cmd_i;
wire          emmc_cmd_o;
wire          emmc_cmd_t;

wire          mdio_phy_mdio_i;
wire          mdio_phy_mdio_o;
wire          mdio_phy_mdio_t;

IOBUF mdio_phy_mdio_iobuf
    (.I(mdio_phy_mdio_o),
    .IO(mdio_phy_mdio_io),
    .O(mdio_phy_mdio_i),
    .T(mdio_phy_mdio_t));
  
    
IOBUF emmc_cmd_iobuf
    (.I(emmc_cmd_o),
    .IO(emmc_cmd_io),
    .O(emmc_cmd_i),
    .T(emmc_cmd_t));
    
wire [7:0]  emmc_data_i;
wire [7:0]  emmc_data_o;
wire [7:0]  emmc_data_t;

emmc_iobuf emmc_iobuf_inst (
    .emmc_data_i(emmc_data_o),
    .emmc_data_io(emmc_data_io),
    .emmc_data_o(emmc_data_i),
    .emmc_data_t(emmc_data_t)
);
*/

/*
ila_emmc ila_emmc_i (
	.clk(emmc_clk), // input wire clk
	.probe0(emmc_rstn), // input wire [0:0]  probe0  
	.probe1(emmc_rstn), // input wire [0:0]  probe1 
	.probe2(emmc_cmd_o), // input wire [0:0]  probe2 
	.probe3(emmc_cmd_i), // input wire [0:0]  probe3 
	.probe4(emmc_cmd_t), // input wire [0:0]  probe4 
	.probe5(emmc_data_o), // input wire [7:0]  probe5 
	.probe6(emmc_data_i), // input wire [7:0]  probe6 
	.probe7(emmc_data_t) // input wire [7:0]  probe7
);
*/
/*
ila_emmc ila_emmc_i (
	.clk(clk_80), // input wire clk
	.probe0(mdio_phy_mdc), // input wire [0:0]  probe0  
	.probe1(phy_resetn) // input wire [0:0]  probe1 
);
*/

// ------------------------ TLK2711-B --------------------------
assign tlk2711b_gtx_clk = clk_80;
assign tlk2711a_gtx_clk = clk_80;

`ifdef TLK2711_TEST 
wire        tlk2711b_start;
wire        tlk2711b_stop;
wire        tlk2711b_stop_ack;
wire [2:0]  tlk2711b_mode;

vio_tlk2711 vio_tlk2711b_i (
  .clk(clk_80),                
  .probe_out0(tlk2711b_start),  
  .probe_out1(tlk2711b_mode),  
  .probe_out2(tlk2711b_stop) 
);
tlk2711 #(
    .DDR_ADDR_WIDTH(DD)
)tlk2711b_inst (
    .clk(clk_80),
    .rst(rst_80),
    .o_txd(tlk2711b_txd),
    .i_start(tlk2711b_start),
    .i_mode(tlk2711b_mode),
    .i_stop(tlk2711b_stop),
    .o_stop_ack(tlk2711b_stop_ack),
    .o_tkmsb(tlk2711b_tkmsb),
    .o_tklsb(tlk2711b_tklsb),
    .o_loopen(tlk2711b_loopen),
    .o_prbsen(tlk2711b_prbsen),
    .o_enable(tlk2711b_enable),
    .o_lckrefn(tlk2711b_lckrefn),
    .o_testen(tlk2711b_testen),

    .rx_clk(tlk2711b_rx_clk),
    .i_rkmsb(tlk2711b_rkmsb),
    .i_rklsb(tlk2711b_rklsb),
    .i_rxd(tlk2711b_rxd)
);


// ------------------------ TLK2711-A --------------------------
wire        tlk2711a_start;
wire        tlk2711a_stop;
wire        tlk2711a_stop_ack;
wire [2:0]  tlk2711a_mode;

vio_tlk2711 vio_tlk2711a_i (
  .clk(clk_80),                
  .probe_out0(tlk2711a_start),  
  .probe_out1(tlk2711a_mode),  
  .probe_out2(tlk2711a_stop)
);

tlk2711 tlk2711a_inst (
    .clk(clk_80),
    .rst(rst_80),
    .o_txd(tlk2711a_txd),
    .i_start(tlk2711a_start),
    .i_mode(tlk2711a_mode),
    .i_stop(tlk2711a_stop),
    .o_stop_ack(tlk2711a_stop_ack),
    .o_tkmsb(tlk2711a_tkmsb),
    .o_tklsb(tlk2711a_tklsb),
    .o_loopen(tlk2711a_loopen),
    .o_prbsen(tlk2711a_prbsen),
    .o_enable(tlk2711a_enable),
    .o_lckrefn(tlk2711a_lckrefn),
    .o_testen(tlk2711a_testen),

    .rx_clk(tlk2711a_rx_clk),
    .i_rkmsb(tlk2711a_rkmsb),
    .i_rklsb(tlk2711a_rklsb),
    .i_rxd(tlk2711a_rxd)
);

`else

// -----------------------
    wire                        fpga_reg_wen_vio;
    wire [15:0]                 fpga_reg_waddr_vio;
    wire [63:0]                 fpga_reg_wdata_vio;
    wire                        fpga_reg_ren_vio;           
    wire [15:0]                 fpga_reg_raddr_vio;
    wire [63:0]                 fpga_reg_rdata_vio;

    ila_2711_rx ila_2711_rx_inst (
	.clk(tlk2711b_rx_clk), // input wire clk
	.probe0(tlk2711b_rklsb), // input wire [0:0]  probe0  
	.probe1(tlk2711b_rkmsb), // input wire [0:0]  probe1 
	.probe2(tlk2711b_rxd) // input wire [15:0]  probe2
    );

    vio_tlk2711_reg vio_tlk2711b_reg_i (
        .clk(clk_80),                
        .probe_out0(fpga_reg_wen_vio),
        .probe_out1(fpga_reg_waddr_vio),
        .probe_out2(fpga_reg_wdata_vio),
        .probe_out3(fpga_reg_ren_vio),
        .probe_out4(fpga_reg_raddr_vio),

        .probe_in0(fpga_reg_rdata_vio)
    );

    tlk2711_top #(    
        .ADDR_WIDTH(DDR_ADDR_WIDTH),
	    .AXI_RDATA_WIDTH(HP0_DATA_WIDTH), //HP0_DATA_WIDTH
	    .AXI_WDATA_WIDTH(HP0_DATA_WIDTH), // HP0_DATA_WIDTH
	    .AXI_WBYTE_WIDTH(HP0_DATA_WIDTH/8),  // HP0_DATA_WIDTH/8
        .STREAM_RDATA_WIDTH(STREAM_DATA_WIDTH), 
	    .STREAM_WDATA_WIDTH(STREAM_DATA_WIDTH),
	    .STREAM_WBYTE_WIDTH(STREAM_DATA_WIDTH/8),  
        .DLEN_WIDTH(16)
    ) tlk2711_top (
        .clk(clk_80),
        .rst(rst_80),

        .i_reg_wen(fpga_reg_wen_vio),
        .i_reg_waddr(fpga_reg_waddr_vio),
        .i_reg_wdata(fpga_reg_wdata_vio),    
        .i_reg_ren(fpga_reg_ren_vio),
        .i_reg_raddr(fpga_reg_raddr_vio),
        .o_reg_rdata(fpga_reg_rdata_vio),
        
        // .i_reg_wen(fpga_reg_wen),
        // .i_reg_waddr(fpga_reg_waddr),
        // .i_reg_wdata(fpga_reg_wdata),    
        // .i_reg_ren(fpga_reg_ren),
        // .i_reg_raddr(fpga_reg_raddr),
        // .o_reg_rdata(fpga_reg_rdata), 
        //interrupt
        .o_tx_irq(tlk2711_tx_irq),
        .o_rx_irq(tlk2711_rx_irq),
        .o_loss_irq(tlk2711_loss_irq),
        //tlk2711 interface
        // TODO rx should use rx_clk
        .i_2711_rkmsb(tlk2711b_rkmsb),
        .i_2711_rklsb(tlk2711b_rklsb),
        .i_2711_rxd(tlk2711b_rxd),

        .o_2711_tkmsb(tlk2711b_tkmsb),
        .o_2711_tklsb(tlk2711b_tklsb),
        .o_2711_enable(tlk2711b_enable),
        .o_2711_loopen(tlk2711b_loopen),
        .o_2711_lckrefn(tlk2711b_lckrefn),
        .o_2711_testen(tlk2711b_testen),
        .o_2711_prbsen(tlk2711b_prbsen),
        .o_2711_txd(tlk2711b_txd),

        .m_axi_arready(m_axi_arready),
        .m_axi_arvalid(m_axi_arvalid),
        .m_axi_arid   (m_axi_arid   ),
        .m_axi_araddr (m_axi_araddr ),
        .m_axi_arlen  (m_axi_arlen  ),
        .m_axi_arsize (m_axi_arsize ),
        .m_axi_arburst(m_axi_arburst),
        .m_axi_arprot (m_axi_arprot ),
        .m_axi_arcache(m_axi_arcache),
        .m_axi_aruser (m_axi_aruser ),  

        .m_axi_rdata  (m_axi_rdata  ),
        .m_axi_rresp  (m_axi_rresp  ),
        .m_axi_rlast  (m_axi_rlast  ),
        .m_axi_rvalid (m_axi_rvalid ),
        .m_axi_rready (m_axi_rready ),

        .m_axi_awready(m_axi_awready),
        .m_axi_awvalid(m_axi_awvalid),
        .m_axi_awid   (m_axi_awid   ),
        .m_axi_awaddr (m_axi_awaddr ),
        .m_axi_awlen  (m_axi_awlen  ),
        .m_axi_awsize (m_axi_awsize ),
        .m_axi_awburst(m_axi_awburst),
        .m_axi_awprot (m_axi_awprot ),
        .m_axi_awcache(m_axi_awcache),
        .m_axi_awuser (m_axi_awuser ),   

        .m_axi_wdata  (m_axi_wdata  ),
        .m_axi_wstrb  (m_axi_wstrb  ),
        .m_axi_wlast  (m_axi_wlast  ),
        .m_axi_wvalid (m_axi_wvalid ),
        .m_axi_wready (m_axi_wready ),
        .m_axi_bresp  (m_axi_bresp  ),
        .m_axi_bvalid (m_axi_bvalid ),
        .m_axi_bready (m_axi_bready )
    );

`endif

// ------------------------ DMA ------------------------------

// ------------------------ TLK2711 --------------------------
mpsoc mpsoc_inst (
    /*
    .emmc_buspow(emmc_rstn),
    .emmc_busvolt(),
    .emmc_clk(emmc_clk),
    .emmc_clk_fb(emmc_clk),
    .emmc_cmd_i(emmc_cmd_i),
    .emmc_cmd_o(emmc_cmd_o),
    .emmc_cmd_t(emmc_cmd_t),
    .emmc_data_i(emmc_data_i),
    .emmc_data_o(emmc_data_o),
    .emmc_data_t(emmc_data_t),

    .mdio_phy_mdc(mdio_phy_mdc),
    .mdio_phy_mdio_i(mdio_phy_mdio_i),
    .mdio_phy_mdio_o(mdio_phy_mdio_o),
    .mdio_phy_mdio_t(mdio_phy_mdio_t),
    .phy_resetn(),
    .rgmii_rd(rgmii_rd),
    .rgmii_rx_ctl(rgmii_rx_ctl),
    .rgmii_rxc(rgmii_rxc),
    .rgmii_td(rgmii_td),
    .rgmii_tx_ctl(rgmii_tx_ctl),
    .rgmii_txc(rgmii_txc),
    .i_clk_375(clk_375),
    .i_lock(locked),
    */
    // FPGA MGT
    .dcm_locked(locked),
    .fpga_mgt_aresetn(rst_80),
    .fpga_mgt_clk(clk_80),
    .i_reg_rdata(fpga_reg_rdata),
    .o_reg_raddr(fpga_reg_raddr),
    .o_reg_ren(fpga_reg_ren),
    .o_reg_waddr(fpga_reg_waddr),
    .o_reg_wdata(fpga_reg_wdata),
    .o_reg_wen(fpga_reg_wen),

    .hp0_clk(clk_80),

    .s_axi_hp0_araddr(m_axi_araddr),
    .s_axi_hp0_arburst(m_axi_arburst),
    .s_axi_hp0_arcache(m_axi_arcache),
    .s_axi_hp0_arid(m_axi_arid),
    .s_axi_hp0_arlen(m_axi_arlen),
    //.s_axi_hp0_arlock(s_axi_hp0_arlock),
    .s_axi_hp0_arprot(m_axi_arprot),
    //.s_axi_hp0_arqos(s_axi_hp0_arqos),
    .s_axi_hp0_arready(m_axi_arready),
    .s_axi_hp0_arsize(m_axi_arsize),
    .s_axi_hp0_aruser(m_axi_aruser),
    .s_axi_hp0_arvalid(m_axi_arvalid),

    .s_axi_hp0_awaddr(m_axi_awaddr),
    .s_axi_hp0_awburst(m_axi_awburst),
    .s_axi_hp0_awcache(m_axi_awcache),
    .s_axi_hp0_awid(m_axi_awid),
    .s_axi_hp0_awlen(m_axi_awlen),
    //.s_axi_hp0_awlock(s_axi_hp0_awlock),
    .s_axi_hp0_awprot(m_axi_awprot),
    //.s_axi_hp0_awqos(s_axi_hp0_awqos),
    .s_axi_hp0_awready(m_axi_awready),
    .s_axi_hp0_awsize(m_axi_awsize),
    .s_axi_hp0_awuser(m_axi_awuser),
    .s_axi_hp0_awvalid(m_axi_awvalid),

    //.s_axi_hp0_bid(s_axi_hp0_bid),
    .s_axi_hp0_bready(m_axi_bready),
    .s_axi_hp0_bresp(m_axi_bresp),
    .s_axi_hp0_bvalid(m_axi_bvalid),

    .s_axi_hp0_rdata(m_axi_rdata),
    //.s_axi_hp0_rid(s_axi_hp0_rid),
    .s_axi_hp0_rlast(m_axi_rlast),
    .s_axi_hp0_rready(m_axi_rready),
    .s_axi_hp0_rresp(m_axi_rresp),
    .s_axi_hp0_rvalid(m_axi_rvalid),

    .s_axi_hp0_wdata(m_axi_wdata),
    .s_axi_hp0_wlast(m_axi_wlast),
    .s_axi_hp0_wready(m_axi_wready),
    .s_axi_hp0_wstrb(m_axi_wstrb),
    .s_axi_hp0_wvalid(m_axi_wvalid),

    .tlk2711_los(tlk2711_loss_irq),
    .tlk2711_rx_irq(tlk2711_rx_irq),
    .tlk2711_tx_irq(tlk2711_tx_irq),

    // ---  Test DMA -----------------

    .hp2_clk(clk_80),

    .hp2_araddr(hp2_araddr),
    .hp2_arburst(hp2_arburst),
    .hp2_arcache(hp2_arcache),
    .hp2_arlen(hp2_arlen),
    .hp2_aruser(hp2_aruser),
   // .hp2_arlock(hp2_arlock),
    .hp2_arprot(hp2_arprot),
   // .hp2_arqos(hp2_arqos),
    .hp2_arready(hp2_arready),
    .hp2_arsize(hp2_arsize),
    .hp2_arvalid(hp2_arvalid),

    //AXI4 write addr
    .hp2_awaddr(hp2_awaddr),
    .hp2_awburst(hp2_awburst),
    .hp2_awcache(hp2_awcache),
    .hp2_awuser(hp2_awuser),
    .hp2_awlen(hp2_awlen),
    .hp2_awprot(hp2_awprot),
    .hp2_awready(hp2_awready),
    .hp2_awsize(hp2_awsize),
    .hp2_awvalid(hp2_awvalid),
    .hp2_awid(hp2_awid),

    .hp2_bready(hp2_bready),
    .hp2_bresp(hp2_bresp),
    .hp2_bvalid(hp2_bvalid),
    //AXI4 read data interface
    .hp2_rdata(hp2_rdata),
    .hp2_rlast(hp2_rlast),
    .hp2_rready(hp2_rready),
    .hp2_rresp(hp2_rresp),
    .hp2_rvalid(hp2_rvalid),
    //AXI4 write data interface
    .hp2_wdata(hp2_wdata),
    .hp2_wlast(hp2_wlast),
    .hp2_wready(hp2_wready),
    .hp2_wstrb(hp2_wstrb),
    .hp2_wvalid(hp2_wvalid),

    .gpio_tri_o(gpio),
    
    .uart_0_rxd(uart_0_rxd),
    .uart_0_txd(uart_0_txd)
);


// REVIEW Debug datamover

tlk2711_datamover datamover_hp2 (
    .m_axi_mm2s_aclk(clk_80),                        // input wire m_axi_mm2s_aclk
    .m_axi_mm2s_aresetn(~rst_80),                  // input wire m_axi_mm2s_aresetn
    // AXI4 interface
    .mm2s_err(mm2s_error),                                      // output wire mm2s_err
    .m_axis_mm2s_cmdsts_aclk(clk_80),        // input wire m_axis_mm2s_cmdsts_aclk
    .m_axis_mm2s_cmdsts_aresetn(~rst_80),  // input wire m_axis_mm2s_cmdsts_aresetn
    
    .m_axis_mm2s_sts_tvalid(m_axis_mm2s_sts_tvalid),          // output wire m_axis_mm2s_sts_tvalid
    .m_axis_mm2s_sts_tready(1'b1),          // input wire m_axis_mm2s_sts_tready
    .m_axis_mm2s_sts_tdata(m_axis_mm2s_sts_tdata),            // output wire [7 : 0] m_axis_mm2s_sts_tdata
    .m_axis_mm2s_sts_tkeep(m_axis_mm2s_sts_tkeep),            // output wire [0 : 0] m_axis_mm2s_sts_tkeep
    .m_axis_mm2s_sts_tlast(m_axis_mm2s_sts_tlast),            // output wire m_axis_mm2s_sts_tlast

    //AXI4 read addr interface arm -> FPGA

    .m_axi_mm2s_arid(hp2_arid),                        // output wire [3 : 0] m_axi_mm2s_arid
    .m_axi_mm2s_araddr(hp2_araddr),                    // output wire [31 : 0] m_axi_mm2s_araddr
    .m_axi_mm2s_arlen(hp2_arlen),                      // output wire [7 : 0] m_axi_mm2s_arlen
    .m_axi_mm2s_arsize(hp2_arsize),                    // output wire [2 : 0] m_axi_mm2s_arsize
    .m_axi_mm2s_arburst(hp2_arburst),                  // output wire [1 : 0] m_axi_mm2s_arburst
    .m_axi_mm2s_arprot(hp2_arprot),                    // output wire [2 : 0] m_axi_mm2s_arprot
    .m_axi_mm2s_arcache(hp2_arcache),                  // output wire [3 : 0] m_axi_mm2s_arcache
    .m_axi_mm2s_aruser(hp2_aruser),                    // output wire [3 : 0] m_axi_mm2s_aruser
    .m_axi_mm2s_arvalid(hp2_arvalid),                  // output wire m_axi_mm2s_arvalid
    .m_axi_mm2s_arready(hp2_arready),                  // input wire m_axi_mm2s_arready

    .m_axi_mm2s_rdata(hp2_rdata),                      // input wire [63 : 0] m_axi_mm2s_rdata
    .m_axi_mm2s_rresp(hp2_rresp),                      // input wire [1 : 0] m_axi_mm2s_rresp
    .m_axi_mm2s_rlast(hp2_rlast),                      // input wire m_axi_mm2s_rlast
    .m_axi_mm2s_rvalid(hp2_rvalid),                    // input wire m_axi_mm2s_rvalid
    .m_axi_mm2s_rready(hp2_rready),                    // output wire m_axi_mm2s_rready
    
    // User interface ARM -> FPGA

    .s_axis_mm2s_cmd_tvalid(user_mm2s_rd_cmd_tvalid),          // input wire s_axis_mm2s_cmd_tvalid
    .s_axis_mm2s_cmd_tready(user_mm2s_rd_cmd_tready),          // output wire s_axis_mm2s_cmd_tready
    .s_axis_mm2s_cmd_tdata(user_mm2s_rd_cmd_tdata),            // input wire [71 : 0] s_axis_mm2s_cmd_tdata

    .m_axis_mm2s_tdata(user_mm2s_rd_tdata),                    // output wire [63 : 0] m_axis_mm2s_tdata
    .m_axis_mm2s_tkeep(user_mm2s_rd_tkeep),                    // output wire [7 : 0] m_axis_mm2s_tkeep
    .m_axis_mm2s_tlast(user_mm2s_rd_tlast),                    // output wire m_axis_mm2s_tlast
    .m_axis_mm2s_tvalid(user_mm2s_rd_tvalid),                  // output wire m_axis_mm2s_tvalid
    .m_axis_mm2s_tready(user_mm2s_rd_tready),                  // input wire m_axis_mm2s_tready

    // AXI4 interface FPGA -> ARM

    .m_axi_s2mm_aclk(clk_80),                        // input wire m_axi_s2mm_aclk
    .m_axi_s2mm_aresetn(~rst_80),                  // input wire m_axi_s2mm_aresetn
    .s2mm_err(s2mm_error),                                      // output wire s2mm_err
    .m_axis_s2mm_cmdsts_awclk(clk_80),      // input wire m_axis_s2mm_cmdsts_awclk
    .m_axis_s2mm_cmdsts_aresetn(~rst_80),  // input wire m_axis_s2mm_cmdsts_aresetn
   
    .m_axis_s2mm_sts_tvalid(user_s2mm_sts_tvalid),          // output wire m_axis_s2mm_sts_tvalid
    .m_axis_s2mm_sts_tready(1'b1),          // input wire m_axis_s2mm_sts_tready
    .m_axis_s2mm_sts_tdata(user_s2mm_sts_tdata),            // output wire [7 : 0] m_axis_s2mm_sts_tdata
    .m_axis_s2mm_sts_tkeep(user_s2mm_sts_tkeep),            // output wire [0 : 0] m_axis_s2mm_sts_tkeep
    .m_axis_s2mm_sts_tlast(user_s2mm_sts_tlast),            // output wire m_axis_s2mm_sts_tlast
    // AXI4 addr interface
   
    .m_axi_s2mm_awid(hp2_awid),                        // output wire [3 : 0] m_axi_s2mm_awid
    .m_axi_s2mm_awaddr(hp2_awaddr),                    // output wire [31 : 0] m_axi_s2mm_awaddr
    .m_axi_s2mm_awlen(hp2_awlen),                      // output wire [7 : 0] m_axi_s2mm_awlen
    .m_axi_s2mm_awsize(hp2_awsize),                    // output wire [2 : 0] m_axi_s2mm_awsize
    .m_axi_s2mm_awburst(hp2_awburst),                  // output wire [1 : 0] m_axi_s2mm_awburst
    .m_axi_s2mm_awprot(hp2_awprot),                    // output wire [2 : 0] m_axi_s2mm_awprot
    .m_axi_s2mm_awcache(hp2_awcache),                  // output wire [3 : 0] m_axi_s2mm_awcache
    .m_axi_s2mm_awuser(hp2_awuser),                    // output wire [3 : 0] m_axi_s2mm_awuser
    .m_axi_s2mm_awvalid(hp2_awvalid),                  // output wire m_axi_s2mm_awvalid
    .m_axi_s2mm_awready(hp2_awready),                  // input wire m_axi_s2mm_awready
    
    //AXI4 data interface
    .m_axi_s2mm_wdata(hp2_wdata),                      // output wire [63 : 0] m_axi_s2mm_wdata
    .m_axi_s2mm_wstrb(hp2_wstrb),                      // output wire [7 : 0] m_axi_s2mm_wstrb
    .m_axi_s2mm_wlast(hp2_wlast),                      // output wire m_axi_s2mm_wlast
    .m_axi_s2mm_wvalid(hp2_wvalid),                    // output wire m_axi_s2mm_wvalid
    .m_axi_s2mm_wready(hp2_wready),                    // input wire m_axi_s2mm_wready
    .m_axi_s2mm_bresp(hp2_bresp),                      // input wire [1 : 0] m_axi_s2mm_bresp
    .m_axi_s2mm_bvalid(hp2_bvalid),                    // input wire m_axi_s2mm_bvalid
    .m_axi_s2mm_bready(hp2_bready),                    // output wire m_axi_s2mm_bready
    // User interface
    .s_axis_s2mm_cmd_tvalid(user_s2mm_wr_cmd_tvalid),          // input wire s_axis_s2mm_cmd_tvalid
    .s_axis_s2mm_cmd_tready(user_s2mm_wr_cmd_tready),          // output wire s_axis_s2mm_cmd_tready
    .s_axis_s2mm_cmd_tdata(user_s2mm_wr_cmd_tdata),            // input wire [71 : 0] s_axis_s2mm_cmd_tdata

    .s_axis_s2mm_tdata(user_s2mm_wr_tdata),                    // input wire [63 : 0] s_axis_s2mm_tdata
    .s_axis_s2mm_tkeep(user_s2mm_wr_tkeep),                    // input wire [7 : 0] s_axis_s2mm_tkeep
    .s_axis_s2mm_tlast(user_s2mm_wr_tlast),                    // input wire s_axis_s2mm_tlast
    .s_axis_s2mm_tvalid(user_s2mm_wr_tvalid),                  // input wire s_axis_s2mm_tvalid
    .s_axis_s2mm_tready(user_s2mm_wr_tready)                  // output wire s_axis_s2mm_tready
);

wire            dm_start;
reg [15:0]      dm_length;
wire            dm_start_vio;
reg             dm_start_vio_r0;
reg             dm_start_vio_p;
wire [15:0]     dm_length_vio;
reg             dm_start_gpio;
reg             gpio_r0;

reg [DDR_ADDR_WIDTH-1:0]      dm_start_addr;
wire [DDR_ADDR_WIDTH-1:0]     dm_start_addr_vio;

reg [DDR_ADDR_WIDTH-1:0]      dm_start_rd_addr;
wire [DDR_ADDR_WIDTH-1:0]     dm_start_rd_addr_vio;

reg [15:0]      dm_rd_length;
wire [15:0]     dm_rd_length_vio;

always @(posedge clk_80) begin
    gpio_r0 <= gpio;
    dm_start_gpio <= ~gpio_r0 & gpio;
end

vio_datamover vio_datamover_inst (
  .clk(clk_80),                // input wire clk
  .probe_out0(dm_start_vio),  // output wire [0 : 0] probe_out0
  .probe_out1(dm_length_vio),  // output wire [8 : 0] probe_out1
  .probe_out2(dm_start_addr_vio),  // output wire [31 : 0] probe_out2
  .probe_out3(dm_rd_length_vio),
  .probe_out4(dm_start_rd_addr_vio)
);

assign dm_start = dm_start_vio;

always @(posedge clk_80) begin
    dm_start_vio_r0 <= dm_start_vio;
    dm_start_vio_p <= ~dm_start_vio_r0 & dm_start_vio;
end

always @(posedge clk_80) begin
    if (rst_80) begin
        dm_length <= 'h0;
        dm_start_addr <= 'h0;
    end else begin
        if (dm_start_gpio) begin
            dm_length <= 9'h080;
            dm_start_addr <= 32'h3000_0000;
            dm_rd_length <= 9'h080;
            dm_start_rd_addr <= 32'h4000_0000;
        end else if (dm_start_vio_p) begin
            dm_length <= dm_length_vio;
            dm_start_addr<= dm_start_addr_vio;
            dm_rd_length <= dm_rd_length_vio;
            dm_start_rd_addr<= dm_start_rd_addr_vio;
        end
    end
    
end

datamover_validation  # (
    .DDR_ADDR_WIDTH(DDR_ADDR_WIDTH),
    .INIT_DATA(64'h0706050403020100)
    )datamover_validation_inst(
    .clk(clk_80),
    .rst(rst_80),

    .i_start(dm_start),
    .i_length(dm_length),
    .i_start_addr(dm_start_addr),
     .i_rd_length(dm_rd_length),
    .i_start_rd_addr(dm_start_rd_addr),

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


    .i_mm2s_rd_cmd_tready(user_mm2s_rd_cmd_tready),
    .o_mm2s_rd_cmd_tdata(user_mm2s_rd_cmd_tdata),
    .o_mm2s_rd_cmd_tvalid(user_mm2s_rd_cmd_tvalid),

    .i_mm2s_rd_tdata(user_mm2s_rd_tdata),
    .i_mms2_rd_tkeep(user_mm2s_rd_tkeep),
    .i_mm2s_rd_tvalid(user_mm2s_rd_tvalid),
    .i_mm2s_rd_tlast(user_mm2s_rd_tlast),
    .o_mm2s_rd_tready(user_mm2s_rd_tready)
);

//ila_datamover ila_datamover_inst (
//	.clk(clk_80), // input wire clk

//	.probe0(user_s2mm_wr_cmd_tready), // input wire [0:0]  probe0  
//	.probe1(user_s2mm_wr_cmd_tdata), // input wire [71:0]  probe1 
//	.probe2(user_s2mm_wr_cmd_tvalid), // input wire [0:0]  probe2 
//	.probe3(user_s2mm_wr_tdata), // input wire [63:0]  probe3 
//	.probe4(user_s2mm_wr_tkeep), // input wire [7:0]  probe4 
//	.probe5(user_s2mm_wr_tlast), // input wire [0:0]  probe5 
//	.probe6(user_s2mm_wr_tvalid), // input wire [0:0]  probe6 
//	.probe7(user_s2mm_wr_tready), // input wire [0:0]  probe7 
//	.probe8(user_s2mm_sts_tvalid), // input wire [0:0]  probe8 
//	.probe9(user_s2mm_sts_tdata), // input wire [3:0]  probe9 
//	.probe10(user_s2mm_sts_tlast), // input wire [0:0]  probe10 
//	.probe11(user_mm2s_rd_tdata), // input wire [63:0]  probe11 
//	.probe12(user_mm2s_rd_tkeep), // input wire [7:0]  probe12 
//	.probe13(user_mm2s_rd_tlast), // input wire [0:0]  probe13 
//	.probe14(user_mm2s_rd_tvalid), // input wire [0:0]  probe14 
//	.probe15(user_mm2s_rd_cmd_tvalid), // input wire [0:0]  probe15 
//	.probe16(user_mm2s_rd_cmd_tdata), // input wire [71:0]  probe16 
//	.probe17(user_mm2s_rd_cmd_tready), // input wire [0:0]  probe17
//	.probe18(mm2s_error),
//    .probe19(m_axis_mm2s_sts_tkeep), // input wire [0:0]  probe19 
//	.probe20(m_axis_mm2s_sts_tlast), // input wire [0:0]  probe20 
//	.probe21(m_axis_mm2s_sts_tvalid), // input wire [0:0]  probe21 
//	.probe22(m_axis_mm2s_sts_tdata), // input wire [7:0]  probe22
//	.probe23(s2mm_error)
//);
/*
ila_hp2 ila_hp2_i(
    .clk(clk_80),

    .probe0(hp2_wdata),
    .probe1(hp2_wstrb),
    .probe2(hp2_wlast),
    .probe3(hp2_wvalid),
    .probe4(hp2_wready),
    .probe5(hp2_bresp),
    .probe6(hp2_bvalid),
    .probe7(hp2_bready),
    .probe8(hp2_awaddr),
    .probe9(hp2_awlen),
    .probe10(hp2_awsize),
    .probe11(hp2_awburst),
    .probe12(hp2_awprot),
    .probe13(hp2_awuser),
    .probe14(hp2_awvalid),
    .probe15(hp2_awready)
);
*/
endmodule
