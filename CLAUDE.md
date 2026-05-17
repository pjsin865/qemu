# QEMU 임베디드 개발 환경 — Claude 컨텍스트

## 프로젝트 개요

Docker 기반 QEMU 임베디드 개발 환경.
`git clone` 후 `./build.sh <target>` 한 줄이면 Docker 자동설치 → 빌드 → QEMU 실행까지 완료.

**지원 타겟 (모두 검증 완료 ✅)**

| 타겟 | 아키텍처 | OS/펌웨어 | 빌드 명령 | 실행 명령 |
|---|---|---|---|---|
| `freertos` | Cortex-M3 / MPS2 AN385 | FreeRTOS CLI 쉘 | `./build.sh freertos` | `./run.sh freertos` |
| `freertos-riscv` | rv32 / QEMU virt | FreeRTOS CLI 쉘 | `./build.sh freertos-riscv` | `./run.sh freertos-riscv` |
| `zephyr` | Cortex-M3 / MPS2 AN385 | Zephyr Shell | `./build.sh zephyr` | `./run.sh zephyr` |
| `zephyr-riscv` | riscv64 / QEMU virt | Zephyr Shell | `./build.sh zephyr-riscv` | `./run.sh zephyr-riscv` |
| `buildroot` | aarch64 / Cortex-A57 | ATF+U-Boot+Linux | `./build.sh buildroot` | `./run.sh linux` |
| `buildroot-riscv` | riscv64 / QEMU virt | OpenSBI+Linux | `./build.sh buildroot-riscv` | `./run.sh linux-riscv` |

## 핵심 명령어

```bash
# 빠른 시작 (각각 독립 실행 가능)
./build.sh freertos        && ./run.sh freertos         # ARM FreeRTOS  (~5분)
./build.sh freertos-riscv  && ./run.sh freertos-riscv   # RISC-V FreeRTOS (~1분)
./build.sh zephyr          && ./run.sh zephyr           # ARM Zephyr    (~15분)
./build.sh zephyr-riscv    && ./run.sh zephyr-riscv     # RISC-V Zephyr (~15분)
./build.sh buildroot       && ./run.sh linux            # ARM Linux     (~90분)
./build.sh buildroot-riscv && ./run.sh linux-riscv      # RISC-V Linux  (~90분)

# 부분 재빌드
./build.sh buildroot-uboot    # U-Boot만
./build.sh buildroot-kernel   # 커널만

# QEMU 종료: Ctrl+A → X
```

## 프로젝트 구조

```
.
├── build.sh                   # 통합 빌드 스크립트 (Docker wrapper 포함)
├── run.sh                     # QEMU 실행 스크립트 (Docker wrapper 포함)
├── Dockerfile                 # Ubuntu 22.04 빌드 환경
├── scripts/
│   └── docker_lib.sh          # Docker 자동설치 (Linux/macOS)
├── freertos_cli/              # ARM FreeRTOS CLI 소스 (git tracked)
├── freertos_riscv_cli/        # RISC-V FreeRTOS CLI 소스 (git tracked)
├── buildroot_patches/         # Buildroot 커스텀 패치
├── buildroot/                 # ARM Buildroot 클론 (git ignored)
├── FreeRTOS/                  # FreeRTOS 소스 클론 (git ignored)
├── zephyr_workspace/          # Zephyr west workspace (git ignored)
├── freertos_images/           # ARM FreeRTOS 빌드 출력 (git ignored)
├── freertos_riscv_images/     # RISC-V FreeRTOS 빌드 출력 (git ignored)
├── zephyr_images/             # ARM Zephyr 빌드 출력 (git ignored)
├── zephyr_riscv_images/       # RISC-V Zephyr 빌드 출력 (git ignored)
└── .docker-dl/                # Buildroot 다운로드 캐시 (git ignored)
```

## Docker 설계 — 중요 결정사항

**마운트: `-v $TOP:$TOP` (절대경로 동일하게)**
Buildroot는 빌드 중 생성하는 `fakeroot` 스크립트 안에 호스트 절대경로를 하드코딩함.
`/workspace` 같은 다른 경로로 마운트하면 `libfakeroot.so not found` 오류 발생.
반드시 호스트와 동일한 절대경로로 마운트해야 함.

**다운로드 캐시: `-v .docker-dl:/dl` + `BR2_DL_DIR=/dl`**
Docker 이미지 재빌드 또는 buildroot/ 삭제 후에도 재다운로드 없이 재사용.

**Docker 그룹 적용**
`./build.sh`가 Docker를 자동설치한 직후에는 현재 셸에 docker 그룹이 미적용.
스크립트 내부에서 `sudo -n docker`로 자동 폴백. 영구 해결은 `newgrp docker` 또는 재로그인.

## 타겟별 기술 세부사항

### ARM Linux (buildroot / ATF 부팅 체인)
- QEMU 옵션: `-M virt,secure=on -cpu cortex-a57` (TrustZone 필수)
- ATF semihosting: `buildroot/output/images/` CWD에서 `bl2.bin`, `bl31.bin`, `bl33.bin` 로드
- `bl33.bin` = `u-boot.bin` 심볼릭 링크 (run.sh에서 자동 생성)
- Buildroot defconfig: `qemu_aarch64_virt_defconfig` (절대 `buildroot/.defconfig` 사용 금지 — 2008년 i686 기본값)
- `CONFIG_PRINTK_TIME=y` 패치 적용됨 (`buildroot_patches/`)

### RISC-V Linux (buildroot-riscv / OpenSBI 부팅 체인)
- QEMU 옵션: `-M virt -cpu rv64` 
- OpenSBI → Linux 직접 부팅 (ATF 없음)
- Buildroot defconfig: `qemu_riscv64_virt_defconfig`
- 빌드 출력: `buildroot_riscv_output/` (ARM buildroot와 분리)

### ARM FreeRTOS CLI (freertos_cli/)
- UART: CMSDK UART0 (0x40004000) — STATE bit1=RXFULL, CTRL bit1=RX_EN
- Non-blocking 폴링: `uart_getchar_nonblock()` + `vTaskDelay(10ms)`
- Linker script: FLASH@0x0 4MB, RAM@0x20000000 4MB
- 툴체인: `arm-none-eabi-gcc` + `libnewlib-arm-none-eabi` (Ubuntu 22.04에서 헤더가 별도 패키지)
- CLI 명령어: `help`, `task-stats`, `echo`, `version`, `uptime`, `free-heap`

### RISC-V FreeRTOS CLI (freertos_riscv_cli/)
- UART: QEMU virt UART (RISC-V)
- 툴체인: `gcc-riscv64-unknown-elf` 또는 `riscv64-linux-gnu-gcc`
- 별도 디렉토리 `freertos_riscv_cli/`에 소스 관리

### Zephyr Shell (ARM + RISC-V 공통)
- west workspace: `zephyr_workspace/` (최초 ~500MB 다운로드)
- Python venv: `.zephyr-venv/` (호스트 볼륨 — 컨테이너 재시작 후에도 유지)
- ARM 보드: `mps2/an385`, RISC-V 보드: `qemu_riscv64`
- 샘플: `samples/subsys/shell/shell_module`
- 프롬프트: `uart:~$`

## 빌드 진행 상황 모니터링

```bash
./build.sh buildroot 2>&1 | tee /tmp/build.log
# 다른 터미널에서:
tail -f /tmp/build.log | grep ">>>"
```

## 알려진 이슈 / 주의사항

1. **`libfakeroot.so not found`**: Docker 마운트가 `$TOP:$TOP`이 아닌 경우 발생. build.sh에서 자동 처리됨.
2. **`buildroot/.defconfig` 로드 금지**: buildroot 내부 `.defconfig`는 i686 기본값. build.sh에서 방지됨.
3. **Zephyr 첫 빌드**: `west init` + `west update`로 ~500MB 다운로드 (5-10분). 이후는 캐시 사용.
4. **Docker 그룹**: 설치 직후 `newgrp docker` 또는 재로그인 필요. 스크립트는 `sudo -n docker` 자동 폴백.
5. **모니터링**: Monitor 툴 대신 `tail -f` 사용 (크레딧 절약 — 글로벌 설정).

## 사용자 선호사항

- 진행 여부 확인 없이 바로 실행 (이 프로젝트에서)
- 모니터링은 Monitor 툴 대신 로컬 `tail -f` 명령어로 먼저 안내
- 코드 주석은 최소화, 필요한 경우에만 추가
