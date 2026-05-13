#!/bin/bash
set -euo pipefail

TOP="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$TOP/freertos_images/RTOSDemo.out"

if [ ! -f "$OUT" ]; then
    echo "ERROR: $OUT not found. Run ./run_build_FreeRTOS.sh first." >&2
    exit 1
fi

# Demo: CORTEX_MPS2_QEMU_IAR_GCC (blinky)
# Target: Cortex-M3 / MPS2 AN385
# Output: "Message received from task" / "Message received from software timer"
qemu-system-arm \
    -machine mps2-an385 \
    -cpu cortex-m3 \
    -monitor none \
    -nographic \
    -serial stdio \
    -kernel "$OUT"
