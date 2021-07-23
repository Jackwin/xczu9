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
