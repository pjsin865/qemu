
### buildroot defconfig
# make qemu_aarch64_virt_defconfig

### buildroot menuconfig
# make menuconfig
# make savedefconfig


### ATF Config
# Bootloaders --->
#   [*] ARM Trusted Firmware (ATF) 체크
#   ARM Trusted Firmware Version (기본값 사용 또는 v2.11 이상 권장)
#   Platform : qemu 입력
#   Target Board : (비워둠, 기본값 사용)
#   Build options : BL32 (Secure Payload) 사용 시 선택 (예: OP-TEE)
#   Additional make options : PLAT=qemu


### uboot defconfig
### qemu_arm64_defconfig
### u-boot/configs/qemu_arm64_defconfig

### uboot menuconfig
# make uboot-menuconfig
# make uboot-savedefconfig


### Kernel config
# make linux-menuconfig
# make linux-savedefconfig




