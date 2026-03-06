<div align= "center">
<img src="https://capsule-render.vercel.app/api?type=waving&color=auto&height=180&text=Guide%20For%20Qemu%20Env.&animation=scaleIn&fontColor=ffffff&fontSize=60" />
</div>
<div style="text-align: left;"> 
<h2 style="border-bottom: 1px solid #d8dee4; color: #282d33;"> QEMU </h2>  
<div style="font-weight: 700; font-size: 15px; text-align: left; color: #282d33;"> 이 페이지는 QEMU 환경과 QEMU 에서 개발용 OS(FreeRTOS, Linux, Etc.)를 부팅 시키는 가이드를 제공합니다. </div> 
</div>
  
# 1. QEMU
  - Download(later)  
    $ `git clone https://github.com/qemu/qemu.git`

  - Build
    - configure  
      $ `cd qemu`  
      $ `./configure --target-list=aarch64-softmmu --enable-debug`
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

# 3. Kernel
  - Kernel config  
    $ `make linux-menuconfig`  

    $ `make linux-savedefconfig`  

  - build  
    $ `make linux`  
    
