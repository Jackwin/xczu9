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
parameter HP0_DATA_WIDTH = 64;

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
wire [HP0_DATA_WIDTH-1:0]   fpga_reg_wdata;
wire [HP0_DATA_WIDTH-1:0]   fpga_reg_rdata;

wire                        tlk2711_tx_irq;
wire                        tlk2711_rx_irq;
wire                        tlk2711_loss_irq;

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
tlk2711 tlk2711b_inst (
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
assign tlk2711b_gtx_clk = clk_80;

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
assign tlk2711a_gtx_clk = clk_80;
`else

// -----------------------
    wire                        fpga_reg_wen_vio;
    wire [15:0]                 fpga_reg_waddr_vio;
    wire [HP0_DATA_WIDTH-1:0]   fpga_reg_wdata_vio;
    wire                        fpga_reg_ren_vio;           
    wire [15:0]                 fpga_reg_raddr_vio;
    wire [HP0_DATA_WIDTH-1:0]   fpga_reg_rdata_vio;

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
	    .RDATA_WIDTH(HP0_DATA_WIDTH), //HP0_DATA_WIDTH
	    .WDATA_WIDTH(HP0_DATA_WIDTH), // HP0_DATA_WIDTH
	    .WBYTE_WIDTH(HP0_DATA_WIDTH/8),  // HP0_DATA_WIDTH/8
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
    
    .uart_0_rxd(uart_0_rxd),
    .uart_0_txd(uart_0_txd)
);

endmodule
