<div align= "center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=auto&height=180&text=Guide%20For%20Qemu%20Env.&animation=scaleIn&fontColor=ffffff&fontSize=60" />
</div>
<div style="text-align: left;"> 
  <h2 style="border-bottom: 1px solid #d8dee4; color: #282d33;"> QEMU </h2>  
  <div style="font-weight: 700; font-size: 15px; text-align: left; color: #282d33;"> 이 페이지는 QEMU 환경과 QEMU 에서 개발용 OS(FreeRTOS, Linux, Etc.)를 부팅 시키는 가이드를 제공합니다. </div> 
</div>
  
  - Ubuntu 22.04  

# 1. QEMU  
  `QEMU는 Buildroot 내 package를 사용하여도 되며, 기본적으로 포함되어 있다.`  

  - Download(later)  
    $ `git clone https://github.com/qemu/qemu.git`

  - Build
    - configure  
      $ `cd qemu`  
      $ `./configure --target-list=aarch64-softmmu --enable-debug --enable-slirp`
      - ensurepip 모듈 error 발생시  
        `sudo apt update`  
        `sudo apt install python3-venv python3-pip python3-tomli`  
        `sudo apt install ninja-build python3-sphinx`

    - make  
      $ `make -j$(nproc)`  

    - Result  
      $ `./build/qemu-system-aarch64 -version`  

          QEMU emulator version 10.2.50 (v10.2.0-1854-g314ff2e07d)  
          Copyright (c) 2003-2026 Fabrice Bellard and the QEMU Project developers

# 2. Buildroot
  - Download(later)  
    $ `git clone https://github.com/buildroot/buildroot.git`  
  
  - Build
    - configure  
      $ `cd buildroot`  
      $ `make qemu_aarch64_virt_defconfig`  
      $ `make menuconfig`  

          -- ATF    --
          Bootloaders  --->  
            [*] ARM Trusted Firmware (ATF)  --->  
                (qemu) ATF platform
                [*]   Build FIP image
                [*]   Build BL31 image  
      
          -- U-Boot --  
          Bootloaders  --->  
              [*] U-Boot  --->  
              (qemu_arm64) Board defconfig  
      
          -- Kernel --  
          Toolchain --->  
            C library (glibc)  --->  
            Custom kernel headers series (6.18.x)  --->  
            [*] Build cross gdb for the host  
                [*]     TUI support  
                Python support (Python 3)  --->  
                [*]     Simulator support  

      $ `make savedefconfig`

    - make  
      $ `make -j$(nproc)`  

# 3. ATF in Buildroot
  - build  
    $ `make arm-trusted-firmware-dirclean`

# 4. U-Boot in Buildroot
  - build  
    $ `make arm-trusted-firmware-dirclean`

# 5. Kernel in Buildroot
  - Kernel config  
    $ `cd buildroot`  
    $ `make linux-menuconfig`

        → Kernel hacking → printk and dmesg options
          CONFIG_PRINTK_TIME

    $ `make linux-savedefconfig`  

  - build  
    $ `make linux-rebuild -j$(nproc)`

# 6. Run
  - Run to QEMU  
    $ `cd buildroot`  
    
        ## Create image
        $ qemu-img create -o size=100M my_disk_raw.raw
        $ qemu-img create -f qcow2 my_disk_qcow2.img

        $ ./output/build/host-qemu-10.2.0/build/qemu-system-aarch64 \
            -M virt -cpu cortex-a53 -smp 2 -m 1024M \
            -nographic \
            \
            -kernel ./output/images/Image \
            -append "rootwait root=/dev/vda console=ttyAMA0" \
            \
            -drive file=./output/images/rootfs.ext4,if=none,format=raw,id=hd0 \
            -device virtio-blk-device,drive=hd0  ${EXTRA_ARGS} "$@" \
            \
            -netdev user,id=eth0 -device virtio-net-device,netdev=eth0 \
            -netdev user,id=eth1 -device virtio-net-device,netdev=eth1 \
            \
            -drive file=my_disk_qcow2.img,if=none,id=drive0,format=qcow2 \
            -device virtio-blk-pci,drive=drive0,id=virtio-disk0,bus=pcie.0,addr=04.0


