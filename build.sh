#!/bin/bash
set -euo pipefail

TOP="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Docker wrapper ────────────────────────────────────────────
# On the host: ensure Docker is installed (auto-install if missing),
# build the image on first run, then re-exec inside the container.
# Inside Docker (/.dockerenv present): skip wrapper, build directly.

DOCKER_IMAGE="qemu-dev:latest"
DOCKER_DL_CACHE="$TOP/.docker-dl"

_in_docker() { [ -f /.dockerenv ]; }

if ! _in_docker; then
    # shellcheck source=scripts/docker_lib.sh
    source "$TOP/scripts/docker_lib.sh"
    _ensure_docker   # installs Docker if missing, sets DOCKER_CMD

    if ! $DOCKER_CMD image inspect "$DOCKER_IMAGE" >/dev/null 2>&1; then
        echo "==> Building Docker image '$DOCKER_IMAGE' (first run only, ~3 min)..."
        $DOCKER_CMD build -t "$DOCKER_IMAGE" "$TOP"
    fi

    mkdir -p "$DOCKER_DL_CACHE"

    # Mount at the same absolute path as the host so that any hardcoded
    # paths baked into buildroot host-tool scripts (e.g. fakeroot) remain valid.
    exec $DOCKER_CMD run --rm \
        -v "$TOP:$TOP" \
        -v "$DOCKER_DL_CACHE:/dl" \
        -e BR2_DL_DIR=/dl \
        -w "$TOP" \
        "$DOCKER_IMAGE" \
        ./build.sh "$@"
fi

# ── Buildroot (aarch64) ──────────────────────────────────────
BUILDROOT_DIR="$TOP/buildroot"
BUILDROOT_REPO_URL="https://github.com/buildroot/buildroot.git"
BUILDROOT_REPO_BRANCH=""   # leave empty for default branch
DEFAULT_DEFCONFIG="qemu_aarch64_virt_defconfig"
PATCH_DIR="$TOP/buildroot_patches"
PARALLEL_JOBS="$(nproc)"

# ── Buildroot (RISC-V) ───────────────────────────────────────
BUILDROOT_RISCV_OUTPUT="$TOP/buildroot_riscv_output"
BUILDROOT_RISCV_DEFCONFIG="qemu_riscv64_virt_defconfig"

# ── FreeRTOS ─────────────────────────────────────────────────
FREERTOS_REPO="https://github.com/FreeRTOS/FreeRTOS.git"
FREERTOS_DIR="$TOP/FreeRTOS"
FREERTOS_CLI_DIR="$TOP/freertos_cli"
FREERTOS_IMAGES="$TOP/freertos_images"
FREERTOS_RISCV_CLI_DIR="$TOP/freertos_riscv_cli"
FREERTOS_RISCV_IMAGES="$TOP/freertos_riscv_images"

# ── Zephyr ───────────────────────────────────────────────────
ZEPHYR_DIR="$TOP/zephyr_workspace"
ZEPHYR_IMAGES="$TOP/zephyr_images"
ZEPHYR_VENV="$TOP/.zephyr-venv"
ZEPHYR_VERSION="v4.1.0"
ZEPHYR_BOARD="mps2/an385"
ZEPHYR_RISCV_BOARD="qemu_riscv64"
ZEPHYR_RISCV_IMAGES="$TOP/zephyr_riscv_images"
ZEPHYR_SAMPLE="samples/subsys/shell/shell_module"

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
  freertos               Build FreeRTOS CLI demo

FreeRTOS (RISC-V RV32 / QEMU virt):
  freertos-riscv         Build FreeRTOS blinky demo (rv32, qemu-system-riscv32)

Zephyr (Cortex-M3 / MPS2 AN385):
  zephyr                 Build Zephyr Shell demo

Zephyr (RISC-V / qemu_riscv64):
  zephyr-riscv           Build Zephyr Shell demo (riscv64)

RISC-V (riscv64 / QEMU virt):
  buildroot-riscv        Linux full build (OpenSBI + Linux)

QEMU 실행은 run.sh 를 사용하세요:
  ./run.sh linux
  ./run.sh freertos
  ./run.sh zephyr
  ./run.sh linux-riscv

Examples:
  $0 buildroot
  $0 buildroot-kernel
  $0 freertos
  $0 zephyr
  $0 buildroot-riscv
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
    FORCE_UNSAFE_CONFIGURE=1 make "$@"
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
    make -C "$FREERTOS_CLI_DIR" clean
    make -C "$FREERTOS_CLI_DIR" -j"$PARALLEL_JOBS"
    mkdir -p "$FREERTOS_IMAGES"
    cp -v "$FREERTOS_CLI_DIR/output/RTOSDemo.out" "$FREERTOS_IMAGES/RTOSDemo.out"
    echo "Done. Binary: $FREERTOS_IMAGES/RTOSDemo.out"
}

# ── Buildroot RISC-V helpers ─────────────────────────────────

target_buildroot_riscv() {
    # Reuse the same Buildroot source clone (aarch64), separate output dir
    _ensure_buildroot
    cd "$BUILDROOT_DIR"
    if [ ! -f "$BUILDROOT_RISCV_OUTPUT/.config" ]; then
        echo "Configuring Buildroot for RISC-V ($BUILDROOT_RISCV_DEFCONFIG)..."
        make O="$BUILDROOT_RISCV_OUTPUT" "$BUILDROOT_RISCV_DEFCONFIG"
    fi
    _buildroot_make O="$BUILDROOT_RISCV_OUTPUT" -j"$PARALLEL_JOBS"
    cd "$TOP"
    echo "Done. Images: $BUILDROOT_RISCV_OUTPUT/images"
}

# ── Zephyr helpers ────────────────────────────────────────────

_ensure_zephyr_venv() {
    # venv is in $TOP (mounted volume) → survives container restarts
    if [ ! -d "$ZEPHYR_VENV" ]; then
        echo "Creating Zephyr Python venv..."
        python3 -m venv "$ZEPHYR_VENV"
    fi
    # shellcheck source=/dev/null
    source "$ZEPHYR_VENV/bin/activate"
}

_ensure_zephyr() {
    _ensure_zephyr_venv

    # Install/upgrade west inside venv (idempotent)
    pip install --quiet --upgrade pip west

    if [ ! -d "$ZEPHYR_DIR" ]; then
        echo "Initializing Zephyr workspace ($ZEPHYR_VERSION)..."
        echo "  → First run downloads ~500MB — expect 5-10 min."
        west init --mr "$ZEPHYR_VERSION" "$ZEPHYR_DIR"
        cd "$ZEPHYR_DIR"
        west update
        pip install --quiet -r "$ZEPHYR_DIR/zephyr/scripts/requirements.txt"
        echo "Zephyr workspace ready."
    else
        cd "$ZEPHYR_DIR"
    fi
}

target_zephyr() {
    _ensure_zephyr

    export ZEPHYR_TOOLCHAIN_VARIANT=gnuarmemb
    export GNUARMEMB_TOOLCHAIN_PATH=/usr
    export ZEPHYR_BASE="$ZEPHYR_DIR/zephyr"

    echo "Building Zephyr ($ZEPHYR_SAMPLE) for $ZEPHYR_BOARD..."
    west build -b "$ZEPHYR_BOARD" \
        "$ZEPHYR_DIR/zephyr/$ZEPHYR_SAMPLE" \
        --build-dir "$ZEPHYR_DIR/build" \
        -p always

    mkdir -p "$ZEPHYR_IMAGES"
    cp -v "$ZEPHYR_DIR/build/zephyr/zephyr.elf" "$ZEPHYR_IMAGES/zephyr.elf"
    cd "$TOP"
    echo "Done. Binary: $ZEPHYR_IMAGES/zephyr.elf"
}

target_freertos_riscv() {
    _ensure_freertos

    # Detect RISC-V toolchain: prefer xPack riscv-none-elf-, fall back to riscv64-unknown-elf-
    # Use only the basename prefix (not full path) so the Makefile's GCC version grep works.
    local cross_prefix
    if command -v riscv-none-elf-gcc >/dev/null 2>&1; then
        cross_prefix="riscv-none-elf-"
    elif command -v riscv64-unknown-elf-gcc >/dev/null 2>&1; then
        cross_prefix="riscv64-unknown-elf-"
    else
        echo "ERROR: RISC-V GCC not found." >&2
        echo "  Rebuild Docker image: docker rmi qemu-dev:latest && ./build.sh freertos-riscv" >&2
        exit 1
    fi

    make -C "$FREERTOS_RISCV_CLI_DIR" clean CROSS="$cross_prefix"
    make -C "$FREERTOS_RISCV_CLI_DIR" -j"$PARALLEL_JOBS" CROSS="$cross_prefix"
    mkdir -p "$FREERTOS_RISCV_IMAGES"
    cp -v "$FREERTOS_RISCV_CLI_DIR/build/RTOSDemo.axf" "$FREERTOS_RISCV_IMAGES/RTOSDemo.axf"
    echo "Done. Binary: $FREERTOS_RISCV_IMAGES/RTOSDemo.axf"
}

target_zephyr_riscv() {
    _ensure_zephyr

    local riscv_gcc
    riscv_gcc="$(command -v riscv-none-elf-gcc 2>/dev/null \
              || command -v riscv64-unknown-elf-gcc 2>/dev/null \
              || true)"
    if [ -z "$riscv_gcc" ]; then
        echo "ERROR: RISC-V GCC not found (riscv-none-elf-gcc / riscv64-unknown-elf-gcc)." >&2
        echo "  Rebuild Docker image: docker rmi qemu-dev:latest && ./build.sh zephyr-riscv" >&2
        exit 1
    fi
    local riscv_prefix="${riscv_gcc%gcc}"   # strip trailing 'gcc' → full path prefix

    export ZEPHYR_TOOLCHAIN_VARIANT=cross-compile
    export CROSS_COMPILE="$riscv_prefix"
    export ZEPHYR_BASE="$ZEPHYR_DIR/zephyr"

    echo "Building Zephyr ($ZEPHYR_SAMPLE) for $ZEPHYR_RISCV_BOARD..."
    west build -b "$ZEPHYR_RISCV_BOARD" \
        "$ZEPHYR_DIR/zephyr/$ZEPHYR_SAMPLE" \
        --build-dir "$ZEPHYR_DIR/build_riscv" \
        -p always

    mkdir -p "$ZEPHYR_RISCV_IMAGES"
    cp -v "$ZEPHYR_DIR/build_riscv/zephyr/zephyr.elf" "$ZEPHYR_RISCV_IMAGES/zephyr.elf"
    cd "$TOP"
    echo "Done. Binary: $ZEPHYR_RISCV_IMAGES/zephyr.elf"
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
    freertos-riscv)         target_freertos_riscv ;;
    zephyr)                 target_zephyr ;;
    zephyr-riscv)           target_zephyr_riscv ;;
    buildroot-riscv)        target_buildroot_riscv ;;
    help|-h|--help)         usage ;;
    *)  echo "ERROR: unknown target '$1'" >&2; usage; exit 1 ;;
esac
