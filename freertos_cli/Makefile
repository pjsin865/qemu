FREERTOS_ROOT  := $(abspath ../FreeRTOS)
FREERTOS_SRC   := $(FREERTOS_ROOT)/FreeRTOS/Source
FREERTOS_DEMO  := $(FREERTOS_ROOT)/FreeRTOS/Demo/CORTEX_MPS2_QEMU_IAR_GCC
FREERTOS_CLI   := $(FREERTOS_ROOT)/FreeRTOS-Plus/Source/FreeRTOS-Plus-CLI
CMSIS_DIR      := $(FREERTOS_DEMO)/CMSIS

OUTPUT_DIR     := ./output
TARGET         := $(OUTPUT_DIR)/RTOSDemo.out

CC     := arm-none-eabi-gcc
LD     := arm-none-eabi-gcc
SIZE   := arm-none-eabi-size

CFLAGS := -mthumb -mcpu=cortex-m3
CFLAGS += -Os -g3 -ffunction-sections -fdata-sections
CFLAGS += -Wall -Wextra -Wshadow -Wno-unused-parameter
CFLAGS += -MMD -MP

CFLAGS += -I. \
          -I$(FREERTOS_SRC)/include \
          -I$(FREERTOS_SRC)/portable/GCC/ARM_CM3 \
          -I$(FREERTOS_CLI) \
          -I$(CMSIS_DIR)

LDFLAGS := -T mps2_m3.ld
LDFLAGS += -Xlinker -Map=$(OUTPUT_DIR)/RTOSDemo.map
LDFLAGS += -Xlinker --gc-sections
LDFLAGS += -nostartfiles -specs=nano.specs -specs=nosys.specs

# ── 소스 파일 ────────────────────────────────────────────────
SRCS := startup.c \
        main.c \
        uart.c \
        cli_commands.c \
        $(FREERTOS_SRC)/tasks.c \
        $(FREERTOS_SRC)/list.c \
        $(FREERTOS_SRC)/queue.c \
        $(FREERTOS_SRC)/timers.c \
        $(FREERTOS_SRC)/event_groups.c \
        $(FREERTOS_SRC)/stream_buffer.c \
        $(FREERTOS_SRC)/portable/MemMang/heap_4.c \
        $(FREERTOS_SRC)/portable/GCC/ARM_CM3/port.c \
        $(FREERTOS_CLI)/FreeRTOS_CLI.c

OBJS := $(patsubst %.c,$(OUTPUT_DIR)/%.o,$(notdir $(SRCS)))
VPATH := . $(FREERTOS_SRC) \
           $(FREERTOS_SRC)/portable/MemMang \
           $(FREERTOS_SRC)/portable/GCC/ARM_CM3 \
           $(FREERTOS_CLI)

# ── 규칙 ─────────────────────────────────────────────────────
.PHONY: all clean

all: $(OUTPUT_DIR) $(TARGET)
	$(SIZE) $(TARGET)

$(OUTPUT_DIR):
	mkdir -p $@

$(TARGET): $(OBJS)
	$(LD) $(CFLAGS) $(LDFLAGS) $^ -o $@

$(OUTPUT_DIR)/%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

-include $(OUTPUT_DIR)/*.d

clean:
	rm -rf $(OUTPUT_DIR)
