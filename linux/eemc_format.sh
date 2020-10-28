#!/bin/sh

EMMC_P1_PATH=/media/emmc_p1
EMMC_P2_PATH=/media/emmc_p2

if [ ! -d $EMMC_P1_PATH ] then mkdir $EMMC_P1_PATH fi
if [ ! -d $EMMC_P2_PATH ] then mkdir $EMMC_P2_PATH fi

mount /dev/mmcblk0p1 $EMMC_P1_PATH 
ret=$? 
if [ $ret -ne 0 ]; then 
    echo "Start format /dev/mmcblk0" 
    dd if=/dev/zero of=/dev/mmcblk0 bs=512 count=1
    sync
    echo "format finished!" 
    echo "Step1:Parting the disks..." 
    fdisk /dev/mmcblk0 <<EOF
    n
    p
    1
    +1024M
    n
    p
    2
    wq
EOF

    partprobe &> /dev/null
    echo "Part finished!"
    echo "Step2:Formating disks..."
    mkfs.vfat /dev/mmcblk0p1 &> /dev/null 
    mkfs.ext4 /dev/mmcblk0p2 &> /dev/null
    echo "Format finished!"
    mount /dev/mmcblk0p1 $EMMC_P1_PAT
    mount /dev/mmcblk0p2 $EMMC_P2_PATH
else 
    mount /dev/mmcblk0p2 $EMMC_P2_PATH 
fi