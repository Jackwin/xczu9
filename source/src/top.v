module top (

input           sys_clk_50,
input           sys_rstn,

output [15:0]   tlk2711b_txd,
output          tlk2711b_loopen,
output          tlk2711b_gtx_clk,
output          tlk2711b_tkmsb,
output          tlk2711b_prbsen,
output          tlk2711b_enable,
output          tlk2711b_lckrefn,
output          tlk2711b_tklsb,

input [15:0]    tlk2711b_rxd,
output          tlk2711b_rklsb,
output          tlk2711b_rx_clk,
output          tlk2711b_testen,
output          tlk2711b_rkmsb,

output          emmc_clk,
inout           emmc_cmd_io,
inout [7:0]     emmc_data_io,


output          mdio_phy_mdc,
inout           mdio_phy_mdio_io,
output          phy_resetn,
input [3:0]     rgmii_rd,
input           rgmii_rx_ctl,
input           rgmii_rxc,
output [3:0]    rgmii_td,
output          rgmii_tx_ctl,
output          rgmii_txc,

input           uart_0_rxd,
output          uart_0_txd

);

wire    clk_80;
wire    locked;
wire    rst_80;

clk_wiz_0 clk_wiz_inst (
    .clk_in1(sys_clk_50),
    .reset(~sys_rstn), 
    .locked(locked),
    .clk_80(clk_80)    
   
);

reset_bridge reset_80_inst(
    .clk(clk_80),    
    .arst_n(locked),  
    .o_srst(rst_80)
);


wire          emmc_buspow;
wire          [2:0]emmc_busvolt;

wire          emmc_cmd_i;
wire          emmc_cmd_o;
wire          emmc_cmd_t;


wire          mdio_phy_mdio_i;
wire          mdio_phy_mdio_o;
wire          mdio_phy_mdio_t;

IOBUF emmc_cmd_iobuf
    (.I(emmc_cmd_o),
    .IO(emmc_cmd_io),
    .O(emmc_cmd_i),
    .T(emmc_cmd_t));

IOBUF mdio_phy_mdio_iobuf
    (.I(mdio_phy_mdio_o),
    .IO(mdio_phy_mdio_io),
    .O(mdio_phy_mdio_i),
    .T(mdio_phy_mdio_t));
    
wire [7:0]  emmc_data_i;
wire [7:0]  emmc_data_o;
wire [7:0]  emmc_data_t;

emmc_iobuf emmc_iobuf_inst (
    .emmc_data_i(emmc_data_o),
    .emmc_data_io(emmc_data_io),
    .emmc_data_o(emmc_data_i),
    .emmc_data_t(emmc_data_t)
);


// ------------------------ TLK2711 --------------------------
wire        tlk2711b_start;
wire        tlk2711b_stop;
wire        tlk2711b_stop_ack;
wire [1:0]  tlk2711b_mode;
tlk2711 tlk2711b_inst (
    .tx_clk(clk_80),
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

    .rx_clk(clk_80),
    .i_rkmsb(tlk2711b_rkmsb),
    .i_rklsb(tlk2711b_rklsb),
    .i_rxd(tlk2711b_rxd)

);

assign tlk2711b_rx_clk = clk_80;
assign tlk2711b_gtx_clk = clk_80;
// ------------------------ TLK2711 --------------------------
mpsoc mpsoc_inst (
    .emmc_buspow(),
    .emmc_busvolt(),
    .emmc_clk(emmc_clk),
    .emmc_clk_fb(),
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
    .phy_resetn(phy_resetn),
    .rgmii_rd(rgmii_rd),
    .rgmii_rx_ctl(rgmii_rx_ctl),
    .rgmii_rxc(rgmii_rxc),
    .rgmii_td(rgmii_td),
    .rgmii_tx_ctl(rgmii_tx_ctl),
    .rgmii_txc(rgmii_txc),
    .uart_0_rxd(uart_0_rxd),
    .uart_0_txd(uart_0_txd)
);

endmodule