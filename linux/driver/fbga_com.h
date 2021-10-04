#ifndef __FBGA_COM_H__
#define __FBGA_COM_H__

/*
 * fbga driver and app common defines
 * author:  delphiqin@foxmail.com
 * date:    2021-08-13
 */

/* structure for command below */
struct devm_data_t {
    uint64_t reg_off; //register offset
    uint64_t val;   //value get from or read to register
};

/* structure for command below */
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

/* register operate command
 * ...GET: read from
 * ...SET: write to
 */
#define IOCTL_FPGA_MAGIC        'FBGA'
//#define IOCMD_DEVM_GET  0x300
//#define IOCMD_DEVM_SET  0x301
#define IOCMD_DEVM_GET          _IOW(IOCTL_FPGA_MAGIC, 01, struct devm_data_t)
#define IOCMD_DEVM_SET          _IOW(IOCTL_FPGA_MAGIC, 02, struct devm_data_t)

/* DMA operate command
 * ...CONFIGTX: config and start transform from PS to DEVICE
 * ...CONFIGRX: config and start transform from DEVICE to PS
 */
// #define IOCMD_DMA_CONFIGTX    0x400
// #define IOCMD_DMA_CONFIGRX    0x401
#define IOCMD_DMA_CONFIGTX      _IOW(IOCTL_FPGA_MAGIC, 01, struct data_config_t)
#define IOCMD_DMA_CONFIGRX      _IOW(IOCTL_FPGA_MAGIC, 02, struct data_config_t)


#endif
