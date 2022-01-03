`timescale 1ns/1ps

module datamover_validation # (
    parameter DDR_ADDR_WIDTH = 40,
    parameter INIT_DATA = 0
    )(
    input                               clk,
    input                               rst,

    input                               i_start,
    input [15:0]                        i_length,
    input [DDR_ADDR_WIDTH-1:0]          i_start_addr,
    input [15:0]                        i_rd_length,
    input [DDR_ADDR_WIDTH-1:0]          i_start_rd_addr,


    input                               i_s2mm_wr_cmd_tready,
    output logic [39+DDR_ADDR_WIDTH:0]  o_s2mm_wr_cmd_tdata,
    output logic                        o_s2mm_wr_cmd_tvalid,

    output logic [63:0]                 o_s2mm_wr_tdata,
    output logic [7:0]                  o_s2mm_wr_tkeep,
    output logic                        o_s2mm_wr_tvalid,
    output logic                        o_s2mm_wr_tlast,
    input  logic                        i_s2mm_wr_tready,

    input  logic [7:0]                  s2mm_sts_tdata,
    input  logic                        s2mm_sts_tvalid,
    input  logic                        s2mm_sts_tkeep,
    input  logic                        s2mm_sts_tlast,

    input                               i_mm2s_rd_cmd_tready,
    output logic [39+DDR_ADDR_WIDTH:0]  o_mm2s_rd_cmd_tdata,
    output logic                        o_mm2s_rd_cmd_tvalid,

    input [63:0]                        i_mm2s_rd_tdata,
    input [7:0]                         i_mms2_rd_tkeep,
    input                               i_mm2s_rd_tvalid,
    input                               i_mm2s_rd_tlast,
    output                              o_mm2s_rd_tready
);

localparam   WR_EOF_VAL = 4'b1010;

logic                       vio_wr_start;
logic                       start_r;
logic                       start_p;
logic                       wr_start;

logic [DDR_ADDR_WIDTH-1:0]  s2mm_wr_saddr;
logic [15:0]                s2mm_wr_length;
logic [DDR_ADDR_WIDTH-1:0]  s2mm_rd_saddr;
logic [15:0]                s2mm_rd_length;
logic [3:0]                 s2mm_wr_eof;

logic [63:0]                gen_data;
logic                       gen_valid;
logic                       gen_last;
logic [7:0]                 gen_keep;

assign o_mm2s_rd_tready = 1;

always_ff @(posedge clk) begin
    start_r <= i_start;
    start_p <= ~start_r & i_start;
end

always_comb begin
    s2mm_wr_saddr = i_start_addr;
    s2mm_wr_length = i_length;
    s2mm_rd_saddr = i_start_rd_addr;
    s2mm_rd_length = i_rd_length;
end

enum logic [2:0] {
    IDLE_s = 'd0,
    WR_CMD_s = 'd1,
    WR_DATA_s = 'd2,
    WR_DONE_s = 'd3,
    RD_CMD_s = 'd4,
    RD_DATA_s = 'd5
} cs, ns;

always_ff @(posedge clk) begin
    if (rst) begin
        cs <= IDLE_s;
    end else begin
        cs <= ns;
    end
end

always_comb begin
    ns = cs;
    case(cs)
        IDLE_s: begin
            if (start_p) begin
                ns = WR_CMD_s;
            end     
        end
        WR_CMD_s: begin
            if (i_s2mm_wr_cmd_tready) begin
                ns = WR_DATA_s;
            end
        end
        WR_DATA_s: begin
            if (gen_last & gen_valid) begin
                ns = WR_DONE_s;
            end
        end
        WR_DONE_s: begin
            if (s2mm_sts_tdata[3:0] == WR_EOF_VAL & s2mm_sts_tvalid & s2mm_sts_tlast) begin
                ns = RD_CMD_s;
            end
        end
        RD_CMD_s: begin
            if (i_mm2s_rd_cmd_tready) begin
                ns = RD_DATA_s;
            end
        end
        RD_DATA_s: begin
            if (i_mm2s_rd_tvalid & i_mm2s_rd_tlast) begin
                ns = IDLE_s;
            end
        end

        default: ns = IDLE_s;
    endcase
end

always_comb begin
    o_s2mm_wr_cmd_tvalid = 0;
    o_mm2s_rd_cmd_tvalid = 0;
    o_mm2s_rd_cmd_tdata = 0;
    o_s2mm_wr_cmd_tdata = 0;
    wr_start = 0;
    case(cs)
        IDLE_s,WR_DATA_s, WR_DONE_s, RD_DATA_s: begin
            o_s2mm_wr_cmd_tvalid = 0;
            o_mm2s_rd_cmd_tvalid = 0;
            wr_start = 0;
        end
        WR_CMD_s: begin
            wr_start = 1;
            o_s2mm_wr_cmd_tvalid = 1;
           // o_s2mm_wr_cmd_tdata = {4'd0, WR_EOF_VAL, s2mm_wr_saddr, 1'b0, 1'b1, 7'd1, 7'd0, s2mm_wr_length};
           o_s2mm_wr_cmd_tdata = {4'd0, WR_EOF_VAL, s2mm_wr_saddr, 1'b0, 1'b1, 7'd1, 7'd0, {s2mm_wr_length[14:0],1'b0}};
        end
        RD_CMD_s: begin
            o_mm2s_rd_cmd_tvalid = 1;
          //  o_mm2s_rd_cmd_tdata = {8'd0, s2mm_rd_saddr, 1'b0, 1'b1, 7'd1, 7'd0, s2mm_rd_length};
            o_mm2s_rd_cmd_tdata = {8'd0, s2mm_rd_saddr, 1'b0, 1'b1, 7'd1, 7'd0,{s2mm_rd_length[14:0], 1'b0}};
        end
        default: begin
            o_s2mm_wr_cmd_tvalid = 0;
            o_mm2s_rd_cmd_tvalid = 0;
        end
    endcase
end

always_comb begin
    o_s2mm_wr_tdata = gen_data;
    o_s2mm_wr_tvalid = gen_valid;
    o_s2mm_wr_tlast = gen_last;
    o_s2mm_wr_tkeep = gen_keep;
end

axi_data_gen # (
    .DATA_WIDTH(64),
    .LENGTH_WIDTH(16),
    .INIT_DATA(INIT_DATA)
)axi_data_gen_inst (
    .clk(clk),
    .rst(rst),
    .i_start(wr_start),
    .i_length(i_length),
    .i_ready(i_s2mm_wr_tready),
    .o_data(gen_data),
    .o_valid(gen_valid),
    .o_keep(gen_keep),
    .o_last(gen_last)
);


endmodule