set_false_path -from [get_clocks -of_objects [get_pins clk_wiz_inst/inst/mmcme4_adv_inst/CLKOUT0]] -to [get_clocks tlk2711a_rx_clk]

set_false_path -from [get_clocks -of_objects [get_pins clk_wiz_inst/inst/mmcme4_adv_inst/CLKOUT0]] -to [get_clocks tlk2711b_rx_clk]