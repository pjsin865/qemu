#!/bin/bash

TOP=`pwd`

cd buildroot

## buildroot build
# make -j$(nproc)

## uboot build in Buildroot
# make uboot-rebuild -j$(nproc)

## Kernel build in Buildroot
make linux-rebuild -j$(nproc)

cd $TOP


