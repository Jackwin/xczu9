module tlk2711 (
    input logic         clk,
    input logic         rst,
    output logic [15:0] o_txd,

    input logic         i_start,
    input logic [1:0]   i_mode,
    input logic         i_stop,
    output logic        o_stop_ack,
    
    output logic        o_tkmsb,
    output logic        o_tklsb,
    output logic        o_loopen,
    output logic        o_prbsen,
    output logic        o_enable,
    output logic        o_lckrefn, // 1 -> track received data
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
    KCODE_s = 3'd3,
    PRBS_s = 3'd4
}current_mode, next_mode;

enum logic[1:0] {
    COMMA1_s = 2'd0,
    COMMA2_s = 2'd1,
    SOF_s = 2'd2,
    DATA_s = 2'd3
}packet;

logic       start;
logic       start_next;
logic       stop;

logic [1:0]     mode_sel;

always_comb begin
    start = i_start;
    mode_sel = i_mode;
    stop = i_stop;
    //o_stop_ack = (stop & (&data_cnt == 1) & current_mode == NORM_s)
               
end

always_ff @(posedge clk) begin
    start_next <= start;
end

always_ff @(posedge clk) begin
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
                    KCODE_MODE: next_mode = KCODE_s;
                endcase
            end
        end
        NORM_s: begin
            if (stop & (&data_cnt == 1)) begin // make sure all the data have been sent
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

logic           loopen_vio;
logic           prbsen_vio;
logic           enable_vio;
logic           lckrefn_vio;
logic           testen_vio;
logic           tklsb_vio;
logic           tkmsb_vio;
logic [15:0]    tx_data_vio;

logic [1:0]     cnt;
logic [4:0]     data_cnt;


always_ff @(posedge clk) begin
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
                lckrefn <= 1;
                testen <= 0;
                tklsb <= 0;
                tkmsb <= 0;
                cnt <= 0;
                data_cnt <= 0;
                o_stop_ack <= stop;
                tx_data[15:8] <= 'h0;
                tx_data[7:0] <= 'h0;
            end
            NORM_s: begin
                enable <= 1;
                lckrefn <= 1;
                loopen <= 1;
                o_stop_ack <= stop & (&data_cnt == 1);
                case(cnt)
                    COMMA1_s: begin
                        tkmsb <= 0; // K code
                        tklsb <= 1;
                        tx_data[7:0] <= K28_5;
                        tx_data[15:8] <= D5_6;
                        cnt <= cnt + 1;
                    end
                    COMMA2_s: begin
                        tkmsb <= 0; // K code
                        tklsb <= 1;
                        tx_data[7:0] <= K28_5;
                        tx_data[15:8] <= D5_6;
                        cnt <= cnt + 1;
                    end
                    SOF_s: begin
                        tkmsb <= 0; // K code
                        tklsb <= 1;
                        tx_data[7:0] <= K28_5;
                        tx_data[15:8] <= D11_5;
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
                lckrefn <= 1;
                tkmsb <= 0; // K code
                tklsb <= 1;
                tx_data[7:0] <= K28_5;
                tx_data[15:8] <= D5_6;
                o_stop_ack <= stop;
            end
            PRBS_s: begin
                enable <= enable_vio;
                loopen <= loopen_vio;
                lckrefn <= lckrefn_vio;
                testen <= testen_vio;
                tkmsb <= tkmsb_vio;
                tklsb <= tklsb_vio;
                tx_data <= tx_data_vio;
                o_stop_ack <= stop;
            end
            KCODE_s: begin
                enable <= 1;
                loopen <= 1;
                tkmsb <= 0; // K code
                tklsb <= 1;
                lckrefn <= 1;
                tx_data[7:0] <= K28_5;
                tx_data[15:8] <= D5_6;
                o_stop_ack <= stop;
            end
            default: begin
                enable <= 0;
            end
        endcase
    end
end

always_comb begin
    o_tkmsb = tkmsb;
    o_tklsb = tklsb;
    o_loopen = loopen;
    o_prbsen = prbsen;
    o_enable = enable;
    o_lckrefn = lckrefn;
    o_testen = testen;
    o_txd = tx_data;
end

ila_0 tlk2711b (
	.clk(clk), // input wire clk

	.probe0(o_stop_ack), // input wire [0:0]  probe0  
	.probe1(testen), // input wire [0:0]  probe1 
	.probe2(data_cnt), // input wire [15:0]  probe2
    .probe3(start_next),
    .probe4(tkmsb), // input wire [0:0]  probe4 
	.probe5(tklsb), // input wire [0:0]  probe5 
	.probe6(loopen), // input wire [0:0]  probe6 
	.probe7(prbsen), // input wire [0:0]  probe7 
	.probe8(enable), // input wire [0:0]  probe8 
	.probe9(lckrefn), // input wire [0:0]  probe9 
	.probe10(tx_data), // input wire [15:0]  probe10 
	.probe11(current_mode), // input wire [2:0]  probe11 
	.probe12(mode_sel), // input wire [1:0]  probe12 
	.probe13(start), // input wire ila_2711_rx_inst[0:0]  probe13 
	.probe14(stop) // input wire [0:0]  probe14 
	
);

ila_2711_rx ila_2711_rx_inst (
	.clk(rx_clk), // input wire clk
	.probe0(i_rklsb), // input wire [0:0]  probe0  
	.probe1(i_rkmsb), // input wire [0:0]  probe1 
	.probe2(i_rxd) // input wire [15:0]  probe2
);


vio_tlk2711_debug tlk2711_debug (
  .clk(clk),                // input wire clk
  .probe_out0(loopen_vio),  // output wire [0 : 0] probe_out0
  .probe_out1(prbsen_vio),  // output wire [0 : 0] probe_out1
  .probe_out2(enable_vio),  // output wire [0 : 0] probe_out2
  .probe_out3(lckrefn_vio),  // output wire [0 : 0] probe_out3
  .probe_out4(testen_vio),  // output wire [0 : 0] probe_out4
  .probe_out5(tklsb_vio),  // output wire [0 : 0] probe_out5
  .probe_out6(tkmsb_vio),  // output wire [0 : 0] probe_out6
  .probe_out7(tx_data_vio)  // output wire [15 : 0] probe_out7
);

endmodule
