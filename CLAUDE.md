# QEMU 임베디드 개발 환경

## 프로젝트 개요

Docker 기반 QEMU 임베디드 개발 환경. Docker 하나만 있으면 어떤 시스템에서도 동일하게 빌드하고 실행할 수 있습니다.

- **Linux**: ATF + U-Boot + Linux 풀 부팅 체인 (aarch64 / Cortex-A57)
- **FreeRTOS**: 인터랙티브 CLI 쉘 (Cortex-M3 / MPS2 AN385)

## 빠른 시작

```bash
# FreeRTOS CLI 빌드 + 실행 (~5분)
./build.sh freertos
./run.sh freertos

# Linux 전체 빌드 + 실행 (~60~90분)
./build.sh buildroot
./run.sh linux
```

## ATF 부팅 핵심 사항

- QEMU 옵션: `-M virt,secure=on -cpu cortex-a57` 필수 (TrustZone 활성화)
- ATF semihosting이 CWD에서 `bl2.bin`, `bl31.bin`, `bl33.bin` 로드
- `bl33.bin`은 `u-boot.bin`의 심볼릭 링크 — `run.sh`에서 자동 생성
- QEMU 실행 전 반드시 `buildroot/output/images/` 디렉토리로 cd (run.sh 내부 자동 처리)

## 빌드 진행 상황 확인

```bash
./build.sh buildroot 2>&1 | tee /tmp/build.log
tail -f /tmp/build.log | grep ">>>"
```

## Buildroot 주의사항

- `buildroot/.defconfig`는 2008년 i686 기본값 — 절대 로드하지 말 것 (build.sh에서 방지됨)
- 다운로드 캐시: `.docker-dl/` 볼륨 마운트로 자동 재사용
- Docker 마운트는 반드시 `$TOP:$TOP` (절대경로 일치) — fakeroot 하드코딩 경로 문제 방지

## Docker 그룹 주의사항

Docker 설치 직후 현재 셸에 그룹이 미적용된 경우:
```bash
newgrp docker   # 또는 새 터미널/VSCode 재시작
```
