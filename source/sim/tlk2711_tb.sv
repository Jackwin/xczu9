module tlk2711_tb();

logic   clk;
logic   rst;

initial begin
    clk = 0;
    forever begin
        # 2.5 clk = ~clk;
    end
end
initial begin
    rst = 1;
    #100;
    rst = 0;
end
logic  [15:0]   tlk2711b_txd;
logic           tlk2711b_loopen;
logic           tlk2711b_gtx_clk;
logic           tlk2711b_tkmsb;
logic           tlk2711b_prbsen;
logic           tlk2711b_enable;
logic           tlk2711b_lckrefn;
logic           tlk2711b_tklsb;
logic [15:0]    tlk2711b_rxd;
logic           tlk2711b_rklsb;
logic           tlk2711b_rx_clk;
logic           tlk2711b_testen;
logic           tlk2711b_rkmsb;

logic           tlk2711b_start;
logic [1:0]     tlk2711b_mode;
logic           tlk2711b_stop;
logic           tlk2711b_stop_ack;

initial begin
    tlk2711b_start = 0;
    tlk2711b_mode = 0;
    tlk2711b_stop = 0;

    #300;
    @(posedge clk);
    tlk2711b_start <= 1;
    tlk2711b_mode <= 0;
    @(posedge clk);
    tlk2711b_start <= 0;

    #400;
    @(posedge clk);
    tlk2711b_stop <= 1;
    wait(tlk2711b_stop_ack);
    @(posedge clk);
    tlk2711b_stop <= 0;
    // LOOPs
    #300;
    @(posedge clk);
    tlk2711b_start <= 1;
    tlk2711b_mode <= 1;
    @(posedge clk);
    tlk2711b_start <= 0;
    #100;
    @(posedge clk);
    tlk2711b_stop <= 1;
    wait(tlk2711b_stop_ack);
    tlk2711b_stop <= 0;
    // Kcode
    #300;
    @(posedge clk);
    tlk2711b_start <= 1;
    tlk2711b_mode <= 2;
    @(posedge clk);
    tlk2711b_start <= 0;
    #100;
    @(posedge clk);
    tlk2711b_stop <= 1;
    wait(tlk2711b_stop_ack);
    tlk2711b_stop <= 0;
    
    #300;
    $stop;

end

tlk2711 tlk2711b_inst (
    .tx_clk(clk),
    .rst(rst),
    .o_txd(tlk2711b_txd),
    .i_start(tlk2711b_start),
    .i_mode(tlk2711b_mode),
    .i_stop(tlk2711b_stop),
    .o_stop_ack(tlk2711b_stop_ack),
    .o_tkmsb(tlk2711b_tkmsb),
    .o_tklsb(tlk2711b_tklsb),
    .o_loopen(tlk2711b_loopen),
    .o_prbsen(tlk2711b_prbsen),
    .o_enable(tlk2711b_enable),
    .o_lckrefn(tlk2711b_lckrefn),
    .o_testen(tlk2711b_testen),

    .rx_clk(clk),
    .i_rkmsb(tlk2711b_rkmsb),
    .i_rklsb(tlk2711b_rklsb),
    .i_rxd(tlk2711b_rxd)

);


endmodule