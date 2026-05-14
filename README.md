# QEMU Embedded Development Environment

QEMU 기반 임베디드 개발 환경. **Docker 하나만 있으면** 어떤 시스템에서도 동일하게 빌드하고 실행할 수 있습니다.

다음 타겟을 지원합니다:

| 아키텍처 | OS | 부팅 체인 | QEMU 바이너리 | 상태 |
|----------|----|-----------|---------------|:----:|
| aarch64 / Cortex-A57 | Linux | ATF → U-Boot → Linux | qemu-system-aarch64 | ✅ |
| riscv64 / QEMU virt | Linux | OpenSBI → Linux | qemu-system-riscv64 | ✅ |
| rv32 / QEMU virt | FreeRTOS | — | qemu-system-riscv32 | ✅ |
| riscv64 / QEMU virt | Zephyr | — | qemu-system-riscv64 | ✅ |
| Cortex-M3 / MPS2 AN385 | FreeRTOS | — | qemu-system-arm | ✅ |
| Cortex-M3 / MPS2 AN385 | Zephyr | — | qemu-system-arm | ✅ |

> **검증 상태 표기**
> - ✅ 실제 테스트 완료
> - ⚠️ 미검증 (구현은 완료, 테스트 필요)
> - 🔧 선택 옵션

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

# FreeRTOS CLI (약 5분) ✅
./build.sh freertos
./run.sh freertos

# Zephyr Shell (첫 실행 약 10~15분 — 소스 500MB 다운로드) ✅
./build.sh zephyr
./run.sh zephyr

# Linux full boot — aarch64 (약 60~90분) ✅
./build.sh buildroot
./run.sh linux

# Linux full boot — RISC-V (약 60~90분, 동일 Buildroot 소스 재사용) ✅
./build.sh buildroot-riscv
./run.sh linux-riscv

# Zephyr Shell — RISC-V (첫 실행: west 소스 공유, 빌드 약 5분) ✅
./build.sh zephyr-riscv
./run.sh zephyr-riscv

# FreeRTOS blinky — RISC-V (약 1분) ✅
./build.sh freertos-riscv
./run.sh freertos-riscv
```

> Docker가 없으면 자동으로 설치합니다. `sudo` 비밀번호 1회 입력 외 별도 설정 불필요.
> ⚠️ Docker 자동설치 스크립트는 구현 완료이나 자동 트리거 경로 미검증 (수동 설치 후 동작 확인).

---

## User Manual

### 사전 조건

| 항목 | 요구사항 | 검증 상태 |
|---|---|---|
| OS | Ubuntu 22.04 | ✅ |
| OS | Ubuntu 20.04 / 24.04 | ⚠️ 미검증 |
| OS | macOS (Homebrew + Colima) | ⚠️ 미검증 |
| OS | Windows WSL2 | ⚠️ 미검증 |
| Docker | 없으면 자동 설치 | ⚠️ 자동설치 트리거 미검증 |
| 디스크 | 최소 30GB 여유 공간 (Buildroot 빌드 시) | — |
| 메모리 | 최소 4GB RAM | — |

### build.sh — 빌드 스크립트

**Buildroot (aarch64 / ATF + U-Boot + Linux):**

| 타겟 | 설명 | 검증 |
|------|------|:----:|
| `buildroot` | 전체 빌드 (클론 → 설정 → 빌드) | ✅ |
| `buildroot-uboot` | U-Boot만 재빌드 | ✅ |
| `buildroot-kernel` | Linux 커널만 재빌드 | ✅ |
| `buildroot-clean` | 클린 후 전체 재빌드 | ⚠️ 미검증 |
| `buildroot-uboot-clean` | 클린 후 U-Boot 재빌드 | ⚠️ 미검증 |
| `buildroot-kernel-clean` | 클린 후 커널 재빌드 | ⚠️ 미검증 |
| `menuconfig` | Buildroot menuconfig 실행 | ⚠️ 미검증 |

**Buildroot (riscv64 / OpenSBI + Linux):**

| 타겟 | 설명 | 검증 |
|------|------|:----:|
| `buildroot-riscv` | 전체 빌드 (aarch64 소스 재사용, `O=buildroot_riscv_output`) | ✅ |

**FreeRTOS (rv32 / QEMU virt):**

| 타겟 | 설명 | 검증 |
|------|------|:----:|
| `freertos-riscv` | FreeRTOS blinky 데모 빌드 (rv32imac, xPack GCC 14.x, `RISC-V-Qemu-virt_GCC`) | ✅ |

**Zephyr (riscv64 / qemu_riscv64):**

| 타겟 | 설명 | 검증 |
|------|------|:----:|
| `zephyr-riscv` | Zephyr Shell 빌드 (riscv64, xPack GCC 14.x 사용) | ✅ |

**FreeRTOS (Cortex-M3 / MPS2 AN385):**

| 타겟 | 설명 | 검증 |
|------|------|:----:|
| `freertos` | FreeRTOS CLI 앱 빌드 | ✅ |

**Zephyr (Cortex-M3 / MPS2 AN385):**

| 타겟 | 설명 | 검증 |
|------|------|:----:|
| `zephyr` | Zephyr Shell 앱 빌드 | ✅ |

> Zephyr 첫 빌드 시 `west init` + `west update` 로 ~500MB 소스 다운로드 (5-10분).
> 이후 빌드는 `$TOP/zephyr_workspace/` 에 캐시되어 빠릅니다.

**예시:**
```bash
./build.sh freertos                              # ✅ 검증됨
./build.sh zephyr                               # ✅ 검증됨
./build.sh buildroot                             # ✅ 검증됨
./build.sh buildroot-kernel                      # ✅ 검증됨
./build.sh buildroot-riscv                       # ✅ 검증됨
./build.sh zephyr-riscv                          # ✅ 검증됨
./build.sh freertos-riscv                        # ✅ 검증됨
BR2_DL_DIR=/mnt/cache ./build.sh buildroot       # ⚠️ 미검증 (커스텀 캐시 경로)
```

### run.sh — QEMU 실행 스크립트

**Targets:**

| 타겟 | 설명 | 검증 |
|------|------|:----:|
| `linux` | ATF → U-Boot → Linux 부팅 (aarch64) | ✅ |
| `linux-riscv` | OpenSBI → Linux 부팅 (riscv64) | ✅ |
| `freertos` | FreeRTOS CLI 쉘 (Cortex-M3) | ✅ |
| `zephyr` | Zephyr Shell (Cortex-M3) | ✅ |
| `zephyr-riscv` | Zephyr Shell (riscv64 / QEMU virt) | ✅ |
| `freertos-riscv` | FreeRTOS blinky 데모 (rv32 / QEMU virt) | ✅ |

**Linux (aarch64) 옵션:**

| 옵션 | 설명 | 검증 |
|------|------|:----:|
| `--smp N` | vCPU 수 (기본: 1) | ✅ |
| `--mem M` | 메모리 크기 (기본: 1024M) | ✅ |
| `--no-net` | 네트워크 비활성화 | ⚠️ 미검증 |
| `--no-pcie-disk` | PCIe 추가 디스크 비활성화 | ⚠️ 미검증 |
| `--usb-storage` | USB xHCI + USB storage 추가 | ⚠️ 미검증 |
| `--gdb` | GDB 서버 활성화 (포트 1234, 연결 대기) | ⚠️ 미검증 |

**Linux (riscv64) 옵션:**

| 옵션 | 설명 | 검증 |
|------|------|:----:|
| `--smp N` | vCPU 수 (기본: 1) | ✅ |
| `--mem M` | 메모리 크기 (기본: 512M) | ✅ |
| `--no-net` | 네트워크 비활성화 | ⚠️ 미검증 |
| `--gdb` | GDB 서버 활성화 (포트 1234, 연결 대기) | ⚠️ 미검증 |

**FreeRTOS (ARM) 옵션:**

| 옵션 | 설명 | 검증 |
|------|------|:----:|
| `--gdb` | GDB 서버 활성화 (포트 1234, 연결 대기) | ⚠️ 미검증 |

**FreeRTOS (RISC-V) 옵션:**

| 옵션 | 설명 | 검증 |
|------|------|:----:|
| `--gdb` | GDB 서버 활성화 (포트 1234, 연결 대기) | ⚠️ 미검증 |

**Zephyr (ARM) 옵션:**

| 옵션 | 설명 | 검증 |
|------|------|:----:|
| `--gdb` | GDB 서버 활성화 (포트 1234, 연결 대기) | ⚠️ 미검증 |

**Zephyr (RISC-V) 옵션:**

| 옵션 | 설명 | 검증 |
|------|------|:----:|
| `--gdb` | GDB 서버 활성화 (포트 1234, 연결 대기) | ⚠️ 미검증 |

**예시:**
```bash
./run.sh freertos                        # ✅ 검증됨
./run.sh linux                           # ✅ 검증됨
./run.sh linux --smp 2 --mem 2048M       # ✅ 검증됨
./run.sh linux --usb-storage             # ⚠️ 미검증
./run.sh linux --gdb                     # ⚠️ 미검증
./run.sh linux-riscv                     # ✅ 검증됨
./run.sh linux-riscv --smp 2 --mem 1024M # ✅ 검증됨
./run.sh freertos --gdb                  # ⚠️ 미검증
./run.sh freertos-riscv                  # ✅ 검증됨
./run.sh freertos-riscv --gdb            # ⚠️ 미검증
./run.sh zephyr                          # ✅ 검증됨
./run.sh zephyr --gdb                    # ⚠️ 미검증
./run.sh zephyr-riscv                    # ✅ 검증됨
./run.sh zephyr-riscv --gdb              # ⚠️ 미검증
```

**QEMU 종료:**

| 타겟 | 종료 방법 | 이유 |
|------|-----------|------|
| `linux` | `Ctrl+A` → `X` | QEMU가 serial+monitor를 mux로 관리. `Ctrl+C`는 Linux 게스트로 전달됨 |
| `linux-riscv` | `Ctrl+A` → `X` | 동일 (mux chardev) |
| `freertos` | `Ctrl+C` | `-monitor none` 설정으로 mux 없음. `Ctrl+C`(SIGINT)가 QEMU 프로세스 자체를 종료 |
| `zephyr` | `Ctrl+C` | 동일 |
| `freertos-riscv` | `Ctrl+A` → `X` | `-chardev stdio,id=con,mux=on` 으로 mux chardev 구성 |
| `zephyr-riscv` | `Ctrl+A` → `X` | `-nographic` 단독 사용 시 mux chardev (monitor+serial 공유) |

### FreeRTOS CLI 명령어 ✅

QEMU 실행 후 `$ ` 프롬프트가 나타나면 아래 명령어를 사용할 수 있습니다:

| 명령어 | 설명 | 검증 |
|---|---|---|
| `help` | 사용 가능한 명령어 목록 | ✅ |
| `task-stats` | FreeRTOS 태스크 목록 및 상태 | ✅ |
| `echo <text>` | 텍스트 출력 (첫 번째 단어만 출력됨) | ✅ (제한 있음) |
| `version` | FreeRTOS 커널 버전 | ✅ |
| `uptime` | 시스템 가동 시간 (ticks 포함) | ✅ |
| `free-heap` | 남은 FreeRTOS 힙 크기 | ✅ |

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

### Zephyr Shell 명령어 ✅

QEMU 실행 후 `uart:~$` 프롬프트가 나타나면 아래 명령어를 사용할 수 있습니다:

| 명령어 | 설명 |
|--------|------|
| `help` | 사용 가능한 명령어 목록 |
| `kernel threads` | Zephyr 스레드 목록 및 상태 |
| `kernel stacks` | 스레드별 스택 사용량 |
| `kernel uptime` | 시스템 가동 시간 (ms) |
| `kernel version` | Zephyr 커널 버전 |
| `shell colors off` | 컬러 출력 비활성화 |

```
*** Booting Zephyr OS build v4.1.0 ***

uart:~$ kernel version
Zephyr version 4.1.0
uart:~$ kernel threads
Scheduler: 1 preemptive thread(s), 0 cooperative thread(s)
uart:~$ kernel uptime
Uptime: 3872 ms
```

### 빌드 진행 상황 모니터링 🔧

```bash
# 빌드 로그를 파일에 저장하면서 동시에 출력
./build.sh buildroot 2>&1 | tee /tmp/build.log

# 다른 터미널에서 진행 상황 확인
tail -f /tmp/build.log | grep ">>>"
```

### GDB 디버깅 ⚠️ 미검증

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
┌─────────────────────────────────────────────────────────────────┐
│                       Host OS (Any)                             │
│                                                                 │
│  ./build.sh ──► docker run ──► 컨테이너 내부 빌드                  │
│  ./run.sh   ──► docker run -it ──► QEMU 실행                     │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │             Docker Container (Ubuntu 22.04)               │  │
│  │                                                           │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │  │
│  │  │Buildroot │  │Buildroot │  │ FreeRTOS │  │  Zephyr  │  │  │
│  │  │(aarch64) │  │(riscv64) │  │CLI Build │  │Shell Bld │  │  │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘  │  │
│  │       │             │             │              │         │  │
│  │  qemu-system  qemu-system    qemu-system-arm (mps2-an385)  │  │
│  │    -aarch64    -riscv64                                    │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Linux 부팅 체인 (aarch64) ✅

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

> ✅ Docker 경유 `./run.sh linux` 포함 전체 부팅 체인 검증 완료.
> (ATF → U-Boot → `Starting kernel` → `Booting Linux` → `buildroot login:`)

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

### Linux 부팅 체인 (riscv64) ✅

```
QEMU virt machine (-M virt)
     │
     ▼
 OpenSBI (fw_jump.bin)    — RISC-V Supervisor Binary Interface (M-mode 펌웨어)
     │  fw_jump: 고정 주소(0x80200000)로 점프, S-mode로 전환
     │  U-Boot 없이 Linux 직접 로드
     ▼
 Linux Kernel (Image)     — riscv64 / QEMU virt
     │  OpenSBI가 Device Tree 전달
     ▼
 rootfs (rootfs.ext2)     — Buildroot 최소 루트파일시스템
     │  /dev/vda → virtio-blk
     ▼
 buildroot login:
```

> ✅ `./run.sh linux-riscv` 전체 부팅 체인 검증 완료.
> (OpenSBI v1.6 → `Linux version 6.18.7` → `Welcome to Buildroot` → `buildroot login:`)

**핵심 QEMU 옵션:**
```bash
-M virt                            # RISC-V 범용 virt 머신
-bios fw_jump.bin                  # OpenSBI (M-mode → S-mode 전환)
-kernel Image                      # Linux 커널 (riscv64)
-append "rootwait root=/dev/vda ro"
-drive file=rootfs.ext2,format=raw # virtio-blk 루트 파일시스템
-netdev user,id=net0 -device virtio-net-device,netdev=net0
```

**aarch64와 riscv64 부팅 체인 비교:**

| 항목 | aarch64 | riscv64 |
|------|---------|---------|
| 펌웨어 계층 | ATF BL1 → BL2 → BL31 → U-Boot | OpenSBI (fw_jump) |
| U-Boot | ✅ 있음 (bl33.bin) | ❌ 없음 (Linux 직접 로드) |
| semihosting | ✅ 필요 (BL2/BL31 로드) | ❌ 불필요 |
| 기본 메모리 | 1024M | 512M |
| 루트파일시스템 | rootfs.ext4 | rootfs.ext2 |
| QEMU 바이너리 | qemu-system-aarch64 | qemu-system-riscv64 |

**Buildroot 멀티 아키텍처 설계 (`O=` 플래그):**

동일한 Buildroot 소스(`buildroot/`)를 재사용하여 RISC-V 전용 출력 디렉토리(`buildroot_riscv_output/`)에 빌드합니다. 소스 클론 없이 디스크 공간을 절약합니다.

```bash
# aarch64 빌드 (기본 O=output/)
make -C buildroot/ qemu_aarch64_virt_defconfig
make -C buildroot/ -j$(nproc)

# riscv64 빌드 (O= 분리 출력)
make -C buildroot/ O=buildroot_riscv_output/ qemu_riscv64_virt_defconfig
make -C buildroot/ O=buildroot_riscv_output/ -j$(nproc)
```

> `FORCE_UNSAFE_CONFIGURE=1`: Docker 내 root 실행 시 `configure: error: you should not run configure as root` 오류 방지. 새 `O=` 디렉토리로 빌드 시 host-tar 등 호스트 툴을 처음 빌드하기 때문에 필요합니다.

### FreeRTOS CLI 아키텍처 (Cortex-M3) ✅

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

### Zephyr Shell 아키텍처 (Cortex-M3) ✅

```
QEMU mps2-an385 machine (-machine mps2-an385 -cpu cortex-m3)
     │
     ▼
 Zephyr OS v4.1.0 (zephyr.elf)
     │  west build -b mps2/an385 samples/subsys/shell/shell_module
     │
     ▼
 Shell 서브시스템
  ├── UART 드라이버 (CMSDK APB UART, 0x40004000)
  ├── Shell 스레드 (우선순위: 14, 스택: 2048B)
  └── 명령어 핸들러
        ├── kernel threads / stacks / uptime / version
        └── shell colors / history / ...
```

**west 워크스페이스 설계 (Python venv 영속화):**

Zephyr의 빌드 도구 `west`는 Python 패키지입니다. Docker 컨테이너는 `--rm`으로 종료 시 삭제되므로, pip 설치 패키지가 사라집니다. 이를 해결하기 위해 venv를 호스트 마운트 경로(`$TOP/.zephyr-venv/`)에 생성합니다.

```
$TOP/ (호스트 ↔ 컨테이너 공유 볼륨)
  ├── .zephyr-venv/          ← Python venv (pip 패키지 영속)
  ├── zephyr_workspace/      ← west workspace (소스 영속)
  │   ├── zephyr/            ← Zephyr 커널 소스
  │   ├── modules/           ← HAL, CMSIS 등
  │   └── build/             ← 빌드 아티팩트
  └── zephyr_images/         ← zephyr.elf (최종 바이너리)
```

**핵심 QEMU 옵션 (FreeRTOS와 동일한 machine):**
```bash
-machine mps2-an385    # ARM MPS2 AN385 플랫폼 (Cortex-M3)
-cpu cortex-m3
-serial stdio          # UART0 → 터미널 연결
-kernel zephyr.elf     # Zephyr ELF 바이너리
```

**툴체인: `ZEPHYR_TOOLCHAIN_VARIANT=gnuarmemb`**

Docker 이미지에 포함된 `arm-none-eabi-gcc`를 그대로 사용합니다. Zephyr SDK(~2GB)를 별도로 설치하지 않아도 됩니다.

```bash
ZEPHYR_TOOLCHAIN_VARIANT=gnuarmemb
GNUARMEMB_TOOLCHAIN_PATH=/usr      # /usr/bin/arm-none-eabi-gcc
```

### Zephyr Shell 아키텍처 (riscv64) ✅

```
QEMU virt machine (-machine virt -cpu rv64 -m 256 -bios none)
     │
     ▼
 Zephyr OS v4.1.0 (zephyr.elf)
     │  west build -b qemu_riscv64 samples/subsys/shell/shell_module
     │
     ▼
 Shell 서브시스템
  ├── UART 드라이버 (NS16550A, 0x10000000)
  ├── Shell 스레드
  └── 명령어 핸들러 (kernel threads / stacks / uptime / version)
```

**ARM vs RISC-V Zephyr 비교:**

| 항목 | Cortex-M3 (ARM) | riscv64 |
|------|-----------------|---------|
| 보드 | `mps2/an385` | `qemu_riscv64` |
| QEMU 머신 | `-machine mps2-an385` | `-machine virt` |
| BIOS | (없음) | `-bios none` (OpenSBI 제외) |
| CPU | `-cpu cortex-m3` | `-cpu rv64` |
| 메모리 | (기본) | `-m 256` |
| UART | CMSDK APB UART (0x40004000) | NS16550A (0x10000000) |
| 종료 | `Ctrl+C` | `Ctrl+A` → `X` |
| 툴체인 | arm-none-eabi-gcc (Ubuntu apt) | xPack riscv-none-elf-gcc 14.x |

**xPack RISC-V GCC 사용 이유:**

Ubuntu 22.04의 `gcc-riscv64-unknown-elf` (GCC 10.2.0)는 Zephyr 4.x가 요구하는 `rv64imac_zicsr_zifencei` ISA 확장 표기(RISC-V 스펙 20191213 표준)를 지원하지 않습니다. GCC 11+부터 지원되며, 이 프로젝트는 [xPack RISC-V GCC 14.2.0](https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack)을 Dockerfile에서 직접 설치합니다 (~150MB).

```
Toolchain prefix: riscv-none-elf-
Install path: /opt/xpack-riscv-none-elf-gcc-14.2.0-2/
```

### FreeRTOS 아키텍처 (rv32 / QEMU virt) ✅

```
QEMU virt machine (-machine virt -bios none -smp 4)
     │
     ▼
 FreeRTOS V11.1.0 (RTOSDemo.axf, rv32imac_zicsr)
     │  Demo: RISC-V-Qemu-virt_GCC (Katsuhiro Suzuki)
     │
     ▼
 Task 구조
  ├── prvQueueSendTask (우선순위 1)
  │     └── 1초마다 큐에 메시지 전송 ("Transfer1"/"Transfer2")
  ├── prvQueueReceiveTask (우선순위 2)
  │     └── 큐에서 메시지 수신 → NS16550A UART 출력
  └── IDLE task
```

**ARM FreeRTOS vs RISC-V FreeRTOS 비교:**

| 항목 | Cortex-M3 (ARM) | rv32 (RISC-V) |
|------|-----------------|---------------|
| 소스 | `freertos_cli/` (커스텀 CLI) | `FreeRTOS/Demo/RISC-V-Qemu-virt_GCC/` |
| 데모 유형 | 인터랙티브 CLI 쉘 | Blinky (큐 Tx/Rx 출력) |
| QEMU 머신 | `mps2-an385` (Cortex-M3) | `virt` (-bios none) |
| QEMU 바이너리 | `qemu-system-arm` | `qemu-system-riscv32` |
| SMP | 1코어 | 4코어 (-smp 4) |
| 바이너리 | `RTOSDemo.out` | `RTOSDemo.axf` |
| UART | CMSDK APB (0x40004000) | NS16550A (0x10000000) |
| ISA | Cortex-M3 (Thumb-2) | rv32imac_zicsr |
| 툴체인 | arm-none-eabi-gcc (Ubuntu apt) | xPack riscv-none-elf-gcc 14.x |

**출력 예시:**
```
Hello FreeRTOS!
0: Tx: Transfer1
0: Rx: Blink1
0: Tx: Transfer2
0: Rx: Blink2
```

> `0:` 접두사는 hart ID (코어 번호). SMP 4코어 설정이지만 FreeRTOS는 hart 0에서만 실행합니다.

### Docker 빌드 시스템 설계

**마운트 경로: `/workspace` 대신 `$TOP:$TOP`을 사용하는 이유** ✅

Buildroot는 빌드 과정에서 호스트 툴(fakeroot 등)을 컴파일하고, 생성된 스크립트 내부에 **절대 경로를 하드코딩**합니다. `/workspace`처럼 다른 경로로 마운트하면 `libfakeroot.so not found` 오류가 발생합니다. 호스트와 동일한 절대 경로로 마운트(`$TOP:$TOP`)하면 이 문제를 방지할 수 있습니다.

**다운로드 캐시 (`.docker-dl/`)** ✅

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
├── buildroot/                # Buildroot 클론 — aarch64 소스 (git ignored)
│   └── output/images/        # aarch64 빌드 출력 (bl1.bin, Image, rootfs.ext4 등)
├── buildroot_riscv_output/   # Buildroot RISC-V 출력 (git ignored)
│   └── images/               # riscv64 빌드 출력 (fw_jump.bin, Image, rootfs.ext2 등)
├── FreeRTOS/                 # FreeRTOS 클론 (git ignored)
├── freertos_images/          # FreeRTOS 빌드 출력 (git ignored)
├── zephyr_workspace/         # Zephyr west 워크스페이스 (git ignored)
│   ├── zephyr/               # Zephyr 커널 소스
│   ├── modules/              # HAL, CMSIS 등 모듈
│   └── build/                # 빌드 아티팩트
├── zephyr_images/            # Zephyr 빌드 출력 (git ignored)
├── .zephyr-venv/             # Zephyr Python venv (git ignored)
└── .docker-dl/               # Buildroot 다운로드 캐시 (git ignored)
```

---

## Release Note

### v1.7.0 — RISC-V FreeRTOS 지원 ✅

**추가:**
- RISC-V FreeRTOS 타겟 (`./build.sh freertos-riscv` / `./run.sh freertos-riscv`)
  - FreeRTOS `RISC-V-Qemu-virt_GCC` 데모 (rv32imac_zicsr, Blinky 큐 Tx/Rx)
  - `Hello FreeRTOS!` + 큐 메시지 출력 (`0: Tx: Transfer1`, `0: Rx: Blink1`, ...)
  - 4코어 SMP 시뮬레이션 (`-smp 4`), FreeRTOS는 hart 0에서 실행
- xPack `riscv-none-elf-gcc` 14.x 재사용 (Zephyr RISC-V와 동일 툴체인)
  - Makefile GCC 버전 감지 (`grep ^$CC`)가 full path prefix로 동작하지 않는 문제:
    `CROSS=riscv-none-elf-` (basename만) + PATH 의존으로 해결
- `.gitignore`에 `freertos_riscv_images/` 추가

**검증 환경: Ubuntu 22.04 LTS, Docker Engine 29.4.3**

| 항목 | 결과 |
|------|------|
| `./build.sh freertos-riscv` (rv32, xPack GCC 14.2.0) | ✅ |
| `./run.sh freertos-riscv` (`Hello FreeRTOS!` + Tx/Rx 큐 메시지) | ✅ |
| qemu-system-riscv32, -machine virt, -smp 4, -bios none | ✅ |

---

### v1.6.0 — RISC-V Zephyr 지원 ✅

**추가:**
- RISC-V Zephyr 타겟 (`./build.sh zephyr-riscv` / `./run.sh zephyr-riscv`)
  - 보드: `qemu_riscv64`, 샘플: `samples/subsys/shell/shell_module`
  - `uart:~$` 프롬프트 및 `kernel threads`, `kernel uptime` 등 동일 명령어 사용 가능
  - 기존 Zephyr west 워크스페이스(`zephyr_workspace/`) 재사용, `build_riscv/` 디렉토리로 분리 빌드
- `Dockerfile`에 xPack RISC-V GCC 14.2.0 추가 (`riscv-none-elf-` 접두사)
  - Ubuntu 22.04 `gcc-riscv64-unknown-elf` (GCC 10.2.0) → 대체: GCC 10이 Zephyr 4.x ISA 확장(`_zicsr`, `_zifencei`) 미지원
- `.gitignore`에 `zephyr_riscv_images/` 추가
- `run.sh` `zephyr-riscv` 타겟: `-machine virt -cpu rv64 -m 256 -bios none` (Zephyr 공식 board.cmake 기준)

**검증 환경: Ubuntu 22.04 LTS, Docker Engine 29.4.3**

| 항목 | 결과 |
|------|------|
| `./build.sh zephyr-riscv` (riscv64, xPack GCC 14.2.0) | ✅ |
| `./run.sh zephyr-riscv` (`uart:~$` 프롬프트 확인) | ✅ |
| `kernel threads` / `kernel uptime` / `kernel version` 명령어 | ✅ |

> **참고:** Docker 이미지를 이미 갖고 있다면 xPack GCC 추가로 인해 재빌드 필요
> ```bash
> docker rmi qemu-dev:latest && ./build.sh zephyr-riscv
> ```

---

### v1.5.0 — RISC-V Linux 지원 ✅

**추가:**
- RISC-V Linux 타겟 (`./build.sh buildroot-riscv` / `./run.sh linux-riscv`)
  - Buildroot `qemu_riscv64_virt_defconfig`, OpenSBI → Linux 직접 부팅 (U-Boot 없음)
  - 동일 Buildroot 소스(`buildroot/`)를 `O=buildroot_riscv_output/` 플래그로 재사용
  - qemu-system-riscv64 (`qemu-system-misc` 패키지), `-M virt`, `-bios fw_jump.bin`
- `Dockerfile`에 `qemu-system-misc` 추가 (RISC-V QEMU 제공)
- `run.sh` `linux-riscv` 타겟: Buildroot 빌드 QEMU 우선, 없으면 시스템 QEMU 폴백
- `.gitignore`에 `buildroot_riscv_output/` 추가
- `FORCE_UNSAFE_CONFIGURE=1` 전역 적용 (`_buildroot_make`): root 실행 시 `host-tar` 등 호스트 툴 configure 오류 방지

**검증 환경: Ubuntu 22.04 LTS, Docker Engine 29.4.3**

| 항목 | 결과 |
|------|------|
| `./build.sh buildroot-riscv` (Buildroot riscv64 전체 빌드) | ✅ |
| `./run.sh linux-riscv` (OpenSBI → Linux → `buildroot login:`) | ✅ |
| `./run.sh linux-riscv --smp 2 --mem 1024M` | ✅ |
| OpenSBI v1.6 부팅 확인 | ✅ |
| Linux 6.18.7 riscv64 커널 부팅 확인 | ✅ |
| `buildroot login:` 프롬프트 확인 | ✅ |

---

### v1.4.0 — Zephyr RTOS 지원 ✅

**추가:**
- Zephyr RTOS Shell 타겟 (`./build.sh zephyr` / `./run.sh zephyr`)
  - Zephyr v4.1.0, `mps2/an385` 보드, `samples/subsys/shell/shell_module`
  - `uart:~$` 프롬프트에서 `kernel threads`, `kernel stacks`, `kernel uptime` 등 사용 가능
- Python `venv`를 호스트 볼륨(`$TOP/.zephyr-venv/`)에 생성 — Docker 재시작 후에도 pip 패키지 유지
- `west` 워크스페이스를 `$TOP/zephyr_workspace/`에 초기화 — 소스 영속, 재다운로드 불필요
- `Dockerfile`에 `python3-venv` 추가
- `.gitignore`에 `zephyr_workspace/`, `zephyr_images/`, `.zephyr-venv/` 추가
- Zephyr SDK 없이 Docker 내 `arm-none-eabi-gcc` 재사용 (`ZEPHYR_TOOLCHAIN_VARIANT=gnuarmemb`)

**검증 환경: Ubuntu 22.04 LTS, Docker Engine 29.4.3**

| 항목 | 결과 |
|------|------|
| `./build.sh zephyr` (west init + build, mps2/an385) | ✅ |
| `./run.sh zephyr` (QEMU, `uart:~$` 프롬프트 확인) | ✅ |
| `kernel threads` / `kernel uptime` / `kernel version` 명령어 | ✅ |
| Zephyr 재빌드 (워크스페이스 캐시 재사용) | ✅ |

> **참고:** Docker 이미지를 이미 갖고 있다면 `python3-venv` 추가로 인해 재빌드 필요
> ```bash
> docker rmi qemu-dev:latest && ./build.sh zephyr
> ```

---

### v1.3.0 — Docker 범용 빌드 환경

**추가:**
- Docker 기반 범용 빌드 환경 (`Dockerfile`, `scripts/docker_lib.sh`)
- Docker 미설치 시 자동 설치
  - Linux: `get.docker.com` 공식 스크립트 (Ubuntu, Debian, Fedora, CentOS 등) ⚠️ 자동 트리거 미검증
  - macOS: Homebrew + Colima (경량 Docker 런타임) ⚠️ 미검증
- Buildroot 다운로드 캐시 볼륨 마운트 (`.docker-dl/`) ✅
- `sudo -n` 폴백으로 TTY 없는 환경에서도 동작 ✅

**수정:**
- Docker 마운트 경로 `/workspace` → `$TOP:$TOP` 변경 (fakeroot 절대경로 문제 해결) ✅
- `Dockerfile`에 `libnewlib-arm-none-eabi` 추가 (ARM C 표준 헤더 누락 수정) ✅

**검증 환경: Ubuntu 22.04 LTS, Docker Engine 29.4.3**

| 항목 | 결과 |
|---|---|
| `./build.sh freertos` (Docker 내부 빌드) | ✅ |
| `./run.sh freertos` (Docker 내부 QEMU) | ✅ |
| `./build.sh buildroot` (Docker 내부 전체 빌드) | ✅ |
| `./run.sh linux` (Docker 경유) | ✅ |
| `./run.sh linux --smp 2 --mem 2048M` | ✅ |
| `./build.sh buildroot-kernel/uboot` | ✅ |
| Docker 자동설치 (Linux) | ⚠️ 스크립트 구현 완료, 트리거 미검증 |
| Docker 자동설치 (macOS) | ⚠️ 미검증 |

---

### v1.2.0 — FreeRTOS CLI Shell ✅

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
- `build.sh` — 기존 7개 스크립트를 단일 파일로 통합 ✅
- `run.sh` — QEMU 실행을 별도 스크립트로 분리
  - `--smp`, `--mem`, `--no-net`, `--no-pcie-disk`, `--usb-storage`, `--gdb` 옵션 ⚠️ 미검증
- FreeRTOS QEMU 빌드/실행 초기 지원 ✅

---

### v1.0.0 — aarch64 Linux 부팅 체인 ✅

**추가:**
- ATF v2.12 + U-Boot 2026.04 + Linux 6.18.7 풀 부팅 체인 구축
- Buildroot 기반 빌드 자동화 (`qemu_aarch64_virt_defconfig`)
- `CONFIG_PRINTK_TIME=y` 커널 로그 타임스탬프

**수정:**
- `buildroot/.defconfig` (2008년 i686 기본값) 자동 로드 방지
- ATF semihosting `bl33.bin → u-boot.bin` 심볼릭 링크 자동 생성

> ⚠️ v1.0.0 검증은 Docker 도입 전 호스트 직접 실행 환경 기준.

---

## 트러블슈팅

### Docker 설치 후 `Cannot connect to Docker daemon` 오류

Docker 자동 설치 후 **현재 셸 세션에 docker 그룹이 아직 적용되지 않은** 상태입니다.

```bash
# 해결 방법 1: 현재 세션에 즉시 적용
newgrp docker

# 해결 방법 2: 새 터미널 열기 (또는 VSCode 재시작)
# → 그룹이 자동 적용됨

# 해결 방법 3: 재로그인
```

스크립트는 `sudo docker`를 자동으로 시도하지만, sudo 비밀번호 캐시가 만료된 경우 위 방법 중 하나로 해결하세요.

---

### `libfakeroot.so not found` 오류 (buildroot 빌드 중)

Buildroot를 **호스트에서 빌드한 후 Docker로 전환**하면 발생할 수 있는 문제입니다.  
Buildroot 호스트 툴 스크립트(fakeroot 등)에 호스트 절대경로가 하드코딩되기 때문입니다.

이 프로젝트는 Docker 마운트를 `$TOP:$TOP`(호스트와 동일한 절대경로)으로 설정하여 이 문제를 방지합니다. 만약 오류가 발생하면:

```bash
# buildroot 디렉토리를 삭제 후 Docker 안에서 처음부터 재빌드
rm -rf buildroot/
./build.sh buildroot
```

---

### Buildroot QEMU 빌드 중 ncurses 관련 오류

`host-qemu` 빌드 시 ncurses 의존성 문제가 발생하면 ncurses와 QEMU를 순서대로 재빌드합니다.

```bash
# Docker 내부에서 실행 (./build.sh 진입 후)
cd buildroot/
make host-ncurses-dirclean
make host-qemu-dirclean
make host-qemu
```

---

### Buildroot 빌드 중 i686 크로스 컴파일러 오류

`buildroot/.defconfig` (2008년 i686 기본값)가 로드되는 경우입니다.  
이 프로젝트의 `build.sh`는 항상 `qemu_aarch64_virt_defconfig`를 사용하므로 정상적으로는 발생하지 않습니다. 만약 발생하면:

```bash
rm -rf buildroot/
./build.sh buildroot
```

---

## 알려진 제한사항 및 미검증 항목

| 항목 | 상태 | 비고 |
|---|---|---|
| `./run.sh linux` (Docker 경유) | ✅ | ATF→U-Boot→Linux login 확인 |
| `./run.sh linux --smp 2 --mem 2048M` | ✅ | SMP 2코어 활성화 확인 |
| `build.sh buildroot-uboot/kernel` 부분 재빌드 | ✅ | |
| `./build.sh buildroot-riscv` | ✅ | OpenSBI + Linux riscv64 전체 빌드 |
| `./run.sh linux-riscv` | ✅ | OpenSBI v1.6 → Linux 6.18.7 → `buildroot login:` |
| `./run.sh linux-riscv --smp 2 --mem 1024M` | ✅ | |
| `run.sh linux-riscv --no-net` | ⚠️ 미검증 | 구현 완료 |
| `run.sh linux-riscv --gdb` | ⚠️ 미검증 | 구현 완료 |
| `./build.sh zephyr-riscv` / `./run.sh zephyr-riscv` | ✅ | Zephyr v4.1.0, qemu_riscv64 |
| `run.sh zephyr-riscv --gdb` | ⚠️ 미검증 | 구현 완료 |
| `./build.sh freertos-riscv` / `./run.sh freertos-riscv` | ✅ | FreeRTOS rv32, qemu-system-riscv32 |
| `run.sh freertos-riscv --gdb` | ⚠️ 미검증 | 구현 완료 |
| Docker 자동설치 자동 트리거 | ⚠️ 미검증 | 수동 설치 후 스크립트 동작 확인 |
| `run.sh --no-net`, `--no-pcie-disk` | ⚠️ 미검증 | 구현 완료 |
| `run.sh --usb-storage` | ⚠️ 미검증 | 구현 완료 |
| `run.sh --gdb` (FreeRTOS/Linux/Zephyr) | ⚠️ 미검증 | 구현 완료 |
| `./build.sh zephyr` / `./run.sh zephyr` | ✅ | Zephyr v4.1.0, mps2/an385 |
| Zephyr Shell 명령어 (`kernel threads` 등) | ✅ | |
| Ubuntu 20.04 / 24.04 | ⚠️ 미검증 | Docker 공식 지원 범위 |
| macOS (Homebrew + Colima) | ⚠️ 미검증 | 구현 완료 |
| Windows WSL2 | ⚠️ 미검증 | — |
| Buildroot 최초 빌드 시간 (aarch64) | — | 약 60~90분 (다운로드 포함) |
| Buildroot 최초 빌드 시간 (riscv64) | — | 약 60~90분 (Buildroot 소스 공유로 일부 단축) |
| Zephyr 최초 빌드 시간 | — | 약 10~15분 (west 소스 500MB 다운로드 포함) |
| docker 그룹 적용 | ✅ | 설치 직후 재로그인 전 `sudo docker` 자동 사용 |
