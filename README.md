# QEMU Embedded Development Environment

QEMU 기반 임베디드 개발 환경. **Docker 하나만 있으면** 어떤 시스템에서도 동일하게 빌드하고 실행할 수 있습니다.

두 가지 타겟을 지원합니다:
- **Linux** — ATF + U-Boot + Linux 풀 부팅 체인 (aarch64 / Cortex-A57)
- **FreeRTOS** — 인터랙티브 CLI 쉘 (Cortex-M3 / MPS2 AN385)

---

## 목차

1. [빠른 시작](#빠른-시작)
2. [User Manual](#user-manual)
3. [Application Note](#application-note)
4. [Release Note](#release-note)

---

## 빠른 시작

```bash
git clone <repo-url>
cd <repo>

# FreeRTOS CLI (약 5분)
./build.sh freertos
./run.sh freertos

# Linux full boot (약 60~90분)
./build.sh buildroot
./run.sh linux
```

> Docker가 없으면 자동으로 설치합니다. `sudo` 비밀번호 1회 입력 외 별도 설정 불필요.

---

## User Manual

### 사전 조건

| 항목 | 요구사항 |
|---|---|
| OS | Ubuntu 20.04 / 22.04 / 24.04, macOS (Homebrew) |
| Docker | 없으면 자동 설치 |
| 디스크 | 최소 30GB 여유 공간 (Buildroot 빌드 시) |
| 메모리 | 최소 4GB RAM |

### build.sh — 빌드 스크립트

```
Usage: ./build.sh <target>

Buildroot (aarch64 / ATF + U-Boot + Linux):
  buildroot              전체 빌드 (클론 → 설정 → 빌드)
  buildroot-uboot        U-Boot만 재빌드
  buildroot-kernel       Linux 커널만 재빌드
  buildroot-clean        클린 후 전체 재빌드
  buildroot-uboot-clean  클린 후 U-Boot 재빌드
  buildroot-kernel-clean 클린 후 커널 재빌드
  menuconfig             Buildroot menuconfig 실행

FreeRTOS (Cortex-M3 / MPS2 AN385):
  freertos               FreeRTOS CLI 앱 빌드
```

**예시:**
```bash
./build.sh freertos
./build.sh buildroot
./build.sh buildroot-kernel          # 커널만 빠르게 재빌드
BR2_DL_DIR=/mnt/cache ./build.sh buildroot  # 다운로드 캐시 경로 지정
```

### run.sh — QEMU 실행 스크립트

```
Usage: ./run.sh <target> [options]

Targets:
  linux     ATF → U-Boot → Linux 부팅 (aarch64)
  freertos  FreeRTOS CLI 쉘 (Cortex-M3)

Linux 옵션:
  --smp N          vCPU 수 (기본: 1)
  --mem M          메모리 크기 (기본: 1024M)
  --no-net         네트워크 비활성화
  --no-pcie-disk   PCIe 추가 디스크 비활성화
  --usb-storage    USB xHCI + USB storage 추가
  --gdb            GDB 서버 활성화 (포트 1234, 연결 대기)

FreeRTOS 옵션:
  --gdb            GDB 서버 활성화 (포트 1234, 연결 대기)
```

**예시:**
```bash
./run.sh freertos
./run.sh linux
./run.sh linux --smp 2 --mem 2048M
./run.sh linux --usb-storage
./run.sh linux --gdb
./run.sh freertos --gdb
```

**QEMU 종료:** `Ctrl+A` → `X`

### FreeRTOS CLI 명령어

QEMU 실행 후 `$ ` 프롬프트가 나타나면 아래 명령어를 사용할 수 있습니다:

| 명령어 | 설명 |
|---|---|
| `help` | 사용 가능한 명령어 목록 |
| `task-stats` | FreeRTOS 태스크 목록 및 상태 |
| `echo <text>` | 텍스트 출력 |
| `version` | FreeRTOS 커널 버전 |
| `uptime` | 시스템 가동 시간 (ticks 포함) |
| `free-heap` | 남은 FreeRTOS 힙 크기 |

```
======================================
  FreeRTOS CLI  |  MPS2 AN385  |  QEMU
======================================
Type 'help' for available commands.

$ version
FreeRTOS V11.1.0+ | Cortex-M3 MPS2 AN385 | QEMU
$ uptime
Uptime: 00:01:23  (ticks: 8300)
$ free-heap
Free heap: 192872 bytes
$ task-stats
Name            State  Pri  Stack  Num
--------------------------------------
CLI             Running   1   1624   1
IDLE            Ready     0    228   2
```

### 빌드 진행 상황 모니터링

```bash
# 빌드 로그를 파일에 저장하면서 동시에 출력
./build.sh buildroot 2>&1 | tee /tmp/build.log

# 다른 터미널에서 진행 상황 확인
tail -f /tmp/build.log | grep ">>>"
```

### GDB 디버깅

```bash
# 터미널 1: QEMU 실행 (GDB 대기)
./run.sh freertos --gdb

# 터미널 2: GDB 연결
arm-none-eabi-gdb freertos_images/RTOSDemo.out
(gdb) target remote :1234
(gdb) continue
```

---

## Application Note

### 시스템 아키텍처

```
┌─────────────────────────────────────────────┐
│               Host OS (Any)                 │
│                                             │
│  ./build.sh ──► docker run ──► 컨테이너 내부 빌드
│  ./run.sh   ──► docker run -it ──► QEMU 실행
│                                             │
│  ┌─────────────────────────────────────┐    │
│  │   Docker Container (Ubuntu 22.04)   │    │
│  │                                     │    │
│  │  ┌──────────────┐  ┌─────────────┐  │    │
│  │  │  Buildroot   │  │  FreeRTOS   │  │    │
│  │  │  (aarch64)   │  │  CLI Build  │  │    │
│  │  └──────┬───────┘  └──────┬──────┘  │    │
│  │         │                 │          │    │
│  │  qemu-system-aarch64   qemu-system-arm    │
│  └─────────────────────────────────────┘    │
└─────────────────────────────────────────────┘
```

### Linux 부팅 체인 (aarch64)

```
QEMU virt machine (-M virt,secure=on -cpu cortex-a57)
     │
     ▼
 BL1 (bl1.bin)        — ATF Boot ROM
     │  semihosting으로 bl2.bin 로드
     ▼
 BL2 (bl2.bin)        — ATF Trusted Boot
     │  semihosting으로 bl31.bin, bl33.bin 로드
     ▼
 BL31 (bl31.bin)      — ATF Runtime (EL3, TrustZone)
     │
     ▼
 BL33 / U-Boot        — bl33.bin은 u-boot.bin의 심볼릭 링크
     │
     ▼
 Linux Kernel (Image) + rootfs (rootfs.ext4)
```

**핵심 QEMU 옵션:**
```bash
-M virt,secure=on          # TrustZone 활성화 (ATF 필수)
-cpu cortex-a57
-bios bl1.bin              # ATF BL1 진입점
-semihosting-config enable=on,target=native  # BL2/BL31/BL33 로드
-kernel Image              # Linux 커널
-append "rootwait root=/dev/vda console=ttyAMA0"
```

> ATF semihosting은 QEMU 실행 디렉토리(`buildroot/output/images/`)에서
> `bl2.bin`, `bl31.bin`, `bl33.bin`을 로드합니다.

### FreeRTOS CLI 아키텍처 (Cortex-M3)

```
QEMU mps2-an385 machine (-machine mps2-an385 -cpu cortex-m3)
     │
     ▼
startup.c          — 벡터 테이블, .data/.bss 초기화
     │
     ▼
main()
  ├── uart_init()              — CMSDK UART0 (0x40004000) TX+RX 활성화
  ├── vRegisterCLICommands()  — CLI 명령어 5개 등록
  ├── xTaskCreate(vCLITask)   — CLI 태스크 생성 (스택 2KB)
  └── vTaskStartScheduler()  — FreeRTOS 스케줄러 시작
         │
         ▼
    vCLITask (non-blocking loop)
      ├── uart_getchar_nonblock() — 입력 없으면 vTaskDelay(10ms)
      ├── 문자 에코 + 백스페이스 처리
      └── Enter → FreeRTOS_CLIProcessCommand() 호출
```

**CMSDK UART0 레지스터 (base: 0x40004000):**

| 레지스터 | 오프셋 | 설명 |
|---|---|---|
| DATA | +0x00 | 송수신 데이터 |
| STATE | +0x04 | bit0=TXFULL, bit1=RXFULL |
| CTRL | +0x08 | bit0=TX_EN, bit1=RX_EN |
| BAUDDIV | +0x10 | 보레이트 분주비 (16 설정) |

### Docker 빌드 시스템 설계

**마운트 경로: `/workspace` 대신 `$TOP:$TOP`을 사용하는 이유**

Buildroot는 빌드 과정에서 호스트 툴(fakeroot 등)을 컴파일하고, 생성된 스크립트 내부에 **절대 경로를 하드코딩**합니다. `/workspace`처럼 다른 경로로 마운트하면 `libfakeroot.so not found` 오류가 발생합니다. 호스트와 동일한 절대 경로로 마운트(`$TOP:$TOP`)하면 이 문제를 방지할 수 있습니다.

**다운로드 캐시 (`.docker-dl/`)**

Buildroot는 소스 코드를 `dl/` 디렉토리에 캐시합니다. 이를 호스트 볼륨으로 마운트하면 (`BR2_DL_DIR=/dl`) Docker 이미지를 재생성하거나 `buildroot/`를 삭제해도 재다운로드가 필요 없습니다.

### 디렉토리 구조

```
.
├── build.sh                  # 통합 빌드 스크립트 (Docker wrapper 포함)
├── run.sh                    # QEMU 실행 스크립트 (Docker wrapper 포함)
├── Dockerfile                # 빌드 환경 정의 (Ubuntu 22.04)
├── scripts/
│   └── docker_lib.sh         # Docker 자동설치 로직 (Linux/macOS)
├── freertos_cli/             # FreeRTOS CLI 소스 (git tracked)
│   ├── FreeRTOSConfig.h      # FreeRTOS 커널 설정
│   ├── main.c                # CLI 태스크, FreeRTOS 훅
│   ├── uart.h / uart.c       # CMSDK UART0 드라이버
│   ├── cli_commands.h/c      # CLI 명령어 구현
│   ├── startup.c             # 벡터 테이블, Reset_Handler
│   ├── mps2_m3.ld            # 링커 스크립트
│   └── Makefile
├── buildroot_patches/        # Buildroot 커스텀 패치
├── buildroot/                # Buildroot 클론 (git ignored)
├── FreeRTOS/                 # FreeRTOS 클론 (git ignored)
├── freertos_images/          # FreeRTOS 빌드 출력 (git ignored)
└── .docker-dl/               # Buildroot 다운로드 캐시 (git ignored)
```

---

## Release Note

### v1.3.0 — Docker 범용 빌드 환경

**추가:**
- Docker 기반 범용 빌드 환경 (`Dockerfile`, `scripts/docker_lib.sh`)
- Docker 미설치 시 자동 설치
  - Linux: `get.docker.com` 공식 스크립트 (Ubuntu, Debian, Fedora, CentOS 등)
  - macOS: Homebrew + Colima (경량 Docker 런타임)
- Buildroot 다운로드 캐시 볼륨 마운트 (`.docker-dl/`)
- `sudo -n` 폴백으로 TTY 없는 환경에서도 동작

**수정:**
- Docker 마운트 경로 `/workspace` → `$TOP:$TOP` 변경 (fakeroot 절대경로 문제 해결)
- `Dockerfile`에 `libnewlib-arm-none-eabi` 추가 (ARM C 표준 헤더 누락 수정)

**검증:**
- Ubuntu 22.04 LTS, Docker Engine 29.4.3 ✅
- `./build.sh freertos` → Docker 빌드 → FreeRTOS 컴파일 → 완료 ✅
- `./run.sh freertos` → QEMU CLI 프롬프트 → 명령어 동작 ✅
- `./build.sh buildroot` → Buildroot 전체 빌드 ✅

---

### v1.2.0 — FreeRTOS CLI Shell

**추가:**
- `freertos_cli/` — 인터랙티브 CLI 쉘 애플리케이션 (git tracked)
  - `task-stats`, `echo`, `version`, `uptime`, `free-heap` 명령어
  - Non-blocking UART 폴링 + `vTaskDelay(10ms)` (CPU 점유 없이 대기)
  - 백스페이스, 문자 에코, `$ ` 프롬프트
- `build.sh` freertos 타겟을 blinky 데모 → CLI 앱으로 전환

**사용 스택:**
- FreeRTOS V11.1.0+, FreeRTOS+CLI
- arm-none-eabi-gcc 10.3.1 (Ubuntu 22.04 apt)
- QEMU 6.2.0, mps2-an385 machine

---

### v1.1.0 — 스크립트 통합 및 QEMU 실행 분리

**추가:**
- `build.sh` — 기존 7개 스크립트를 단일 파일로 통합
- `run.sh` — QEMU 실행을 별도 스크립트로 분리
  - `--smp`, `--mem`, `--no-net`, `--no-pcie-disk`, `--usb-storage`, `--gdb` 옵션
- FreeRTOS QEMU 빌드/실행 초기 지원

---

### v1.0.0 — aarch64 Linux 부팅 체인

**추가:**
- ATF v2.12 + U-Boot 2026.04 + Linux 6.18.7 풀 부팅 체인 구축
- Buildroot 기반 빌드 자동화 (`qemu_aarch64_virt_defconfig`)
- `CONFIG_PRINTK_TIME=y` 커널 로그 타임스탬프

**수정:**
- `buildroot/.defconfig` (2008년 i686 기본값) 자동 로드 방지
- ATF semihosting `bl33.bin → u-boot.bin` 심볼릭 링크 자동 생성

---

## 알려진 제한사항

| 항목 | 내용 |
|---|---|
| Windows | WSL2 환경에서 동작 (Native PowerShell 미지원) |
| macOS ARM | Colima 기반 Docker로 동작, 빌드 성능 제한 있음 |
| Ubuntu 24.04 | Docker 설치 지원되나 미검증 |
| Buildroot 최초 빌드 | 약 60~90분 소요 (다운로드 포함) |
| docker 그룹 | 설치 직후 재로그인 전까지 `sudo docker` 자동 사용 |
