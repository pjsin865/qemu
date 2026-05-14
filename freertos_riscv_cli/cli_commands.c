#include <FreeRTOS.h>
#include <task.h>
#include <FreeRTOS_CLI.h>
#include <stdio.h>
#include <string.h>

#include "cli_commands.h"

/* task-stats ----------------------------------------------------------- */
static BaseType_t prvTaskStatsCommand(char *buf, size_t buflen,
                                      const char *cmd)
{
    (void)cmd;
    static const char hdr[] =
        "Name            State  Pri  Stack  Num\r\n"
        "--------------------------------------\r\n";
    if (buflen > sizeof(hdr))
        strcpy(buf, hdr);
    vTaskList(buf + strlen(buf));
    return pdFALSE;
}

static const CLI_Command_Definition_t xTaskStats = {
    "task-stats",
    "task-stats: FreeRTOS task list\r\n",
    prvTaskStatsCommand, 0
};

/* version -------------------------------------------------------------- */
static BaseType_t prvVersionCommand(char *buf, size_t buflen,
                                    const char *cmd)
{
    (void)cmd;
    snprintf(buf, buflen,
             "FreeRTOS %s | RISC-V rv32 QEMU virt | NS16550A UART\r\n",
             tskKERNEL_VERSION_NUMBER);
    return pdFALSE;
}

static const CLI_Command_Definition_t xVersion = {
    "version",
    "version:    FreeRTOS kernel version\r\n",
    prvVersionCommand, 0
};

/* uptime --------------------------------------------------------------- */
static BaseType_t prvUptimeCommand(char *buf, size_t buflen,
                                   const char *cmd)
{
    (void)cmd;
    TickType_t ticks = xTaskGetTickCount();
    uint32_t   secs  = (uint32_t)(ticks / configTICK_RATE_HZ);
    uint32_t   h     = secs / 3600;
    uint32_t   m     = (secs % 3600) / 60;
    uint32_t   s     = secs % 60;
    snprintf(buf, buflen,
             "Uptime: %02lu:%02lu:%02lu  (ticks: %lu)\r\n",
             (unsigned long)h, (unsigned long)m,
             (unsigned long)s, (unsigned long)ticks);
    return pdFALSE;
}

static const CLI_Command_Definition_t xUptime = {
    "uptime",
    "uptime:     System uptime\r\n",
    prvUptimeCommand, 0
};

/* free-heap ------------------------------------------------------------ */
static BaseType_t prvFreeHeapCommand(char *buf, size_t buflen,
                                     const char *cmd)
{
    (void)cmd;
    snprintf(buf, buflen, "Free heap: %lu bytes\r\n",
             (unsigned long)xPortGetFreeHeapSize());
    return pdFALSE;
}

static const CLI_Command_Definition_t xFreeHeap = {
    "free-heap",
    "free-heap:  Remaining FreeRTOS heap\r\n",
    prvFreeHeapCommand, 0
};

/* echo ----------------------------------------------------------------- */
static BaseType_t prvEchoCommand(char *buf, size_t buflen,
                                 const char *cmd)
{
    const char *arg = FreeRTOS_CLIGetParameter(cmd, 1, NULL);
    if (arg)
        snprintf(buf, buflen, "%s\r\n", arg);
    else
        snprintf(buf, buflen, "\r\n");
    return pdFALSE;
}

static const CLI_Command_Definition_t xEcho = {
    "echo",
    "echo <text>: Echo first word\r\n",
    prvEchoCommand, 1
};

/* register all --------------------------------------------------------- */
void vRegisterCLICommands(void)
{
    FreeRTOS_CLIRegisterCommand(&xTaskStats);
    FreeRTOS_CLIRegisterCommand(&xVersion);
    FreeRTOS_CLIRegisterCommand(&xUptime);
    FreeRTOS_CLIRegisterCommand(&xFreeHeap);
    FreeRTOS_CLIRegisterCommand(&xEcho);
}
