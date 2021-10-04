#include <linux/module.h>
#include <linux/cdev.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/device.h>
#include <linux/slab.h>
#include <linux/mman.h>
#include <linux/pagemap.h>
#include <linux/sched.h>
#include <asm/io.h>
#include <linux/init.h>
#include <linux/platform_device.h>
#include <linux/miscdevice.h>
#include <linux/ioport.h>
#include <linux/of.h>
#include <linux/uaccess.h>
#include <linux/of_address.h>
#include <linux/irq.h>
#include <linux/interrupt.h>

#include "fbga_drv.h"
#include "fbga_com.h"

//unsigned myint = 0xdeadbeef;
//char *mystr = "default";

//module_param(myint, int, S_IRUGO);
//module_param(mystr, charp, S_IRUGO);

static struct fasync_struct *fb_async = NULL;
struct fbga_drv *fb_drv = NULL;

void write_reg64(struct fbga_drv* pdrv, uint64_t off, uint64_t val) {
    *(uint64_t*)(pdrv->vaddr_devm + off) = val;
}
void read_reg64(struct fbga_drv* pdrv, uint64_t off, uint64_t* val) {
    *val = *(uint64_t*)(pdrv->vaddr_devm + off);
}

/*config and start  dma tx, wati until irq or timeout*/ 
static int _dma_config_tx(struct data_config_t *param) {
    uint64_t addr = fb_drv->paddr_data + param->addr_off;
    write_reg64(fb_drv, DMA_REGOFF_TXADDR, addr);
    write_reg64(fb_drv, DMA_REGOFF_TXLEN, param->data_len);
    uint32_t body_len = 870;
    uint64_t body_num = param->data_len / 870;
    uint64_t tail_len = param->data_len % 870;
    uint64_t pack_conf = (body_num << DMA_TXPACK_BODYNUM_SHIFT) |
            (tail_len << DMA_TXPACK_TAILLEN_SHIFT) |
            (param->data_mode << DMA_TXPACK_MODE_SHIFT);
    write_reg64(fb_drv, DMA_REGOFF_TXPACK, pack_conf);
    write_reg64(fb_drv, DMA_REGOFF_TXEN, 0);
    printk("begin dma tx: len:%d, addr:0x%lx, pack:0x%lx\n", param->data_len, addr, pack_conf);

	unsigned long timeout = msecs_to_jiffies(TIMEOUT_MS_DMATX);
    timeout = wait_for_completion_timeout(&fb_drv->cmp_dmatx, timeout);
    if (0 == timeout) {
        printk("wait for dma tx timeout\n");
        return -ETIMEDOUT;
    }
    
    return 0;
}
static int _dma_config_rx(struct data_config_t *param) {
    write_reg64(fb_drv, DMA_REGOFF_RXADDR, fb_drv->paddr_data + param->addr_off);
    write_reg64(fb_drv, DMA_REGOFF_RXEN, 0);

	unsigned long timeout = msecs_to_jiffies(TIMEOUT_MS_DMATX);
    timeout = wait_for_completion_timeout(&fb_drv->cmp_dmarx, timeout);
    if (0 == timeout) {
        printk("wait for dma rx timeout\n");
        return -ETIMEDOUT;
    }

    uint64_t intsr;
    read_reg64(fb_drv, DMA_REGOFF_INTSR, &intsr);
    uint64_t inttype = (intsr & ~DMA_INTSR_TYPE_MASK) >> DMA_INTSR_TYPE_SHIFT;
    if (3 == inttype) {
        printk("link error, INTSR: %016lx\n", intsr);
        return -EPIPE;
    }

    uint32_t len = intsr & DMA_INTSR_RECVLEN_MASK;
    param->data_len = len;
    if (intsr & DMA_INTSR_FILEND_MASK) {
        param->status |= TRANS_STAT_FILE_DONE;
    }
    return 0; 
}

int fbga_drv_open(struct inode * inode, struct file *filp)
{
    printk("device is open!\n");
    return 0;
}

int fbga_drv_release(struct inode *inode, struct file *filp)
{
    printk("device is release!\n");
    return 0;
}

static ssize_t fbga_drv_read(struct file *filp, char __user *buf, size_t size, loff_t *ppos)
{
//测试读配置内存，读指定大小数据
    unsigned int count = (size > MAX_CONFIG_RAM) ? MAX_CONFIG_RAM : size;
    /*
    unsigned int ret = 0;
    printk("count:%d\n", count);

    unsigned int *p0 = (unsigned int*)(fb_drv->vaddr_bram);
    unsigned int *p1 = (unsigned int*)(fb_drv->vaddr_devm);
    printk("p0:0x%08x,0x%08x,0x%08x\n", p0[0],p0[1],p0[2]);
    printk("p1:0x%08x,0x%08x,0x%08x\n", p1[0],p1[1],p1[2]);

    if(copy_to_user(buf, (void*)(fb_drv->vaddr_bram), count))
    {
	    ret = -EINVAL;
    }
    */
    
    if(copy_to_user(buf, (void*)(fb_drv->vaddr_bram), count)) {
	    return -EINVAL;
    }
    return count;
}

static ssize_t fbga_drv_write(struct file *filp,const char __user *buf, size_t size, loff_t *ppos)
{
    unsigned int count = (size > MAX_CONFIG_RAM) ? MAX_CONFIG_RAM : size;
    /*
    unsigned int rdata;
    unsigned int ret = 0;
    char buf_tmp[16];
    memset(buf_tmp,0,16);

    printk("write size:%d\n", size);
    if(copy_from_user((char *)buf_tmp, buf, 16)) {
	    ret = -EINVAL;
    }

    printk("\nbuf_tmp[0]=0x%x\n",(unsigned int)buf_tmp[0]);
    
    iowrite32((unsigned int)buf_tmp[0], fb_drv->vaddr_bram);

    rdata=ioread32(fb_drv->vaddr_bram);
    printk("read mem after copy_from_user, rdata = %x\n", rdata);
    */
    
    if(copy_from_user((char *)(fb_drv->vaddr_bram), buf, count)) {
	    return -EINVAL;
    }
    return size;
}

static int fbga_fasync (int fd, struct file *filp, int on)
{
    printk("\n: fbga_fasync\n");
    return fasync_helper(fd, filp, on, &fb_async);
}

static long fbga_ioctl(struct file *filp, unsigned int cmd, unsigned long arg)
{
    printk("fbga_ioctl\n");

    void __user *argp = (void __user*)arg;
    struct devm_data_t devmd;
    struct data_config_t param;
    uint64_t reg = 0;
    int ret = 0;
    switch(cmd)
    {
        case IOCMD_DEVM_GET:
            printk("dev mgt: get reg val.\n");
            copy_from_user((char*)(&devmd), argp, sizeof(devmd));
printk("IOCMD_DEVM_GET:1, off:%ld\n", devmd.reg_off);
            read_reg64(fb_drv, devmd.reg_off, &(devmd.val));
printk("IOCMD_DEVM_GET:2, val:%lx\n", devmd.val);
            copy_to_user(argp, (char*)(&devmd), sizeof(devmd));
            break;
        case IOCMD_DEVM_SET:
            printk("dev mgt: set reg val.\n");
            copy_from_user((char*)(&devmd), argp, sizeof(devmd));
            write_reg64(fb_drv, devmd.reg_off, devmd.val);
            break;
        case IOCMD_DMA_CONFIGTX:
            printk("dma tx.\n");
            copy_from_user((char*)(&param), argp, sizeof(param));
            return _dma_config_tx(&param);
        case IOCMD_DMA_CONFIGRX:
            printk("dma rx.\n");
            copy_from_user((char*)(&param), argp, sizeof(param));
            ret = _dma_config_rx(&param);
            copy_to_user(argp, (char*)(&param), sizeof(param));
            return ret;
            break;
        default :
            return -EINVAL;
    }
    return 0;
}

void data_vma_open(struct vm_area_struct *vma)
{   
    printk(KERN_NOTICE "Simple VMA open, virt %lx, off %lx\n",
                            vma->vm_start, vma->vm_pgoff << PAGE_SHIFT);
    struct memory_data *md = (struct memory_data*)(vma->vm_private_data);
    atomic_inc(&(md->refcnt));
}

void data_vma_close(struct vm_area_struct *vma)
{
    printk(KERN_NOTICE "Simple VMA close.\n");
    if (vma->vm_private_data == NULL) {
        printk(KERN_ALERT, "Wrong VMA !!! private data not set!\n");
        return;
    }
    struct memory_data *md = (struct memory_data*)(vma->vm_private_data);
    if (!atomic_dec_and_test(&(md->refcnt))) {
        return;
    }
    struct fbga_drv *fdev = md->fdev;
    kfree(md);
}

static struct vm_operations_struct data_remap_vm_ops = {
    .open =  data_vma_open,
    .close = data_vma_close,
};

int fbga_mmap(struct file *file, struct vm_area_struct *vma) {
    struct inode *inode = file_inode(file);
    struct fbga_drv *fdev = container_of(inode->i_cdev, struct fbga_drv, fb_cdev);
    uint32_t size = vma->vm_end - vma->vm_start;
    printk("device mmap now: size: %d, phyaddr:%p\n", size, fdev->paddr_data);

    if (remap_pfn_range(vma, vma->vm_start, (uint64_t)(fdev->paddr_data) >> PAGE_SHIFT, size, vma->vm_page_prot)) {
        printk("remap paddr failed\n");
        return -EAGAIN;
    }
    struct memory_data *md = kmalloc(sizeof(struct memory_data), GFP_KERNEL);
    atomic_set(&(md->refcnt), 1);

    vma->vm_private_data = (void*)md;
    vma->vm_ops = &data_remap_vm_ops;
    data_vma_open(vma);
    return 0;
}

static const struct file_operations fbga_drv_fops=
{
    .owner = THIS_MODULE,
    .open = fbga_drv_open,
    .release = fbga_drv_release,
    .read = fbga_drv_read,
    .write = fbga_drv_write,
    .fasync = fbga_fasync,
    .unlocked_ioctl = fbga_ioctl,
    .mmap = fbga_mmap,
};

static irqreturn_t fbga_drv_irq(int irq, void *lp)
{
	printk("fbga_drv interrupt triggered\n");

    uint64_t intsr = 0;
    read_reg64(fb_drv, DMA_REGOFF_INTSR, &intsr);
    printk("INTSR:%016lx\n", intsr);
    uint64_t inttype = (intsr & DMA_INTSR_TYPE_MASK) >> DMA_INTSR_TYPE_SHIFT;
    if (1 == inttype) {
        printk("tx complete\n");
        complete(&fb_drv->cmp_dmatx);
    }
    else if (2 == inttype || 3 == inttype) {
        printk("rx complete\n");
        complete(&fb_drv->cmp_dmarx);
    }
    else {
        printk("irq status error, type:%d\n", inttype);
        uint64_t rxsr;
        read_reg64(fb_drv, DMA_REGOFF_RXSR, &rxsr);
        printk("RXSR:%016lx\n", rxsr);
    }
/*
*/
    if (fb_async) {
        kill_fasync(&fb_async, SIGIO, POLL_IN);
    }
	printk("fbga_drv interrupt handled done\n");
	return IRQ_HANDLED;
}

static int fbga_drv_probe(struct platform_device *pdev)
{
	printk("fbga_drv probing\n");
    struct resource r_mem;
    struct device_node *np = NULL;
    struct device *dev = &pdev->dev;
	int rc = 0;

	dev_info(dev, "Device Tree Probing\n");
	dev_err(dev, "err:Device Tree Probing\n");
	dev_dbg(dev, "dbg:Device Tree Probing\n");
	fb_drv = kmalloc(sizeof(struct fbga_drv), GFP_KERNEL);
	if (fb_drv == NULL) {
		printk( "unable to allocate device structure\n");
		return -ENOMEM;
	}
    memset(fb_drv, 0, sizeof(fb_drv));

    /* Get reserved memory region from Device-tree */
    np = of_parse_phandle(dev->of_node, "memory-region", 0);
    if (!np) {
        printk( "No %s specified\n", "memory-region");
        goto error_handle5;
    }
  
    rc = of_address_to_resource(np, 0, &r_mem);
    if (rc) {
        printk( "No memory address assigned to the region\n");
        goto error_handle5;
    }
    fb_drv->paddr_data = (void*)r_mem.start;
    fb_drv->vaddr_data = memremap(r_mem.start, resource_size(&r_mem), MEMREMAP_WB);
    dev_info(dev, "Allocated reserved memory, vaddr: 0x%p, paddr: 0x%p\n", fb_drv->vaddr_data, fb_drv->paddr_data);
    if(!fb_drv->vaddr_data) 
    {
        printk( "cannot map the mem\n");
        return -EINVAL;
    }

    rc = of_address_to_resource(np, 1, &r_mem);
    if (rc) {
        printk( "No memory address assigned to the region\n");
        goto error_handle4;
    }
    fb_drv->paddr_devm = (void*)r_mem.start;
    fb_drv->vaddr_devm = memremap(r_mem.start, resource_size(&r_mem), MEMREMAP_WB);
    dev_info(dev, "Allocated reserved memory, vaddr: 0x%p, paddr: 0x%p\n", fb_drv->vaddr_devm, fb_drv->paddr_devm);
    if(!fb_drv->vaddr_devm) 
    {
        printk( "cannot map the mem\n");
        goto error_handle4;
    }

	rc =alloc_chrdev_region(&fb_drv->devno,0, 1,DEVICE_NAME);
	if (rc < 0)
	{
		dev_err(&pdev->dev, "unable to alloc chrdev \n");
		goto error_handle4;
	}
    
	cdev_init(&fb_drv->fb_cdev, &fbga_drv_fops);

	fb_drv->fb_cdev.owner = THIS_MODULE;
	fb_drv->fb_cdev.ops = &fbga_drv_fops;
	rc = cdev_add(&fb_drv->fb_cdev,fb_drv->devno,1);
    if(rc < 0){
		dev_err(&pdev->dev, "unable to do cdev add \n");
        goto error_handle3;
    }
    
	fb_drv->fb_class = class_create(THIS_MODULE, DEVICE_NAME);
	
    rc=device_create(fb_drv->fb_class, NULL, MKDEV(MAJOR(fb_drv->devno), 0), NULL, DEVICE_NAME);
    //rc = device_create(fb_drv->fb_class, &pdev->dev, MKDEV(MAJOR(fb_drv->devno), 0), NULL, DEVICE_NAME);
    if(rc <0){
       dev_err(&pdev->dev, "unable to create device \n");
       goto error_handle2;
    }
        
    init_completion(&fb_drv->cmp_dmatx);
    init_completion(&fb_drv->cmp_dmarx);

    fb_drv->irq = platform_get_irq(pdev,0);
    if (fb_drv->irq <= 0) {
        printk("platform get irq failed\n");
        rc = fb_drv->irq;
        goto error_handle1;
    }
    rc = request_threaded_irq(fb_drv->irq, NULL,
            fbga_drv_irq,
            IRQF_TRIGGER_RISING | IRQF_ONESHOT,
            DEVICE_NAME, NULL);
    if (rc) {
        printk(KERN_ALERT "irq_probe irq error=%d\n", rc);
        goto error_handle1;
    }
    else {
        printk("\nirq = %d\n", fb_drv->irq);
    }

    fb_drv->pdev = pdev;
    dev_info(&pdev->dev, "fbga drv added successfully\n");
    
    return 0;

error_handle0:
    free_irq(fb_drv->irq,NULL);
error_handle1:
    class_destroy(fb_drv->fb_class);
error_handle2:
    cdev_del(&fb_drv->fb_cdev);
error_handle3:
	unregister_chrdev_region(fb_drv->devno, 1);
error_handle4:
    if (fb_drv->vaddr_data) iounmap(fb_drv->vaddr_data);
    if (fb_drv->vaddr_devm) iounmap(fb_drv->vaddr_devm);
error_handle5:
    kfree(fb_drv);
    fb_drv = NULL;
    return rc;
}

static int fbga_drv_remove(struct platform_device *pdev)
{
	printk("fbga_drv removing\n");

    if (!fb_drv) {
        printk("not init.\n");
        return 0;
    }
    if (fb_drv->irq > 0) {
        printk("fbga_drv freeing irq\n");
        free_irq(fb_drv->irq, NULL);
    }
	device_destroy(fb_drv->fb_class,MKDEV(MAJOR(fb_drv->devno),0));
    class_destroy(fb_drv->fb_class);
    cdev_del(&fb_drv->fb_cdev);
	unregister_chrdev_region(fb_drv->devno, 1);
    
    printk("fbga_drv delete char dev.\n");

    if (fb_drv->vaddr_data) iounmap(fb_drv->vaddr_data);
    if (fb_drv->vaddr_devm) iounmap(fb_drv->vaddr_devm);

    if(fb_drv){
	    kfree(fb_drv);
        fb_drv = NULL;
    }

	return 0;
}

static struct of_device_id fbga_drv_of_match[] = {
	{ .compatible = "xlnx,fpga_zu9", },
	{ /* end of list */ },
};

MODULE_DEVICE_TABLE(of, fbga_drv_of_match);

static struct platform_driver fbga_driver = {
	.driver = {
		.name = DEVICE_NAME,
		.owner = THIS_MODULE,
		.of_match_table	= fbga_drv_of_match,
	},
	.probe		= fbga_drv_probe,
	.remove		= fbga_drv_remove,
};

static int __init fbga_drv_init(void)
{
	printk("mooresi fpga driver init .\n");
	return platform_driver_register(&fbga_driver);
}

static void __exit fbga_drv_exit(void)
{
	platform_driver_unregister(&fbga_driver);
	printk(KERN_ALERT "mooresi fpga driver exit.\n");
}

module_init(fbga_drv_init);
module_exit(fbga_drv_exit);

MODULE_AUTHOR("CHENGL");
MODULE_DESCRIPTION("FBGA_DRV");
MODULE_LICENSE("GPL");
