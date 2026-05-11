# QEMU aarch64 개발 환경

## 프로젝트 개요

Buildroot 기반 QEMU aarch64 개발 환경. ATF + U-Boot + Linux Kernel 부팅 체인 구성.

## 빠른 시작

```bash
# 1. 빌드 (buildroot 클론 + ATF 패치 + 전체 빌드 자동)
./buildroot_build.sh full

# 2. 실행 (ATF → U-Boot → Kernel 부팅)
./run_qemu_uboot_kernel.sh
```

## ATF 부팅 핵심 사항

- QEMU 옵션: `-M virt,secure=on -cpu cortex-a57` 필수 (TrustZone 활성화)
- ATF semihosting이 CWD에서 `bl2.bin`, `bl31.bin`, `bl33.bin` 로드
- `bl33.bin`은 `u-boot.bin`의 심볼릭 링크 — 스크립트에서 자동 생성
- QEMU 실행 전 반드시 `buildroot/output/images/` 디렉토리로 cd 필요

## 빌드 진행 상황 확인

```bash
tail -f /tmp/test_build.log | grep ">>>"
```

## Buildroot 주의사항

- defconfig 변경 시 반드시 `make clean` 후 재빌드 (i686 아티팩트 충돌 방지)
- 다운로드 캐시 재활용: `BR2_DL_DIR=<기존 dl 경로> ./buildroot_build.sh full`
