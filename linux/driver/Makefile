
PROJECT_NAME := fbgadrv
OBJS :=  fbga_drv.o

#set kernel dir
KERNELDIR := /lib/modules/$(shell uname -r)/build

obj-m:=$(PROJECT_NAME).o
$(PROJECT_NAME)-objs += $(OBJS)

KERNELDIR ?= /lib/modules/$(shell uname -r)/build
THIS_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

GIT_VERSION := $(shell $(THIS_DIR)/git-ver.sh 2> /dev/null)
#EXTRA_CFLAGS += -DGIT_VERSION=\"$(strip ${MAJOR_VERSION}).$(strip ${MINOR_VERSION}).$(strip ${MAINTAINANCE_VERSION})-${GIT_VERSION}\"
#EXTRA_CFLAGS += -DFPGA_ZYNQMP_DEVICE=\"$(strip ${FPGA_ZYNQMP_DEVICE})\"

SRC := $(shell pwd)

INCLUDE := -I. 

ifeq ($(DEBUG), 1)
	EXTRA_CFLAGS += -DDEBUG
endif


# following 6 lines are used in cross-compiling env.

# all:
# 	$(MAKE) -C $(KERNEL_SRC) M=$(SRC)

# modules_install:
# 	$(MAKE) -C $(KERNEL_SRC) M=$(SRC) modules_install

# following 3 lines are used in standalone-compiling env.

#KERNEL_SRC = /home/ssd/works/chunjie/workspace/fpga_dev/Fmaker/fmaker/petalinux/alinx_7035/build/tmp/work/plnx_zynq7-xilinx-linux-gnueabi/linux-xlnx/4.14-xilinx-v2018.3+gitAUTOINC+eeab73d120-r0/linux-plnx_zynq7-standard-build/ 
#KERNEL_SRC = ~/work/pt_183_proj/zu5_prj/build/tmp/work/plnx_zynqmp-xilinx-linux/linux-xlnx/4.14-xilinx-v2018.3+gitAUTOINC+eeab73d120-r0/linux-plnx_zynqmp-standard-build/
#KERNEL_SRC = /home/users/qinlei/work/7035/sys_proj/7035/build/tmp/work/plnx_zynq7-xilinx-linux-gnueabi/linux-xlnx/4.14-xilinx-v2018.3+gitAUTOINC+eeab73d120-r0/linux-plnx_zynq7-standard-build
#KERNEL_SRC = /home/users/qinlei/work/pt_183_proj/zu5_prj/build/tmp/work/plnx_zynqmp-xilinx-linux/linux-xlnx/4.14-xilinx-v2018.3+gitAUTOINC+eeab73d120-r0/linux-plnx_zynqmp-standard-build
#KERNEL_SRC = /home/users/peta/workspaces/peta.191/zu5-191/build/tmp/work/plnx_zynqmp-xilinx-linux/linux-xlnx/4.19-xilinx-v2019.1+gitAUTOINC+9811303824-r0/linux-plnx_zynqmp-standard-build
#KERNEL_SRC = /home/users/qinlei/work/pt_191_proj/zu5_2/zu5-191/build/tmp/work/plnx_zynqmp-xilinx-linux/linux-xlnx/4.19-xilinx-v2019.1+git999-r0/linux-xlnx-4.19-xilinx-v2019.1+git999
KERNEL_SRC = /home/users/qinlei/work/ms/zu9_proj/peta_proj/build/tmp/work/plnx_zynqmp-xilinx-linux/linux-xlnx/4.14-xilinx-v2018.3+gitAUTOINC+eeab73d120-r0/linux-plnx_zynqmp-standard-build/

all:
	$(MAKE) -C $(KERNEL_SRC) M=$(SRC)
#	make -C $(KERNELDIR) $(INCLUDE) M=$(PWD) modules

clean:
	rm -f *.o *.ko *.ko.unsigned *.mod.c *.order *.symvers .*.cmd
	rm -f .$(PROJECT_NAME).*
	rm -rf .tmp_versions
