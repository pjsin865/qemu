#!/bin/bash

TOP=`pwd`

# CORTEX_MPU_M3_MPS2_QEMU_GCC
Target=CORTEX_MPU_M3_MPS2_QEMU_GCC

DemoTargetDir=FreeRTOS/FreeRTOS/Demo/$Target

cd $DemoTargetDir
#make clean; make -j8
cd $TOP

Result_Dir=$DemoTargetDir/build

if [ ! -d run_image ] ; then
	mkdir run_image
fi
#cp -v $Result_Dir/RTOSDemo.axf run_image/RTOSDemo_$Target.axf





