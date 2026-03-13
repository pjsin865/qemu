## Folders tree
# ├── FreeRTOS
# ├── FreeRTOS-Kernel
# ├── buildroot
# ├── optee
# ├── qemu
# └── temp
## Files
# ├── my_disk_qcow2.img
# ├── my_disk_raw.raw
# ├── run_build_FreeRTOS.sh
# ├── run_buildroot_kbuild.sh
# ├── run_buildroot_menuconfig.sh
# ├── run_create_disk.sh
# ├── run_qemu.sh
# ├── run_qemu_BuildRoot.sh
# ├── run_qemu_FreeRTOS.sh
# └── run_qemu_uboot_kernel.sh

## raw image(PC side)
#   qemu-img create -o size=100M my_disk_raw.raw

# 2GB 크기의 qcow2 형식 디스크 이미지 생성
#   qemu-img create -f qcow2 my_disk_qcow2.img 2G

## hard disk
#   -drive file=./output/images/rootfs.ext4,if=none,id=hd0 \
#   -device virtio-blk-device,drive=hd0 \

## usb xhci emulator (QEMU side)
#   -device qemu-xhci \
#
#   -device usb-ehci \
#   -device usb-host,vendorid=0x1e7d,productid=0xafca \
#   -device usb-host,vendorid=0x046d,productid=0xc53d \

## usb-hub
#   -device usb-hub,bus=usb-bus.0,port=1 \
#   -device usb-hub,bus=usb-bus.0,port=2 \
#   -device usb-hub,bus=usb-bus.0,port=3
#   /sys/bus/usb/drivers/hub/bind

## usb-storage
#   -drive if=none,id=stick,format=raw,file=./my_disk_raw.raw \
#   -device nec-usb-xhci,id=xhci                              \
#   -device usb-storage,bus=xhci.0,drive=stick   

## pcie-storage
#  -drive file=my_disk_qcow2.img,if=none,id=drive0,format=qcow2 \
#  -device virtio-blk-pci,drive=drive0,id=virtio-disk0,bus=pcie.0,addr=04.0

## Ethernet
## QEMU : libslirp 
### sudo apt-get install libslirp-dev
### ./configure 실행 시 --enable-slirp
#   -netdev user,id=eth0  -device virtio-net-device,netdev=eth0 \
#   -netdev user,id=eth1  -device virtio-net-device,netdev=eth1 \
### Kernel
#   $ sudo ip link set eth1 up
#   $ sudo udhcpc -i eth1
#   $ ifconfig


## ATF image
#  -bios ./buildroot/output/images/bl1.bin \

## uboot image
#  -bios ./buildroot/output/images/u-boot.bin \

## kernel image
#  -kernel ./buildroot/output/images/Image \


## Ubuntu Packege : QEMU emulator version 6.2.0
# qemu-system-aarch64
## Github : QEMU emulator version 10.2.50
# ./qemu/build/qemu-system-aarch64
## Buildroot : QEMU emulator version 10.2.50
# ./buildroot/output/build/host-qemu-10.2.0/build/qemu-system-aarch64 \


# ./qemu/build/qemu-system-aarch64 \
   # -kernel ./buildroot/output/images/Image \
   # -M virt,gic-version=3 -smp 4 -m 1024 -cpu cortex-a57 \
   # -no-reboot --nographic \
   # -append "rw root=/dev/vda console=ttyAMA0 loglevel=8 rootwait fsck.repair=yes memtest=1" \
   # -netdev user,id=net0,hostfwd=tcp::5022-:22 \
   # -device virtio-net-device,netdev=net0 \
   # -drive file=./buildroot/output/images/rootfs.ext4,if=none,id=hd0 \
   # -device virtio-blk-device,drive=hd0 \
   # -device qemu-xhci \
   # -device usb-hub,bus=usb-bus.0,port=1 \
   # -device usb-hub,bus=usb-bus.0,port=2 \
   # -device usb-hub,bus=usb-bus.0,port=3 \
   # -device usb-hub,bus=usb-bus.0,port=4


./buildroot/output/build/host-qemu-10.2.0/build/qemu-system-aarch64 \
    -M virt -cpu cortex-a53 -smp 2 -m 1024M \
    -nographic \
    \
    -kernel ./buildroot/output/images/Image \
    -append "rootwait root=/dev/vda console=ttyAMA0" \
    \
    -drive file=./buildroot/output/images/rootfs.ext4,if=none,format=raw,id=hd0 \
    -device virtio-blk-device,drive=hd0  ${EXTRA_ARGS} "$@" \
    \
    -netdev user,id=eth0 -device virtio-net-device,netdev=eth0 \
    -netdev user,id=eth1 -device virtio-net-device,netdev=eth1 \
    \
    -drive file=my_disk_qcow2.img,if=none,id=drive0,format=qcow2 \
    -device virtio-blk-pci,drive=drive0,id=virtio-disk0,bus=pcie.0,addr=04.0

# ./buildroot/output/build/host-qemu-10.2.0/build/qemu-system-aarch64 \
#     -M virt -cpu cortex-a53 -smp 2 -m 1024M \
#     -nographic \
#     \
#     -bios ./buildroot/output/images/bl1.bin \
#     -semihosting-config enable=on,target=native \
#     \
#     -drive file=./buildroot/output/images/rootfs.ext4,if=none,format=raw,id=hd0 \
#     -device virtio-blk-device,drive=hd0  ${EXTRA_ARGS} "$@" \
#     \
#     -netdev user,id=eth0 -device virtio-net-device,netdev=eth0 \
#     -netdev user,id=eth1 -device virtio-net-device,netdev=eth1 \
#     \
#     -drive file=my_disk_qcow2.img,if=none,id=drive0,format=qcow2 \
#     -device virtio-blk-pci,drive=drive0,id=virtio-disk0,bus=pcie.0,addr=04.0
