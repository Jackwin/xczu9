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

wire    clk_375;
wire    locked;

clk_wiz_0 clk_wiz_inst
   (
    .clk_in1(sys_clk_50),
    .reset(~sys_rstn), 
    .locked(locked),
    .clk_375(clk_375)    
   
    ); 

  wire          emmc_buspow;
  wire          [2:0]emmc_busvolt;

  wire          emmc_cmd_i;
  wire          emmc_cmd_io;
  wire          emmc_cmd_o;
  wire          emmc_cmd_t;
  /*
  wire [0:0]    emmc_data_i_0;
  wire [1:1]    emmc_data_i_1;
  wire [2:2]    emmc_data_i_2;
  wire [3:3]    emmc_data_i_3;
  wire [4:4]    emmc_data_i_4;
  wire [5:5]    emmc_data_i_5;
  wire [6:6]    emmc_data_i_6;
  wire [7:7]    emmc_data_i_7;
  wire [0:0]    emmc_data_io_0;
  wire [1:1]    emmc_data_io_1;
  wire [2:2]    emmc_data_io_2;
  wire [3:3]    emmc_data_io_3;
  wire [4:4]    emmc_data_io_4;
  wire [5:5]    emmc_data_io_5;
  wire [6:6]    emmc_data_io_6;
  wire [7:7]    emmc_data_io_7;
  wire [0:0]    emmc_data_o_0;
  wire [1:1]    emmc_data_o_1;
  wire [2:2]    emmc_data_o_2;
  wire [3:3]    emmc_data_o_3;
  wire [4:4]    emmc_data_o_4;
  wire [5:5]    emmc_data_o_5;
  wire [6:6]    emmc_data_o_6;
  wire [7:7]    emmc_data_o_7;
  wire [0:0]    emmc_data_t_0;
  wire [1:1]    emmc_data_t_1;
  wire [2:2]    emmc_data_t_2;
  wire [3:3]    emmc_data_t_3;
  wire [4:4]    emmc_data_t_4;
  wire [5:5]    emmc_data_t_5;
  wire [6:6]    emmc_data_t_6;
  wire [7:7]    emmc_data_t_7;
  wire          emmc_led;
  */
  wire          mdio_phy_mdc;
  wire          mdio_phy_mdio_i;
  wire          mdio_phy_mdio_io;
  wire          mdio_phy_mdio_o;
  wire          mdio_phy_mdio_t;

  wire          phy_resetn;
  wire          [3:0]rgmii_rd;
  wire          rgmii_rx_ctl;
  wire          rgmii_rxc;
  wire          [3:0]rgmii_td;
  wire          rgmii_tx_ctl;
  wire          rgmii_txc;
  wire          uart_0_rxd;
  wire          uart_0_txd;

IOBUF emmc_cmd_iobuf
    (.I(emmc_cmd_o),
    .IO(emmc_cmd_io),
    .O(emmc_cmd_i),
    .T(emmc_cmd_t));
/*
IOBUF emmc_data_iobuf_0
    (.I(emmc_data_o_0),
    .IO(emmc_data_io[0]),
    .O(emmc_data_i_0),
    .T(emmc_data_t_0));
IOBUF emmc_data_iobuf_1
    (.I(emmc_data_o_1),
    .IO(emmc_data_io[1]),
    .O(emmc_data_i_1),
    .T(emmc_data_t_1));
IOBUF emmc_data_iobuf_2
    (.I(emmc_data_o_2),
    .IO(emmc_data_io[2]),
    .O(emmc_data_i_2),
    .T(emmc_data_t_2));
IOBUF emmc_data_iobuf_3
    (.I(emmc_data_o_3),
    .IO(emmc_data_io[3]),
    .O(emmc_data_i_3),
    .T(emmc_data_t_3));
IOBUF emmc_data_iobuf_4
    (.I(emmc_data_o_4),
    .IO(emmc_data_io[4]),
    .O(emmc_data_i_4),
    .T(emmc_data_t_4));
IOBUF emmc_data_iobuf_5
    (.I(emmc_data_o_5),
    .IO(emmc_data_io[5]),
    .O(emmc_data_i_5),
    .T(emmc_data_t_5));
IOBUF emmc_data_iobuf_6
    (.I(emmc_data_o_6),
    .IO(emmc_data_io[6]),
    .O(emmc_data_i_6),
    .T(emmc_data_t_6));
IOBUF emmc_data_iobuf_7
    (.I(emmc_data_o_7),
    .IO(emmc_data_io[7]),
    .O(emmc_data_i_7),
    .T(emmc_data_t_7));
    */
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

mpsoc mpsoc_inst (
    .emmc_buspow(),
    .emmc_busvolt(),
    .emmc_clk(emmc_clk),
    .emmc_clk_fb(),
    .emmc_cmd_i(emmc_cmd_i),
    .emmc_cmd_o(emmc_cmd_o),
    .emmc_cmd_t(emmc_cmd_t),
    /*
    .emmc_data_i({emmc_data_i_7,emmc_data_i_6,emmc_data_i_5,emmc_data_i_4,emmc_data_i_3,emmc_data_i_2,emmc_data_i_1,emmc_data_i_0}),
    .emmc_data_o({emmc_data_o_7,emmc_data_o_6,emmc_data_o_5,emmc_data_o_4,emmc_data_o_3,emmc_data_o_2,emmc_data_o_1,emmc_data_o_0}),
    .emmc_data_t({emmc_data_t_7,emmc_data_t_6,emmc_data_t_5,emmc_data_t_4,emmc_data_t_3,emmc_data_t_2,emmc_data_t_1,emmc_data_t_0}),
    .emmc_led(),
    */
    .emmc_data_i(emmc_data_i),
    .emmc_data_o(emmc_data_o),
    .emmc_data_t(emmc_data_t),

    .i_clk_375(clk_375),
    .i_lock(lock),
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