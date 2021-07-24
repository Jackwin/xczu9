//////////////////////////////////////////////////////////////////////////////////
// Company:  
// Engineer: 
//
// Create Date:    2021-7-24
// Design Name:
// Module Name:    xdma_interface
// Project Name:
// Target Devices: ZCU102
// Tool versions:
// Description:   interface conversion between the user app and the xdma_IP
//
// Dependencies:
//
// Revision: 
//
//
//////////////////////////////////////////////////////////////////////////////////
module axi_reg_interface #
    (
    parameter C_REG_WIDTH       = 32,
    parameter C_REG_ADDR_WIDTH  = 32
    )
    (
    input                               clk,
    input                               rst,
    // AXI-LITE reg read/write interface from xdma
    input       [C_REG_ADDR_WIDTH-1:0]  s_axi_awaddr,
    input       [2 : 0]                 s_axi_awprot,
    input                               s_axi_awvalid,
    output                              s_axi_awready,
    input       [C_REG_WIDTH-1:0]       s_axi_wdata,
    input       [(C_REG_WIDTH/8)-1:0]   s_axi_wstrb,
    input                               s_axi_wvalid,
    output                              s_axi_wready,
    output                              s_axi_bvalid,
    output      [1 : 0]                 s_axi_bresp,
    input                               s_axi_bready,
    input       [C_REG_ADDR_WIDTH-1:0]  s_axi_araddr,
    input       [2 : 0]                 s_axi_arprot,
    input                               s_axi_arvalid,
    output                              s_axi_arready,
    output      [C_REG_WIDTH-1:0]       s_axi_rdata,
    output      [1 : 0]                 s_axi_rresp,
    output                              s_axi_rvalid,
    input                               s_axi_rready,
    // user-app reg read/write interface
    output                              o_reg_wen,
    output      [31 : 0]                o_reg_waddr,
    output      [63 : 0]                o_reg_wdata,
    output                              o_reg_ren,
    output      [31 : 0]                o_reg_raddr,
    input       [63 : 0]                i_reg_rdata
    );

//-----------------wires and regs-----------------------//

    reg axil_awready = 'b0;
    reg [C_REG_ADDR_WIDTH-1:0] axil_awaddr = 'b0;
    reg axil_wready = 'b0;
    reg axil_bvalid = 'b0;
    reg [1:0]   axil_bresp = 'b0;
    reg axil_arready = 'b0;
    reg [C_REG_ADDR_WIDTH-1:0] axil_araddr = 'b0;
    reg axil_rvalid;
    reg [1:0] axil_rresp;
    reg [C_REG_WIDTH-1:0] axil_rdata;

    reg reg_rden,reg_rden_d,reg_rden_2d;
    reg reg_rd_sel,reg_rd_sel_d,reg_rd_sel_2d;

//-----------------main body----------------------------//

	// I/O Connections assignments
	assign s_axi_awready	= axil_awready;
	assign s_axi_wready	= axil_wready;
	assign s_axi_bresp	= axil_bresp;
	assign s_axi_bvalid	= axil_bvalid;
	assign s_axi_arready	= axil_arready;
	assign s_axi_rdata	= axil_rdata;
	assign s_axi_rresp	= axil_rresp;
	assign s_axi_rvalid	= axil_rvalid;

    // axil_awready is asserted for one clock cycle
    // slave is ready to accept write address when
    // there is a valid write address and write data
    // on the write address and data bus. This design
    // expects no outstanding transactions.
    always @( posedge clk )
    begin
        if ( rst )
            axil_awready <= 1'b0;
        else if (~axil_awready && s_axi_awvalid  )
            axil_awready <= 1'b1;
        else
            axil_awready <= 1'b0;
    end

    // latching axi_awaddr
    always @( posedge clk )
    begin
        if (~axil_awready && s_axi_awvalid )
            axil_awaddr <= s_axi_awaddr;
    end

    // axi_wready generation
    // axi_wready is asserted for one S_AXI_ACLK clock cycle when both
    // S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is
    // de-asserted when reset is low.
    always @( posedge clk )
    begin
        if ( rst )
            axil_wready <= 1'b0;
      //  else if (~axil_wready && s_axi_wvalid )   //debug for data channel is early ,addr channel is late
      else if(~axil_wready && s_axi_awvalid)
            axil_wready <= 1'b1;
        else
            axil_wready <= 1'b0;
    end

    // Implement write response logic
    // The write response and response valid signals are asserted by the slave
    // when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.
    // This marks the acceptance of address and indicates the status of
    // write transaction.
    always @( posedge clk )
    begin
        if ( rst )
            begin
                axil_bvalid  <= 0;
                axil_bresp   <= 2'b0;
            end
        else if ( ~axil_bvalid && axil_wready && s_axi_wvalid)
            begin
                axil_bvalid <= 1'b1;
                axil_bresp  <= 2'b0; // 'OKAY' response
            end
        else if (s_axi_bready && axil_bvalid)
            begin
                axil_bvalid <= 1'b0;
                axil_bresp  <= 2'b0;
            end
    end

    // Implement axi_arready generation
    // axi_arready is asserted for one S_AXI_ACLK clock cycle when
    // S_AXI_ARVALID is asserted. axi_awready is
    // de-asserted when reset (active low) is asserted.
    // The read address is also latched when S_AXI_ARVALID is
    // asserted. axi_araddr is reset to zero on reset assertion.
    always @( posedge clk )
    begin
        if (rst)
            axil_arready <= 'b0;
        else if (~axil_arready && s_axi_arvalid)
            axil_arready <= 1'b1; // indicates that the slave has acceped the valid read address
        else
            axil_arready <= 1'b0;
    end

    always @( posedge clk )
    begin
        if (~axil_arready && s_axi_arvalid)
            axil_araddr  <= s_axi_araddr; // Read address latching
    end

    // Implement axi_arvalid generation
    // axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both
    // S_AXI_ARVALID and axi_arready are asserted. The slave registers
    // data are available on the axi_rdata bus at this instance. The
    // assertion of axi_rvalid marks the validity of read data on the
    // bus and axi_rresp indicates the status of read transaction.axi_rvalid
    // is deasserted on reset (active low). axi_rresp and axi_rdata are
    // cleared to zero on reset (active low).
    always @( posedge clk )
    begin
        if ( rst )
        begin
            axil_rvalid <= 0;
            axil_rresp  <= 0;
        end
        else
        begin
            if (reg_rden_2d  && ~axil_rvalid)
            begin
                axil_rvalid <= 1'b1;// Valid read data is available at the read data bus
                axil_rresp  <= 2'b0; // 'OKAY' response
            end
            else if (axil_rvalid && s_axi_rready)
            begin
                axil_rvalid <= 1'b0; // Read data is accepted by the master
                axil_rresp  <= 2'b0; // 'OKAY' response
            end
        end
    end

    // Implement memory mapped register write logic
    // The write data is accepted and written to memory mapped registers when
    // axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.
    wire reg_wren;
    assign reg_wren = axil_wready && s_axi_wvalid ;
    reg [C_REG_WIDTH-1:0] axil_wdata;
    always @(posedge clk)
    begin
        if (~axil_wready && s_axi_wvalid)
        axil_wdata <= s_axi_wdata;
    end

    // change two 32bits reg_write to one 64bits reg-write
    (*mark_debug="true"*)wire reg_wren_lo;
    (*mark_debug="true"*)reg [31:0] reg64_lo='b0;
    (*mark_debug="true"*)wire reg_wren_hi;
    (*mark_debug="true"*)reg reg64_wren;
    (*mark_debug="true"*)reg [63:0] reg64_wdata;
    (*mark_debug="true"*)reg [31:0] reg64_waddr;

    assign reg_wren_lo = reg_wren && ~axil_awaddr[2];
    assign reg_wren_hi = reg_wren && axil_awaddr[2];

    always @(posedge clk)
    begin
        if (reg_wren_lo)
            reg64_lo <= axil_wdata;

        reg64_wren <= reg_wren_hi;
        reg64_wdata <= reg_wren_hi ? {axil_wdata,reg64_lo} : 'b0;
        reg64_waddr <= reg_wren_hi ? {axil_awaddr[C_REG_ADDR_WIDTH-1:3],3'b0} : 'b0;
    end

    assign o_reg_wen = reg64_wren;
    assign o_reg_waddr = reg64_waddr;
    assign o_reg_wdata = reg64_wdata;

    // Implement memory mapped register select and read logic
    // read latency is 4 clock cycles
    // if read the low 32bits, reg_rd_sel = 0,other reg_rd_sel = 1;
    reg reg64_rden;
    always @(posedge clk)
    begin
        if (~axil_arready && s_axi_arvalid)
            reg_rden <= 1'b1;
        else
            reg_rden <= 1'b0;
    end

    always @(posedge clk)
    begin
        if (~axil_arready && s_axi_arvalid)
            reg_rd_sel <= s_axi_araddr[2];
    end

    always @(posedge clk)
    begin
        if (~axil_arready && s_axi_arvalid && ~s_axi_araddr[2])
            reg64_rden <= 1'b1;
        else
            reg64_rden <= 1'b0;
    end

    always @(posedge clk)
    begin
        reg_rden_d <= reg_rden;
        reg_rden_2d <= reg_rden_d;

        reg_rd_sel_d <= reg_rd_sel;
        reg_rd_sel_2d <= reg_rd_sel_d;
    end

    reg [63:0] reg64_rdata = 'b0;
    always @(posedge clk)
    begin
        if (reg_rden_2d & ~reg_rd_sel_2d)
            reg64_rdata <= i_reg_rdata;
    end

    always @(posedge clk)
    begin
        if (reg_rden_2d)
            axil_rdata <= reg_rd_sel_2d ? reg64_rdata[63:32]:i_reg_rdata[31:0];
    end

    assign o_reg_ren = reg64_rden;
    assign o_reg_raddr = {axil_araddr[C_REG_ADDR_WIDTH-1:3],3'b0};

endmodule
