onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider tx_cmd
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_cmd/clk
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_cmd/rst
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_cmd/i_soft_rst
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_cmd/i_rd_cmd_ack
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_cmd/o_rd_cmd_req
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_cmd/o_rd_cmd_data
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_cmd/i_dma_rd_last
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_cmd/i_tx_start
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_cmd/i_tx_base_addr
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_cmd/i_tx_packet_body
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_cmd/i_tx_packet_tail
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_cmd/i_tx_body_num
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_cmd/tx_frame_cnt
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_cmd/rd_bbt
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_cmd/rd_addr
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_cmd/rd_cmd_req
add wave -noupdate -divider tx_data
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_data/clk
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_data/rst
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_data/i_soft_reset
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_data/i_tx_mode
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_data/i_tx_start
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_data/i_tx_packet_body
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_data/i_tx_packet_tail
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_data/i_tx_body_num
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_data/i_dma_rd_valid
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_data/i_dma_rd_last
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_data/i_dma_rd_data
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_data/o_dma_rd_ready
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_data/o_tx_interrupt
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_data/o_2711_tkmsb
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_data/o_2711_tklsb
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_data/o_2711_enable
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_data/o_2711_loopen
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_data/o_2711_lckrefn
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_data/o_2711_txd
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_data/tx_state
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_data/fifo_enable
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_data/fifo_rden
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_data/fifo_wren
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_data/fifo_full
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_data/fifo_rdata
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_data/frame_cnt
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_data/valid_dlen
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_data/verif_dcnt
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_data/tx_mode
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_data/sync_cnt
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_data/head_cnt
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_data/vld_data_cnt
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_tx_data/backward_cnt
add wave -noupdate -divider rx_link
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_rx_link/clk
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_rx_link/rst
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_rx_link/i_soft_rst
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_rx_link/i_wr_cmd_ack
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_rx_link/o_wr_cmd_req
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_rx_link/o_wr_cmd_data
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_rx_link/i_rx_start
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_rx_link/i_rx_base_addr
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_rx_link/i_dma_wr_ready
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_rx_link/i_wr_finish
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_rx_link/o_dma_wr_valid
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_rx_link/o_dma_wr_keep
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_rx_link/o_dma_wr_data
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_rx_link/o_rx_interrupt
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_rx_link/o_rx_total_packet
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_rx_link/o_rx_packet_tail
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_rx_link/o_rx_body_num
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_rx_link/i_2711_rkmsb
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_rx_link/i_2711_rklsb
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_rx_link/i_2711_rxd
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_rx_link/o_loss_interrupt
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_rx_link/o_sync_loss
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_rx_link/o_link_loss
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_rx_link/rx_frame_cnt
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_rx_link/wr_bbt
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_rx_link/wr_addr
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_rx_link/tlk2711_rxd
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_rx_link/frame_start
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_rx_link/frame_end
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_rx_link/frame_valid
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_rx_link/frame_data_cnt
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_rx_link/valid_data_num
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_rx_link/fifo_wren
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_rx_link/fifo_empty
add wave -noupdate /tlk2711_tb/tlk2711_top/tlk2711_rx_link/tail_frame_ind
TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate /tlk2711_tb/tlk2711_top/clk
add wave -noupdate /tlk2711_tb/tlk2711_top/rst
add wave -noupdate /tlk2711_tb/tlk2711_top/i_reg_wen
add wave -noupdate /tlk2711_tb/tlk2711_top/i_reg_waddr
add wave -noupdate /tlk2711_tb/tlk2711_top/i_reg_wdata
add wave -noupdate /tlk2711_tb/tlk2711_top/i_reg_ren
add wave -noupdate /tlk2711_tb/tlk2711_top/i_reg_raddr
add wave -noupdate /tlk2711_tb/tlk2711_top/o_reg_rdata
add wave -noupdate /tlk2711_tb/tlk2711_top/o_tx_irq
add wave -noupdate /tlk2711_tb/tlk2711_top/o_rx_irq
add wave -noupdate /tlk2711_tb/tlk2711_top/o_loss_irq
add wave -noupdate /tlk2711_tb/tlk2711_top/i_2711_rkmsb
add wave -noupdate /tlk2711_tb/tlk2711_top/i_2711_rklsb
add wave -noupdate /tlk2711_tb/tlk2711_top/i_2711_rxd
add wave -noupdate /tlk2711_tb/tlk2711_top/o_2711_tkmsb
add wave -noupdate /tlk2711_tb/tlk2711_top/o_2711_tklsb
add wave -noupdate /tlk2711_tb/tlk2711_top/o_2711_enable
add wave -noupdate /tlk2711_tb/tlk2711_top/o_2711_loopen
add wave -noupdate /tlk2711_tb/tlk2711_top/o_2711_lckrefn
add wave -noupdate /tlk2711_tb/tlk2711_top/o_2711_txd
add wave -noupdate /tlk2711_tb/tlk2711_top/m_axi_arready
add wave -noupdate /tlk2711_tb/tlk2711_top/m_axi_arvalid
add wave -noupdate /tlk2711_tb/tlk2711_top/m_axi_arid
add wave -noupdate /tlk2711_tb/tlk2711_top/m_axi_araddr
add wave -noupdate /tlk2711_tb/tlk2711_top/m_axi_arlen
add wave -noupdate /tlk2711_tb/tlk2711_top/m_axi_arsize
add wave -noupdate /tlk2711_tb/tlk2711_top/m_axi_arburst
add wave -noupdate /tlk2711_tb/tlk2711_top/m_axi_arprot
add wave -noupdate /tlk2711_tb/tlk2711_top/m_axi_arcache
add wave -noupdate /tlk2711_tb/tlk2711_top/m_axi_aruser
add wave -noupdate /tlk2711_tb/tlk2711_top/m_axi_rdata
add wave -noupdate /tlk2711_tb/tlk2711_top/m_axi_rresp
add wave -noupdate /tlk2711_tb/tlk2711_top/m_axi_rlast
add wave -noupdate /tlk2711_tb/tlk2711_top/m_axi_rvalid
add wave -noupdate /tlk2711_tb/tlk2711_top/m_axi_rready
add wave -noupdate /tlk2711_tb/tlk2711_top/m_axi_awready
add wave -noupdate /tlk2711_tb/tlk2711_top/m_axi_awvalid
add wave -noupdate /tlk2711_tb/tlk2711_top/m_axi_awid
add wave -noupdate /tlk2711_tb/tlk2711_top/m_axi_awaddr
add wave -noupdate /tlk2711_tb/tlk2711_top/m_axi_awlen
add wave -noupdate /tlk2711_tb/tlk2711_top/m_axi_awsize
add wave -noupdate /tlk2711_tb/tlk2711_top/m_axi_awburst
add wave -noupdate /tlk2711_tb/tlk2711_top/m_axi_awprot
add wave -noupdate /tlk2711_tb/tlk2711_top/m_axi_awcache
add wave -noupdate /tlk2711_tb/tlk2711_top/m_axi_awuser
add wave -noupdate /tlk2711_tb/tlk2711_top/m_axi_wdata
add wave -noupdate /tlk2711_tb/tlk2711_top/m_axi_wstrb
add wave -noupdate /tlk2711_tb/tlk2711_top/m_axi_wlast
add wave -noupdate /tlk2711_tb/tlk2711_top/m_axi_wvalid
add wave -noupdate /tlk2711_tb/tlk2711_top/m_axi_wready
add wave -noupdate /tlk2711_tb/tlk2711_top/m_axi_bresp
add wave -noupdate /tlk2711_tb/tlk2711_top/m_axi_bvalid
add wave -noupdate /tlk2711_tb/tlk2711_top/m_axi_bready
add wave -noupdate /tlk2711_tb/tlk2711_top/tx_base_addr
add wave -noupdate /tlk2711_tb/tlk2711_top/tx_total_packet
add wave -noupdate /tlk2711_tb/tlk2711_top/tx_packet_body
add wave -noupdate /tlk2711_tb/tlk2711_top/tx_packet_tail
add wave -noupdate /tlk2711_tb/tlk2711_top/tx_body_num
add wave -noupdate /tlk2711_tb/tlk2711_top/tx_mode
add wave -noupdate /tlk2711_tb/tlk2711_top/tx_config_done
add wave -noupdate /tlk2711_tb/tlk2711_top/tx_interrupt
add wave -noupdate /tlk2711_tb/tlk2711_top/rx_base_addr
add wave -noupdate /tlk2711_tb/tlk2711_top/rx_config_done
add wave -noupdate /tlk2711_tb/tlk2711_top/rx_interrupt
add wave -noupdate /tlk2711_tb/tlk2711_top/rx_total_packet
add wave -noupdate /tlk2711_tb/tlk2711_top/rx_packet_body
add wave -noupdate /tlk2711_tb/tlk2711_top/rx_packet_tail
add wave -noupdate /tlk2711_tb/tlk2711_top/rx_body_num
add wave -noupdate /tlk2711_tb/tlk2711_top/loss_interrupt
add wave -noupdate /tlk2711_tb/tlk2711_top/sync_loss
add wave -noupdate /tlk2711_tb/tlk2711_top/link_loss
add wave -noupdate /tlk2711_tb/tlk2711_top/soft_rst
add wave -noupdate /tlk2711_tb/tlk2711_top/rd_cmd_data
add wave -noupdate /tlk2711_tb/tlk2711_top/rd_cmd_req
add wave -noupdate /tlk2711_tb/tlk2711_top/rd_cmd_ack
add wave -noupdate /tlk2711_tb/tlk2711_top/wr_cmd_data
add wave -noupdate /tlk2711_tb/tlk2711_top/wr_cmd_req
add wave -noupdate /tlk2711_tb/tlk2711_top/wr_cmd_ack
add wave -noupdate /tlk2711_tb/tlk2711_top/dma_rd_ready
add wave -noupdate /tlk2711_tb/tlk2711_top/dma_rd_valid
add wave -noupdate /tlk2711_tb/tlk2711_top/dma_rd_last
add wave -noupdate /tlk2711_tb/tlk2711_top/dma_rd_data
add wave -noupdate /tlk2711_tb/tlk2711_top/dma_wr_valid
add wave -noupdate /tlk2711_tb/tlk2711_top/dma_wr_keep
add wave -noupdate /tlk2711_tb/tlk2711_top/dma_wr_data
add wave -noupdate /tlk2711_tb/tlk2711_top/dma_wr_ready
add wave -noupdate /tlk2711_tb/tlk2711_top/wr_finish
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 2} {656 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 456
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {713 ps}