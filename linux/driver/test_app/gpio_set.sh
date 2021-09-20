#!/bin/bash

GPIO_EN_BRAMW=1020
GPIO_EN_DATAMOVER=1021
GPIO_SET_INT=1022


gpio_init() {
    if [ ! -d /sys/class/gpio/gpio${GPIO_EN_BRAMW} ]; then
        echo $GPIO_EN_BRAMW > /sys/class/gpio/export
        echo "out" > /sys/class/gpio/gpio${GPIO_EN_BRAMW}/direction
    fi

    if [ ! -d /sys/class/gpio/gpio${GPIO_EN_DATAMOVER} ]; then
        echo $GPIO_EN_DATAMOVER > /sys/class/gpio/export
        echo "out" > /sys/class/gpio/gpio${GPIO_EN_DATAMOVER}/direction
    fi

    if [ ! -d /sys/class/gpio/gpio${GPIO_SET_INT} ]; then
        echo $GPIO_SET_INT > /sys/class/gpio/export
        echo "out" > /sys/class/gpio/gpio${GPIO_SET_INT}/direction
    fi
}

gpio_set_int() {
    echo 0 > /sys/class/gpio/gpio${GPIO_SET_INT}/value
    echo 1 > /sys/class/gpio/gpio${GPIO_SET_INT}/value
}

gpio_start_datamover() {
    echo 0 > /sys/class/gpio/gpio${GPIO_EN_DATAMOVER}/value
    echo 1 > /sys/class/gpio/gpio${GPIO_EN_DATAMOVER}/value
}

gpio_en_bramw() {
    echo 0 > /sys/class/gpio/gpio${GPIO_EN_BRAMW}/value
    echo 1 > /sys/class/gpio/gpio${GPIO_EN_BRAMW}/value
}

usage() {
    echo -e "-----------------
\t./gpio_set.sh int : triger interupt for debug
\t./gpio_set.sh brw : enable write to bram from fpga
\t./gpio_set.sh dm  : start once data mover
-----------------"
}

if [ $# -ne 1 ]; then
    usage
    exit 1
fi

gpio_init
if [ "$1" == "int" ]; then
    gpio_set_int
elif [ "$1" == "brw" ]; then
    gpio_en_bramw
elif [ "$1" == "dm" ]; then
    gpio_start_datamover
else
    echo "bad args."
    usage
    exit 2
fi





