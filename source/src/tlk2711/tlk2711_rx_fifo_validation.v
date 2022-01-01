///////////////////////////////////////////////////////////////////////////////
// Project: TLK2711
// Device: zu9eg
// Purpose: To validate the rd_data from rx FIFO
// Author: Chunjie Wang
// Reference:  
// Revision History:
//   Rev 1.0 - First created, chunjie, 2022-1-1
//   
// Email: 
///////////////////////////////////////////////////////////////////////////////

module tlk2711_rx_fifo_validation (
    input                   clk,
    input                   rst,
    input                   i_soft_rst,

    input                   i_valid,
    input  [63:0]           i_data,

    input                   i_check_ena,
    output                  o_check_error
);

reg         check_ena;
reg         check_error;
reg [63:0]  data_gen;

reg [63:0]  data;
reg         valid;
reg [7:0]   data_cnt;

always @(posedge clk) begin
    check_ena <= i_check_ena;
    data <= i_data;
    valid <= i_valid;
end

always @(posedge clk) begin
    if (rst | i_soft_rst) begin
        check_error <= 1'h0;
        data_gen <= 64'h0000000100020003;
        data_cnt <= 8'h0;
    end else begin
        if (valid) begin
            // In test mode, the received data length is 870 bytes, 
            // aligning to 109 64bit.
            if (data_cnt == 8'd108) begin
                data_cnt <= 8'd0;
                 data_gen <= 64'h0000000100020003;
            end else begin
                data_cnt <= data_cnt + 1'd1;
                data_gen <= data_gen + 64'h0004000400040004;
            end
            
            if (data != data_gen & data_cnt != 8'd108) begin
                check_error <= 1'b1;
            end else if (data[63:16] != data_gen[63:16] & data_cnt == 8'd108) begin
                check_error <= 1'b1;
            end else begin
                check_error <= 1'b0;
            end
        end else begin
            check_error <= 1'b0;
        end
    end
end

assign o_check_error = check_error;

ila_fifo_rx_validation  ila_fifo_rx_validation_inst (
    .clk(clk),
    .probe0(check_ena),
    .probe1(check_error),
    .probe2(data_gen),
    .probe3(data),
    .probe4(valid),
    .probe5(data_cnt)
);


endmodule