1. ncurses 패키지 재빌드 (in Buildroot)
   - 기존 빌드된 ncurses와 QEMU를 삭제
     make host-ncurses-dirclean
     make host-qemu-dirclean

   - QEMU를 다시 빌드하면 의존성에 따라 ncurses도 함께 다시 빌드됩
     make host-qemu
