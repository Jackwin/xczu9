`timescale 1ns/1ps

module axi_data_gen_sim();

logic sys_clk;
logic sys_rst;


initial begin
    sys_clk = 0;
    forever begin
        #5 sys_clk = ~sys_clk;
    end
end

initial begin
    sys_rst = 1;
    # 120 sys_rst = 0;
end

logic           start;
logic [9:0]     length;
logic           gen_ready;
logic [63:0]    gen_data;
logic [7:0]     gen_keep;
logic           gen_valid;
logic           gen_last;

initial begin
    start <= 0;
    length <= 0;
    #250;

    @(posedge sys_clk);
    start <= 1;
    length <= 256;
    @(posedge sys_clk);
    start <= 0;
    length <= 256;
    wait(gen_last);

    #100;
    @(posedge sys_clk);
    start <= 1;
    length <= 255;
    @(posedge sys_clk);
    start <= 0;
    
    #1500;
    $stop;
end

initial begin
    gen_ready <= 0;
    #250;
    @(posedge sys_clk);
    @(posedge sys_clk);
    @(posedge sys_clk);
    gen_ready <= 0;

    @(posedge sys_clk);
    gen_ready <= 1;

    #100;
    @(posedge sys_clk);
    gen_ready <= 0;
    @(posedge sys_clk);
    gen_ready <= 1;
    @(posedge sys_clk);
    gen_ready <= 0;

    @(posedge sys_clk);
    @(posedge sys_clk);
    gen_ready <= 1;
end
    


axi_data_gen # (
    .DATA_WIDTH(64)
)axi_data_gen_inst (
    .clk(sys_clk),
    .rst(sys_rst),
    .i_start(start),
    .i_length(length),
    .i_ready(gen_ready),
    .o_data(gen_data),
    .o_valid(gen_valid),
    .o_keep(gen_keep),
    .o_last(gen_last)
);

endmodule