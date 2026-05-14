#include <FreeRTOS.h>
#include <task.h>
#include <FreeRTOS_CLI.h>
#include <string.h>
#include <stdio.h>

#include "riscv-virt.h"
#include "uart.h"
#include "cli_commands.h"

extern void freertos_risc_v_trap_handler(void);

#define CLI_TASK_STACK  ( 1024 )
#define CLI_BUF_SIZE    ( 512 )
#define INPUT_BUF_SIZE  ( 64 )

static void vCLITask(void *pv)
{
    static char outbuf[CLI_BUF_SIZE];
    static char input[INPUT_BUF_SIZE];
    int         len = 0;
    int         c;
    BaseType_t  more;

    uart_puts(
        "\r\n"
        "======================================\r\n"
        "  FreeRTOS CLI  |  RISC-V QEMU virt\r\n"
        "======================================\r\n"
        "Type 'help' for available commands.\r\n"
        "\r\n"
        "$ ");

    for (;;) {
        c = uart_getchar_nonblock();
        if (c < 0) {
            vTaskDelay(pdMS_TO_TICKS(10));
            continue;
        }

        if (c == '\r' || c == '\n') {
            uart_puts("\r\n");
            if (len > 0) {
                input[len] = '\0';
                do {
                    more = FreeRTOS_CLIProcessCommand(input, outbuf, sizeof(outbuf));
                    uart_puts(outbuf);
                } while (more == pdTRUE);
                len = 0;
            }
            uart_puts("$ ");
        } else if (c == 127 || c == '\b') {
            if (len > 0) {
                uart_puts("\b \b");
                len--;
            }
        } else if (len < INPUT_BUF_SIZE - 1) {
            input[len++] = (char)c;
            uart_putchar((char)c);
        }
    }
}

int main(void)
{
    /* Set direct-mode trap handler (freertos_risc_v_trap_handler handles
     * machine-timer interrupt for FreeRTOS tick). */
    __asm volatile("csrw mtvec, %0"
                   : : "r"(freertos_risc_v_trap_handler));

    uart_init();
    vRegisterCLICommands();

    xTaskCreate(vCLITask, "CLI", CLI_TASK_STACK, NULL, tskIDLE_PRIORITY + 1, NULL);

    vTaskStartScheduler();

    /* Should never reach here */
    for (;;)
        ;
    return 0;
}
