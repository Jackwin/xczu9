#!/bin/bash

#-------------------------------------------------------------------------------
#Setup Loopback test
#-------------------------------------------------------------------------------

loopback_test() {
  # Soft reset
  busybox devmem 0xb0000104 32 0x0

  busybox devmem 0xb0000030 32 0x0
  # set Loop-back mode
  busybox devmem 0xb0000034 32 0xa0000000
  # Start
 busybox devmem 0xb000000c 32 0x00000000
}


#-------------------------------------------------------------------------------
#Setup K-code test
#-------------------------------------------------------------------------------
Kcode_test() {
  # Soft reset
  busybox devmem 0xb0000104 32 0x0

  busybox devmem 0xb0000030 32 0x0
  # set K-code mode
  busybox devmem 0xb0000034 32 0x10000000
  # Start
  busybox devmem 0xb000000c 32 0x00000000
}

#-------------------------------------------------------------------------------
#Setup data test
#-------------------------------------------------------------------------------
data_test() {
  # Soft reset
  busybox devmem 0xb0000104 32 0x0

  busybox devmem 0xb0000030 32 0x0
  # set K-code mode
  busybox devmem 0xb0000034 32 0x20000000
  # Start
  busybox devmem 0xb000000c 32 0x00000000
}

usage() {
    echo -e "----------------------Uage---------------------
    \t./tlk2711.sh loopback-test : Internal chip data test
    \t./tlk2711.sh kcode-test : Tx sends K-code
    \t./tlk2711.sh data-test  : Tx sends test data
    -------------------------------------------------------"
}


if [ $# -ne 1 ]; then
    usage
    exit 1
fi

if [ "$1" == "loopback-test" ]; then
    loopback_test
elif [ "$1" == "kcode-test" ]; then
    Kcode_test
elif [ "$1" == "data-test" ]; then
    data_test
else
    echo "bad args."
    usage
    exit 2
fi

