`timescale 1ns/1ps

module axi_data_gen #(
    parameter DATA_WIDTH = 32,
    parameter LENGTH_WIDTH = 9,
    parameter STRB_WIDTH = DATA_WIDTH/8

)(
    input logic                     clk,
    input logic                     rst,

    input logic                     i_start,
    input logic [LENGTH_WIDTH-1:0]  i_length,
    input logic                     i_ready,
    output logic [DATA_WIDTH-1:0]   o_data,
    output logic                    o_valid,
    output logic [STRB_WIDTH-1:0]   o_keep,
    output logic                    o_last
);

localparam WORD_WIDTH = STRB_WIDTH;

localparam BIT_WIDTH = $clog2(STRB_WIDTH);

logic [BIT_WIDTH-1:0]   last_bytes;
logic [LENGTH_WIDTH-1-BIT_WIDTH:0]   word_num;

logic [LENGTH_WIDTH-1:0]    cnt;
logic                       cnt_ena;
logic [DATA_WIDTH-1:0]      gen_data;
logic                       gen_valid;
logic                       gen_last;
logic [STRB_WIDTH-1:0]      gen_keep;    

always_comb begin
    word_num = i_length[LENGTH_WIDTH-1:BIT_WIDTH] + |i_length[BIT_WIDTH-1:0];
    last_bytes = i_length[BIT_WIDTH-1:0];
end

always_ff @(posedge clk) begin
    if (rst) begin
        cnt <= 0;
        cnt_ena <= 0;
    end else begin
        if (i_start) begin
            cnt_ena <= 1;
        end else if (cnt == word_num - 1) begin
            cnt_ena <= 0;
        end

        if (cnt_ena & i_ready) begin
            if (cnt == word_num - 1) begin
                cnt <= 0;
            end else begin
                cnt <= cnt + 1;
            end
        end
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        gen_data <= 'h0;
    end else begin
        if (cnt_ena & i_ready) begin
            gen_data <= gen_data + 1'd1;
        end 
    end
end

always_comb begin
    gen_valid = cnt_ena & i_ready;
    gen_last = (cnt == word_num - 1) & cnt_ena & i_ready;
end

always_comb begin
    if (gen_last) begin
        case(last_bytes)
            'h0: gen_keep = 'hFF;
            'h1: gen_keep = 'h1;
            'h2: gen_keep = 'h3;
            'h3: gen_keep = 'h7;
            'h4: gen_keep = 'hf;
            'h5: gen_keep = 'h1f;
            'h6: gen_keep = 'h3f;
            'h7: gen_keep = 'h7f;
        endcase
    end else begin
        gen_keep = 'hff;
    end
end

always_comb begin
    o_data = gen_data;
    o_valid = gen_valid;
    o_keep = gen_keep;
    o_last = gen_last;
end
            


endmodule