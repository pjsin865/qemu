#include <stdint.h>
#include "uart.h"

/* QEMU virt NS16550A UART at 0x10000000 */
#define UART0_BASE  0x10000000UL

#define REG_RBR     0x00    /* Receive Buffer Register (read) */
#define REG_THR     0x00    /* Transmit Holding Register (write) */
#define REG_IER     0x01    /* Interrupt Enable Register */
#define REG_FCR     0x02    /* FIFO Control Register */
#define REG_LCR     0x03    /* Line Control Register */
#define REG_LSR     0x05    /* Line Status Register */

#define LSR_DR      0x01    /* Data Ready (RX data available) */
#define LSR_THRE    0x20    /* TX Holding Register Empty */
#define LCR_8N1     0x03    /* 8 data bits, no parity, 1 stop */
#define LCR_DLAB    0x80    /* Divisor Latch Access Bit */

static uint8_t readb(uintptr_t a)           { return *(volatile uint8_t *)a; }
static void    writeb(uint8_t v, uintptr_t a) { *(volatile uint8_t *)a = v; }

void uart_init(void)
{
    /* QEMU NS16550A works without explicit init, but set 8N1 to be safe */
    writeb(LCR_DLAB, UART0_BASE + REG_LCR);  /* DLAB=1: access divisor */
    writeb(1, UART0_BASE + REG_RBR);          /* divisor LSB = 1 */
    writeb(0, UART0_BASE + REG_IER);          /* divisor MSB = 0 */
    writeb(LCR_8N1, UART0_BASE + REG_LCR);   /* 8N1, DLAB=0 */
    writeb(0x07, UART0_BASE + REG_FCR);       /* enable + clear FIFOs */
}

void uart_putchar(char c)
{
    while ((readb(UART0_BASE + REG_LSR) & LSR_THRE) == 0)
        ;
    writeb((uint8_t)c, UART0_BASE + REG_THR);
}

void uart_puts(const char *s)
{
    while (*s) {
        if (*s == '\n')
            uart_putchar('\r');
        uart_putchar(*s++);
    }
}

int uart_getchar_nonblock(void)
{
    if (readb(UART0_BASE + REG_LSR) & LSR_DR)
        return (int)(unsigned char)readb(UART0_BASE + REG_RBR);
    return -1;
}
