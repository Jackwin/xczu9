///////////////////////////////////////////////////////////////////////////////
// Project: TLK2711
// Device: zu9eg
// Purpose: To validate the tx_data from tx FIFO
// Author: Chunjie Wang
// Reference:  
// Revision History:
//   Rev 1.0 - First created, chunjie, 2022-1-3
//   
// Email: 
///////////////////////////////////////////////////////////////////////////////

module tlk2711_tx_validation # (
    parameter DEBUG_ENA = "TRUE"
    )(
    input                   clk,
    input                   rst,
    input                   i_soft_rst,

    input                   i_valid,
    input  [63:0]           i_data,

    input                   i_check_ena,
    input                   i_tx_start,
    input [2:0]             i_tx_mode,
    output                  o_check_error
);

reg         check_ena;
reg         check_error;
reg [15:0]  data_gen;

reg [15:0]  data;
reg         valid;
reg [15:0]  data_cnt;
reg [15:0]  frame_length;

reg         tx_start_r;
reg         tx_start_p;

always @(posedge clk) begin
    tx_start_r <= i_tx_start;
    tx_start_p <= ~tx_start_r & i_tx_start;
end

always @(posedge clk) begin
    check_ena <= i_check_ena;
    data <= i_data;
    valid <= i_valid;
end

always @(posedge clk) begin
    if (rst | i_soft_rst) begin
        frame_length <= 16'd108;
    end else begin
        if (tx_start_p & i_tx_mode == 3'd3) begin
            frame_length <= 16'd5376; // 10752/2=5376
        end else begin
            frame_length <= 16'd434; // 870/2= 435
        end
    end
end

always @(posedge clk) begin
    if (rst | i_soft_rst) begin
        check_error <= 1'h0;
        data_gen <= 64'h0001;
        data_cnt <= 8'h0;
    end else begin
        if(check_ena) begin
            if (valid) begin
                // In test mode, the received data length is 870 bytes, 
                // aligning to 109 64bit.
                if (data_cnt == frame_length) begin
                    data_cnt <= 8'd0;
                    data_gen <= 16'h0001;
                end else begin
                    data_cnt <= data_cnt + 1'd1;
                    data_gen <= data_gen + 16'h0202;
                end
                
                if (data != data_gen & data_cnt != frame_length) begin
                    check_error <= 1'b1;
                end else begin
                    check_error <= 1'b0;
                end
            end else begin
                check_error <= 1'b0;
            end
        end else begin
            data_cnt <= 8'd0;
            data_gen <= 16'h0001;
            check_error <= 1'b0;
        end
    end
end

assign o_check_error = check_error;
if (DEBUG_ENA == "TRUE" || DEBUG_ENA == "true") 
    ila_fifo_tx_validation  ila_fifo_tx_validation_inst (
        .clk(clk),
        .probe0(check_ena),
        .probe1(check_error),
        .probe2(data_gen),
        .probe3(data),
        .probe4(valid),
        .probe5(data_cnt)
    );


endmodule