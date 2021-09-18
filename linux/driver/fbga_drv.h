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

#define DMA_REGOFF_RESET    0x0
#define DMA_REGOFF_TXEN     0x0100
#define DMA_REGOFF_TXADDR   0x0108
#define DMA_REGOFF_TXLEN    0x0008
#define DMA_REGOFF_TXTB     0x0118  //tail len and body len
#define DMA_REGOFF_TXMOD    0x0120  //transe mode and body number
#define DMA_REGOFF_RXADDR   0x0208

#define DMA_REGOFF_INTSR    0x0110
#define DMA_INTSR_TYPE_MASK GENMASK(63,60)
#define DMA_INTSR_TYPE_SHIFT    60
#define DMA_INTSR_CKSUM_MASK    BIT(32)
#define DMA_INTSR_RECVROW_MASK  GENMASK(32,16)
#define DMA_INTSR_RECVROW_SHIFT 16
#define DMA_INTSR_RECVLEN_MASK  GENMASK(16,0)
#define DMA_INTSR_SYNCERR_MASK  BIT(1)
#define DMA_INTSR_LINKBRK_MASK  BIT(0)


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

