module emmc_iobuf (
    input [7:0]     emmc_data_i,
    inout [7:0]     emmc_data_io,
    output [7:0]    emmc_data_o,
    input [7:0]     emmc_data_t

);

genvar var;
generate for(var = 0; var < 8; var = var + 1) begin : emmc_data_iobuf
    IOBUF emmc_data_iobuf_0 (
        .I(emmc_data_i[var]),
        .IO(emmc_data_io[var]),
        .O(emmc_data_o[var]),
        .T(emmc_data_t[var])
    );
end
endgenerate



endmodule