`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: chunjie
// 
// Create Date: 2021/10/09 07:31:15
// Design Name: 
// Module Name: clk_wiz
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module clk_wiz(
    output        clk_100,
    output        clk_375,

    input         reset,
    output        locked,

    input         clk_in1
 );

clk_wiz_0_clk_wiz inst(
    .clk_100(clk_100),
    .clk_375(clk_375),

    .reset(reset), 
    .locked(locked),

    .clk_in1(clk_in1)
);


endmodule
