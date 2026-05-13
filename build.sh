#!/bin/bash
set -euo pipefail

TOP="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Buildroot ────────────────────────────────────────────────
BUILDROOT_DIR="$TOP/buildroot"
BUILDROOT_REPO_URL="https://github.com/buildroot/buildroot.git"
BUILDROOT_REPO_BRANCH=""   # leave empty for default branch
DEFAULT_DEFCONFIG="qemu_aarch64_virt_defconfig"
PATCH_DIR="$TOP/buildroot_patches"
PARALLEL_JOBS="$(nproc)"

# ── FreeRTOS ─────────────────────────────────────────────────
FREERTOS_REPO="https://github.com/FreeRTOS/FreeRTOS.git"
FREERTOS_DIR="$TOP/FreeRTOS"
FREERTOS_DEMO_DIR="$FREERTOS_DIR/FreeRTOS/Demo/CORTEX_MPS2_QEMU_IAR_GCC/build/gcc"
FREERTOS_IMAGES="$TOP/freertos_images"

# ── QEMU (Linux) ─────────────────────────────────────────────
IMAGES_DIR="$BUILDROOT_DIR/output/images"
BUILDROOT_QEMU="$BUILDROOT_DIR/output/build/host-qemu-10.2.0/build/qemu-system-aarch64"
DISK_IMG="$TOP/my_disk_qcow2.img"

# ─────────────────────────────────────────────────────────────

usage() {
    cat <<EOF
Usage: $0 <target>

Buildroot (aarch64 / ATF + U-Boot + Linux):
  buildroot              Full build
  buildroot-uboot        Rebuild U-Boot only
  buildroot-kernel       Rebuild Linux kernel only
  buildroot-clean        Clean + full build
  buildroot-uboot-clean  Clean + rebuild U-Boot
  buildroot-kernel-clean Clean + rebuild Linux kernel
  menuconfig             Buildroot menuconfig

FreeRTOS (Cortex-M3 / MPS2 AN385):
  freertos               Build FreeRTOS blinky demo

QEMU:
  run-linux              Run QEMU  →  ATF → U-Boot → Linux
  run-freertos           Run QEMU  →  FreeRTOS blinky

Examples:
  $0 buildroot
  $0 buildroot-kernel
  $0 freertos
  $0 run-linux
  $0 run-freertos
EOF
}

# ── Buildroot helpers ─────────────────────────────────────────

_ensure_buildroot() {
    if [ ! -d "$BUILDROOT_DIR" ]; then
        echo "Cloning Buildroot..."
        if [ -n "$BUILDROOT_REPO_BRANCH" ]; then
            git clone --depth 1 --branch "$BUILDROOT_REPO_BRANCH" "$BUILDROOT_REPO_URL" "$BUILDROOT_DIR"
        else
            git clone --depth 1 "$BUILDROOT_REPO_URL" "$BUILDROOT_DIR"
        fi
    fi
}

_apply_patches() {
    [ -d "$PATCH_DIR" ] || return 0
    shopt -s nullglob
    local patches=("$PATCH_DIR"/*.patch)
    shopt -u nullglob
    [ ${#patches[@]} -eq 0 ] && return 0

    for patch in "${patches[@]}"; do
        echo "Applying patch: $(basename "$patch")"
        if git apply --check "$patch" >/dev/null 2>&1; then
            git apply "$patch"
        elif git apply --reverse --check "$patch" >/dev/null 2>&1; then
            echo "  (already applied)"
        else
            echo "ERROR: failed to apply $patch" >&2; exit 1
        fi
    done
}

_apply_defconfig() {
    # Do NOT use .defconfig inside buildroot/ — that file is a 2008-era i686
    # default tracked by the buildroot repo and must not be loaded.
    if [ -n "${BR2_DEFCONFIG:-}" ]; then
        make "$BR2_DEFCONFIG"
    else
        echo "Using defconfig: $DEFAULT_DEFCONFIG"
        make "$DEFAULT_DEFCONFIG"
    fi
}

_buildroot_make() {
    echo "Running: make $*"
    make "$@"
}

_buildroot_setup() {
    _ensure_buildroot
    cd "$BUILDROOT_DIR"
    _apply_patches
    [ -f .config ] || { echo "No .config — configuring..."; _apply_defconfig; }
}

# ── FreeRTOS helpers ──────────────────────────────────────────

_ensure_freertos() {
    if [ ! -d "$FREERTOS_DIR" ]; then
        echo "Cloning FreeRTOS..."
        git clone --depth 1 --recurse-submodules --shallow-submodules \
            "$FREERTOS_REPO" "$FREERTOS_DIR"
    fi
}

# ── QEMU (Linux) helpers ──────────────────────────────────────

_ensure_disk() {
    if [ ! -f "$DISK_IMG" ]; then
        echo "Creating $DISK_IMG (2G)..."
        qemu-img create -f qcow2 "$DISK_IMG" 2G
    fi
}

# ── Targets ───────────────────────────────────────────────────

target_buildroot() {
    _buildroot_setup
    _apply_defconfig
    _buildroot_make -j"$PARALLEL_JOBS"
    cd "$TOP"
    echo "Done. Images: $IMAGES_DIR"
}

target_buildroot_uboot() {
    _buildroot_setup
    _buildroot_make uboot-rebuild -j"$PARALLEL_JOBS"
    cd "$TOP"
    echo "Done. Images: $IMAGES_DIR"
}

target_buildroot_kernel() {
    _buildroot_setup
    _buildroot_make linux-rebuild -j"$PARALLEL_JOBS"
    cd "$TOP"
    echo "Done. Images: $IMAGES_DIR"
}

target_buildroot_clean() {
    _buildroot_setup
    _buildroot_make clean
    _apply_defconfig
    _buildroot_make -j"$PARALLEL_JOBS"
    cd "$TOP"
    echo "Done. Images: $IMAGES_DIR"
}

target_buildroot_uboot_clean() {
    _buildroot_setup
    _buildroot_make uboot-dirclean
    _buildroot_make uboot-rebuild -j"$PARALLEL_JOBS"
    cd "$TOP"
    echo "Done. Images: $IMAGES_DIR"
}

target_buildroot_kernel_clean() {
    _buildroot_setup
    _buildroot_make linux-dirclean
    _buildroot_make linux-rebuild -j"$PARALLEL_JOBS"
    cd "$TOP"
    echo "Done. Images: $IMAGES_DIR"
}

target_menuconfig() {
    _buildroot_setup
    _buildroot_make menuconfig
    cd "$TOP"
}

target_freertos() {
    _ensure_freertos
    make -C "$FREERTOS_DEMO_DIR" clean
    make -C "$FREERTOS_DEMO_DIR" -j"$PARALLEL_JOBS"
    mkdir -p "$FREERTOS_IMAGES"
    cp -v "$FREERTOS_DEMO_DIR/output/RTOSDemo.out" "$FREERTOS_IMAGES/RTOSDemo.out"
    echo "Done. Binary: $FREERTOS_IMAGES/RTOSDemo.out"
}

target_run_linux() {
    if [ ! -f "$BUILDROOT_QEMU" ]; then
        echo "ERROR: QEMU not found at $BUILDROOT_QEMU" >&2
        echo "  Run: $0 buildroot" >&2
        exit 1
    fi
    if [ ! -f "$IMAGES_DIR/bl1.bin" ]; then
        echo "ERROR: images not found in $IMAGES_DIR" >&2
        echo "  Run: $0 buildroot" >&2
        exit 1
    fi

    # ATF semihosting loads bl2.bin, bl31.bin, bl33.bin from CWD
    cd "$IMAGES_DIR"
    ln -sf u-boot.bin bl33.bin
    _ensure_disk

    "$BUILDROOT_QEMU" \
        -M virt,secure=on -cpu cortex-a57 -smp 1 -m 1024M \
        -nographic \
        -bios bl1.bin \
        -semihosting-config enable=on,target=native \
        -kernel Image \
        -append "rootwait root=/dev/vda console=ttyAMA0" \
        -drive file=rootfs.ext4,if=none,format=raw,id=hd0 \
        -device virtio-blk-device,drive=hd0 ${EXTRA_ARGS:-} "$@" \
        -netdev user,id=eth0 -device virtio-net-device,netdev=eth0 \
        -netdev user,id=eth1 -device virtio-net-device,netdev=eth1 \
        -drive file="$DISK_IMG",if=none,id=drive0,format=qcow2 \
        -device virtio-blk-pci,drive=drive0,id=virtio-disk0,bus=pcie.0,addr=04.0
}

target_run_freertos() {
    local axf="$FREERTOS_IMAGES/RTOSDemo.out"
    if [ ! -f "$axf" ]; then
        echo "ERROR: $axf not found." >&2
        echo "  Run: $0 freertos" >&2
        exit 1
    fi

    # Demo: CORTEX_MPS2_QEMU_IAR_GCC (blinky)
    # Output: "Message received from task / software timer"
    qemu-system-arm \
        -machine mps2-an385 \
        -cpu cortex-m3 \
        -monitor none \
        -nographic \
        -serial stdio \
        -kernel "$axf"
}

# ── Dispatch ──────────────────────────────────────────────────

if [ $# -eq 0 ]; then usage; exit 0; fi

case "$1" in
    buildroot)              target_buildroot ;;
    buildroot-uboot)        target_buildroot_uboot ;;
    buildroot-kernel)       target_buildroot_kernel ;;
    buildroot-clean)        target_buildroot_clean ;;
    buildroot-uboot-clean)  target_buildroot_uboot_clean ;;
    buildroot-kernel-clean) target_buildroot_kernel_clean ;;
    menuconfig)             target_menuconfig ;;
    freertos)               target_freertos ;;
    run-linux)              shift; target_run_linux "$@" ;;
    run-freertos)           target_run_freertos ;;
    help|-h|--help)         usage ;;
    *)  echo "ERROR: unknown target '$1'" >&2; usage; exit 1 ;;
esac
