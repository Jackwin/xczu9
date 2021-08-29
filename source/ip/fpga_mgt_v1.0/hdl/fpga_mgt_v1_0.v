
`timescale 1 ns / 1 ps

	module fpga_mgt_v1_0 #
        (
            // Users to add parameters here
           
            // User parameters ends
            // Do not modify the parameters beyond this line
    
    
            // Parameters of Axi Slave Bus Interface s_axi
            parameter integer C_DATA_WIDTH    = 32,
            parameter integer C_ADDR_WIDTH    = 32
        )
        (
            // Users to add ports here
            
             output wire                            o_reg_wen,
             output wire    [31 : 0]                o_reg_waddr,
             output wire    [63 : 0]                o_reg_wdata,
             output wire                            o_reg_ren,
             output wire    [31 : 0]                o_reg_raddr,
             input  wire    [63 : 0]                i_reg_rdata,
            // User ports ends
            // Do not modify the ports beyond this line
    
    
            // Ports of Axi Slave Bus Interface s_axi
            input wire                          s_axi_aclk,
            input wire                          s_axi_aresetn,
            input wire [C_ADDR_WIDTH-1 : 0]     s_axi_awaddr,
            input wire [2 : 0]                  s_axi_awprot,
            input wire                          s_axi_awvalid,
            output wire                         s_axi_awready,
            input wire [C_DATA_WIDTH-1 : 0]     s_axi_wdata,
            input wire [(C_DATA_WIDTH/8)-1 : 0] s_axi_wstrb,
            input wire                          s_axi_wvalid,
            output wire                         s_axi_wready,
            output wire [1 : 0]                 s_axi_bresp,
            output wire                         s_axi_bvalid,
            input wire                          s_axi_bready,
            input wire [C_ADDR_WIDTH-1 : 0]     s_axi_araddr,
            input wire [2 : 0]                  s_axi_arprot,
            input wire                          s_axi_arvalid,
            output wire                         s_axi_arready,
            output wire [C_DATA_WIDTH-1 : 0]    s_axi_rdata,
            output wire [1 : 0]                 s_axi_rresp,
            output wire                         s_axi_rvalid,
            input wire                          s_axi_rready
        );
    // Instantiation of Axi Bus Interface s_axi
        axi_reg_interface # ( 
            .C_REG_WIDTH(C_DATA_WIDTH),
            .C_REG_ADDR_WIDTH (C_ADDR_WIDTH)
        ) axi_reg_interface_v1_0_s_axi_inst (
            .o_reg_wen    (o_reg_wen),
            .o_reg_waddr  (o_reg_waddr),
            .o_reg_wdata  (o_reg_wdata),
            .o_reg_ren    (o_reg_ren),
            .o_reg_raddr  (o_reg_raddr),
            .i_reg_rdata  (i_reg_rdata),
            
            .clk(s_axi_aclk),
            .rst(~s_axi_aresetn),
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

        endmodule

