#include "uart.h"
#include <stdio.h>

void uart_init(void)
{
    UART0_BAUDDIV = 16;
    UART0_CTRL = UART_CTRL_TX_EN | UART_CTRL_RX_EN;
}

void uart_putchar(char c)
{
    while (UART0_STATE & UART_STATE_TXFULL)
        ;
    UART0_DATA = (uint32_t)c;
}

void uart_puts(const char *s)
{
    while (*s)
        uart_putchar(*s++);
}

int uart_getchar_nonblock(char *c)
{
    if (UART0_STATE & UART_STATE_RXFULL) {
        *c = (char)(UART0_DATA & 0xFF);
        return 1;
    }
    return 0;
}

/* Redirect printf → UART */
int __write(int fd, char *buf, int len)
{
    (void)fd;
    for (int i = 0; i < len; i++)
        uart_putchar(buf[i]);
    return len;
}
