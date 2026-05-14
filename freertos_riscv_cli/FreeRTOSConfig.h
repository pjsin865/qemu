#ifndef FREERTOS_CONFIG_H
#define FREERTOS_CONFIG_H

#include "riscv-virt.h"

/* RISC-V timer registers */
#define configMTIME_BASE_ADDRESS    ( CLINT_ADDR + CLINT_MTIME )
#define configMTIMECMP_BASE_ADDRESS ( CLINT_ADDR + CLINT_MTIMECMP )

#define configUSE_PREEMPTION            1
#define configUSE_IDLE_HOOK             1
#define configUSE_TICK_HOOK             1
#define configCPU_CLOCK_HZ              ( 10000000 )
#define configTICK_RATE_HZ              ( ( TickType_t ) 1000 )
#define configMAX_PRIORITIES            ( 7 )
#define configMINIMAL_STACK_SIZE        ( ( unsigned short ) 512 )
#define configTOTAL_HEAP_SIZE           ( ( size_t ) 65536 )
#define configMAX_TASK_NAME_LEN         ( 16 )
#define configUSE_TRACE_FACILITY        1
#define configUSE_STATS_FORMATTING_FUNCTIONS 1
#define configUSE_16_BIT_TICKS          0
#define configIDLE_SHOULD_YIELD         1
#define configUSE_MUTEXES               1
#define configQUEUE_REGISTRY_SIZE       8
#define configCHECK_FOR_STACK_OVERFLOW  2
#define configUSE_RECURSIVE_MUTEXES     1
#define configUSE_MALLOC_FAILED_HOOK    1
#define configUSE_APPLICATION_TASK_TAG  0
#define configUSE_COUNTING_SEMAPHORES   1
#define configGENERATE_RUN_TIME_STATS   0

/* RISC-V ISR stack */
#define configISR_STACK_SIZE_WORDS      2048

/* FreeRTOS+CLI */
#define configCOMMAND_INT_MAX_OUTPUT_SIZE       512

/* Software timers */
#define configUSE_TIMERS                1
#define configTIMER_TASK_PRIORITY       ( configMAX_PRIORITIES - 1 )
#define configTIMER_QUEUE_LENGTH        6
#define configTIMER_TASK_STACK_DEPTH    ( 256 )

/* Assert */
void vAssertCalled(void);
#define configASSERT_DEFINED            1
#define configASSERT(x)                 do { if (!(x)) vAssertCalled(); } while (0)

/* Optional API */
#define INCLUDE_vTaskPrioritySet        1
#define INCLUDE_uxTaskPriorityGet       1
#define INCLUDE_vTaskDelete             1
#define INCLUDE_vTaskSuspend            1
#define INCLUDE_vTaskDelayUntil         1
#define INCLUDE_vTaskDelay              1
#define INCLUDE_eTaskGetState           1
#define INCLUDE_xTimerPendFunctionCall  1
#define INCLUDE_xTaskGetCurrentTaskHandle 1
#define INCLUDE_xTaskGetHandle          1
#define INCLUDE_xSemaphoreGetMutexHolder 1
#define INCLUDE_xTaskAbortDelay         1

#endif /* FREERTOS_CONFIG_H */
