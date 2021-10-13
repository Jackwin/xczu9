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
struct dev_conf_t {
//offset to addr_data
    uint32_t addr_off;  
    uint64_t data_len;
//trans status
#define TRANS_STAT_FILE_DONE    0x00000001
    uint32_t status;
    uint8_t mode_conn;  //connection mode: 0-open, 1-loopback
    uint8_t mode_work;  //work mode: 0-normal, 1-K code, 2-data test
    uint8_t mode_prew;  //pre-weight: 0-5%, 1-20%
    uint8_t chip_sel;   //select 2711: 0-B, 1-A, 2-default(B-tx,A-rx)
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
#define IOCMD_DMA_CONFIGTX      _IOW(IOCTL_FPGA_MAGIC, 01, struct dev_conf_t)
#define IOCMD_DMA_CONFIGRX      _IOW(IOCTL_FPGA_MAGIC, 02, struct dev_conf_t)


#endif
