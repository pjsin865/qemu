# QEMU Embedded Development Environment

Docker 하나만 있으면 어떤 시스템에서도 임베디드 타겟을 빌드하고 QEMU로 실행할 수 있는 개발 환경입니다.

## 지원 타겟

| 아키텍처 | OS | 부팅 체인 | 상태 |
|---|---|---|:---:|
| aarch64 / Cortex-A57 | Linux | ATF → U-Boot → Linux | ✅ |
| riscv64 / QEMU virt | Linux | OpenSBI → Linux | ✅ |
| Cortex-M3 / MPS2 AN385 | FreeRTOS CLI | — | ✅ |
| rv32 / QEMU virt | FreeRTOS CLI | — | ✅ |
| Cortex-M3 / MPS2 AN385 | Zephyr Shell | — | ✅ |
| riscv64 / QEMU virt | Zephyr Shell | — | ✅ |

## 빠른 시작

```bash
git clone https://github.com/pjsin865/qemu.git
cd qemu

./build.sh freertos        && ./run.sh freertos         # FreeRTOS CLI — ARM    (~5분)
./build.sh freertos-riscv  && ./run.sh freertos-riscv   # FreeRTOS CLI — RISC-V (~1분)
./build.sh zephyr          && ./run.sh zephyr           # Zephyr Shell — ARM    (~15분)
./build.sh zephyr-riscv    && ./run.sh zephyr-riscv     # Zephyr Shell — RISC-V (~15분)
./build.sh buildroot       && ./run.sh linux            # Linux — aarch64       (~90분)
./build.sh buildroot-riscv && ./run.sh linux-riscv      # Linux — RISC-V        (~90분)
```

> Docker가 없으면 자동으로 설치합니다. `sudo` 비밀번호 1회 입력 외 별도 설정 불필요.

## QEMU 종료

```
Ctrl+A  →  X
```

## 문서

자세한 내용은 **[Wiki](https://github.com/pjsin865/qemu/wiki)** 를 참고하세요.

| 페이지 | 내용 |
|---|---|
| [Getting Started](https://github.com/pjsin865/qemu/wiki/Getting-Started) | 사전 조건, 설치, 첫 실행 |
| [Build Guide](https://github.com/pjsin865/qemu/wiki/Build-Guide) | build.sh 전체 타겟 레퍼런스 |
| [Running Targets](https://github.com/pjsin865/qemu/wiki/Running-Targets) | run.sh 옵션, QEMU 종료 방법 |
| [CLI Reference](https://github.com/pjsin865/qemu/wiki/CLI-Reference) | FreeRTOS CLI · Zephyr Shell 명령어 |
| [Architecture](https://github.com/pjsin865/qemu/wiki/Architecture) | 부팅 체인, Docker 설계 |
| [Troubleshooting](https://github.com/pjsin865/qemu/wiki/Troubleshooting) | 자주 발생하는 문제와 해결법 |
| [Release Notes](https://github.com/pjsin865/qemu/wiki/Release-Notes) | 버전별 변경 이력 |
