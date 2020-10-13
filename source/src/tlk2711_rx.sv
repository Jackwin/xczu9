
module tlk2711_rx(

    input logic         clk,
    input logic         rst,
    input logic         i_rkmsb,
    input logic         i_rklsb,
    input logic [15:0]  i_rxd

);
localparam SP = 16'hc5bc;
localparam SF = 16'h5cfb;
localparam EF = 16'hFDFE;

enum logic[1:0] {
    IDLE_s = 2'd0,
    SYNC_s = 2'd1,
    DATA_s = 2'd2,
    END_s = 2'd3 
}cs, ns;

logic           rkmsb_r;
logic           rklsb_r;
logic [15:0]    rx_data_r;

always_ff @(posedge clk) begin
    rkmsb_r <= i_rkmsb;
    rklsb_r <= i_rklsb;
    rx_data_r <= i_rxd;
end

always_ff @(posedge clk) begin
    if (rst) begin
        cs <= IDLE_s
    end else begin
        cs <= ns;
    end
end

always_comb begin
    ns = cs;
    case(cs)
    IDLE_s: begin
        if (rx_data_r == SP & ~rkmsb_r & rklsb_r) begin
            ns = SYNC_s;
        end
    end
    SYNC_s: begin
        if (rx_data_r == SF & rkmsb_r & rklsb_r) begin // Tx should send sync code continuously
            ns = SYNC_s;
        end else if (rx_data_r == SP & rkmsb_r & rklsb_r) begin
            ns = DATA_s
        end else begin
            ns = IDLE_s;
        end
    end
    DATA_s: begin
        if (rkmsb_r | rklsb_r) begin
            ns = IDLE_s;
        end
    end
end

endmodule

