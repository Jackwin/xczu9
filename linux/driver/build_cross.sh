#!/bin/bash

make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-

cd test_app
aarch64-linux-gnu-gcc fbga_app.c -I.. -o test_app