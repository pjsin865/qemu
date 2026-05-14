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
    # ARM bare-metal toolchain (FreeRTOS / Zephyr)
    gcc-arm-none-eabi binutils-arm-none-eabi libnewlib-arm-none-eabi \
    # QEMU
    qemu-system-arm qemu-system-aarch64 qemu-system-misc \
    # Python venv (for Zephyr west workspace)
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
