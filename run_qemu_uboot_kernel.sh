#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGES_DIR="${SCRIPT_DIR}/buildroot/output/images"
QEMU="${SCRIPT_DIR}/buildroot/output/build/host-qemu-10.2.0/build/qemu-system-aarch64"
DISK_IMG="${SCRIPT_DIR}/my_disk_qcow2.img"

# ATF semihosting loads bl2.bin, bl31.bin, bl33.bin from CWD.
# bl33.bin must be a symlink to u-boot.bin (created at build time).
cd "${IMAGES_DIR}"
ln -sf u-boot.bin bl33.bin

# Create extra disk image if it does not exist
if [ ! -f "${DISK_IMG}" ]; then
    echo "Creating ${DISK_IMG} (2G)..."
    qemu-img create -f qcow2 "${DISK_IMG}" 2G
fi

"${QEMU}" \
    -M virt,secure=on -cpu cortex-a57 -smp 1 -m 1024M \
    -nographic \
    \
    -bios bl1.bin \
    -semihosting-config enable=on,target=native \
    \
    -kernel Image \
    -append "rootwait root=/dev/vda console=ttyAMA0" \
    \
    -drive file=rootfs.ext4,if=none,format=raw,id=hd0 \
    -device virtio-blk-device,drive=hd0 ${EXTRA_ARGS} "$@" \
    \
    -netdev user,id=eth0 -device virtio-net-device,netdev=eth0 \
    -netdev user,id=eth1 -device virtio-net-device,netdev=eth1 \
    \
    -drive file="${DISK_IMG}",if=none,id=drive0,format=qcow2 \
    -device virtio-blk-pci,drive=drive0,id=virtio-disk0,bus=pcie.0,addr=04.0
