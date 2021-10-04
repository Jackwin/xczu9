#ifndef __FBGA_COM_H__
#define __FBGA_COM_H__

/*
 * fbga driver and app common defines
 * author:  delphiqin@foxmail.com
 * date:    2021-08-13
 */

/* register operate command
 * ...GET: read from
 * ...SET: write to
 */
#define IOCMD_DEVM_GET  0x300
#define IOCMD_DEVM_SET  0x301

/* structure for command above */
struct devm_data_t {
    uint64_t reg_off; //register offset
    uint64_t val;   //value get from or read to register
};


/* DMA operate command
 * ...CONFIGTX: config and start transform from PS to DEVICE
 * ...CONFIGRX: config and start transform from DEVICE to PS
 */
#define IOCMD_DMA_CONFIGTX    0x400
#define IOCMD_DMA_CONFIGRX    0x401

/* structure for command above */
struct data_config_t {
//offset to addr_data
    uint32_t addr_off;  
    uint64_t data_len;
//trans status
#define TRANS_STAT_FILE_DONE    0x00000001
    uint32_t status;
//data mode: 0--normal; 1--inside loop; 2--Kcode test; 3--data test
    uint32_t data_mode;
};

#endif
