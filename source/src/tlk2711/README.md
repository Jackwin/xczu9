## Register address

|  reg name   | address  |function | |
|  ----  | ----  | --- | --- |
| SOFT_R_REG  | 0x00 | soft reset| |
| TX_IRQ_REG  | 0x0100 | Tx interrupt||
| RX_IRQ_REG  | 0x0200 | Rx interrupt||
| RX_LOSS_REG  | 0x0300 | Rx Link loss||
| TX BASE ADDR | 0x0108 | TX DDR address ||
| TX TOTAL PACKET  | 0x0110 | total packet ||
| TX PACKET BODY/TAIL  | 0x0118 | [15:0] -> body length [63:32] -> tail length||
| TX CTRL REG  | 0x0120 | [3:0] -> tx_mode [63:32] -> body_num ||
| RX BASE ADDR  | 0x0208 | RX DDR address ||

## Modelsim usage
1. Set the source code path in the sim.do
2. Use your own modelsim.ini to replace with the one in the sim/tlk2711
``` bash
cd sim/tlk2711
do sim.do
```
## Debug tlk2711

1. i_reg_waddr <= 16'h0108; i_reg_wdata <= 0x8_0000_0000;
2. i_reg_waddr <= 16'h0208; i_reg_wdata <= 0xh8_0010_0000;
3. i_reg_waddr <= 16'h0110; i_reg_wdata <= h708(d1800); // total length 
4. i_reg_waddr <= 16'h0118; i_reg_wdata[63:32] <= h3c(d60); i_reg_wdata[31:0]  <= h366(d870); // tail & body
5. i_reg_waddr <= 16'h0120; i_reg_wdata[63:32] <= d2; i_reg_wdata[31:0] <= 0; // tx mode & body number
6. i_reg_wen <= 'd1; i_reg_waddr <= 16'h0100; //tx_start
7. i_reg_wen <= 'd1; i_reg_waddr <= 16'h0200; //rx_start

### Loopback Test
    localparam NORM_MODE = 4'd0;
    localparam LOOPBACK_MODE = 4'd1; // Internal chip loopback test
    localparam KCODE_MODE = 4'd2;
    localparam TEST_MODE = 4'd3; // chip to chip test
- i_reg_waddr <= 16'h0120; i_reg_wdata[63:0] <= 1
- reg_waddr == 16'h0100; i_reg_wen will trigger the test start
- reg_waddr == 16'h0000 i_reg_wen will trigger the test start
### KCODE test
- i_reg_waddr <= 16'h0120; i_reg_wdata[63:0] <= 2
- reg_waddr == 16'h0100; i_reg_wen will trigger the test start
- reg_waddr == 16'h0000 i_reg_wen will stop the test start
