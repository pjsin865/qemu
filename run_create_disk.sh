## raw image(PC side)
#   qemu-img create -o size=100M my_disk_raw.raw

## usb-storage
#   -drive if=none,id=stick,format=raw,file=./my_disk_raw.raw \
#   -device nec-usb-xhci,id=xhci                              \
#   -device usb-storage,bus=xhci.0,drive=stick   



## 2GB 크기의 qcow2 형식 디스크 이미지 생성
#   qemu-img create -f qcow2 my_disk_qcow2.img 2G

## pcie-storage
#  -drive file=my_disk_qcow2.img,if=none,id=drive0,format=qcow2 \
#  -device virtio-blk-pci,drive=drive0,id=virtio-disk0,bus=pcie.0,addr=04.0


