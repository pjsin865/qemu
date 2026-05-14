#ifndef UART_H_
#define UART_H_

void uart_init(void);
void uart_putchar(char c);
void uart_puts(const char *s);
int  uart_getchar_nonblock(void);   /* -1 if no data available */

#endif /* UART_H_ */
