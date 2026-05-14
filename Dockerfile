FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core build tools
    build-essential g++ make cmake ninja-build \
    # Source / download
    git wget curl ca-certificates \
    # Buildroot dependencies
    python3 python3-pip \
    cpio rsync bc file \
    libssl-dev libncurses-dev libelf-dev \
    bison flex unzip patch xz-utils \
    # ARM bare-metal toolchain (FreeRTOS / Zephyr ARM)
    gcc-arm-none-eabi binutils-arm-none-eabi libnewlib-arm-none-eabi \
    # QEMU
    qemu-system-arm qemu-system-aarch64 qemu-system-misc \
    # Python venv (for Zephyr west workspace)
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# RISC-V bare-metal toolchain: xPack GCC 14.x (Ubuntu 22.04 apt ships GCC 10
# which does not support rv64imac_zicsr_zifencei required by Zephyr 4.x)
RUN XPACK_VER="14.2.0-2" && \
    XPACK_DIR="xpack-riscv-none-elf-gcc-${XPACK_VER}" && \
    wget -q -O /tmp/riscv-gcc.tar.gz \
        "https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/download/v${XPACK_VER}/${XPACK_DIR}-linux-x64.tar.gz" && \
    tar -xf /tmp/riscv-gcc.tar.gz -C /opt/ && \
    rm /tmp/riscv-gcc.tar.gz
ENV PATH="/opt/xpack-riscv-none-elf-gcc-14.2.0-2/bin:${PATH}"

WORKDIR /workspace
