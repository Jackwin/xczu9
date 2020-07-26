
set_property PACKAGE_PIN T8  [get_ports sys_clk_50]
set_property PACKAGE_PIN R10  [get_ports sys_rstn]

set_property IOSTANDARD LVCMOS18 [get_ports sys_clk_50]
set_property IOSTANDARD LVCMOS18 [get_ports sys_rstn]

## EMMC
set_property PACKAGE_PIN L13  [get_ports {emmc_data_io[0]}]
set_property PACKAGE_PIN L16  [get_ports {emmc_data_io[1]}]
set_property PACKAGE_PIN L11  [get_ports {emmc_data_io[2]}]
set_property PACKAGE_PIN M13  [get_ports {emmc_data_io[3]}]
set_property PACKAGE_PIN N11  [get_ports {emmc_data_io[4]}]
set_property PACKAGE_PIN T6  [get_ports {emmc_data_io[5]}]
set_property PACKAGE_PIN U6  [get_ports {emmc_data_io[6]}]
set_property PACKAGE_PIN K13  [get_ports {emmc_data_io[7]}]

set_property PACKAGE_PIN U9  [get_ports emmc_cmd_io]
set_property PACKAGE_PIN P10  [get_ports emmc_clk]


set_property IOSTANDARD LVCMOS18 [get_ports {emmc_data_io[*]}]
set_property IOSTANDARD LVCMOS18 [get_ports emmc_cmd_io]
set_property IOSTANDARD LVCMOS18 [get_ports emmc_clk]

### ethernet phy2

set_property PACKAGE_PIN AE7  [get_ports rgmii_rxc]
set_property PACKAGE_PIN AF8  [get_ports rgmii_rx_ctl]
set_property PACKAGE_PIN AE8  [get_ports {rgmii_rd[0]}]
set_property PACKAGE_PIN AD6  [get_ports {rgmii_rd[1]}]
set_property PACKAGE_PIN AD7  [get_ports {rgmii_rd[2]}]
set_property PACKAGE_PIN AH8  [get_ports {rgmii_rd[3]}]

set_property PACKAGE_PIN AF6  [get_ports rgmii_txc]
set_property PACKAGE_PIN AG8  [get_ports rgmii_tx_ctl]
set_property PACKAGE_PIN AH6  [get_ports {rgmii_td[0]}]
set_property PACKAGE_PIN AE9  [get_ports {rgmii_td[1]}]

set_property PACKAGE_PIN AD10  [get_ports {rgmii_td[2]}]
set_property PACKAGE_PIN AG9  [get_ports {rgmii_td[3]}]

set_property PACKAGE_PIN AG10  [get_ports mdio_phy_mdc]
set_property PACKAGE_PIN AG11  [get_ports mdio_phy_mdio_io]
set_property PACKAGE_PIN AF11  [get_ports phy_resetn]

set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_rd[*]}]
set_property IOSTANDARD LVCMOS18 [get_ports rgmii_rxc]
set_property IOSTANDARD LVCMOS18 [get_ports rgmii_rx_ctl]

set_property IOSTANDARD LVCMOS18 [get_ports {rgmii_td[*]}]
set_property IOSTANDARD LVCMOS18 [get_ports rgmii_txc]
set_property IOSTANDARD LVCMOS18 [get_ports rgmii_tx_ctl]

set_property IOSTANDARD LVCMOS18 [get_ports mdio_phy_mdc]
set_property IOSTANDARD LVCMOS18 [get_ports mdio_phy_mdio_io]
set_property IOSTANDARD LVCMOS18 [get_ports phy_resetn]

## ethernet phy1
set_property PACKAGE_PIN K15  [get_ports phy1_resetn]
set_property IOSTANDARD LVCMOS18 [get_ports phy1_resetn]

### uart
set_property PACKAGE_PIN D22  [get_ports uart_0_txd]
set_property PACKAGE_PIN E22  [get_ports uart_0_rxd]
set_property IOSTANDARD LVCMOS33 [get_ports uart_0_txd]
set_property IOSTANDARD LVCMOS33 [get_ports uart_0_rxd]