///////////////////////////////////////////////////////////////////////////////
// Project: TLK2711
// Device: zu9eg
// Purpose: tlk2711 rx data validation in tx test-mode, aiming at the link check
// Author: Chunjie Wang
// Reference:  
// Revision History:
//   Rev 1.1 - Support CDC, chunjie, 2022-1-1
//   Rev 1.0 - First created, chunjie, 2021-12-29
//   
// Email: 
///////////////////////////////////////////////////////////////////////////////

module tlk2711_rx_validation # (
    parameter DATAWIDTH = 16
)
(
    input                   clk,
    input                   rst,
    input                   i_soft_rst,
    input                   i_2711_rkmsb,
    input                   i_2711_rklsb,
    input  [15:0]           i_2711_rxd,

    input                   i_check_ena,
    output                  o_check_error,
    output [3:0]            o_error_status
);

//frame start
localparam K27_7 = 8'hFB; 
localparam K28_2 = 8'h5C;
//frame end
localparam K30_7 = 8'hFE;
localparam K29_7 = 8'hFD;
//sync code
localparam K28_5 = 8'hBC;
localparam D5_6  = 8'hC5;

//frame header
localparam HEAD_0 = 16'hEB90;
localparam HEAD_1 = 16'hE116;


localparam TEST_IDLE_s = 4'd0;
localparam TEST_SYNC_s = 4'd1;
localparam TEST_SOF_s = 4'd2;
localparam TEST_HOF0_s = 4'd3; // head of frame
localparam TEST_HOF1_s = 4'd4; // head of frame
localparam TEST_FILEEND_s = 4'd5;
localparam TEST_FRAME_CNT_s = 4'd6;
localparam TEST_LENGTH_s = 4'd7;
localparam TEST_DATA_s = 4'd8;
localparam TEST_CHECKSUM_s = 4'd9;
localparam TEST_EOF_s = 4'd10;
localparam TEST_BACKWARD_s = 4'd11;
localparam TEST_END_s = 4'd12;

reg [3:0]   cs, ns;
reg [3:0]   error_status = 'h0;
reg         check_error = 1'b0;

reg [15:0]  tlk2711_rxd;

reg [15:0]  last_line_num;

reg [15:0]  data_gen;
reg [15:0]  backward_cnt;
reg [15:0]  checksum = 'h0;
reg [15:0]  checksum_1r;

reg         tlk2711_rklsb;
reg         tlk2711_rkmsb;

reg         check_ena;
reg [15:0]  data_cnt;
reg [15:0]  data_length;


assign o_check_error = check_error;
assign o_error_status = error_status;

always @(posedge clk) begin
    check_ena <= i_check_ena;
end

always @(posedge clk) begin
    tlk2711_rxd <= i_2711_rxd;
    tlk2711_rklsb <= i_2711_rklsb;
    tlk2711_rkmsb <= i_2711_rkmsb;
 end


always @(posedge clk) begin
    if (rst | i_soft_rst) begin
        cs <= TEST_IDLE_s;
    end else begin
        cs <= ns;
    end
end

always @(*) begin
    if (check_ena) begin
        ns = cs;
        case(cs) 
        TEST_IDLE_s: begin
            if (~tlk2711_rkmsb & tlk2711_rklsb & (tlk2711_rxd == {D5_6, K28_5})) begin
                ns = TEST_SYNC_s;
            end
        end
        TEST_SYNC_s: begin
            if (i_2711_rkmsb & i_2711_rklsb & (i_2711_rxd == {K28_2, K27_7})) begin
                ns = TEST_SOF_s;
            end
        end
        TEST_SOF_s: begin
            ns = TEST_HOF0_s;

        end
        TEST_HOF0_s: begin
            ns = TEST_HOF1_s;
        end

        TEST_HOF1_s: begin
            ns = TEST_FILEEND_s;
        end
        TEST_FILEEND_s: begin
            ns = TEST_FRAME_CNT_s;
        end
        TEST_FRAME_CNT_s: begin
            ns = TEST_LENGTH_s;
        end
        TEST_LENGTH_s: begin
            ns = TEST_DATA_s;
        end
        TEST_DATA_s: begin
            if (data_cnt == data_length[15:1] - 1'd1)
            ns = TEST_CHECKSUM_s;
        end

        TEST_CHECKSUM_s: begin
            ns = TEST_EOF_s;
        end

        TEST_EOF_s: begin
            ns = TEST_BACKWARD_s;
        end

        TEST_BACKWARD_s: begin
            // if (backward_cnt == 'd256) begin
            //     ns = TEST_SYNC_s;
            // end
            ns = TEST_IDLE_s;
        end
        default: begin
            ns = TEST_IDLE_s;
        end
        endcase
    end else begin
        ns = TEST_IDLE_s;
    end

end

always @(posedge clk) begin
    if (rst | i_soft_rst) begin
        error_status <= 'h0;
        check_error <= 'h0;
        last_line_num <= 'hFFFF;
        data_gen <= 'h0;
        backward_cnt <= 'h0;
        data_cnt <= 'h0;
        data_length <= 'h0;
    end else begin
        data_gen <= 'h0;
        backward_cnt <= 'h0;
        check_error <= 1'b0;
        error_status <= 'h0;
        data_cnt <= 'h0;
        if(check_ena) begin
            case(cs)
            TEST_IDLE_s: begin
                if (~tlk2711_rkmsb & tlk2711_rklsb & (tlk2711_rxd == {D5_6, K28_5})) begin
                    check_error <= 1'b0;
                    error_status <= 'h0;
                end else begin
                    check_error <= 1'b1;
                    error_status <= 'h1;
                end
            end

            TEST_SYNC_s: begin
                if (~tlk2711_rkmsb & tlk2711_rklsb & (tlk2711_rxd == {D5_6, K28_5})) begin
                    check_error <= 1'b0;
                    error_status <= 'h0;
                end else begin
                    check_error <= 1'b1;
                    error_status <= 'h1;
                end
            end
    
            TEST_SOF_s: begin
                if (tlk2711_rxd != {K28_2, K27_7}) begin
                    check_error <= 1'b1;
                    error_status <= 'h2;
                end

            end
            TEST_HOF0_s: begin
                if (tlk2711_rxd != HEAD_0) begin
                    check_error <= 1'b1;
                    error_status <= 'h3;
                end
            end
            TEST_HOF1_s: begin
                if (tlk2711_rxd != HEAD_1) begin
                    check_error <= 1'b1;
                    error_status <= 'h4;
                end
            end

            TEST_FILEEND_s: begin
                if (tlk2711_rxd != 16'h8101) begin
                    check_error <= 1'b1;
                    error_status <= 'h5;
                end
            end
            TEST_FRAME_CNT_s: begin
                last_line_num <= tlk2711_rxd;
                // if (last_line_num == 'h0) begin
                //     if (tlk2711_rxd != 'h0) begin
                //         check_error <= 1'b1;
                //         error_status <= 'h6;
                //     end
                // end else begin
                if (last_line_num != tlk2711_rxd - 1'd1) begin
                    //if (tlk2711_rxd != 'h0) begin
                    check_error <= 1'b1;
                    error_status <= 'h6;
                    //end
                end
                // end
            end
            TEST_LENGTH_s: begin
                data_length <= tlk2711_rxd;
                // if (tlk2711_rxd != 16'h366) begin
                //     check_error <= 1'b1;
                //     error_status <= 'h7;
                // end
            end
            TEST_DATA_s: begin
                if (tlk2711_rxd != data_gen) begin
                    check_error <= 1'b1;
                    error_status <= 'h8;
                end else begin
                    data_gen <= data_gen + 1'd1;
                end
                data_cnt <= data_cnt + 1'd1;
            end

            TEST_CHECKSUM_s: begin
                if (tlk2711_rxd != checksum_1r) begin
                    check_error <= 1'b1;
                    error_status <= 'h9;
                end
            end

            TEST_EOF_s: begin
                if (tlk2711_rxd != {K29_7, K30_7}) begin
                    check_error <= 1'b1;
                    error_status <= 'ha;
                end
            end

            TEST_BACKWARD_s: begin
                backward_cnt <= backward_cnt + 1'd1;
            end
            default: begin
                check_error <= 1'b0;
                error_status <= 'h0;
            end
            endcase
        end else begin
            check_error <= 1'b0;
            error_status <= 'h0;
            last_line_num <= 'hffff;
        end
    end
end

 always @(posedge clk) begin
    if (rst | i_soft_rst) begin
        checksum <= 'h0; 
        
    end else begin
        case(cs)
        TEST_IDLE_s, TEST_SYNC_s, TEST_EOF_s, TEST_BACKWARD_s, TEST_END_s: begin
            checksum <= 'h0;
        end
        TEST_HOF1_s, TEST_FILEEND_s, TEST_FRAME_CNT_s, TEST_LENGTH_s, TEST_DATA_s: begin
            checksum <= checksum + i_2711_rxd;
        end
        default: checksum <= 'h0;
        endcase
    end
end

always @(posedge clk) begin
    checksum_1r <= checksum;
end

// ila_rx_validation ila_rx_validation_inst (
//     .clk(clk),

//     .probe0(cs),
//     .probe1(check_error),
//     .probe2(tlk2711_rklsb),
//     .probe3(tlk2711_rxd),
//     .probe4(last_line_num),
//     .probe5(checksum_1r),
//     .probe6(data_gen),
//     .probe7(tlk2711_rkmsb),
//     .probe8(check_ena),
//     .probe9(error_status)
// );

endmodule