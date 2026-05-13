#include <stdint.h>
#include <string.h>

extern void vPortSVCHandler(void);
extern void xPortPendSVHandler(void);
extern void xPortSysTickHandler(void);

static void HardFault_Handler(void) __attribute__((naked));
static void Default_Handler(void) __attribute__((naked));
void Reset_Handler(void) __attribute__((naked));

extern int main(void);
extern uint32_t _estack;
extern uint32_t _sidata, _sdata, _edata, _sbss, _ebss;

const uint32_t *isr_vector[] __attribute__((section(".isr_vector"), used)) = {
    (uint32_t *)&_estack,
    (uint32_t *)&Reset_Handler,
    (uint32_t *)&Default_Handler,   /* NMI */
    (uint32_t *)&HardFault_Handler,
    (uint32_t *)&Default_Handler,   /* MemManage */
    (uint32_t *)&Default_Handler,   /* BusFault */
    (uint32_t *)&Default_Handler,   /* UsageFault */
    0, 0, 0, 0,
    (uint32_t *)&vPortSVCHandler,
    (uint32_t *)&Default_Handler,   /* DebugMon */
    0,
    (uint32_t *)&xPortPendSVHandler,
    (uint32_t *)&xPortSysTickHandler,
    0, 0, 0, 0, 0, 0, 0, 0,
    (uint32_t *)&Default_Handler,   /* Timer 0 */
    (uint32_t *)&Default_Handler,   /* Timer 1 */
    0, 0, 0,
    0,                              /* Ethernet */
};

void Reset_Handler(void)
{
    uint32_t *src = &_sidata;
    uint32_t *dst = &_sdata;
    while (dst < &_edata)
        *dst++ = *src++;

    memset(&_sbss, 0, (size_t)((uintptr_t)&_ebss - (uintptr_t)&_sbss));

    main();
    for (;;)
        ;
}

volatile uint32_t r0, r1, r2, r3, r12, lr, pc, psr;

static __attribute__((used)) void prvGetRegistersFromStack(uint32_t *pulFaultStackAddress)
{
    r0  = pulFaultStackAddress[0];
    r1  = pulFaultStackAddress[1];
    r2  = pulFaultStackAddress[2];
    r3  = pulFaultStackAddress[3];
    r12 = pulFaultStackAddress[4];
    lr  = pulFaultStackAddress[5];
    pc  = pulFaultStackAddress[6];
    psr = pulFaultStackAddress[7];
    for (;;)
        ;
}

void HardFault_Handler(void)
{
    __asm volatile(
        ".align 8                          \n"
        " tst lr, #4                       \n"
        " ite eq                           \n"
        " mrseq r0, msp                    \n"
        " mrsne r0, psp                    \n"
        " ldr r1, [r0, #24]                \n"
        " ldr r2, =prvGetRegistersFromStack\n"
        " bx r2                            \n"
        " .ltorg                           \n"
    );
}

void Default_Handler(void)
{
    __asm volatile(
        ".align 8                          \n"
        " ldr r3, =0xe000ed04              \n"
        " ldr r2, [r3, #0]                 \n"
        " uxtb r2, r2                      \n"
        "Infinite_Loop:                    \n"
        " b  Infinite_Loop                 \n"
        " .ltorg                           \n"
    );
}
