#include "FreeRTOS.h"
#include "task.h"
#include "FreeRTOS_CLI.h"
#include "cli_commands.h"
#include <string.h>
#include <stdio.h>

/* ── task-stats ────────────────────────────────────────────── */

static BaseType_t prvTaskStatsCommand(char *pcWriteBuffer, size_t xWriteBufferLen,
                                       const char *pcCommandString)
{
    (void)pcCommandString;
    static const char header[] =
        "Name            State  Pri  Stack  Num\r\n"
        "--------------------------------------\r\n";
    strncpy(pcWriteBuffer, header, xWriteBufferLen);
    vTaskList(pcWriteBuffer + strlen(header));
    return pdFALSE;
}

static const CLI_Command_Definition_t xTaskStats = {
    "task-stats",
    "task-stats:\r\n  Show FreeRTOS task list and state\r\n",
    prvTaskStatsCommand, 0
};

/* ── echo ──────────────────────────────────────────────────── */

static BaseType_t prvEchoCommand(char *pcWriteBuffer, size_t xWriteBufferLen,
                                  const char *pcCommandString)
{
    const char *param;
    BaseType_t paramLen;
    param = FreeRTOS_CLIGetParameter(pcCommandString, 1, &paramLen);
    if (param) {
        snprintf(pcWriteBuffer, xWriteBufferLen, "%.*s\r\n", (int)paramLen, param);
    } else {
        strncpy(pcWriteBuffer, "\r\n", xWriteBufferLen);
    }
    return pdFALSE;
}

static const CLI_Command_Definition_t xEcho = {
    "echo",
    "echo <text>:\r\n  Print text to console\r\n",
    prvEchoCommand, -1
};

/* ── version ───────────────────────────────────────────────── */

static BaseType_t prvVersionCommand(char *pcWriteBuffer, size_t xWriteBufferLen,
                                     const char *pcCommandString)
{
    (void)pcCommandString;
    snprintf(pcWriteBuffer, xWriteBufferLen,
             "FreeRTOS %s | Cortex-M3 MPS2 AN385 | QEMU\r\n",
             tskKERNEL_VERSION_NUMBER);
    return pdFALSE;
}

static const CLI_Command_Definition_t xVersion = {
    "version",
    "version:\r\n  Show FreeRTOS kernel version\r\n",
    prvVersionCommand, 0
};

/* ── uptime ────────────────────────────────────────────────── */

static BaseType_t prvUptimeCommand(char *pcWriteBuffer, size_t xWriteBufferLen,
                                    const char *pcCommandString)
{
    (void)pcCommandString;
    TickType_t ticks = xTaskGetTickCount();
    uint32_t sec  = ticks / configTICK_RATE_HZ;
    uint32_t min  = sec / 60; sec %= 60;
    uint32_t hour = min / 60; min %= 60;
    snprintf(pcWriteBuffer, xWriteBufferLen,
             "Uptime: %02lu:%02lu:%02lu  (ticks: %lu)\r\n",
             (unsigned long)hour, (unsigned long)min, (unsigned long)sec,
             (unsigned long)ticks);
    return pdFALSE;
}

static const CLI_Command_Definition_t xUptime = {
    "uptime",
    "uptime:\r\n  Show system uptime\r\n",
    prvUptimeCommand, 0
};

/* ── free-heap ─────────────────────────────────────────────── */

static BaseType_t prvFreeHeapCommand(char *pcWriteBuffer, size_t xWriteBufferLen,
                                      const char *pcCommandString)
{
    (void)pcCommandString;
    snprintf(pcWriteBuffer, xWriteBufferLen,
             "Free heap: %u bytes\r\n",
             (unsigned)xPortGetFreeHeapSize());
    return pdFALSE;
}

static const CLI_Command_Definition_t xFreeHeap = {
    "free-heap",
    "free-heap:\r\n  Show available FreeRTOS heap\r\n",
    prvFreeHeapCommand, 0
};

/* ── 등록 ──────────────────────────────────────────────────── */

void vRegisterCLICommands(void)
{
    FreeRTOS_CLIRegisterCommand(&xTaskStats);
    FreeRTOS_CLIRegisterCommand(&xEcho);
    FreeRTOS_CLIRegisterCommand(&xVersion);
    FreeRTOS_CLIRegisterCommand(&xUptime);
    FreeRTOS_CLIRegisterCommand(&xFreeHeap);
}
