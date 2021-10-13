#include <linux/types.h>
#include <sys/ioctl.h>  
#include <sys/types.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>
#include <stdint.h>
#include <string.h>

#include <fbga_com.h>

struct dev_desc {
    int fd;
    void* map_data;
    uint64_t map_len;
};
struct op_desc {
    enum {
        DEVM_R,
        DEVM_W,
        DMA_R,
        DMA_W,
        NONE
    }op_type;
    struct devm_data_t dd;
    struct dev_conf_t dma_conf;
};


static const char* gc_strdevfile = "/dev/fbga_drv";
static struct dev_desc g_dev_desc;
static struct op_desc g_op_desc;

void dump_mem(unsigned char* data, int len) {
    printf("------------------------------------");
    int i;
    for (i = 0; i < len; i++) {
        if (0 == i%16) {
            printf("\n");
        }
        printf("%02x ", data[i]);
    }

    printf("\n------------------------------------\n");
}

void my_signal_fun(int signum){
    static int cnt;
    printf("signal = %d, %d times\n",signum, ++cnt);
}

int open_and_map(const char* dev_file, struct dev_desc* devd) {
	devd->fd = open(dev_file, O_RDWR); 
	if (devd->fd <= 0) {
		perror("open failed!");
		return -1;
	}
    printf("device opened, fd:%d\n", devd->fd);

    devd->map_data = mmap(0, devd->map_len, PROT_READ | PROT_WRITE, MAP_SHARED, devd->fd, 0); 
    if (MAP_FAILED == devd->map_data) {
        printf("map failed!\n");
		return -2;
    }
    printf("map addr: %p\n", devd->map_data);
    return 0;
}

int test_op(struct dev_desc* devd, struct op_desc* opd) {
    printf("test devm\n");
    if (opd->op_type == DEVM_R) {
        ioctl(devd->fd, IOCMD_DEVM_GET, &(opd->dd));
        printf("devm read off:%d, val:0x%08x\n", opd->dd.reg_off, opd->dd.val);
    }
    else if (opd->op_type == DEVM_W) {
        ioctl(devd->fd, IOCMD_DEVM_GET, &(opd->dd));
        printf("devm write off:%d, val:0x%08x\n", opd->dd.reg_off, opd->dd.val);

    }
    else if (opd->op_type == DMA_R) {
        ioctl(devd->fd, IOCMD_DMA_CONFIGTX, &(opd->dma_conf));
        printf("dma tx\n");
    }
    else if (opd->op_type == DMA_W) {
        ioctl(devd->fd, IOCMD_DMA_CONFIGRX, &(opd->dma_conf));
        printf("dma rx\n");
    }
    else {
        printf("op type error.\n");
    }
    return 0;
}

/* devm operation, read or write
 * type: 0--read, 1--write
 */
int devm_op(struct dev_desc* devd, struct devm_data_t dd, int32_t type) {
    if (type == 0) {
        if (0 == ioctl(devd->fd, IOCMD_DEVM_GET, &dd)) {
            printf("devm read offset:%ld done: 0x%016lx\n", dd.reg_off, dd.val);
        }
        else {
            printf("devm read error\n");
            return -1;
        }
    }
    else if (type == 1) {
        if (0 == ioctl(devd->fd, IOCMD_DEVM_SET, &dd)) {
            printf("devm write offset:%ld done: 0x%016lx\n", dd.reg_off, dd.val);
        }
        else {
            printf("devm write error\n");
            return -2;
        }
    }
    else {
        printf("Param error\n");
        return -3;
    }
    return 0;
}

int test_dma_rx(struct dev_desc* devd, struct dev_conf_t *dc) {
    printf("dma rx begin...\n");
    dc->addr_off = 0;
    int32_t dlen = ioctl(devd->fd, IOCMD_DMA_CONFIGRX, dc);
    if (dlen < 0) {
        printf("dma rx faild, return:%d,stat:0x%x,\n", dlen, dc->status);
        return -1;
    }
    printf("dma rx len: %d, status:0x%x\n", dlen, dc->status);
    dlen = (dlen > 32) ? 32 : dlen;
    dump_mem(devd->map_data, dlen);
    return 0;
}

int test_dma_tx(struct dev_desc* devd, struct dev_conf_t *dc) {
    printf("dma tx begin...\n");
	uint8_t val[16]={0x1,0x2,0x3,0x4,0x5,0x6,0x7,0x8,0x9,0xa,0xb,0xc,0xd,0xe,0xf,0x0};
    memcpy((uint8_t*)(devd->map_data), val, 16);
    dc->addr_off = 0xa000000;
    dc->data_len = 1800;
    printf("tx ioctl now\n");
    if (0 != ioctl(devd->fd, IOCMD_DMA_CONFIGTX, dc)) {
        perror("dma tx faild:");
        return -1;
    }
    printf("dma tx done, len: %d", dc->data_len);
    return 0;
}

void cmd_split(const char* cmd, char cmds[][32]) {
    if ((NULL == cmd) || (NULL == cmds)) {
        return;
    }
    int32_t i = 0;
    int32_t j = 0;
    int32_t jk = 0;
    while(cmd[i] != '\0') {
        if (' ' == cmd[i]) {
            if (0 != jk) {
                j++;
            }
            jk = 0;
        }
        else {
            cmds[j][jk++] = cmd[i];
        }
        i++;
    }
}

/* type: "l"--long, "ul"--unsigned long, "i"--int, 'ui'--unsigned int, 'd'--double */
int32_t str2num(const char* strnum, const char* type, void* val){
    if(!strnum || strlen(strnum)<1) {
        return -1;
    }
    int base = 10;
    if ((strnum[0] == '0') && ((strnum[1] == 'x') || (strnum[1] == 'X'))) {
        base = 16;
    }
    if (0 == strcmp(type, "l")) {
        *((long*)val) = strtol(strnum, NULL, base);
    }
    else if (0 == strcmp(type, "ul")) {
        *((unsigned long*)val) = strtoul(strnum, NULL, base);
    }
    else if (0 == strcmp(type, "i")) {
        long v = strtol(strnum, NULL, base);
        *(int*)val = (int)v;
    }
    else if (0 == strcmp(type, "ui")) {
        unsigned long v = strtoul(strnum, NULL, base);
        *(unsigned int*)val = (unsigned int)v;
    }
    else if (0 == strcmp(type, "d")) {
        *((double *)val) = strtod(strnum, NULL);
    }
    else {
        return -2;
    }
    return 0;
}

void usage() {
    printf("use [cmd] <op1> <op2> ..., like below\n"
            "\th or ?: print this help\n"
            "\tdevm w [offset] [val]: write dev manager register at offset with val\n"
            "\t\tdevm r [offset]: read dev manager register at offset\n"
            "\tdma w: write dma test\n"
            "\t\tdma r: read dma test\n"
            "\tset mc [flag]: connect mode: 0--open, 1--loopback\n"
            "\t\tset mw [flag]: work mode: 0-normal, 1-K code, 2-data test\n"
            "\t\tset mp [flag]: pre-weight: 0-5\%, 1-20\%\n"
            "\t\tset cp [flag]: select chip 2711, 0-A, 1-B, 2-default()\n"
            "\tq: quit\n");
}

void run() {
    char cmd[256];
    char cmds[5][32];
    int ret = 0;
    usage();
    while(1) {
        memset(cmd, 0, 256);
        memset(cmds, 0, 5*32);
        gets(cmd);
        cmd_split(cmd, cmds);
        if (0 == strcmp(cmds[0], "devm")) {
            struct devm_data_t dd;
            memset(&dd, 0, sizeof(dd));
            if (0 == strcmp(cmds[1], "w")){
                printf("dev mgt writing...\n");
                str2num(cmds[2], "ul", &(dd.reg_off));
                str2num(cmds[3], "ul", &(dd.val));
                ioctl(g_dev_desc.fd, IOCMD_DEVM_SET, &dd);
            }
            else if (0 == strcmp(cmds[1], "r")){
                printf("dev mgt reading...\n");
                str2num(cmds[2], "ul", &(dd.reg_off));
                printf("reg off:%d, fd:%d\n", dd.reg_off, g_dev_desc.fd);
                ret = ioctl(g_dev_desc.fd, IOCMD_DEVM_GET, &dd);
                if (0 != ret) {
                    perror("ioctl DEVM_GET\n");
                }
                printf("devm read val:0x%016lx\n", dd.val);
                // ioctl(g_dev_desc.fd, IOCMD_DEVM_GET, &dd);
            }
            else {
                printf("cmd error\n");
            }
        }
        else if (0 == strcmp(cmds[0], "dma")) {
            if (0 == strcmp(cmds[1], "w")){
                test_dma_tx(&g_dev_desc, &(g_op_desc.dma_conf));
            }
            else if (0 == strcmp(cmds[1], "r")){
                test_dma_rx(&g_dev_desc, &(g_op_desc.dma_conf));
            }
            else {
                printf("cmd error\n");
            }
        }
        else if (0 == strcmp(cmds[0], "set")) {
            uint32_t val = 0;
            str2num(cmds[2], "ui", &val);
            if (0 == strcmp(cmds[1], "mc")){
                g_op_desc.dma_conf.mode_conn = val;
            }
            else if (0 == strcmp(cmds[1], "mw")){
                g_op_desc.dma_conf.mode_work = val;
            }
            else if (0 == strcmp(cmds[1], "mp")){
                g_op_desc.dma_conf.mode_prew = val;
            }
            else if (0 == strcmp(cmds[1], "cp")){
                g_op_desc.dma_conf.chip_sel = val;
            }
            else {
                printf("cmd error\n");
            }
       }
        else if ((0 == strcmp(cmds[0], "?")) || (0 == strcmp(cmds[0], "h"))) {
            usage();
        }
        else if (0 == strcmp(cmds[0], "q")) {
            exit(0);
        }
        else {
            printf("cmd error\n");
        }
    }
}

int main(int argc, char **argv)
{
    memset(&g_dev_desc, 0, sizeof(struct dev_desc));
    memset(&g_op_desc, 0, sizeof(struct op_desc));
    g_dev_desc.map_len = 1024 * 1024;
    if (open_and_map(gc_strdevfile, &g_dev_desc) < 0) {
        printf("open_and_map failed\n");
        exit(-1);
    }
    run();
	return 0;
}
