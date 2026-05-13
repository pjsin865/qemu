# docker_lib.sh — sourced by build.sh and run.sh
# Provides: _ensure_docker, DOCKER_CMD

# ─────────────────────────────────────────────────────────────

_detect_os() {
    case "$(uname -s)" in
        Darwin)
            echo "macos" ;;
        Linux)
            if [ -f /etc/os-release ]; then
                # shellcheck disable=SC1091
                . /etc/os-release
                echo "${ID:-linux}"
            else
                echo "linux"
            fi ;;
        *)
            echo "unknown" ;;
    esac
}

# ── Linux: Docker 공식 설치 스크립트 ──────────────────────────

_install_docker_linux() {
    echo "==> Installing Docker (get.docker.com)..."
    if ! command -v curl >/dev/null 2>&1; then
        # curl이 없으면 먼저 설치
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update -qq && sudo apt-get install -y -qq curl
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y -q curl
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y -q curl
        fi
    fi

    curl -fsSL https://get.docker.com | sudo sh

    # 현재 사용자를 docker 그룹에 추가
    if [ -n "${SUDO_USER:-}" ]; then
        sudo usermod -aG docker "$SUDO_USER"
    elif [ -n "${USER:-}" ] && [ "$USER" != "root" ]; then
        sudo usermod -aG docker "$USER"
    fi

    # Docker 서비스 시작
    if command -v systemctl >/dev/null 2>&1; then
        sudo systemctl enable --now docker
    elif command -v service >/dev/null 2>&1; then
        sudo service docker start
    fi

    echo ""
    echo "Docker installed successfully."
    echo "NOTE: You may need to re-login for group changes to take full effect."
    echo "      For this session, 'sudo docker' will be used automatically."
    echo ""
}

# ── macOS: Homebrew + Colima ──────────────────────────────────

_install_docker_macos() {
    echo "==> Installing Docker on macOS..."

    if ! command -v brew >/dev/null 2>&1; then
        echo "==> Installing Homebrew first..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Apple Silicon 경로 설정
        if [ -f /opt/homebrew/bin/brew ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    fi

    echo "==> Installing docker CLI + colima (lightweight Docker runtime)..."
    brew install docker colima

    echo "==> Starting colima..."
    colima start --cpu 4 --memory 8 --disk 60

    echo ""
    echo "Docker (colima) installed and started."
    echo "To start colima on next boot: colima start"
    echo ""
}

# ── 권한 확인 (설치 후 sudo 필요 여부) ───────────────────────

_resolve_docker_cmd() {
    if docker info >/dev/null 2>&1; then
        DOCKER_CMD="docker"
    elif sudo -n docker info >/dev/null 2>&1; then
        # -n: non-interactive (no password prompt), works when NOPASSWD is set
        DOCKER_CMD="sudo docker"
        echo "Note: using 'sudo docker'"
        echo "  To use docker without sudo: sudo usermod -aG docker \$USER && newgrp docker"
    else
        echo "" >&2
        echo "ERROR: Cannot connect to Docker daemon." >&2
        echo "" >&2
        echo "  1. Add yourself to the docker group:" >&2
        echo "       sudo usermod -aG docker \$USER && newgrp docker" >&2
        echo "" >&2
        echo "  2. Or start the Docker daemon:" >&2
        echo "       sudo systemctl start docker" >&2
        exit 1
    fi
}

# ── macOS colima 자동 시작 ────────────────────────────────────

_ensure_colima_running() {
    if command -v colima >/dev/null 2>&1; then
        if ! colima status 2>/dev/null | grep -q "Running"; then
            echo "==> Starting colima..."
            colima start
        fi
    fi
}

# ── 메인: Docker 확인 + 없으면 설치 ──────────────────────────

_ensure_docker() {
    local os
    os="$(_detect_os)"

    # macOS: colima 먼저 확인
    if [ "$os" = "macos" ]; then
        _ensure_colima_running
    fi

    if ! command -v docker >/dev/null 2>&1; then
        echo "==> Docker not found. Installing automatically..."
        case "$os" in
            macos)   _install_docker_macos ;;
            unknown)
                echo "ERROR: Unsupported OS. Install Docker manually:" >&2
                echo "  https://docs.docker.com/get-docker/" >&2
                exit 1 ;;
            *)
                # ubuntu, debian, fedora, centos, arch, etc.
                _install_docker_linux ;;
        esac
    fi

    _resolve_docker_cmd
}

DOCKER_CMD="docker"
