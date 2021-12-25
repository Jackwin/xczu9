
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
//   Rev 1.1 - Add ADDR_MASK and ADDR_BASE, 2021-10-5
// Email: 
////////////////////////////////////////////////////////////////////////////////

module reg_mgt 
#(  
    parameter DEBUG_ENA = "TRUE",     
    parameter ADDR_WIDTH = 32,
    parameter ADDR_MASK = 16'h00ff,
    parameter ADDR_BASE = 16'h0000
)
(  
    // PS logics
    input                       ps_clk,
    input                       ps_rst,
    input                       i_reg_wen,
    input [15:0]                i_reg_waddr,
    input [63:0]                i_reg_wdata,
    input                       i_reg_ren,
    input [15:0]                i_reg_raddr,
    output [63:0]               o_reg_rdata,

    // user logics
    input                       clk,
    input                       rst,
    output                      o_tx_irq,
    output                      o_rx_irq,
    output                      o_loss_irq,
  
    // TX port set
    //read data address from DDR to tx module
    output [ADDR_WIDTH-1:0]     o_tx_base_addr, 
    //total file packet length in byte
    output [31:0]               o_tx_total_length, 
    //body length in byte, 870B here for fixed value
    output [15:0]               o_tx_packet_body, 
    //tail length in byte
    output [15:0]               o_tx_packet_tail, 
    //body number, total_packet = packet_body*body_num + packet_tail
    output [23:0]               o_tx_body_num, 
    // 0--norm mode, 1--kcode mode, 2--test data
    output [2:0]                o_tx_mode,
    // 1--loopback enable
    output                      o_loopback_ena,
    // configured when all the above register is done and start the transfer 
    output reg                  o_tx_config_done,
    // inform cpu after the total packet transfer is finished
    input                       i_tx_interrupt, 
    // tlk2711 pre-emphasis
    output                      o_tx_pre,
    // the number of receied lines to trig the interrupt
    output [23:0]               o_line_num_per_intr,

    output [19:0]               o_backward_cycle_num,

    // tx interrupt pulse width
    output [15:0]               o_tx_intr_width,
    output [15:0]               o_rx_intr_width,
    output [15:0]               o_link_intr_width,

    //RX port set
    //write data address to DDR from rx module
    output [ADDR_WIDTH-1:0]     o_rx_base_addr, 
    output                      o_rx_fifo_rd,

    output reg                  o_rx_config_done,
    output                      o_link_loss_detect_ena,
    output                      o_sync_loss_detect_ena,
     output                     o_rx_check_ena,

    input                       i_rx_interrupt, //when asserted, the packet information is valid at the same time
    input  [15:0]               i_rx_frame_length,
    input  [23:0]               i_rx_frame_num, //870B here the same as tx configuration and no need to reported 
    
    input [6:0]                 i_rx_status,
    input [9:0]                 i_tx_status,
    input [3:0]                 i_rx_data_type,
    input                       i_rx_file_end_flag,
    input                       i_rx_checksum_flag,
    input [1:0]                 i_rx_channel_id,
   
    input                       i_loss_interrupt,
    input                       i_sync_loss,
    input                       i_link_loss,

    output                      o_soft_rst
    
    );

    localparam  TX_CFG_REG      = 16'h0008 + ADDR_BASE;
    localparam  RX_CFG_REG      = 16'h0010 + ADDR_BASE;

    localparam  TX_ADDR_REG     = 16'h0020 + ADDR_BASE;
    localparam  TX_LENGTH_REG   = 16'h0028 + ADDR_BASE;
    localparam  TX_PACKET_REG   = 16'h0030 + ADDR_BASE;
    localparam  TX_STATUS_REG   = 16'h0038 + ADDR_BASE;

    localparam  RX_ADDR_REG     = 16'h0040 + ADDR_BASE;
    localparam  RX_CTRL_REG     = 16'h0048 + ADDR_BASE;
    localparam  RX_STATUS_REG   = 16'h0050 + ADDR_BASE;
    localparam  RX_CTRL_REG2    = 16'h0058 + ADDR_BASE;

    localparam  RX_IRQ_REG      = 16'h0060 + ADDR_BASE;
    localparam  IRQ_CTRL_REG    = 16'h0068 + ADDR_BASE;

    localparam  SOFT_R_REG      = 16'h0070 + ADDR_BASE;

    localparam  TX_IRQ_REG      = 16'h0078 + ADDR_BASE;

    // localparam  TX_ADDR_REG     = 16'h0010 + ADDR_BASE;
    // localparam  TX_LENGTH_REG   = 16'h0018 + ADDR_BASE;
    // localparam  TX_PACKET_REG   = 16'h0020 + ADDR_BASE;
    // localparam  TX_STATUS_REG   = 16'h0028 + ADDR_BASE;
    // localparam  TX_CFG_REG      = 16'h0030 + ADDR_BASE;

    // localparam  RX_ADDR_REG     = 16'h0040 + ADDR_BASE;
    // localparam  RX_CTRL_REG     = 16'h0048 + ADDR_BASE;
    // localparam  RX_STATUS_REG   = 16'h0050 + ADDR_BASE;
    // localparam  RX_CFG_REG      = 16'h0058 + ADDR_BASE;

    // localparam  IRQ_REG         = 16'h0060 + ADDR_BASE;

    // localparam  SOFT_R_REG      = 16'h0080 + ADDR_BASE;

// ----------------------------------------------------------------------
// Sync logics
// ----------------------------------------------------------------------
reg                     ps_reg_wen_1r;
reg [15:0]              ps_reg_waddr_1r;
reg [63:0]              ps_reg_wdata_1r;
reg                     ps_reg_ren_1r;
reg [15:0]              ps_reg_raddr_1r;
reg [63:0]              ps_reg_rdata;

reg                     usr_reg_wen;
reg [15:0]              usr_reg_waddr;
reg [63:0]              usr_reg_wdata;
reg                     usr_reg_ren;
reg [15:0]              usr_reg_raddr;
reg [63:0]              usr_reg_rdata_1d;

wire                    reg_sel;
reg                     reg_sel_1d;
reg                     reg_sel_2d;

wire                    reg_rd_sel;
reg                     reg_rd_sel_1d;
reg                     reg_rd_sel_2d;

wire [7:0]              auto_intr_times;
wire [27:0]             auto_intr_gap; // unit of 10ns
reg                     auto_intr;
wire                    auto_intr_start;
wire [7:0]              auto_intr_width;

assign reg_sel = ((i_reg_waddr & ~ADDR_MASK) == ADDR_BASE) ? 1'b1 : 1'b0;
assign reg_rd_sel = ((i_reg_raddr & ~ADDR_MASK) == ADDR_BASE) ? 1'b1 : 1'b0;

always @(posedge clk) begin
    ps_reg_wen_1r <= i_reg_wen;
    ps_reg_waddr_1r <= i_reg_waddr;
    ps_reg_wdata_1r <= i_reg_wdata;
    ps_reg_ren_1r <= i_reg_ren;
    ps_reg_raddr_1r <= i_reg_raddr;
    
    usr_reg_wen <= ps_reg_wen_1r;
    usr_reg_waddr <= ps_reg_waddr_1r;
    usr_reg_wdata <= ps_reg_wdata_1r;
    usr_reg_ren <= ps_reg_ren_1r;
    usr_reg_raddr <= ps_reg_raddr_1r;

    reg_sel_1d <= reg_sel;
    reg_sel_2d <= reg_sel_1d;

    reg_rd_sel_1d <= reg_rd_sel;
    reg_rd_sel_2d <= reg_rd_sel_1d;

end

always @(posedge ps_clk) begin
    usr_reg_rdata_1d <= reg_rdata;
    ps_reg_rdata <= usr_reg_rdata_1d;
end

assign o_reg_rdata = ps_reg_rdata; 

//////////////////////////////////////////////////////////////////////////
//  TX and RX register configuration
//////////////////////////////////////////////////////////////////////////

reg                 reg_wen;
reg [63:0]          reg_wdata;
reg [15:0]          reg_waddr;
reg [63:0]          reg_rdata;
reg [63:0]          rx_intr_status;
reg [63:0]          tx_intr_status;
reg [63:0]          tx_base_addr_reg;
reg [63:0]          tx_length_reg;
reg [63:0]          tx_packet_reg;
reg [63:0]          rx_base_addr_reg;
reg [63:0]          rx_ctrl_reg;
reg [63:0]          rx_ctrl_reg2;

always@(posedge clk)begin
    if(rst)
        reg_wen <= 0;
    else begin
        if(usr_reg_wen & reg_sel_2d) begin
            reg_waddr <= usr_reg_waddr;
            reg_wdata <= usr_reg_wdata;
        end
        reg_wen <= usr_reg_wen & reg_sel_2d;
    end        
end

always@(posedge clk) begin
    // for tx config done
    if( reg_wen && ( reg_waddr == TX_CFG_REG ) ) //&& (reg_wdata[3:0] == 4'h5a)
        o_tx_config_done <=  1'b1;
    else 
        o_tx_config_done <= 1'b0;

    if( reg_wen && ( reg_waddr == RX_CFG_REG )) // for rx config done
        o_rx_config_done <=  1'b1;
    else 
        o_rx_config_done <= 1'b0;
end

assign o_tx_base_addr = tx_base_addr_reg[ADDR_WIDTH-1:0];
assign o_backward_cycle_num = tx_base_addr_reg[19+ADDR_WIDTH:ADDR_WIDTH];
assign o_tx_total_length = tx_length_reg[31:0];
assign o_tx_packet_body = tx_packet_reg[15:0];
assign o_tx_body_num = tx_packet_reg[8+16+15:16];
assign o_tx_packet_tail = tx_packet_reg[15+40:40];
assign o_tx_pre = tx_packet_reg[59];
assign o_tx_mode = tx_packet_reg[62:60];
assign o_loopback_ena = tx_packet_reg[63];

assign o_rx_base_addr = rx_base_addr_reg[ADDR_WIDTH-1:0];
assign o_rx_fifo_rd = rx_ctrl_reg[0];
assign o_link_loss_detect_ena = rx_ctrl_reg[1];
assign o_sync_loss_detect_ena = rx_ctrl_reg[2];
assign auto_intr_start = rx_ctrl_reg[3];
assign auto_intr_times = rx_ctrl_reg[11:4];
assign auto_intr_gap = rx_ctrl_reg[39:12];
assign auto_intr_width = rx_ctrl_reg[47:40];

assign o_line_num_per_intr = rx_ctrl_reg2[23:0];
assign o_rx_check_ena = rx_ctrl_reg2[24];

//////////////////////////////////////////////////////////////////////////
//  IRQ control configuration
/////////////////////////////////////////////////////////////////////////

reg [63:0]          irq_ctrl_reg = 64'h0;

reg [15:0]          tx_intr_width;
reg [15:0]          rx_intr_width;
reg [15:0]          link_intr_width;

always @(posedge clk) begin
    case(irq_ctrl_reg[63:60])
    4'd1: tx_intr_width <= irq_ctrl_reg[15:0];
    4'd2: rx_intr_width <= irq_ctrl_reg[15:0];
    4'd3: link_intr_width <= irq_ctrl_reg[15:0];
    default: begin
        tx_intr_width <= 16'd16;
        rx_intr_width <= 16'd16;
        link_intr_width <= 16'd16;
    end
    endcase
end

assign o_tx_intr_width = tx_intr_width;
assign o_rx_intr_width = rx_intr_width;
assign o_link_intr_width = link_intr_width;

always@(posedge clk) begin
    if( reg_wen ) begin
        case(reg_waddr)
        //tx
        TX_ADDR_REG: tx_base_addr_reg <= reg_wdata;
        TX_LENGTH_REG: tx_length_reg <= reg_wdata;
        TX_PACKET_REG: begin
            tx_packet_reg <= reg_wdata;
            $display("%t (reg_mgt.v)TX_PACKET_REG: frame_length is %d", $time, reg_wdata[15:0]);
            $display("%t (reg_mgt.v)TX_PACKET_REG: body_num is %d", $time, reg_wdata[39:16]);
            $display("%t (reg_mgt.v)TX_PACKET_REG: tail_length is %d", $time, reg_wdata[55:40]);
            $display("%t (reg_mgt.v)TX_PACKET_REG: pre-set is %d", $time, reg_wdata[59]);
            $display("%t (reg_mgt.v)TX_PACKET_REG: mode is %d", $time, reg_wdata[62:60]);
            $display("%t (reg_mgt.v)TX_PACKET_REG: loop-back is %d", $time, reg_wdata[63]);
        end 
        RX_ADDR_REG: rx_base_addr_reg <= reg_wdata;
        RX_CTRL_REG: rx_ctrl_reg <= reg_wdata;
        RX_CTRL_REG2: begin
            rx_ctrl_reg2 <= reg_wdata;
            $display("%t RX_CTRL_REG2: line_num_per_intr is %d", $time, reg_wdata[23:0]);
        end
        IRQ_CTRL_REG: begin
            irq_ctrl_reg <= reg_wdata;
            $display("%t IRQ_CTRL_REG: interrupt pulse width is %d", $time, reg_wdata[15:0]);
        end
        default;
        endcase
    end
end

always @(posedge clk) begin
    if (usr_reg_ren & reg_rd_sel_2d) begin
        case(usr_reg_raddr)
            RX_STATUS_REG: begin
                reg_rdata[6:0] <= i_rx_status;
                reg_rdata[59:7] <= 'h0;
                reg_rdata[63:60] <= 'ha;
            end
            TX_STATUS_REG: begin
                reg_rdata[9:0] <= i_tx_status;
                reg_rdata[59:10] <= 'h0;
                reg_rdata[63:60] <= 'h9;
            end
            RX_IRQ_REG: reg_rdata <= rx_intr_status;
            TX_IRQ_REG: reg_rdata <= tx_intr_status;
            TX_ADDR_REG: reg_rdata <= tx_base_addr_reg;
            TX_LENGTH_REG: reg_rdata <= tx_length_reg;
            TX_PACKET_REG: reg_rdata <= tx_packet_reg;
            RX_ADDR_REG: reg_rdata <= rx_base_addr_reg;
            RX_CTRL_REG: reg_rdata <= rx_ctrl_reg;
            default: begin
                reg_rdata <= 'h0;
            end
        endcase
    end else begin
        reg_rdata <= 'h0;
    end
end

//////////////////////////////////////////////////////////////////////////
//  soft_rst
//////////////////////////////////////////////////////////////////////////
reg soft_rst_reg = 1'b0;
reg [7:0] count = 8'd0;

always @ (posedge clk) begin
    if (usr_reg_wen && usr_reg_waddr == SOFT_R_REG & reg_sel_2d)
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
//  Gen the interrupt automatically
//////////////////////////////////////////////////////////////////////////
reg         auto_intr_gen;
reg         auto_intr_start_r;
reg [28:0]  auto_intr_counter;
reg         auto_intr_signal;
reg         auto_intr_signal_r;
reg [7:0]   auto_intr_signal_count;

always @(posedge clk) begin
    auto_intr_start_r <= auto_intr_start;
end

always @(posedge clk) begin
    auto_intr_signal_r <= auto_intr_signal;
end

always @(posedge clk) begin
    if (rst) begin
        auto_intr_gen <= 1'b0;
        auto_intr_counter <= 'h0;
        auto_intr_signal <= 1'b0;
    end else begin
        if (auto_intr_start_r == 1'b0 & auto_intr_start) begin
            auto_intr_gen <= 1'b1;
        end else if (auto_intr_signal_count == auto_intr_times - 1 
            & (auto_intr_signal_r & ~auto_intr_signal)) begin
            auto_intr_gen <= 1'b0;
        end

        if (auto_intr_gen) begin
            auto_intr_counter <= auto_intr_counter + 1'b1;
            if (auto_intr_counter == auto_intr_gap -1) begin
                auto_intr_signal <= 1'b1;
            end else if (auto_intr_counter == auto_intr_gap + auto_intr_width -1) begin
                auto_intr_signal <= 1'b0;
                auto_intr_counter <= 'h0;
            end
        end else begin
            auto_intr_signal <= 1'b0;
            auto_intr_counter <= 'h0;
        end
    end
end

// Count the number of intr
always @(posedge clk) begin
    if (rst) begin
        auto_intr_signal_count <= 'h0;
    end else begin
        if (auto_intr_signal_r & ~auto_intr_signal) begin
            auto_intr_signal_count <= auto_intr_signal_count + 1'b1;
            // if (auto_intr_signal_count == auto_intr_times - 1) begin
            //     auto_intr_signal_count <= 'h0;
            // end
        end else if (auto_intr_start_r == 1'b0 & auto_intr_start) begin
            auto_intr_signal_count <= 'h0;
        end
    end
end

//////////////////////////////////////////////////////////////////////////
//  TX and RX interrupt report
//////////////////////////////////////////////////////////////////////////

reg [15:0]  tx_intr_cnt;
reg [11:0]  rx_intr_cnt;
reg         tx_intr_r1;
reg         tx_intr_r2;
reg         rx_intr_r1;
reg         rx_intr_r2;

always @(posedge clk) begin
    tx_intr_r1 <= i_tx_interrupt;
    tx_intr_r2 <= tx_intr_r1;

    rx_intr_r1 <= i_rx_interrupt;
    rx_intr_r2 <= rx_intr_r1;
end

always @(posedge clk) begin
    if (rst | soft_rst_reg) begin
        tx_intr_cnt <= 'h0;
        rx_intr_cnt <= 'h0;
    end else begin
        if (~tx_intr_r1 & i_tx_interrupt) begin
            tx_intr_cnt <= tx_intr_cnt + 1'd1;
        end

        if (~rx_intr_r1 & i_rx_interrupt) begin
            rx_intr_cnt <= rx_intr_cnt + 1'd1;
        end
    end
end
// TODO  Suppor more regs read
always @ (posedge clk ) begin
    if (rst) begin
        rx_intr_status <= 'h0;
    end else begin
        if (rx_intr_r2)
            // rx_intr_status <= {4'd2, 18'h0,i_rx_data_type, i_rx_file_end_flag,
            //                     i_rx_checksum_flag, i_rx_frame_num, i_rx_frame_length};
            rx_intr_status <= {4'd2, rx_intr_cnt, i_rx_frame_length, i_rx_data_type, 
                                i_rx_channel_id,i_rx_file_end_flag, 
                                i_rx_checksum_flag, i_rx_frame_num};
        else if (tx_intr_r2)
            tx_intr_status <= {4'd1, 28'd0, tx_intr_cnt, 16'h5aa5};
        else if (i_loss_interrupt) 
            rx_intr_status <= {4'd3, 32'h0, 20'h0, i_rx_status, i_sync_loss, i_link_loss};
        else if(auto_intr_signal) begin
            rx_intr_status <= {4'd4, 28'd0, 8'h0, auto_intr_signal_count, 16'hffff};
        end
    end
end

assign o_tx_irq = i_tx_interrupt;
assign o_rx_irq = i_rx_interrupt | auto_intr_signal;
assign o_loss_irq = i_loss_interrupt;
if (DEBUG_ENA == "TRUE" || DEBUG_ENA == "true") 
    ila_mgt ila_mgt_i (
    .clk(clk),
    .probe0(usr_reg_wen),
    .probe1(usr_reg_wdata),
    .probe2(usr_reg_waddr), 
    .probe3(usr_reg_ren),
    .probe4(o_reg_rdata),
    .probe5(o_tx_total_length),
    .probe6(o_tx_packet_body),
    .probe7(o_tx_packet_tail),
    .probe8(o_tx_body_num),
    .probe9(o_tx_mode),
    .probe10(o_rx_base_addr),
    .probe11(rx_intr_status),
    .probe12(usr_reg_raddr),
    .probe13(i_rx_status),
    .probe14(i_tx_status),
    .probe15(i_tx_interrupt),
    .probe16(o_tx_base_addr),
    .probe17(i_link_loss),
    .probe18(i_sync_loss),
    .probe19(reg_rd_sel_2d),
    .probe20(reg_rdata),
    .probe21(usr_reg_rdata_1d),
    .probe22(reg_rd_sel_1d),
    .probe23(reg_rd_sel),
    .probe24(i_rx_interrupt),
    .probe25(o_link_loss_detect_ena),
    .probe26(o_sync_loss_detect_ena),
    .probe27(auto_intr_start),
    .probe28(auto_intr_times),
    .probe29(auto_intr_gap),
    .probe30(o_rx_intr_width),
    .probe31(irq_ctrl_reg),
    .probe32(auto_intr_signal),
    .probe33(tx_intr_status),
    .probe34(auto_intr_signal_count)


);
    



    
endmodule

    

    




