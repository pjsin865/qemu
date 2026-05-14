# Toolchain prefix — use basename so the GCC version grep in make works.
# Set via: make CROSS=riscv-none-elf-
CROSS ?= riscv-none-elf-
CC    = $(CROSS)gcc
LD    = $(CROSS)gcc
SIZE  = $(CROSS)size

THIS_DIR      := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
TOP           := $(THIS_DIR)/..
FREERTOS_DIR  := $(TOP)/FreeRTOS
FREERTOS_SRC  := $(FREERTOS_DIR)/FreeRTOS/Source
FREERTOS_CLI  := $(FREERTOS_DIR)/FreeRTOS-Plus/Source/FreeRTOS-Plus-CLI
PORT_DIR      := $(FREERTOS_SRC)/portable/GCC/RISC-V
CHIP_EXT_DIR  := $(PORT_DIR)/chip_specific_extensions/RV32I_CLINT_no_extensions
DEMO_DIR      := $(FREERTOS_DIR)/FreeRTOS/Demo/RISC-V-Qemu-virt_GCC

BUILD_DIR     := $(THIS_DIR)/build
IMAGE         := $(BUILD_DIR)/RTOSDemo.axf

# GCC version detection (requires CC to be the basename, not a full path)
GCC_VERSION             := $(shell $(CC) --version | grep ^$(CC) | sed 's/^.* //g' | awk -F. '{ printf("%d%02d%02d"), $$1, $$2, $$3 }')
GCC_VERSION_NEED_ZICSR  := "110100"

ifeq ($(shell test $(GCC_VERSION) -ge $(GCC_VERSION_NEED_ZICSR) && echo true),true)
    MARCH = rv32imac_zicsr
else
    MARCH = rv32imac
endif

CPPFLAGS = \
    -D__riscv_float_abi_soft \
    -DportasmHANDLE_INTERRUPT=handle_trap \
    -I$(THIS_DIR) \
    -I$(FREERTOS_SRC)/include \
    -I$(PORT_DIR) \
    -I$(CHIP_EXT_DIR) \
    -I$(FREERTOS_CLI)

CFLAGS = \
    -march=$(MARCH) -mabi=ilp32 -mcmodel=medany \
    -Wall -fmessage-length=0 \
    -ffunction-sections -fdata-sections \
    -fno-builtin-printf

LDFLAGS = \
    -nostartfiles -T$(DEMO_DIR)/fake_rom.lds \
    -march=rv32imac -mabi=ilp32 -mcmodel=medany \
    -Xlinker --gc-sections \
    -Xlinker --defsym=__stack_size=1024 \
    -Xlinker -Map=$(BUILD_DIR)/RTOSDemo.map

ifeq ($(DEBUG), 1)
    CFLAGS += -Og -ggdb3
else
    CFLAGS += -O2
endif

SRCS = \
    $(THIS_DIR)/main.c \
    $(THIS_DIR)/uart.c \
    $(THIS_DIR)/riscv-virt.c \
    $(THIS_DIR)/cli_commands.c \
    $(FREERTOS_CLI)/FreeRTOS_CLI.c \
    $(FREERTOS_SRC)/event_groups.c \
    $(FREERTOS_SRC)/list.c \
    $(FREERTOS_SRC)/queue.c \
    $(FREERTOS_SRC)/stream_buffer.c \
    $(FREERTOS_SRC)/tasks.c \
    $(FREERTOS_SRC)/timers.c \
    $(FREERTOS_SRC)/portable/MemMang/heap_4.c \
    $(PORT_DIR)/port.c

ASMS = \
    $(DEMO_DIR)/start.S \
    $(DEMO_DIR)/vector.S \
    $(PORT_DIR)/portASM.S

OBJS = $(SRCS:%.c=$(BUILD_DIR)/%.o) $(ASMS:%.S=$(BUILD_DIR)/%.o)
DEPS = $(SRCS:%.c=$(BUILD_DIR)/%.d)

$(IMAGE): $(OBJS) Makefile
	@mkdir -p $(BUILD_DIR)
	$(LD) $(LDFLAGS) $(OBJS) -o $@
	$(SIZE) $@

$(BUILD_DIR)/%.o: %.c Makefile
	@mkdir -p $(@D)
	$(CC) $(CPPFLAGS) $(CFLAGS) -MMD -MP -c $< -o $@

$(BUILD_DIR)/%.o: %.S Makefile
	@mkdir -p $(@D)
	$(CC) $(CPPFLAGS) $(CFLAGS) -MMD -MP -c $< -o $@

clean:
	rm -rf $(BUILD_DIR)

-include $(DEPS)

.PHONY: clean
