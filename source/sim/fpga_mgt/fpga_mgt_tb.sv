

module fpga_mgt_tb();


localparam C_ADDR_WIDTH = 32;
localparam C_DATA_WIDTH = 32;
logic 							clk;
logic 							rst;

logic                         	o_reg_wen;
logic [31 : 0]                	o_reg_waddr;
logic [63 : 0]                	o_reg_wdata;
logic                          	o_reg_ren;
logic [31 : 0]                	o_reg_raddr;
logic [63 : 0]     				i_reg_rdata;

// Ports of Axi Slave Bus Interface s_axi
logic                          	s_axi_aclk;
logic                          	s_axi_aresetn;
logic [C_ADDR_WIDTH-1 : 0]     	s_axi_awaddr;
logic [2 : 0]                  	s_axi_awprot;
logic                          	s_axi_awvalid;
logic                          	s_axi_awready;
logic [C_DATA_WIDTH-1 : 0]     	s_axi_wdata;
logic [(C_DATA_WIDTH/8)-1 : 0] 	s_axi_wstrb;
logic                          	s_axi_wvalid;
logic                          	s_axi_wready;
logic  [1 : 0]                 	s_axi_bresp;
logic                          	s_axi_bvalid;
logic                          	s_axi_bready;
logic [C_ADDR_WIDTH-1 : 0]     	s_axi_araddr;
logic [2 : 0]                  	s_axi_arprot;
logic                          	s_axi_arvalid;
logic                          	s_axi_arready;
logic  [C_DATA_WIDTH-1 : 0]    	s_axi_rdata;
logic  [1 : 0]                 	s_axi_rresp;
logic                          	s_axi_rvalid;
logic                          	s_axi_rready;

wire [C_ADDR_WIDTH-1:0]   		tx_base_addr;
wire [31:0]             		tx_total_packet;
wire [15:0]             		tx_packet_body;
wire [15:0]             		tx_packet_tail;
wire [15:0]             		tx_body_num;
wire [3:0]              		tx_mode;
wire                    		tx_config_done; 
wire                    		tx_interrupt;

wire [C_ADDR_WIDTH-1:0] 		 rx_base_addr;
wire                    		rx_config_done;
wire                    		rx_interrupt;
wire [15:0]             		rx_frame_length;
wire [15:0]             		rx_packet_body; 
wire [15:0]             		rx_packet_tail;
wire [15:0]             		rx_frame_num;

wire                    		loss_interrupt;
wire                    		sync_loss;
wire                    		link_loss;
wire                    		soft_rst;
wire [7:0]              		rx_data_type;
wire                    		rx_file_end_flag;
wire                    		rx_checksum_flag;

wire [5:0]                      rx_status = 'h3d;
wire [9:0]                      tx_status = 'h3ff;
wire                            rx_fifo_rd;

logic [63:0] 					reg_read_data;


fpga_mgt_v1_0 fpga_mgt_v1_0_inst(

	.o_reg_wen(o_reg_wen),
	.o_reg_waddr(o_reg_waddr),
	.o_reg_wdata(o_reg_wdata),
	.o_reg_ren(o_reg_ren),
	.o_reg_raddr(o_reg_raddr),
	.i_reg_rdata(i_reg_rdata),
	// User ports ends
	// Do not modify the ports beyond this line


	// Ports of Axi Slave Bus Interface s_axi
	.s_axi_aclk(clk),
	.s_axi_aresetn(~rst),
	.s_axi_awaddr(s_axi_awaddr),
	.s_axi_awprot(s_axi_awprot),
	.s_axi_awvalid(s_axi_awvalid),
	.s_axi_awready(s_axi_awready),

	.s_axi_wdata(s_axi_wdata),
	.s_axi_wstrb(s_axi_wstrb),
	.s_axi_wvalid(s_axi_wvalid),
	.s_axi_wready(s_axi_wready),

	.s_axi_bresp(s_axi_bresp),
	.s_axi_bvalid(s_axi_bvalid),
	.s_axi_bready(s_axi_bready),

	.s_axi_araddr(s_axi_araddr),
	.s_axi_arprot(s_axi_arprot),
	.s_axi_arvalid(s_axi_arvalid),
	.s_axi_arready(s_axi_arready),

	.s_axi_rdata(s_axi_rdata),
	.s_axi_rresp(s_axi_rresp),
	.s_axi_rvalid(s_axi_rvalid),
	.s_axi_rready(s_axi_rready)
);

   reg_mgt #(       
       .ADDR_WIDTH(C_ADDR_WIDTH)
   ) reg_mgt (  
       .ps_clk(clk),
       .ps_rst(rst),
       .i_reg_wen(o_reg_wen),
       .i_reg_waddr(o_reg_waddr),
       .i_reg_wdata(o_reg_wdata),
       .i_reg_ren(o_reg_ren),
       .i_reg_raddr(o_reg_raddr),
       .o_reg_rdata(i_reg_rdata),
       .o_tx_irq(o_tx_irq),
       .o_rx_irq(o_rx_irq),
       .o_loss_irq(o_loss_irq),

       .clk(clk),
       .rst(rst),
       .o_tx_base_addr(tx_base_addr), 
       .o_tx_total_packet(tx_total_packet), 
       .o_tx_packet_body(tx_packet_body), 
       .o_tx_packet_tail(tx_packet_tail), 
       .o_tx_body_num(tx_body_num),  
       .o_tx_mode(tx_mode), 
       .o_tx_config_done(tx_config_done),  
       .i_tx_interrupt(tx_interrupt), 
       .o_rx_base_addr(rx_base_addr), 
       .o_rx_config_done(rx_config_done),
       .o_rx_fifo_rd(rx_fifo_rd),

       .i_rx_interrupt(rx_interrupt), 
       .i_rx_frame_length(rx_frame_length),
       .i_rx_frame_num(rx_frame_num),
       .i_rx_data_type(rx_data_type),
       .i_rx_file_end_flag(rx_file_end_flag),
       .i_rx_checksum_flag(rx_checksum_flag),

       .i_tx_status(tx_status),
       .i_rx_status(rx_status),
       .i_loss_interrupt(loss_interrupt),
       .i_sync_loss(sync_loss),
       .i_link_loss(link_loss),
       .o_soft_rst(soft_rst) 
    );

initial  begin  
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
	s_axi_araddr = 0;
	s_axi_arvalid = 0;
	s_axi_bready = 0;
	s_axi_rready = 0;

	#100;
	@(posedge clk);
	s_axi_araddr = 32'h80;
	s_axi_arvalid = 1'b1;
	s_axi_bready = 1;

	s_axi_rready = 1;

	@(posedge clk);
	s_axi_arvalid = 0;
	s_axi_bready = 0;

	#100;

	reg_read('h0, reg_read_data);
	reg_read('h4, reg_read_data);

end


task reg_read;
	input [31:0] 	i_addr;
	output [53:0]	o_rd_data;
	begin
		o_rd_data = s_axi_rdata;
		@(posedge clk);
		s_axi_arvalid = 1'b0;
		s_axi_bready = 0;

		@(posedge clk);
		s_axi_araddr = i_addr;
		s_axi_arvalid = 1'b1;
		s_axi_bready = 1;
		
		@(posedge clk);
		s_axi_arvalid = 0;
		s_axi_bready = 0;
	end
endtask



endmodule