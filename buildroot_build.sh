#!/bin/bash
set -euo pipefail

TOP="$(pwd)"
BUILDROOT_DIR="$TOP/buildroot"
PARALLEL_JOBS="$(nproc)"
BUILDROOT_REPO_URL="https://github.com/buildroot/buildroot.git"
BUILDROOT_REPO_BRANCH="" # leave empty for default branch
DEFAULT_DEFCONFIG="qemu_aarch64_virt_defconfig"
PATCH_DIR="$TOP/buildroot_patches"

usage() {
    cat <<EOF
Usage: $0 [OPTION]...

Options:
  full            Build the entire Buildroot tree (make -jN)
  uboot           Rebuild U-Boot only (make uboot-rebuild -jN)
  kernel          Rebuild Linux kernel only (make linux-rebuild -jN)
  full-clean      Clean and build the entire Buildroot tree
  uboot-clean     Clean and build U-Boot
  kernel-clean    Clean and build the Linux kernel
  help            Show this help message

If Buildroot is missing, this script will clone it from $BUILDROOT_REPO_URL.
If no .config exists, it will use .defconfig, BR2_DEFCONFIG, or $DEFAULT_DEFCONFIG.

Examples:
  $0 full
  $0 uboot-clean
  $0 kernel
EOF
}

clone_buildroot() {
    if ! command -v git >/dev/null 2>&1; then
        echo "ERROR: git is required to download Buildroot." >&2
        exit 1
    fi

    echo "Buildroot directory not found. Cloning Buildroot..."
    if [ -n "$BUILDROOT_REPO_BRANCH" ]; then
        git clone --depth 1 --branch "$BUILDROOT_REPO_BRANCH" "$BUILDROOT_REPO_URL" "$BUILDROOT_DIR"
    else
        git clone --depth 1 "$BUILDROOT_REPO_URL" "$BUILDROOT_DIR"
    fi
}

ensure_buildroot() {
    if [ ! -d "$BUILDROOT_DIR" ]; then
        clone_buildroot
    fi
}

apply_buildroot_patches() {
    if [ ! -d "$PATCH_DIR" ]; then
        return
    fi

    shopt -s nullglob
    local patches=("$PATCH_DIR"/*.patch)
    shopt -u nullglob

    if [ ${#patches[@]} -eq 0 ]; then
        return
    fi

    for patch in "${patches[@]}"; do
        echo "Applying patch: $patch"
        if git apply --check "$patch" >/dev/null 2>&1; then
            git apply "$patch"
        else
            if git apply --reverse --check "$patch" >/dev/null 2>&1; then
                echo "Patch already applied: $patch"
            else
                echo "ERROR: failed to apply patch $patch" >&2
                exit 1
            fi
        fi
    done
}

if [ $# -ne 1 ] || [[ "$1" == "help" ]]; then
    usage
    exit 0
fi

ensure_buildroot
TARGET="$1"
cd "$BUILDROOT_DIR"

apply_buildroot_patches

apply_defconfig() {
    if [ -f .defconfig ]; then
        make defconfig
    elif [ -n "${BR2_DEFCONFIG:-}" ]; then
        make "$BR2_DEFCONFIG"
    else
        echo "NOTICE: Using default config: $DEFAULT_DEFCONFIG"
        make "$DEFAULT_DEFCONFIG"
    fi
}

if [ ! -f .config ]; then
    echo "NOTICE: .config not found. Configuring Buildroot..."
    apply_defconfig
fi

run_make() {
    local cmd="$1"
    echo "Running: $cmd"
    eval "$cmd"
}

case "$TARGET" in
    full)
        apply_defconfig
        run_make "make -j\"$PARALLEL_JOBS\""
        ;;
    uboot)
        run_make "make uboot-rebuild -j\"$PARALLEL_JOBS\""
        ;;
    kernel)
        run_make "make linux-rebuild -j\"$PARALLEL_JOBS\""
        ;;
    full-clean)
        run_make "make clean"
        apply_defconfig
        run_make "make -j\"$PARALLEL_JOBS\""
        ;;
    uboot-clean)
        run_make "make uboot-dirclean"
        run_make "make uboot-rebuild -j\"$PARALLEL_JOBS\""
        ;;
    kernel-clean)
        run_make "make linux-dirclean"
        run_make "make linux-rebuild -j\"$PARALLEL_JOBS\""
        ;;
    *)
        echo "ERROR: unknown target '$TARGET'" >&2
        usage
        exit 1
        ;;
esac

cd "$TOP"

echo "Build completed. Output is in: $BUILDROOT_DIR/output"


