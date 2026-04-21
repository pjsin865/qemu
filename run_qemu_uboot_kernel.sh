qemu-system-aarch64 \
    -M virt \
    -cpu cortex-a53 \
    -m 1024M \
    -nographic \
    -bios output/images/u-boot.bin \
    -kernel output/images/Image \
    -append "root=/dev/vda console=ttyAMA0" \
    -drive file=output/images/rootfs.ext4,format=raw,if=virtio

