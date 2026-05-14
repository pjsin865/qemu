#include <FreeRTOS.h>
#include <task.h>
#include "riscv-virt.h"
#include "uart.h"

int xGetCoreID(void)
{
    int id;
    __asm("csrr %0, mhartid" : "=r"(id));
    return id;
}

/* Required by portasmHANDLE_INTERRUPT=handle_trap (unexpected trap → hang) */
void handle_trap(void)
{
    for (;;)
        ;
}

void vApplicationTickHook(void) {}

void vApplicationIdleHook(void) {}

void vApplicationMallocFailedHook(void)
{
    uart_puts("FATAL: malloc failed\n");
    for (;;)
        ;
}

void vApplicationStackOverflowHook(TaskHandle_t xTask, char *pcTaskName)
{
    (void)xTask;
    uart_puts("FATAL: stack overflow in task: ");
    uart_puts(pcTaskName);
    uart_puts("\n");
    for (;;)
        ;
}

void vAssertCalled(void)
{
    uart_puts("FATAL: assert\n");
    for (;;)
        ;
}
