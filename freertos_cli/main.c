#include "FreeRTOS.h"
#include "task.h"
#include "FreeRTOS_CLI.h"
#include "uart.h"
#include "cli_commands.h"
#include <string.h>
#include <stdio.h>

#define CLI_INPUT_BUF_LEN    128
#define CLI_OUTPUT_BUF_LEN   configCOMMAND_INT_MAX_OUTPUT_SIZE
#define CLI_TASK_STACK       ( configMINIMAL_STACK_SIZE * 8 )
#define CLI_TASK_PRIORITY    ( tskIDLE_PRIORITY + 1 )

static void vCLITask(void *pvParameters);

/* ── main ─────────────────────────────────────────────────── */

int main(void)
{
    uart_init();

    vRegisterCLICommands();

    xTaskCreate(vCLITask, "CLI", CLI_TASK_STACK, NULL, CLI_TASK_PRIORITY, NULL);

    vTaskStartScheduler();

    /* Should never reach here */
    for (;;)
        ;
    return 0;
}

/* ── CLI task ─────────────────────────────────────────────── */

static void vCLITask(void *pvParameters)
{
    (void)pvParameters;

    static char cInputBuf[CLI_INPUT_BUF_LEN];
    static char cOutputBuf[CLI_OUTPUT_BUF_LEN];
    int idx = 0;

    uart_puts("\r\n");
    uart_puts("======================================\r\n");
    uart_puts("  FreeRTOS CLI  |  MPS2 AN385  |  QEMU\r\n");
    uart_puts("======================================\r\n");
    uart_puts("Type 'help' for available commands.\r\n\r\n");
    uart_puts("$ ");

    for (;;) {
        char c;

        /* Non-blocking read — yield to scheduler when no input */
        if (!uart_getchar_nonblock(&c)) {
            vTaskDelay(pdMS_TO_TICKS(10));
            continue;
        }

        if (c == '\r' || c == '\n') {
            uart_puts("\r\n");
            if (idx == 0) {
                uart_puts("$ ");
                continue;
            }
            cInputBuf[idx] = '\0';
            idx = 0;

            /* Process command (may return multiple times for long output) */
            BaseType_t xMore;
            do {
                memset(cOutputBuf, 0, sizeof(cOutputBuf));
                xMore = FreeRTOS_CLIProcessCommand(cInputBuf, cOutputBuf,
                                                    sizeof(cOutputBuf));
                uart_puts(cOutputBuf);
            } while (xMore != pdFALSE);

            uart_puts("$ ");

        } else if (c == '\b' || c == 127) {
            /* Backspace */
            if (idx > 0) {
                idx--;
                uart_puts("\b \b");
            }
        } else if (c >= ' ' && idx < (int)(sizeof(cInputBuf) - 1)) {
            /* Printable character — echo and buffer */
            cInputBuf[idx++] = c;
            uart_putchar(c);
        }
    }
}

/* ── FreeRTOS hooks ───────────────────────────────────────── */

void vApplicationMallocFailedHook(void)
{
    uart_puts("\r\nERROR: malloc failed\r\n");
    for (;;)
        ;
}

void vApplicationStackOverflowHook(TaskHandle_t xTask, char *pcTaskName)
{
    (void)xTask;
    uart_puts("\r\nERROR: stack overflow in task: ");
    uart_puts(pcTaskName);
    uart_puts("\r\n");
    for (;;)
        ;
}

void vApplicationGetTimerTaskMemory(StaticTask_t **ppxTimerTaskTCBBuffer,
                                     StackType_t **ppxTimerTaskStackBuffer,
                                     configSTACK_DEPTH_TYPE *pulTimerTaskStackSize)
{
    (void)ppxTimerTaskTCBBuffer;
    (void)ppxTimerTaskStackBuffer;
    (void)pulTimerTaskStackSize;
}

void vApplicationGetIdleTaskMemory(StaticTask_t **ppxIdleTaskTCBBuffer,
                                    StackType_t **ppxIdleTaskStackBuffer,
                                    configSTACK_DEPTH_TYPE *pulIdleTaskStackSize)
{
    (void)ppxIdleTaskTCBBuffer;
    (void)ppxIdleTaskStackBuffer;
    (void)pulIdleTaskStackSize;
}
