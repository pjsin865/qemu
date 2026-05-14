#!/bin/bash
set -euo pipefail

TOP="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Docker wrapper ────────────────────────────────────────────

DOCKER_IMAGE="qemu-dev:latest"

_in_docker() { [ -f /.dockerenv ]; }

if ! _in_docker; then
    # shellcheck source=scripts/docker_lib.sh
    source "$TOP/scripts/docker_lib.sh"
    _ensure_docker   # installs Docker if missing, sets DOCKER_CMD

    if ! $DOCKER_CMD image inspect "$DOCKER_IMAGE" >/dev/null 2>&1; then
        echo "ERROR: Docker image '$DOCKER_IMAGE' not found. Run ./build.sh first." >&2
        exit 1
    fi
    # -it: allocate TTY for interactive QEMU serial console
    # Mount at same absolute path as host (keeps buildroot hardcoded paths valid)
    exec $DOCKER_CMD run --rm -it \
        -v "$TOP:$TOP" \
        -w "$TOP" \
        "$DOCKER_IMAGE" \
        ./run.sh "$@"
fi

# ── 경로 설정 ─────────────────────────────────────────────────
IMAGES_DIR="$TOP/buildroot/output/images"
BUILDROOT_QEMU="$TOP/buildroot/output/build/host-qemu-10.2.0/build/qemu-system-aarch64"
DISK_QCOW2="$TOP/my_disk_qcow2.img"
DISK_RAW="$TOP/my_disk_raw.raw"
FREERTOS_BIN="$TOP/freertos_images/RTOSDemo.out"
ZEPHYR_BIN="$TOP/zephyr_images/zephyr.elf"
BUILDROOT_RISCV_IMAGES="$TOP/buildroot_riscv_output/images"

# ─────────────────────────────────────────────────────────────

usage() {
    cat <<EOF
Usage: $0 <target> [options]

Targets:
  linux              ATF → U-Boot → Linux (aarch64 / Cortex-A57)
  linux-riscv        OpenSBI → Linux (riscv64 / QEMU virt)
  freertos           FreeRTOS CLI shell (Cortex-M3 / MPS2 AN385)
  zephyr             Zephyr Shell (Cortex-M3 / MPS2 AN385)

Linux options:
  --smp N            vCPU 수 (기본: 1)
  --mem M            메모리 크기 (기본: 1024M)
  --no-net           네트워크 비활성화 (기본: 활성화)
  --no-pcie-disk     PCIe 추가 디스크 비활성화 (기본: 활성화)
  --usb-storage      USB xHCI + USB storage 추가 (raw 이미지)
  --gdb              GDB 서버 활성화 (:1234, 연결 대기)

FreeRTOS options:
  --gdb              GDB 서버 활성화 (:1234, 연결 대기)

Zephyr options:
  --gdb              GDB 서버 활성화 (:1234, 연결 대기)

RISC-V options:
  --smp N            vCPU 수 (기본: 1)
  --mem M            메모리 크기 (기본: 512M)
  --no-net           네트워크 비활성화
  --gdb              GDB 서버 활성화 (:1234, 연결 대기)

Examples:
  $0 linux
  $0 linux --smp 2 --mem 2048M
  $0 linux --usb-storage
  $0 linux --gdb
  $0 linux-riscv
  $0 linux-riscv --smp 2 --mem 1024M
  $0 freertos
  $0 freertos --gdb
  $0 zephyr
  $0 zephyr --gdb
EOF
}

# ── 공통 유틸 ─────────────────────────────────────────────────

_ensure_qcow2() {
    if [ ! -f "$DISK_QCOW2" ]; then
        echo "Creating $DISK_QCOW2 (2G)..."
        qemu-img create -f qcow2 "$DISK_QCOW2" 2G
    fi
}

_ensure_raw() {
    if [ ! -f "$DISK_RAW" ]; then
        echo "Creating $DISK_RAW (512M)..."
        qemu-img create -f raw "$DISK_RAW" 512M
    fi
}

# ── linux ─────────────────────────────────────────────────────

run_linux() {
    # ── 기본값 ──
    local smp=1
    local mem="1024M"
    local opt_net=true
    local opt_pcie_disk=true
    local opt_usb_storage=false
    local opt_gdb=false

    # ── 옵션 파싱 ──
    while [ $# -gt 0 ]; do
        case "$1" in
            --smp)         smp="$2";    shift 2 ;;
            --mem)         mem="$2";    shift 2 ;;
            --no-net)      opt_net=false;       shift ;;
            --no-pcie-disk) opt_pcie_disk=false; shift ;;
            --usb-storage) opt_usb_storage=true; shift ;;
            --gdb)         opt_gdb=true;         shift ;;
            *) echo "ERROR: unknown option '$1'" >&2; usage; exit 1 ;;
        esac
    done

    # ── 사전 확인 ──
    if [ ! -f "$BUILDROOT_QEMU" ]; then
        BUILDROOT_QEMU="$(command -v qemu-system-aarch64 2>/dev/null || true)"
        if [ -z "$BUILDROOT_QEMU" ]; then
            echo "ERROR: qemu-system-aarch64 not found." >&2
            echo "  → ./build.sh buildroot" >&2; exit 1
        fi
        echo "Note: using system qemu-system-aarch64 (Buildroot QEMU not found)"
    fi
    if [ ! -f "$IMAGES_DIR/bl1.bin" ]; then
        echo "ERROR: images not found in $IMAGES_DIR" >&2
        echo "  → ./build.sh buildroot" >&2; exit 1
    fi

    # ATF semihosting이 CWD에서 bl2.bin, bl31.bin, bl33.bin 로드
    cd "$IMAGES_DIR"
    ln -sf u-boot.bin bl33.bin

    # ── QEMU 인수 조립 ──
    local args=(
        -M virt,secure=on -cpu cortex-a57
        -smp "$smp"
        -m "$mem"
        -nographic

        # ATF 부팅 체인
        -bios bl1.bin
        -semihosting-config enable=on,target=native

        # Linux 커널 + rootfs
        -kernel Image
        -append "rootwait root=/dev/vda console=ttyAMA0"
        -drive file=rootfs.ext4,if=none,format=raw,id=hd0
        -device virtio-blk-device,drive=hd0
    )

    # ── 옵션별 장치 추가 ──

    if $opt_net; then
        args+=(
            -netdev user,id=eth0 -device virtio-net-device,netdev=eth0
            -netdev user,id=eth1 -device virtio-net-device,netdev=eth1
        )
    fi

    if $opt_pcie_disk; then
        _ensure_qcow2
        args+=(
            -drive file="$DISK_QCOW2",if=none,id=drive0,format=qcow2
            -device virtio-blk-pci,drive=drive0,id=virtio-disk0,bus=pcie.0,addr=04.0
        )
    fi

    if $opt_usb_storage; then
        _ensure_raw
        args+=(
            -device qemu-xhci,id=xhci
            -drive if=none,id=usb-stick,format=raw,file="$DISK_RAW"
            -device usb-storage,bus=xhci.0,drive=usb-stick
        )
    fi

    if $opt_gdb; then
        echo "GDB 서버 대기 중... (arm-none-eabi-gdb 또는 gdb-multiarch로 :1234 연결)"
        args+=(-s -S)
    fi

    echo "Starting QEMU (Linux): smp=$smp mem=$mem net=$opt_net pcie-disk=$opt_pcie_disk usb=$opt_usb_storage gdb=$opt_gdb"
    "$BUILDROOT_QEMU" "${args[@]}" ${EXTRA_ARGS:-}
}

# ── freertos ──────────────────────────────────────────────────

run_freertos() {
    local opt_gdb=false

    while [ $# -gt 0 ]; do
        case "$1" in
            --gdb) opt_gdb=true; shift ;;
            *) echo "ERROR: unknown option '$1'" >&2; usage; exit 1 ;;
        esac
    done

    if [ ! -f "$FREERTOS_BIN" ]; then
        echo "ERROR: binary not found: $FREERTOS_BIN" >&2
        echo "  → ./build.sh freertos" >&2; exit 1
    fi

    local args=(
        -machine mps2-an385
        -cpu cortex-m3
        -monitor none
        -nographic
        -serial stdio
        -kernel "$FREERTOS_BIN"
    )

    if $opt_gdb; then
        echo "GDB 서버 대기 중... (arm-none-eabi-gdb로 :1234 연결)"
        args+=(-s -S)
    fi

    echo "Starting QEMU (FreeRTOS): gdb=$opt_gdb"
    qemu-system-arm "${args[@]}"
}

# ── linux-riscv ──────────────────────────────────────────────

run_linux_riscv() {
    local smp=1
    local mem="512M"
    local opt_net=true
    local opt_gdb=false

    while [ $# -gt 0 ]; do
        case "$1" in
            --smp)    smp="$2";       shift 2 ;;
            --mem)    mem="$2";       shift 2 ;;
            --no-net) opt_net=false;  shift ;;
            --gdb)    opt_gdb=true;   shift ;;
            *) echo "ERROR: unknown option '$1'" >&2; usage; exit 1 ;;
        esac
    done

    # QEMU: Buildroot-built 우선, 없으면 시스템 QEMU
    local RISCV_QEMU
    RISCV_QEMU="$(ls "$BUILDROOT_RISCV_IMAGES/../host/bin/qemu-system-riscv64" 2>/dev/null || true)"
    [ -z "$RISCV_QEMU" ] && RISCV_QEMU="$(command -v qemu-system-riscv64 2>/dev/null || true)"
    if [ -z "$RISCV_QEMU" ]; then
        echo "ERROR: qemu-system-riscv64 not found." >&2
        echo "  → ./build.sh buildroot-riscv" >&2; exit 1
    fi

    if [ ! -f "$BUILDROOT_RISCV_IMAGES/Image" ]; then
        echo "ERROR: images not found in $BUILDROOT_RISCV_IMAGES" >&2
        echo "  → ./build.sh buildroot-riscv" >&2; exit 1
    fi

    cd "$BUILDROOT_RISCV_IMAGES"

    # rootfs: ext2 또는 ext4
    local rootfs=""
    for f in rootfs.ext2 rootfs.ext4; do
        [ -f "$f" ] && rootfs="$f" && break
    done
    if [ -z "$rootfs" ]; then
        echo "ERROR: rootfs not found in $BUILDROOT_RISCV_IMAGES" >&2; exit 1
    fi

    local args=(
        -M virt
        -nographic
        -smp "$smp"
        -m "$mem"
        -kernel Image
        -append "rootwait root=/dev/vda ro"
        -drive file="$rootfs",if=none,format=raw,id=hd0
        -device virtio-blk-device,drive=hd0
    )

    # OpenSBI (fw_jump.elf 존재 시)
    [ -f fw_jump.elf ] && args+=(-bios fw_jump.elf)

    if $opt_net; then
        args+=(-netdev user,id=eth0 -device virtio-net-device,netdev=eth0)
    fi

    if $opt_gdb; then
        echo "GDB 서버 대기 중... (riscv64-unknown-elf-gdb 또는 gdb-multiarch로 :1234 연결)"
        args+=(-s -S)
    fi

    echo "Starting QEMU (Linux RISC-V): smp=$smp mem=$mem net=$opt_net gdb=$opt_gdb"
    "$RISCV_QEMU" "${args[@]}"
}

# ── zephyr ───────────────────────────────────────────────────

run_zephyr() {
    local opt_gdb=false

    while [ $# -gt 0 ]; do
        case "$1" in
            --gdb) opt_gdb=true; shift ;;
            *) echo "ERROR: unknown option '$1'" >&2; usage; exit 1 ;;
        esac
    done

    if [ ! -f "$ZEPHYR_BIN" ]; then
        echo "ERROR: binary not found: $ZEPHYR_BIN" >&2
        echo "  → ./build.sh zephyr" >&2; exit 1
    fi

    local args=(
        -machine mps2-an385
        -cpu cortex-m3
        -monitor none
        -nographic
        -serial stdio
        -kernel "$ZEPHYR_BIN"
    )

    if $opt_gdb; then
        echo "GDB 서버 대기 중... (arm-none-eabi-gdb로 :1234 연결)"
        args+=(-s -S)
    fi

    echo "Starting QEMU (Zephyr): gdb=$opt_gdb"
    qemu-system-arm "${args[@]}"
}

# ── Dispatch ──────────────────────────────────────────────────

if [ $# -eq 0 ]; then usage; exit 0; fi

target="$1"; shift
case "$target" in
    linux)       run_linux       "$@" ;;
    linux-riscv) run_linux_riscv "$@" ;;
    freertos)    run_freertos    "$@" ;;
    zephyr)      run_zephyr      "$@" ;;
    help|-h|--help) usage ;;
    *) echo "ERROR: unknown target '$target'" >&2; usage; exit 1 ;;
esac
