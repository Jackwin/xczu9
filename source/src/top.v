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
output          tlk2711b_pre,

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
output          tlk2711a_pre,

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

parameter DEBUG_ENA = "TRUE";
parameter RX_CDC_CFG = "FIFO"; // rx clock domain crossing
parameter DDR_ADDR_WIDTH = 40;
parameter HP0_DATA_WIDTH = 128;
parameter STREAM_DATA_WIDTH = 64;

parameter TLK2711B_ADDR_MASK = 16'h00ff;
parameter TLK2711B_ADDR_BASE = 16'h0000;
parameter TLK2711A_ADDR_MASK = 16'h00ff;
parameter TLK2711A_ADDR_BASE = 16'h0100;

wire                        clk_100;
wire                        locked;
wire                        clk_100_rst;
wire                        clk_375;
wire                        pl_clk0_100m;
wire                        pl_clk0_rst;

wire [3:0]                  hp0_m_axi_arid;
wire [DDR_ADDR_WIDTH-1:0]   hp0_m_axi_araddr;
wire [7:0]                  hp0_m_axi_arlen;
wire [2:0]                  hp0_m_axi_arsize;
wire [1:0]                  hp0_m_axi_arburst;
wire [2:0]                  hp0_m_axi_arprot;
wire [3:0]                  hp0_m_axi_arcache;
wire [3:0]                  hp0_m_axi_aruser;
wire                        hp0_m_axi_arvalid;
wire                        hp0_m_axi_arready;
wire [HP0_DATA_WIDTH-1:0]   hp0_m_axi_rdata;
wire [1:0]                  hp0_m_axi_rresp;
wire                        hp0_m_axi_rlast;
wire                        hp0_m_axi_rvalid;
wire                        hp0_m_axi_rready;
wire [3:0]                  hp0_m_axi_awid;
wire [DDR_ADDR_WIDTH-1:0]   hp0_m_axi_awaddr;
wire [7:0]                  hp0_m_axi_awlen;
wire [2:0]                  hp0_m_axi_awsize;
wire [1:0]                  hp0_m_axi_awburst;
wire [2:0]                  hp0_m_axi_awprot;
wire [3:0]                  hp0_m_axi_awcache;
wire [3:0]                  hp0_m_axi_awuser;
wire                        hp0_m_axi_awvalid;
wire                        hp0_m_axi_awready;
wire [HP0_DATA_WIDTH-1:0]   hp0_m_axi_wdata;
wire [7:0]                  hp0_m_axi_wstrb;
wire                        hp0_m_axi_wlast;
wire                        hp0_m_axi_wvalid;
wire                        hp0_m_axi_wready;
wire [1:0]                  hp0_m_axi_bresp;
wire                        hp0_m_axi_bvalid;
wire                        hp0_m_axi_bready;

wire                        fpga_reg_wen;
wire                        fpga_reg_ren;
wire [31:0]                 fpga_reg_waddr;
wire [31:0]                 fpga_reg_raddr;
wire [63:0]                 fpga_reg_wdata;
wire [63:0]                 fpga_reg_rdata;

wire                        tlk2711b_tx_irq;
wire                        tlk2711b_rx_irq;
wire                        tlk2711b_loss_irq;

wire                        tlk2711a_tx_irq;
wire                        tlk2711a_rx_irq;
wire                        tlk2711a_loss_irq;

// ------------------ -----------------
wire [1:0]                  hp2_bresp;
wire                        hp2_bvalid;

wire [127:0]                hp2_rdata;
wire                        hp2_rlast;
wire [1:0]                  hp2_rresp;
wire                        hp2_rvalid;
wire                        hp2_rready;
 
wire [DDR_ADDR_WIDTH-1:0]   hp2_araddr;
wire [1:0]                  hp2_arburst;
wire [3:0]                  hp2_arcache;
wire [3:0]                  hp2_arid;
wire [7:0]                  hp2_arlen;
wire                        hp2_aruser;
wire                        hp2_arlock;
wire [2:0]                  hp2_arprot;
wire [2:0]                  hp2_arsize;
wire                        hp2_arvalid;
wire                        hp2_arready;

wire [DDR_ADDR_WIDTH-1:0]   hp2_awaddr;
wire [1:0]                  hp2_awburst;
wire [3:0]                  hp2_awcache;
wire [3:0]                  hp2_awid;
wire [7:0]                  hp2_awlen;
wire                        hp2_awlock;
wire [2:0]                  hp2_awprot;
wire [2:0]                  hp2_awsize;
wire                        hp2_awvalid;
wire                        hp2_awuser;
wire                        hp2_awready;

wire [127:0]                hp2_wdata;
wire [5:0]                  hp2_wid;
wire                        hp2_wlast;
wire [15:0]                 hp2_wstrb;
wire                        hp2_wvalid;


wire                        s2mm_error;
wire                        mm2s_error;

wire                        gpio;

clk_wiz_0 clk_wiz_inst (
    .clk_in1(sys_clk_50),
    .reset(~sys_rstn), 
    .locked(locked),
    .clk_100(clk_100),
    .clk_375(clk_375)
   
);

reset_bridge reset_100_inst(
    .clk(clk_100),    
    .arst_n(locked),  
    .srst(clk_100_rst)
);

// --------------------- user led --------------------------------

reg [26:0]  led_cnt;

always @(posedge clk_100) begin
    if (clk_100_rst) begin
        led_cnt <= 'h0;
    end else begin
        led_cnt <= led_cnt + 1'd1;
    end
end

assign usr_led = led_cnt[26];

// --------------------- ethernet phy1 ---------------------------
reg [15:0]     eth_rst_cnt;

always @(posedge clk_100) begin
    if (clk_100_rst) begin
        eth_rst_cnt <= 'h0;
    end else if (&eth_rst_cnt != 1'b1) begin
        eth_rst_cnt <= eth_rst_cnt + 1'b1;
    end
end
assign phy1_resetn = &eth_rst_cnt;
assign phy_resetn = &eth_rst_cnt;

// ------------------------ TLK2711 --------------------------
wire [15:0]     tlk2711a_rxd_w;
wire            tlk2711a_rkmsb_w;
wire            tlk2711a_rklsb_w;

wire [15:0]     tlk2711b_rxd_w;
wire            tlk2711b_rkmsb_w;
wire            tlk2711b_rklsb_w;

assign tlk2711b_gtx_clk = clk_100;
assign tlk2711a_gtx_clk = clk_100;

// clock domain crossing
if (RX_CDC_CFG == "REG") begin
    reg [15:0]  tlk2711b_rxd_1r, tlk2711b_rxd_2r, tlk2711b_rxd_3r;
    reg tlk2711b_rklsb_1r, tlk2711b_rklsb_2r, tlk2711b_rklsb_3r;
    reg tlk2711b_rkmsb_1r, tlk2711b_rkmsb_2r, tlk2711b_rkmsb_3r;

    reg [15:0]  tlk2711a_rxd_1r, tlk2711a_rxd_2r, tlk2711a_rxd_3r;
    reg tlk2711a_rklsb_1r, tlk2711a_rklsb_2r, tlk2711a_rklsb_3r;
    reg tlk2711a_rkmsb_1r, tlk2711a_rkmsb_2r, tlk2711a_rkmsb_3r;

    always @(posedge tlk2711b_rx_clk) begin
        tlk2711b_rxd_1r <= tlk2711b_rxd;
        tlk2711b_rklsb_1r <= tlk2711b_rklsb;
        tlk2711b_rkmsb_1r <= tlk2711b_rkmsb;
    end

    always @(posedge tlk2711a_rx_clk) begin
        tlk2711a_rxd_1r <= tlk2711a_rxd;
        tlk2711a_rklsb_1r <= tlk2711a_rklsb;
        tlk2711a_rkmsb_1r <= tlk2711a_rkmsb;
    end

    always @(posedge clk_100) begin
        tlk2711b_rxd_2r <= tlk2711b_rxd_1r;
        tlk2711b_rxd_3r <= tlk2711b_rxd_2r;
        tlk2711b_rklsb_2r <= tlk2711b_rklsb_1r;
        tlk2711b_rklsb_3r <= tlk2711b_rklsb_2r;
        tlk2711b_rkmsb_2r <= tlk2711b_rkmsb_1r;
        tlk2711b_rkmsb_3r <= tlk2711b_rkmsb_2r;

        tlk2711a_rxd_2r <= tlk2711a_rxd_1r;
        tlk2711a_rxd_3r <= tlk2711a_rxd_2r;

        tlk2711a_rklsb_2r <= tlk2711a_rklsb_1r;
        tlk2711a_rklsb_3r <= tlk2711a_rklsb_2r;
        tlk2711a_rkmsb_2r <= tlk2711a_rkmsb_1r;
        tlk2711a_rkmsb_3r <= tlk2711a_rkmsb_2r;
    end

    assign tlk2711ba_rkmsb_w = tlk2711a_rkmsb_3r;
    assign tlk2711ba_rklsb_w = tlk2711a_rklsb_3r;
    assign tlk2711ba_rxd_w = tlk2711a_rxd_3r;

    assign tlk2711b_rkmsb_w = tlk2711b_rkmsb_3r;
    assign tlk2711b_rklsb_w = tlk2711b_rklsb_3r;
    assign tlk2711b_rxd_w = tlk2711b_rxd_3r;
end

if (RX_CDC_CFG == "FIFO") begin
    tlk2711_rx_cdc  #(
        .DATAWIDTH(18)
    ) tlk2711a_rx_cdc_inst (
        .tlk2711_rx_clk(tlk2711a_rx_clk),
        .i_tlk2711_data({tlk2711a_rkmsb, tlk2711a_rklsb, tlk2711a_rxd}),
        .clk(clk_100),
        .rst(clk_100_rst),
        .i_soft_rst(clk_100_rst),
        .o_tlk2711_data({tlk2711a_rkmsb_w, tlk2711a_rklsb_w, tlk2711a_rxd_w})
    );

    tlk2711_rx_cdc  #(
        .DATAWIDTH(18)
    ) tlk2711b_rx_cdc_inst (
        .tlk2711_rx_clk(tlk2711b_rx_clk),
        .i_tlk2711_data({tlk2711b_rkmsb, tlk2711b_rklsb, tlk2711b_rxd}),
        .clk(clk_100),
        .rst(clk_100_rst),
        .i_soft_rst(clk_100_rst),
        .o_tlk2711_data({tlk2711b_rkmsb_w, tlk2711b_rklsb_w, tlk2711b_rxd_w})
    );
end
tlk2711_wrapper #(  
    .DEBUG_ENA(DEBUG_ENA),  
    .ADDR_WIDTH(DDR_ADDR_WIDTH),
    .AXI_RDATA_WIDTH(HP0_DATA_WIDTH), //HP0_DATA_WIDTH
    .AXI_WDATA_WIDTH(HP0_DATA_WIDTH), // HP0_DATA_WIDTH
    .AXI_WBYTE_WIDTH(HP0_DATA_WIDTH/8),  // HP0_DATA_WIDTH/8
    .STREAM_RDATA_WIDTH(STREAM_DATA_WIDTH), 
    .STREAM_WDATA_WIDTH(STREAM_DATA_WIDTH),
    .STREAM_WBYTE_WIDTH(STREAM_DATA_WIDTH/8),  
    .DLEN_WIDTH(16),
    .TLK2711A_ADDR_MASK(TLK2711A_ADDR_MASK),
    .TLK2711A_ADDR_BASE(TLK2711A_ADDR_BASE),
    .TLK2711B_ADDR_MASK(TLK2711B_ADDR_MASK),
    .TLK2711B_ADDR_BASE(TLK2711B_ADDR_BASE)
) tlk2711_wrapper (
    .ps_clk(pl_clk0_100m),
    .ps_rst(pl_clk0_rst),

    .clk(clk_100),
    .rst(clk_100_rst),

    .i_reg_wen(fpga_reg_wen),
    .i_reg_waddr(fpga_reg_waddr[15:0]),
    .i_reg_wdata(fpga_reg_wdata),    
    .i_reg_ren(fpga_reg_ren),
    .i_reg_raddr(fpga_reg_raddr[15:0]),
    .o_reg_rdata(fpga_reg_rdata), 

    // ----------------------- tlk2711b -------------------------
    .o_2711b_tx_irq(tlk2711b_tx_irq),
    .o_2711b_rx_irq(tlk2711b_rx_irq),
    .o_2711b_loss_irq(tlk2711b_loss_irq),

    .i_2711b_rkmsb(tlk2711b_rkmsb_w),
    .i_2711b_rklsb(tlk2711b_rklsb_w),
    .i_2711b_rxd(tlk2711b_rxd_w),

    .o_2711b_tkmsb(tlk2711b_tkmsb),
    .o_2711b_tklsb(tlk2711b_tklsb),
    .o_2711b_enable(tlk2711b_enable),
    .o_2711b_loopen(tlk2711b_loopen),
    .o_2711b_lckrefn(tlk2711b_lckrefn),
    .o_2711b_testen(tlk2711b_testen),
    .o_2711b_prbsen(tlk2711b_prbsen),
    .o_2711b_pre(tlk2711b_pre),
    .o_2711b_txd(tlk2711b_txd),

    .tlk2711b_m_axi_arready(hp0_m_axi_arready),
    .tlk2711b_m_axi_arvalid(hp0_m_axi_arvalid),
    .tlk2711b_m_axi_arid   (hp0_m_axi_arid   ),
    .tlk2711b_m_axi_araddr (hp0_m_axi_araddr ),
    .tlk2711b_m_axi_arlen  (hp0_m_axi_arlen  ),
    .tlk2711b_m_axi_arsize (hp0_m_axi_arsize ),
    .tlk2711b_m_axi_arburst(hp0_m_axi_arburst),
    .tlk2711b_m_axi_arprot (hp0_m_axi_arprot ),
    .tlk2711b_m_axi_arcache(hp0_m_axi_arcache),
    .tlk2711b_m_axi_aruser (hp0_m_axi_aruser ),  

    .tlk2711b_m_axi_rdata  (hp0_m_axi_rdata  ),
    .tlk2711b_m_axi_rresp  (hp0_m_axi_rresp  ),
    .tlk2711b_m_axi_rlast  (hp0_m_axi_rlast  ),
    .tlk2711b_m_axi_rvalid (hp0_m_axi_rvalid ),
    .tlk2711b_m_axi_rready (hp0_m_axi_rready ),

    .tlk2711b_m_axi_awready(hp0_m_axi_awready),
    .tlk2711b_m_axi_awvalid(hp0_m_axi_awvalid),
    .tlk2711b_m_axi_awid   (hp0_m_axi_awid   ),
    .tlk2711b_m_axi_awaddr (hp0_m_axi_awaddr ),
    .tlk2711b_m_axi_awlen  (hp0_m_axi_awlen  ),
    .tlk2711b_m_axi_awsize (hp0_m_axi_awsize ),
    .tlk2711b_m_axi_awburst(hp0_m_axi_awburst),
    .tlk2711b_m_axi_awprot (hp0_m_axi_awprot ),
    .tlk2711b_m_axi_awcache(hp0_m_axi_awcache),
    .tlk2711b_m_axi_awuser (hp0_m_axi_awuser ),   

    .tlk2711b_m_axi_wdata  (hp0_m_axi_wdata  ),
    .tlk2711b_m_axi_wstrb  (hp0_m_axi_wstrb  ),
    .tlk2711b_m_axi_wlast  (hp0_m_axi_wlast  ),
    .tlk2711b_m_axi_wvalid (hp0_m_axi_wvalid ),
    .tlk2711b_m_axi_wready (hp0_m_axi_wready ),
    .tlk2711b_m_axi_bresp  (hp0_m_axi_bresp  ),
    .tlk2711b_m_axi_bvalid (hp0_m_axi_bvalid ),
    .tlk2711b_m_axi_bready (hp0_m_axi_bready ),

    // ----------------------- tlk2711a -------------------------
    .o_2711a_tx_irq(tlk2711a_tx_irq),
    .o_2711a_rx_irq(tlk2711a_rx_irq),
    .o_2711a_loss_irq(tlk2711a_loss_irq),

    .i_2711a_rkmsb(tlk2711a_rkmsb_w),
    .i_2711a_rklsb(tlk2711a_rklsb_w),
    .i_2711a_rxd(tlk2711a_rxd_w),

    .o_2711a_tkmsb(tlk2711a_tkmsb),
    .o_2711a_tklsb(tlk2711a_tklsb),
    .o_2711a_enable(tlk2711a_enable),
    .o_2711a_loopen(tlk2711a_loopen),
    .o_2711a_lckrefn(tlk2711a_lckrefn),
    .o_2711a_testen(tlk2711a_testen),
    .o_2711a_prbsen(tlk2711a_prbsen),
    .o_2711a_pre(tlk2711a_pre),
    .o_2711a_txd(tlk2711a_txd),


    .tlk2711a_m_axi_arready(hp2_arready),
    .tlk2711a_m_axi_arvalid(hp2_arvalid),
    .tlk2711a_m_axi_arid   (hp2_arid ),
    .tlk2711a_m_axi_araddr (hp2_araddr ),
    .tlk2711a_m_axi_arlen  (hp2_arlen  ),
    .tlk2711a_m_axi_arsize (hp2_arsize ),
    .tlk2711a_m_axi_arburst(hp2_arburst),
    .tlk2711a_m_axi_arprot (hp2_arprot ),
    .tlk2711a_m_axi_arcache(hp2_arcache),
    .tlk2711a_m_axi_aruser (hp2_aruser ),  

    .tlk2711a_m_axi_rdata  (hp2_rdata  ),
    .tlk2711a_m_axi_rresp  (hp2_rresp  ),
    .tlk2711a_m_axi_rlast  (hp2_rlast  ),
    .tlk2711a_m_axi_rvalid (hp2_rvalid ),
    .tlk2711a_m_axi_rready (hp2_rready ),

    .tlk2711a_m_axi_awready(hp2_awready),
    .tlk2711a_m_axi_awvalid(hp2_awvalid),
    .tlk2711a_m_axi_awid   (hp2_awid   ),
    .tlk2711a_m_axi_awaddr (hp2_awaddr ),
    .tlk2711a_m_axi_awlen  (hp2_awlen  ),
    .tlk2711a_m_axi_awsize (hp2_awsize ),
    .tlk2711a_m_axi_awburst(hp2_awburst),
    .tlk2711a_m_axi_awprot (hp2_awprot ),
    .tlk2711a_m_axi_awcache(hp2_awcache),
    .tlk2711a_m_axi_awuser (hp2_awuser ),   

    .tlk2711a_m_axi_wdata  (hp2_wdata  ),
    .tlk2711a_m_axi_wstrb  (hp2_wstrb  ),
    .tlk2711a_m_axi_wlast  (hp2_wlast  ),
    .tlk2711a_m_axi_wvalid (hp2_wvalid ),
    .tlk2711a_m_axi_wready (hp2_wready ),
    .tlk2711a_m_axi_bresp  (hp2_bresp  ),
    .tlk2711a_m_axi_bvalid (hp2_bvalid ),
    .tlk2711a_m_axi_bready (hp2_bready )
);

mpsoc mpsoc_inst (
    // FPGA MGT
    .dcm_locked(locked),
    .fpga_mgt_aresetn(clk_100_rst),
    .fpga_mgt_clk(clk_100),
    .pl_clk0_100m(pl_clk0_100m),
    .pl_clk0_rst(pl_clk0_rst),
    .i_reg_rdata(fpga_reg_rdata),
    .o_reg_raddr(fpga_reg_raddr),
    .o_reg_ren(fpga_reg_ren),
    .o_reg_waddr(fpga_reg_waddr),
    .o_reg_wdata(fpga_reg_wdata),
    .o_reg_wen(fpga_reg_wen),

    .hp0_clk(clk_100),

    .s_axi_hp0_araddr(hp0_m_axi_araddr),
    .s_axi_hp0_arburst(hp0_m_axi_arburst),
    .s_axi_hp0_arcache(hp0_m_axi_arcache),
    .s_axi_hp0_arid(hp0_m_axi_arid),
    .s_axi_hp0_arlen(hp0_m_axi_arlen),
    .s_axi_hp0_arprot(hp0_m_axi_arprot),
    .s_axi_hp0_arready(hp0_m_axi_arready),
    .s_axi_hp0_arsize(hp0_m_axi_arsize),
    .s_axi_hp0_aruser(hp0_m_axi_aruser),
    .s_axi_hp0_arvalid(hp0_m_axi_arvalid),

    .s_axi_hp0_awaddr(hp0_m_axi_awaddr),
    .s_axi_hp0_awburst(hp0_m_axi_awburst),
    .s_axi_hp0_awcache(hp0_m_axi_awcache),
    .s_axi_hp0_awid(hp0_m_axi_awid),
    .s_axi_hp0_awlen(hp0_m_axi_awlen),
    
    .s_axi_hp0_awprot(hp0_m_axi_awprot),
    .s_axi_hp0_awready(hp0_m_axi_awready),
    .s_axi_hp0_awsize(hp0_m_axi_awsize),
    .s_axi_hp0_awuser(hp0_m_axi_awuser),
    .s_axi_hp0_awvalid(hp0_m_axi_awvalid),

    .s_axi_hp0_bready(hp0_m_axi_bready),
    .s_axi_hp0_bresp(hp0_m_axi_bresp),
    .s_axi_hp0_bvalid(hp0_m_axi_bvalid),

    .s_axi_hp0_rdata(hp0_m_axi_rdata),
    .s_axi_hp0_rlast(hp0_m_axi_rlast),
    .s_axi_hp0_rready(hp0_m_axi_rready),
    .s_axi_hp0_rresp(hp0_m_axi_rresp),
    .s_axi_hp0_rvalid(hp0_m_axi_rvalid),

    .s_axi_hp0_wdata(hp0_m_axi_wdata),
    .s_axi_hp0_wlast(hp0_m_axi_wlast),
    .s_axi_hp0_wready(hp0_m_axi_wready),
    .s_axi_hp0_wstrb(hp0_m_axi_wstrb),
    .s_axi_hp0_wvalid(hp0_m_axi_wvalid),

    .i_tlk2711b_loss_irq(tlk2711b_loss_irq),
    .i_tlk2711b_rx_irq(tlk2711b_rx_irq),
    .i_tlk2711b_tx_irq(tlk2711b_tx_irq),

    // ---  Test DMA -----------------

    .hp2_clk(clk_100),

    .hp2_araddr(hp2_araddr),
    .hp2_arburst(hp2_arburst),
    .hp2_arcache(hp2_arcache),
    .hp2_arlen(hp2_arlen),
    .hp2_aruser(hp2_aruser),
    .hp2_arprot(hp2_arprot),
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

    .i_tlk2711a_loss_irq(tlk2711a_loss_irq),
    .i_tlk2711a_rx_irq(tlk2711a_rx_irq),
    .i_tlk2711a_tx_irq(tlk2711a_tx_irq),


    .gpio_tri_o(gpio),
    
    .uart_0_rxd(uart_0_rxd),
    .uart_0_txd(uart_0_txd)
);

ila_2711_rx ila_2711b_rx_inst (
	.clk(tlk2711b_rx_clk), // input wire clk
	.probe0(tlk2711b_rklsb), // input wire [0:0]  probe0  
	.probe1(tlk2711b_rkmsb), // input wire [0:0]  probe1 
	.probe2(tlk2711b_rxd) // input wire [15:0]  probe2
);

ila_2711_rx ila_2711a_rx_inst (
	.clk(tlk2711a_rx_clk), // input wire clk
	.probe0(tlk2711a_rklsb), // input wire [0:0]  probe0  
	.probe1(tlk2711a_rkmsb), // input wire [0:0]  probe1 
	.probe2(tlk2711a_rxd) // input wire [15:0]  probe2
);

endmodule
