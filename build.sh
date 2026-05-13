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

QEMU 실행은 run.sh 를 사용하세요:
  ./run.sh linux
  ./run.sh freertos

Examples:
  $0 buildroot
  $0 buildroot-kernel
  $0 freertos
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

# ── Targets ───────────────────────────────────────────────────

target_buildroot() {
    _buildroot_setup
    _apply_defconfig
    _buildroot_make -j"$PARALLEL_JOBS"
    cd "$TOP"
    echo "Done. Images: $BUILDROOT_DIR/output/images"
}

target_buildroot_uboot() {
    _buildroot_setup
    _buildroot_make uboot-rebuild -j"$PARALLEL_JOBS"
    cd "$TOP"
    echo "Done. Images: $BUILDROOT_DIR/output/images"
}

target_buildroot_kernel() {
    _buildroot_setup
    _buildroot_make linux-rebuild -j"$PARALLEL_JOBS"
    cd "$TOP"
    echo "Done. Images: $BUILDROOT_DIR/output/images"
}

target_buildroot_clean() {
    _buildroot_setup
    _buildroot_make clean
    _apply_defconfig
    _buildroot_make -j"$PARALLEL_JOBS"
    cd "$TOP"
    echo "Done. Images: $BUILDROOT_DIR/output/images"
}

target_buildroot_uboot_clean() {
    _buildroot_setup
    _buildroot_make uboot-dirclean
    _buildroot_make uboot-rebuild -j"$PARALLEL_JOBS"
    cd "$TOP"
    echo "Done. Images: $BUILDROOT_DIR/output/images"
}

target_buildroot_kernel_clean() {
    _buildroot_setup
    _buildroot_make linux-dirclean
    _buildroot_make linux-rebuild -j"$PARALLEL_JOBS"
    cd "$TOP"
    echo "Done. Images: $BUILDROOT_DIR/output/images"
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
    help|-h|--help)         usage ;;
    *)  echo "ERROR: unknown target '$1'" >&2; usage; exit 1 ;;
esac
