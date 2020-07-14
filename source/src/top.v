module top (

input       sys_clk_50,
input       sys_rstn

);

wire    clk_200;
wire    locked;

clk_wiz_0 instance_name
   (
    .clk_in1(sys_clk_50),
    .reset(~sys_rstn), 
    .locked(locked),
    .clk_200(clk_200)    
   
    ); 

mpsoc mpsoc_inst (
    .emmc_buspow(),
    .emmc_busvolt(),
    .emmc_clk(),
    .emmc_clk_fb(),
    .emmc_cmd_io(),
    .emmc_data_io(),
    .emmc_led(),
    .i_clk_200(),
    .i_lock(),
    .mdio_phy_mdc(),
    .mdio_phy_mdio_io(),
    .phy_resetn(),
    .rgmii_rd(),
    .rgmii_rx_ctl(),
    .rgmii_rxc(),
    .rgmii_td(),
    .rgmii_tx_ctl(),
    .rgmii_txc(),
    .uart_0_rxd(),
    .uart_0_txd()
);

endmodule