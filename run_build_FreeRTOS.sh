#!/bin/bash
set -euo pipefail

TOP="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FREERTOS_REPO="https://github.com/FreeRTOS/FreeRTOS.git"
FREERTOS_DIR="$TOP/FreeRTOS"
DEMO_DIR="$FREERTOS_DIR/FreeRTOS/Demo/CORTEX_MPS2_QEMU_IAR_GCC/build/gcc"
OUTPUT_DIR="$TOP/freertos_images"

# Clone FreeRTOS if not present
if [ ! -d "$FREERTOS_DIR" ]; then
    echo "Cloning FreeRTOS..."
    git clone --depth 1 --recurse-submodules --shallow-submodules "$FREERTOS_REPO" "$FREERTOS_DIR"
fi

make -C "$DEMO_DIR" clean
make -C "$DEMO_DIR" -j$(nproc)

mkdir -p "$OUTPUT_DIR"
cp -v "$DEMO_DIR/output/RTOSDemo.out" "$OUTPUT_DIR/RTOSDemo.out"
echo "Build done: $OUTPUT_DIR/RTOSDemo.out"
