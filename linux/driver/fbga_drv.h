#ifndef __FBGA_DRV_H__
#define __FBGA_DRV_H__

#include <linux/bitops.h>
#include <linux/workqueue.h>
#include <linux/of_irq.h>

#define DEVICE_NAME "fbga_drv"

#define WR_OP 0
#define RD_OP 1

#define MAX_CONFIG_RAM  0xFFF
#define TIMEOUT_MS_DMATX    100

#define DMA_REGOFF_RESET    0x0100
#define DMA_REGOFF_TXEN     0x0008
#define DMA_REGOFF_RXEN     0x0010

#define DMA_REGOFF_TXADDR   0x0020
#define DMA_REGOFF_TXLEN    0x0028

#define DMA_REGOFF_TXPACK   0x0030  //trans package config: tail len and body len
#define DMA_TXPACK_MODE_SHIFT   60  //mode shift 
#define DMA_TXPACK_TAILLEN_SHIFT    32  //tail len shift
#define DMA_TXPACK_BODYNUM_SHIFT    15  //body num shift
#define DMA_TXPACK_DATALEN_SHIFT    0  //valid data len shift

#define DMA_REGOFF_TXSR   0x0038  //trans status
#define DMA_TXSR_FIFOEMP_MASK  BIT_ULL(9)
#define DMA_TXSR_FIFOFULL_MASK  BIT_ULL(8)
#define DMA_TXSR_SM_MASK    GENMASK_ULL(7,4)    //status machine
#define DMA_TXSR_MODE_MASK  GENMASK_ULL(3,0)    //

#define DMA_REGOFF_RXADDR   0x0040

#define DMA_REGOFF_RXCTRL   0x0048
#define DMA_RXCTRL_FIFOEN_MASK  BIT_ULL(0)

#define DMA_REGOFF_RXSR 0x0050
#define DMA_RXSR_FIFOEMP_MASK  BIT_ULL(5)
#define DMA_RXSR_FIFOFULL_MASK  BIT_ULL(4)
#define DMA_RXSR_MODE_MASK  GENMASK_ULL(3,0)

#define DMA_REGOFF_INTSR    0x0060
#define DMA_INTSR_TYPE_MASK GENMASK_ULL(63,60)
#define DMA_INTSR_TYPE_SHIFT    60
#define DMA_INTSR_MODE_MASK GENMASK_ULL(41,34)
#define DMA_INTSR_FILEND_MASK   BIT_ULL(33)
#define DMA_INTSR_CKSUM_MASK    BIT_ULL(32)
#define DMA_INTSR_RECVROW_MASK  GENMASK_ULL(31,16)
#define DMA_INTSR_RECVROW_SHIFT 16
#define DMA_INTSR_RECVLEN_MASK  GENMASK_ULL(15,0)
#define DMA_INTSR_SYNCERR_MASK  BIT_ULL_ULL(1)
#define DMA_INTSR_LINKBRK_MASK  BIT_ULL(0)


struct fbga_drv
{
    struct platform_device *pdev;
    dev_t devno;
    struct class *fb_class;
    struct cdev fb_cdev;
    void __iomem *paddr_bram;
    void __iomem *paddr_data;
    void __iomem *paddr_devm;
    void __iomem *vaddr_bram;
    void __iomem *vaddr_data;
    void __iomem *vaddr_devm;
    int irq;
    struct completion cmp_dmatx;
    struct completion cmp_dmarx;
};

struct memory_data {
	char magic[20];
	struct fbga_drv *fdev;
	atomic_t refcnt;
};


#endif

