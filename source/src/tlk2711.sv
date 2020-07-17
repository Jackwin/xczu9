module tlk2711 (
    input logic         tx_clk,
    input logic         rst,
    output logic [15:0] o_txd,
    
    output logic        o_tkmsb,
    output logic        o_tklsb,
    output logic        o_loopen,
    output logic        o_prbsen,
    output logic        o_enable,
    output logic        o_lckrefn,
    output logic        o_testen,

    input logic         rx_clk,
    input logic         i_rkmsb,
    input logic         i_rklsb,
    input logic [15:0]  i_rxd
);

localparam NORM_MODE = 2'd0;
localparam LOOPBACK_MODE = 2'd1;
localparam KCODE_MODE = 2'd2;
localparam PRSB_MODE = 2'd3;

localparam K28_5 = 8'b1011_1100;
localparam D5_6 = 8'b11000101; // 110_00101
localparam D11_5 = 8'b1010_1011; //101_01011

enum logic[2:0] {
    IDLE_s = 3'd0,
    NORM_s = 3'd1,
    LOOP_s = 3'd2,
    PRBS_s = 3'd3,
    KCODE_s = 3'd4,
    END_s = 3'd5
}mode;

enum logic[1:0] {
    COMMA1_s = 2'd0,
    COMMA2_s = 2'd1,
    SOF_s = 2'd2,
    DATA_s = 2'd3
}packet;

logic       start;
logic       start_next;
logic       stop;

mode current_mode, next_mode;

logic [1:0]     mode_sel;

always_ff @(posedge tx_clk) begin
    start_next <= start;
end

always_ff @(posedge tx_clk) begin
    if (rst) begin
        current_mode <= IDLE_s;
    end else begin
        current_mode <= next_mode;
    end
end

always_comb begin
    next_mode = current_mode;

    case(current_mode)
        IDLE_s: begin
            if (~start_next & start) begin
                case(mode_sel)
                    NORM_MODE: next_mode = NORM_s;
                    LOOPBACK_MODE: next_mode = LOOP_s;
                    PRSB_MODE: next_mode = PRBS_s;
                    KCODE_MODE: next_mode = KCODE_MODE;
                endcase
            end
        end
        NORM_s: begin
            if (stop) begin
                next_mode = IDLE_s;
            end
        end
        LOOP_s: begin
            if (stop) begin
                next_mode = IDLE_s;
            end
        end
        KCODE_s: begin
            if (stop) begin
                next_mode = IDLE_s;
            end
        end
    endcase
end

logic           loopen;
logic           prbsen;
logic           enable;
logic           lckrefn;
logic           testen;
logic           tklsb;
logic           tkmsb;
logic [15:0]    tx_data;

logic [1:0]     cnt;
logic [4:0]     data_cnt;


always_ff @(posedge tx_clk) begin
    if (rst) begin
        loopen <= 0;
        prbsen <= 0;
        enable <= 0;
        lckrefn <= 0;
        testen <= 0;
        tklsb <= 0;
        tkmsb <= 0;
        cnt <= 0;
    end else begin
        case(current_mode)
            IDLE_s: begin
                loopen <= 0;
                prbsen <= 0;
                enable <= 0;
                lckrefn <= 0;
                testen <= 0;
                tklsb <= 0;
                tkmsb <= 0;
                cnt <= 0;
                data_cnt <= 0;
            end
            NORM_s: begin
                enable <= 1;
                
                case(cnt)
                    COMMA1_s: begin
                        tkmsb <= 1; // K code
                        tklsb <= 0;
                        tx_data[15:8] <= K28_5;
                        tx_data[7:0] <= D5_6;
                        cnt <= cnt + 1;
                    end
                    COMMA2_s: begin
                        tkmsb <= 1; // K code
                        tklsb <= 0;
                        tx_data[15:8] <= K28_5;
                        tx_data[7:0] <= D5_6;
                        cnt <= cnt + 1;
                    end
                    SOF_s: begin
                        tkmsb <= 1; // K code
                        tklsb <= 0;
                        tx_data[15:8] <= K28_5;
                        tx_data[7:0] <= D11_5;
                        cnt <= cnt + 1;
                    end
                    DATA_s: begin
                        data_cnt <= data_cnt + 1;
                        tx_data[15:8] <= {3'h0, data_cnt};
                        tx_data[7:0] <= {3'h0, data_cnt};
                        tkmsb <= 0;
                        tklsb <= 0;
                        if (&data_cnt == 1) cnt <= 0;
                    end
                    default: begin
                        cnt <= 0;
                    end
                endcase
            end
            LOOP_s: begin
                enable <= 1;
                loopen <= 1;
                tkmsb <= 1; // K code
                tklsb <= 0;
                tx_data[15:8] <= K28_5;
                tx_data[7:0] <= D5_6;
            end
            KCODE_s: begin
                enable <= 1;
                tkmsb <= 1; // K code
                tklsb <= 0;
                tx_data[15:8] <= K28_5;
                tx_data[7:0] <= D5_6;
            end
            default: begin
                enable <= 0;
            end
        endcase
    end
end





endmodule
