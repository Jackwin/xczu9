
///////////////////////////////////////////////////////////////////////////////
//  
//    Version: 1.0
//    Filename:  reg_mgt.v
//    Date Created: 2021-06-27
// 
//   
// Project: TLK2711
// Device: zu9eg
// Purpose: register configuration
// Author: Zhu Lin
// Reference:  
// Revision History:
//   Rev 1.0 - First created, zhulin, 2021-06-27
//   
// Email: jewel122410@163.com
////////////////////////////////////////////////////////////////////////////////

module reg_mgt 
#(       
    parameter ADDR_WIDTH = 32
)
(  
    input               clk,
    input               rst,
    
    input               i_reg_wen,
    input      [15:0]   i_reg_waddr,
    input      [63:0]   i_reg_wdata,

    input               i_reg_ren,
    input      [15:0]   i_reg_raddr,
    output     [63:0]   o_reg_rdata,

    output              o_tx_irq,
    output              o_rx_irq,
    output              o_loss_irq,
  
    
    // TX port set
    //read data address from DDR to tx module
    output reg [ADDR_WIDTH-1:0]   o_tx_base_addr, 
    //total file packet length in byte
    output reg [31:0]             o_tx_total_packet, 
    //body length in byte, 870B here for fixed value
    output reg [15:0]             o_tx_packet_body, 
    //tail length in byte
    output reg [15:0]             o_tx_packet_tail, 
    //body number, total_packet = packet_body*body_num + packet_tail
    output reg [15:0]             o_tx_body_num, 
    // 0--norm mode, 1--loopback mode, 2--kcode mode
    output reg [3:0]              o_tx_mode,
    // configured when all the above register is done and start the transfer 
    output reg                    o_tx_config_done,
    // inform cpu after the total packet transfer is finished
    input                         i_tx_interrupt, 

    //RX port set
    //write data address to DDR from rx module
    output reg [ADDR_WIDTH-1:0]   o_rx_base_addr, 
    output reg                    o_rx_config_done,

    input                         i_rx_interrupt, //when asserted, the packet information is valid at the same time
    input  [15:0]                 i_rx_frame_length,
    input  [15:0]                 i_rx_frame_num, //870B here the same as tx configuration and no need to reported 
    
    input                       i_rx_fifo_status,   
    input                       i_loss_interrupt,
    input                       i_sync_loss,
    input                       i_link_loss,

    output                        o_soft_rst
    
    );

    localparam  SOFT_R_REG       = 16'h0000;
    localparam  TX_CFG_REG       = 16'h0008;
    localparam  RX_CFG_REG       = 16'h0010;
    localparam  IRQ_REG          = 16'h0100;

    localparam  TX_IRQ_REG       = 16'h0100;
    localparam  RX_IRQ_REG       = 16'h0200;
    localparam  RX_LOSS_REG      = 16'h0300;

//////////////////////////////////////////////////////////////////////////
//  TX and RX register configuration
//////////////////////////////////////////////////////////////////////////

    // TODO Add tx and rx status & ctrl register 9-14

    (*keep="true"*)reg         reg_wen;
    (*keep="true"*)reg  [63:0] reg_wdata;
    (*keep="true"*)reg  [15:0] reg_waddr;
	
    always@(posedge clk)begin
        if(rst)
            reg_wen <= 0;
        else begin
			if(i_reg_wen) begin
				reg_waddr <= i_reg_waddr;
			    reg_wdata <= i_reg_wdata;
			end
			reg_wen <= i_reg_wen;
        end        
    end

    always@(posedge clk) begin
        if( reg_wen && ( reg_waddr == TX_CFG_REG )) // for tx config done
            o_tx_config_done <=  1'b1;
        else 
            o_tx_config_done <= 1'b0;

        if( reg_wen && ( reg_waddr == RX_CFG_REG )) // for rx config done
            o_rx_config_done <=  1'b1;
        else 
            o_rx_config_done <= 1'b0;
    end

    always@(posedge clk) begin
        if( reg_wen )
          case(reg_waddr)
            //tx
            16'h0108:   o_tx_base_addr    <= reg_wdata;
            16'h0110:   o_tx_total_packet <= reg_wdata;
            16'h0118:begin                             
                o_tx_packet_body  <= reg_wdata[15:0]; //configured as 870B here
                o_tx_packet_tail  <= reg_wdata[15+32:32];
            end                        
            16'h0120:begin
                o_tx_mode         <= reg_wdata[3:0];  
                // REVIEW the tx_body is limited to 65536x870B = 54MB
                o_tx_body_num     <= reg_wdata[32+15:32];
            end
            //rx
            16'h0208:
                o_rx_base_addr    <= reg_wdata;  
            
          endcase
    end

//////////////////////////////////////////////////////////////////////////
//  soft_rst
//////////////////////////////////////////////////////////////////////////
    reg soft_rst_reg = 1'b0;
    reg [7:0] count = 8'd0; 

    always @ (posedge clk) begin
        if (i_reg_wen && i_reg_waddr == SOFT_R_REG )
            soft_rst_reg <= 1'b1;       
        else if (count==8'hff)
            soft_rst_reg <= 1'b0;
    end

    always @ (posedge clk) begin
        if (soft_rst_reg==1'b1)
            count <= count - 8'd1;
        else
            count <= 8'hfe;
    end

    assign o_soft_rst = soft_rst_reg;

//////////////////////////////////////////////////////////////////////////
//  TX and RX interrupt report
//////////////////////////////////////////////////////////////////////////
    wire tx_intr_rd;
    wire rx_intr_rd;
    wire loss_intr_rd;
    wire intr_rd;

    assign intr_rd = (i_reg_raddr == IRQ_REG) && i_reg_ren;
    
    assign tx_intr_rd = (i_reg_raddr == TX_IRQ_REG) && i_reg_ren;
    assign rx_intr_rd = (i_reg_raddr == RX_IRQ_REG) && i_reg_ren;
    assign loss_intr_rd = (i_reg_raddr == RX_LOSS_REG) && i_reg_ren;

    reg [63:0]  rd_reg = 'd0;
    reg [63:0]  rx_status;

    // TODO  Suppor more regs read
    always @ (posedge clk ) begin
        if (rst) begin
            rx_status <= 'h0;
            rd_reg <= 'h0;
        end else begin
            // if(tx_intr_rd)
            //     rd_reg <= 64'h1010;
            // else if (rx_intr_rd) 
            //     rd_reg <= rx_status;
            // else if (loss_intr_rd)    
            //     rd_reg <= {31'b0, i_sync_loss, 31'b0, i_link_loss};

            if (intr_rd)
                rd_reg <= rx_status;

            if (i_rx_interrupt)
                rx_status <= {4'd2, 28'h0, i_rx_frame_num, i_rx_frame_length};
            else if (i_tx_interrupt)
                 rx_status <= {4'd1, 28'd0, 16'h0000, 16'h5aa5};
            else if (i_loss_interrupt) 
                rx_status <= {4'd3, 32'h0, 29'h0, i_rx_fifo_status, i_sync_loss, i_link_loss};
        end
    end

   // assign o_irq = i_tx_interrupt | i_rx_interrupt | i_loss_interrupt;

    // always @(posedge clk) begin
    //     if (rst) begin
    //         o_irq_msg <= 'h0;
    //     end else begin
    //         if (i_rx_interrupt) begin
    //             o_irq_msg[63:60] <= 4'd1;
    //         end else if (i_loss_interrupt)
    //     end
    // end

    assign o_tx_irq = i_tx_interrupt;
    assign o_rx_irq = i_rx_interrupt;
    assign o_loss_irq = i_loss_interrupt;
    assign o_reg_rdata = rd_reg; 
// Review
/*
ila_mgt ila_mgt_i (
    .clk(clk),
    .probe0(i_reg_wen),
    .probe1(i_reg_wdata),
    .probe2(i_reg_waddr), 
    .probe3(i_reg_ren),
    .probe4(o_reg_rdata),
    .probe5(o_tx_total_packet),
    .probe6(o_tx_packet_body),
    .probe7(o_tx_packet_tail),
    .probe8(o_tx_body_num),
    .probe9(o_tx_mode),
    .probe10(o_rx_base_addr),
    .probe11(i_rx_total_packet),
    .probe12(i_rx_packet_body),
    .probe13(i_rx_packet_tail),
    .probe14(i_rx_body_num),
    .probe15(i_tx_interrupt),
    .probe16(o_tx_base_addr)

);
*/
    
endmodule

    

    




