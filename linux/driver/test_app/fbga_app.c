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
    struct data_config_t dma_conf;
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

    devd->map_data = mmap(0, devd->map_len, PROT_READ, MAP_SHARED, devd->fd, 0); 
    if (MAP_FAILED == devd->map_data) {
        printf("map failed!\n");
		return -2;
    }
    return 0;
}

int test_op(struct dev_desc* devd, struct op_desc* opd) {
    printf("test devm\n");
    if (opd->op_type == DEVM_R) {
        fcntl(devd->fd, IOCMD_DEVM_GET, &(opd->dd));
        printf("devm read off:%d, val:0x%08x\n", opd->dd.reg_off, opd->dd.val);
    }
    else if (opd->op_type == DEVM_W) {
        fcntl(devd->fd, IOCMD_DEVM_GET, &(opd->dd));
        printf("devm write off:%d, val:0x%08x\n", opd->dd.reg_off, opd->dd.val);

    }
    else if (opd->op_type == DMA_R) {
        fcntl(devd->fd, IOCMD_DMA_CONFIGTX, &(opd->dma_conf));
        printf("dma tx\n");
    }
    else if (opd->op_type == DMA_W) {
        fcntl(devd->fd, IOCMD_DMA_CONFIGRX, &(opd->dma_conf));
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
        if (0 == fcntl(devd->fd, IOCMD_DEVM_GET, &dd)) {
            printf("devm read offset:%ld done: 0x%016lx\n", dd.reg_off, dd.val);
        }
        else {
            printf("devm read error\n");
            return -1;
        }
    }
    else if (type == 1) {
        if (0 == fcntl(devd->fd, IOCMD_DEVM_SET, &dd)) {
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

int test_dma_rx(struct dev_desc* devd) {
    struct data_config_t dc;
    dc.addr_off = 0;
    int32_t dlen = fcntl(devd->fd, IOCMD_DMA_CONFIGRX, &dc);
    if (dlen < 0) {
        printf("dma rx faild, return:%d,stat:0x%x,\n", dlen, dc.status);
        return -1;
    }
    printf("dma rx len: %d, status:0x%x\n", dlen, dc.status);
    dlen = (dlen > 32) ? 32 : dlen;
    dump_mem(devd->map_data, dlen);
    return 0;
}

int test_dma_tx(struct dev_desc* devd) {
    struct data_config_t dc;
	uint8_t val[16]={0x1,0x2,0x3,0x4,0x5,0x6,0x7,0x8,0x9,0xa,0xb,0xc,0xd,0xe,0xf,0x0};
    memcpy((uint8_t*)(devd->map_data), val, 16);
    dc.addr_off = 0;
    dc.data_len = 16;
    if (0 != fcntl(devd->fd, IOCMD_DMA_CONFIGRX, &dc)) {
        printf("dma tx faild\n");
        return -1;
    }
    printf("dma tx done, len: %d", dc.data_len);
    return 0;
}

void usage() {
    printf("use [cmd] <op1> <op2> ..., like below\n"
            "\th or ?: print this help\n"
            "\tdevm w [offset] [val]: write dev manager register at offset with val\n"
            "\tdevm r [offset]: read dev manager register at offset\n"
            "\tdma w: write dma test\n"
            "\tdma r: read dma test\n"
            "\tq: quit\n");
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

void run() {
    char cmd[256];
    char cmds[5][32];
    usage();
    while(1) {
        memset(cmd, 0, 256);
        memset(cmds, 0, 5*32);
        gets(cmd);
        cmd_split(cmd, cmds);
        if (0 == strcmp(cmds[0], "devm")) {
            struct devm_data_t dd;
            if (0 == strcmp(cmds[1], "w")){
                dd.reg_off = atol(cmd[2]);
                dd.val = atol(cmd[3]);
                fcntl(g_dev_desc.fd, IOCMD_DEVM_SET, &dd);
            }
            else if (0 == strcmp(cmds[1], "r")){
                dd.reg_off = atol(cmd[2]);
                fcntl(g_dev_desc.fd, IOCMD_DEVM_GET, &dd);
                printf("devm read val:0x%016x\n", dd.val);
            }
            else {
                printf("cmd error\n");
            }
        }
        else if (0 == strcmp(cmds[0], "dma")) {
            if (0 == strcmp(cmds[1], "w")){
                test_dma_tx(&g_dev_desc);
            }
            else if (0 == strcmp(cmds[1], "r")){
                test_dma_rx(&g_dev_desc);
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
    if (open_and_map(gc_strdevfile, &g_dev_desc) < 0) {
        printf("open_and_map failed\n");
        exit(-1);
    }
    run();
	return 0;
}
