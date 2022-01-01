`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: zhulin
//////////////////////////////////////////////////////////////////////////////////

module tlk2711_tb(

    );
	reg  [39:0]         tx_base_addr = 40'h000000;
	reg  [39:0]         rx_base_addr = 'h000100;

	localparam FRAME_LENGTH = 10752;
	localparam FRAME_NUM = 6;
	localparam LINE_NUM_PER_INTR = 3;

	//integer  			frame_length = 'd870;
	integer             tx_total_packet = FRAME_LENGTH * FRAME_NUM; // total packet bytes
	reg[15:0]           tx_packet_body = 'd10752; 
	reg[15:0]           tx_packet_tail = 'd10752;
	reg[23:0] 			tx_body_num = 24'd3;
	
	integer             tx_mode = 3'd2; //0--norm mode, 1--kcode mode, 2--test mode, 3--specific mode 4--protocal test mode
	integer  			rx_check_ena = 1'd1;

	reg[23:0] 			rx_line_num_per_intr = LINE_NUM_PER_INTR;
	  
	reg [15:0]  TX_IRQ_REG       = 16'h0060;
    reg [15:0]  RX_IRQ_REG       = 16'h0200;
    reg [15:0]  LOSS_IRQ_REG      = 16'h0300;

	reg [15:0]  IRQ_REG       = 16'h0060;

	parameter DDR_ADDR_WIDTH = 40;
	parameter HP0_DATA_WIDTH = 128;
	parameter STREAM_DATA_WIDTH = 64;
	localparam DEBUG_ENA = "FALSE";	

 
    wire             o_tx_irq;
    wire             o_rx_irq;
    wire             o_loss_irq;

    wire             i_2711_rkmsb;
    wire             i_2711_rklsb;
    wire   [15:0]    i_2711_rxd;
    wire             o_2711_tkmsb;
    wire             o_2711_tklsb;
    wire             o_2711_enable;
    wire             o_2711_loopen;
    wire             o_2711_lckrefn;
    wire  [15:0]     o_2711_txd;
    
    wire [3:0]   m_axi_arid   ;
    wire [31:0]  m_axi_araddr ;
    wire [7:0]   m_axi_arlen  ;
    wire [2:0]   m_axi_arsize ;
    wire [1:0]   m_axi_arburst;
    wire [2:0]   m_axi_arprot ;
    wire [3:0]   m_axi_arcache;
    wire [3:0]   m_axi_aruser ;
    wire         m_axi_arvalid;
    reg          m_axi_arready = 1'b1;
    reg [HP0_DATA_WIDTH-1:0]   m_axi_rdata = {16'd4, 16'd5, 16'd6, 16'd7, 
											16'd0, 16'd1, 16'd2, 16'd3};
    reg [1:0]    m_axi_rresp = 2'b00;
    wire         m_axi_rlast;
    wire         m_axi_rvalid;
    wire         m_axi_rready;
    wire [3:0]   m_axi_awid   ;
    wire [31:0]  m_axi_awaddr ;
    wire [7:0]   m_axi_awlen  ;
    wire [2:0]   m_axi_awsize ;
    wire [1:0]   m_axi_awburst;
    wire [2:0]   m_axi_awprot ;
    wire [3:0]   m_axi_awcache;
    wire [3:0]   m_axi_awuser ;
    wire         m_axi_awvalid;
    reg          m_axi_awready = 1'b1;
    wire [HP0_DATA_WIDTH-1:0]  m_axi_wdata;
    wire [7:0]   m_axi_wstrb;
    wire         m_axi_wlast;
    wire         m_axi_wvalid;
    reg          m_axi_wready = 1'b1;
    reg [1:0]    m_axi_bresp = 2'b00;
    reg          m_axi_bvalid = 1'b0;
    wire         m_axi_bready;
	
	reg 		clk,rst;
	reg 		tlk2711_rx_clk;

	reg [63:0]	reg_rdata;

	initial begin  
		clk = 1'b0;  
		rst = 1'b1;
		#100 
		@(posedge clk)
		rst = 1'b0;		
	end 
	
	always begin  
		#10 clk = ~clk;  // 100M	
	end

	initial begin
		tlk2711_rx_clk = 1'b0;
		forever begin
			#11 tlk2711_rx_clk = ~tlk2711_rx_clk;
		end
	end

	reg            	i_reg_wen, i_reg_ren;
	reg  [15:0]    	i_reg_waddr, i_reg_raddr;
	reg  [63:0]    	i_reg_wdata;
	wire [63:0]    	i_reg_rdata;
	reg  [10:0]    	start_cnt = 'd0;
	wire [63:0] 	o_reg_rdata;

	localparam TX_ENA_REG_ADDR = 16'h0008;
	localparam TX_BASE_REG_ADDR = 16'h0020;
	localparam TX_PACKET_REG_ADDR = 16'h0030;
	localparam TX_TX_STATUS_REG_ADDR= 16'h0038;
	
	localparam RX_ENA_REG_ADDR = 16'h0010;
	localparam RX_BASE_REG_ADDR = 16'h0040;
	localparam RX_CTRL_REG_ADDR = 16'h0048;
	localparam RX_STATUS_REG_ADDR = 16'h0050;
	localparam RX_CTRL_REG2_ADDR = 16'h0058;
	localparam IRQ_CTRL_REG_ADDR = 16'h0068;
	

initial begin
	repeat(50) @(posedge clk);
	write_reg(TX_BASE_REG_ADDR, {4'h0, 20'h300, tx_base_addr});

	write_reg(RX_BASE_REG_ADDR, rx_base_addr);

	write_reg(TX_PACKET_REG_ADDR, {1'b1, tx_mode, 1'b1, 3'h0, tx_packet_tail, 
									  tx_body_num, tx_packet_body});
	write_reg(RX_CTRL_REG2_ADDR, {'h0, rx_check_ena, rx_line_num_per_intr});

	write_reg(RX_CTRL_REG_ADDR, 64'h0);

	write_reg(IRQ_CTRL_REG_ADDR, 64'h1000_0000_0000_0010);
		
	write_reg(IRQ_CTRL_REG_ADDR, 64'h2000_0000_0000_0010);

	write_reg(TX_ENA_REG_ADDR, 64'h3);

	write_reg(RX_ENA_REG_ADDR, 64'h3);

	#50000;

	task_reg_read(RX_STATUS_REG_ADDR, reg_rdata);
	task_reg_read(RX_CTRL_REG2_ADDR, reg_rdata);

end

task task_reg_read;
	input [15:0]  	i_addr;
	output [63:0]   o_rd_data;
	begin
		@(posedge clk);
		i_reg_ren = 1'b0;
		i_reg_raddr = 1'b0;

		@(posedge clk);
		i_reg_ren = 1;
		i_reg_raddr = i_addr;
		@(posedge clk);
		i_reg_ren = 0;
		o_rd_data = o_reg_rdata;
		repeat(3) @(posedge clk);

		$display("%g The read data   :%h", $time, o_rd_data);
	end
endtask

 task write_reg;
    input [15:0] waddr;
    input [63:0] wdata;
    begin
        @(posedge clk);
        i_reg_wen   = 1'b1;
        i_reg_waddr = waddr;
        i_reg_wdata = wdata;
        @(posedge clk);
        i_reg_wen   = 1'b0;
        $display("write reg: offset %x  %x\n",waddr,wdata);
    end
endtask


//   always@(posedge clk)
// 	begin
// 	  if (o_tx_irq)
// 	  begin
// 	  	i_reg_ren   <= 'b1;
// 	  	i_reg_raddr <= TX_IRQ_REG;
// 	  end	
// 	  else if (o_rx_irq)
// 	  begin
// 	  	i_reg_ren   <= 'b1;
// 	  	i_reg_raddr <= RX_IRQ_REG;
// 	  end	
// 	  else if (o_loss_irq)
// 	  begin
// 	  	i_reg_ren   <= 'b1;
// 	  	i_reg_raddr <= LOSS_IRQ_REG;
// 	  end	
// 	  else
// 	  begin
// 	  	i_reg_ren   <= 'b0;
// 	  	i_reg_raddr <= 'd0;
// 	  end
// 	end

	// always@(posedge clk) begin
	// 	if (rst) begin
	// 		i_reg_ren <= 1'b0;
	// 		i_reg_raddr <= 'h0;
	// 	end else begin
	// 		if (o_tx_irq | o_rx_irq | o_loss_irq)begin
	// 			i_reg_ren   <= 'b1;
	// 			i_reg_raddr <= IRQ_REG;
	// 		end else begin
	// 			i_reg_ren <= 0;
	// 			i_reg_raddr <= 'h0;
	// 		end
	// 	end
  	// end


	// Count rx interrupt
	reg [7:0] 	rx_irq_cnt;
	reg rx_intr_r1;

	always @(posedge clk) begin
		rx_intr_r1 <= o_rx_irq;
	end

	always @(posedge clk) begin
		if (rst) begin
			rx_irq_cnt <= 'h0;
		end else begin
			if (~rx_intr_r1 & o_rx_irq) begin
				rx_irq_cnt <= rx_irq_cnt + 1'd1;
				$display("%t (top.v) rx interrupt cnt is %d.", $time, rx_irq_cnt);
			end
		end
	end

	always @(posedge clk) begin
		wait(rx_irq_cnt == (FRAME_NUM / LINE_NUM_PER_INTR -1));
		wait(o_tx_irq);
		repeat(200) @(posedge clk);
		$display("%t (top.v) sim DONE.", $time);
		$stop;
	end

	reg [64:0] 	reg_rd_data;
	initial begin
		i_reg_ren = 0;
		i_reg_raddr = 0;
		forever begin
			wait(o_tx_irq | o_rx_irq | o_loss_irq);
			task_reg_read(IRQ_REG, reg_rd_data);
		end
	end

  reg [31:0] num_video = 32'd0;
  	
	assign  m_axi_rlast = m_axi_rvalid & m_axi_rready & (num_video[3:0] == 1);
	assign  m_axi_rvalid = m_axi_rready & (num_video != 'd0);
	
	always @(posedge clk) begin
		if (m_axi_arvalid & m_axi_arready)
		    num_video <= num_video + m_axi_arlen + 1;
		else if (m_axi_rready & m_axi_rvalid)
		    num_video <= num_video - 1;
		 
		if(m_axi_rready & m_axi_rvalid)
			m_axi_rdata <= m_axi_rdata + {8{16'h8}}; // $random%1200; 
		
	end
	
	always @(posedge clk) begin		  
		  if (m_axi_rlast) 
		       m_axi_arready <= 1'b1;   
		  else if (m_axi_arvalid)
		      m_axi_arready <= 1'b0;
	end
	
	always@(posedge clk) begin
    	if (m_axi_wvalid & m_axi_wready & m_axi_wlast)
          m_axi_bvalid <= 1'b1;
      else if (m_axi_bready)
          m_axi_bvalid <= 1'b0;
    end
	
    assign i_2711_rkmsb = o_2711_tkmsb;
    assign i_2711_rklsb = o_2711_tklsb;
    assign i_2711_rxd   = o_2711_txd;


	// Write DMA data to a file
	integer i = 0;
	reg [127:0] memory [0:127]; // 128 bit memory with 128 entries

	// initial begin
    // 	for (i=0; i<16; i++) begin
    //     	memory[i] = i;
    // end
    // 	//$writememb("memory_binary.txt", memory);
    // 	$writememh("memory_hex.txt", memory);
	// end	

	always @(posedge clk) begin
		if (m_axi_wvalid) begin
			i <= i + 1;
			memory[i] <= m_axi_wdata;
		end
	end
    
    tlk2711_top #(
		.DEBUG_ENA(DEBUG_ENA),
    	.ADDR_WIDTH(DDR_ADDR_WIDTH),
	    .AXI_RDATA_WIDTH(HP0_DATA_WIDTH), //HP0_DATA_WIDTH
	    .AXI_WDATA_WIDTH(HP0_DATA_WIDTH), // HP0_DATA_WIDTH
	    .AXI_WBYTE_WIDTH(HP0_DATA_WIDTH/8),  // HP0_DATA_WIDTH/8
        .STREAM_RDATA_WIDTH(STREAM_DATA_WIDTH), 
	    .STREAM_WDATA_WIDTH(STREAM_DATA_WIDTH),
	    .STREAM_WBYTE_WIDTH(STREAM_DATA_WIDTH/8),  
        .DLEN_WIDTH(16)
    ) tlk2711_top (
		.ps_clk(clk),
		.ps_rst(rst),
        .clk(clk),
        .rst(rst),
        .i_reg_wen(i_reg_wen),
        .i_reg_waddr(i_reg_waddr),
        .i_reg_wdata(i_reg_wdata),    
        .i_reg_ren(i_reg_ren),
        .i_reg_raddr(i_reg_raddr),
        .o_reg_rdata(o_reg_rdata), 
        //interrupt
        .o_tx_irq(o_tx_irq),
        .o_rx_irq(o_rx_irq),
        .o_loss_irq(o_loss_irq),
        //tlk2711 interface
		.i_2711_rx_clk(tlk2711_rx_clk),
        .i_2711_rkmsb(i_2711_rkmsb),
        .i_2711_rklsb(i_2711_rklsb),
        .i_2711_rxd(i_2711_rxd),
        .o_2711_tkmsb(o_2711_tkmsb),
        .o_2711_tklsb(o_2711_tklsb),
        .o_2711_enable(o_2711_enable),
        .o_2711_loopen(o_2711_loopen),
        .o_2711_lckrefn(o_2711_lckrefn),
        .o_2711_txd(o_2711_txd),

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
	
	
endmodule
