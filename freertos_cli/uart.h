#ifndef UART_H
#define UART_H

#include <stdint.h>

/* CMSDK UART0 registers (MPS2 AN385) */
#define UART0_BASE      0x40004000UL
#define UART0_DATA      ( *( (volatile uint32_t *)(UART0_BASE + 0x00) ) )
#define UART0_STATE     ( *( (volatile uint32_t *)(UART0_BASE + 0x04) ) )
#define UART0_CTRL      ( *( (volatile uint32_t *)(UART0_BASE + 0x08) ) )
#define UART0_BAUDDIV   ( *( (volatile uint32_t *)(UART0_BASE + 0x10) ) )

#define UART_STATE_TXFULL   ( 1u << 0 )
#define UART_STATE_RXFULL   ( 1u << 1 )
#define UART_CTRL_TX_EN     ( 1u << 0 )
#define UART_CTRL_RX_EN     ( 1u << 1 )

void uart_init(void);
void uart_putchar(char c);
void uart_puts(const char *s);
int  uart_getchar_nonblock(char *c); /* 0=no data, 1=got char */

#endif
