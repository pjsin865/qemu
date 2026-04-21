qemu-system-aarch64 \
    -M virt \
    -cpu cortex-a53 \
    -m 1024M \
    -nographic \
    -bios ./buildroot/output/images/u-boot.bin \
    -kernel ./buildroot/output/images/Image \
    -append "root=/dev/vda console=ttyAMA0" \
    -drive file=./buildroot/output/images/rootfs.ext4,format=raw,if=virtio

