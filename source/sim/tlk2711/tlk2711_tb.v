`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: zhulin
//////////////////////////////////////////////////////////////////////////////////

module tlk2711_tb(

    );
	reg  [47:0]          tx_base_addr = 'h000000;
	reg  [47:0]          rx_base_addr = 'h000100;
	  
	integer              tx_total_packet = 'd1800; // total packet bytes
	integer              tx_packet_body = 'd870; 
	integer              tx_packet_tail = 'd60;
	integer              tx_body_num = 'd2;
	integer              tx_mode = 'd0; //0--norm mode, 1--loopback mode, 2--kcode mode
	  
	reg [15:0]  TX_IRQ_REG       = 16'h0100;
    reg [15:0]  RX_IRQ_REG       = 16'h0200;
    reg [15:0]  LOSS_IRQ_REG      = 16'h0300;

	reg [15:0]  IRQ_REG       = 16'h0100;

	parameter DDR_ADDR_WIDTH = 40;
	parameter HP0_DATA_WIDTH = 128;
	parameter STREAM_DATA_WIDTH = 64;	

 
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
	
	reg clk,rst;

	initial  
	begin  
		clk = 1'b0;  
		rst = 1'b1;
		#100 
		@(posedge clk)
		rst = 1'b0;		
	end 
	
	always  
	begin  
		#10 clk = ~clk;  // 100M	
	end
	
	reg            	i_reg_wen, i_reg_ren;
	reg  [15:0]    	i_reg_waddr, i_reg_raddr;
	reg  [63:0]    	i_reg_wdata;
	wire [63:0]    	i_reg_rdata;
	reg  [10:0]    	start_cnt = 'd0;
	wire [63:0] 	o_reg_rdata;
	
	always@(posedge clk)                             
	begin
		if(!rst)
		begin
			if(start_cnt < 'd20)
				start_cnt <= start_cnt + 'd1;
		end

		case(start_cnt)
		'd10:
		begin
			i_reg_wen <= 'd1;
			i_reg_waddr <= 16'h0108;
			i_reg_wdata <= tx_base_addr;
		end
		'd11:
		begin
			i_reg_wen <= 'd1;
			i_reg_waddr <= 16'h0208;
			i_reg_wdata <= rx_base_addr;
		end
		'd12:
		begin
			i_reg_wen   <= 'd1;
			i_reg_waddr <= 16'h0110;
			i_reg_wdata <= tx_total_packet;
		end
		'd13:
		begin
			i_reg_wen <= 'd1;
			i_reg_waddr <= 16'h0118;
			i_reg_wdata[63:32] <= tx_packet_tail;
			i_reg_wdata[31:0]  <= tx_packet_body;
		end
		'd14:
		begin
			i_reg_wen <= 'd1;
			i_reg_waddr <= 16'h0120;
			i_reg_wdata[63:32] <= tx_body_num;
			i_reg_wdata[31:0]  <= tx_mode;
		end
		'd15:
		begin //tx start
			i_reg_wen <= 'd1;
			i_reg_waddr <= 16'h0100;
		end
	  'd16:
		begin //rx start 
			i_reg_wen <= 'd1;
			i_reg_waddr <= 16'h0200;
		end
		default:
		begin
			i_reg_wen <= 'd0;
		end
		endcase	
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
	
	always@(posedge clk)
	begin
		if (m_axi_arvalid & m_axi_arready)
		    num_video <= num_video + m_axi_arlen + 1;
		else if (m_axi_rready & m_axi_rvalid)
		    num_video <= num_video - 1;
		 
		if(m_axi_rready & m_axi_rvalid)
			m_axi_rdata <= m_axi_rdata + {8{16'h8}}; // $random%1200; 
		
	end
	
	always@(posedge clk)
	begin		  
		  if (m_axi_rlast) 
		       m_axi_arready <= 1'b1;   
		  else if (m_axi_arvalid)
		      m_axi_arready <= 1'b0;
	end
	
	always@(posedge clk)
    begin
    	if (m_axi_wvalid & m_axi_wready & m_axi_wlast)
          m_axi_bvalid <= 1'b1;
      else if (m_axi_bready)
          m_axi_bvalid <= 1'b0;
    end
	
    assign i_2711_rkmsb = o_2711_tkmsb;
    assign i_2711_rklsb = o_2711_tklsb;
    assign i_2711_rxd   = o_2711_txd;
    
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
