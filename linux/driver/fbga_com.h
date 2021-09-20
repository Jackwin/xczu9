#ifndef __FBGA_COM_H__
#define __FBGA_COM_H__

/*
 * fbga driver and app common defines
 * author:  delphiqin@foxmail.com
 * date:    2021-08-13
 */

#define IOCMD_DEVM_GET  0x300
#define IOCMD_DEVM_SET  0x301

#define IOCMD_DMA_CONFIGTX    0x400
#define IOCMD_DMA_CONFIGRX    0x401


struct devm_data_t {
    uint64_t reg_off;
    uint64_t val;
};

struct data_config_t {
//offset to addr_data
    uint32_t addr_off;  
    uint64_t data_len;
//data mode: 0--normal; 1--inside loop; 2--Kcode test; 3--data test
    int32_t data_mode;
};

#endif
