#tlk2711B loopback
#Set DMA sending start DDR addr,backwward 1000,000（F4240）
busybox devmem 0xb0000020 64 0xF42400040000000
#Send one frame 10752B loop-back mode
busybox devmem 0xb0000030 64 0xb02a000000002a00

#Set DMA recv
busybox devmem 0xb0000040 64 0x6a000000 
##RX_CTRL_REG2(0x58) trig per line
busybox devmem 0xb0000058 64 0x00000001
## intr width is 16
busybox devmem 0xb0000068 64 0x2000000000000010

#start
busybox devmem 0xb0000008 64 0x3