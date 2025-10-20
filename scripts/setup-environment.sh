#!/bin/bash

# Xiaomi Pad 6S Pro 内核构建环境设置脚本
# 设备代号: sheng
# 内核版本: Linux 5.15.x

set -e

# 确保路径处理正确，兼容不同操作系统
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null || pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null || pwd)"

# 确保路径使用正确的分隔符
ROOT_DIR=$(echo "$ROOT_DIR" | sed 's/\\/\//g')
SCRIPT_DIR=$(echo "$SCRIPT_DIR" | sed 's/\\/\//g')

echo "==================================================="
echo "设置 Xiaomi Pad 6S Pro 内核构建环境"
echo "==================================================="

# 检查操作系统
echo "[*] 检查操作系统..."
if [[ "$(uname -s)" == "Linux" ]]; then
    OS="Linux"
    # 检查包管理器
    if command -v apt-get &> /dev/null; then
        PKG_MANAGER="apt-get"
    elif command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
    elif command -v pacman &> /dev/null; then
        PKG_MANAGER="pacman"
    else
        echo "[!] 不支持的包管理器。请手动安装依赖。"
        exit 1
    fi
elif [[ "$(uname -s)" == "Darwin" ]]; then
    OS="macOS"
    if ! command -v brew &> /dev/null; then
        echo "[!] 请先安装Homebrew: https://brew.sh/"
        exit 1
    fi
    PKG_MANAGER="brew"
else
    echo "[!] 不支持的操作系统。请使用Linux或macOS进行构建。"
    exit 1
fi

# 创建必要的目录结构
echo "[*] 创建目录结构..."
mkdir -p "$ROOT_DIR/toolchains"
mkdir -p "$ROOT_DIR/out/sheng"
mkdir -p "$ROOT_DIR/kernel/sheng"
mkdir -p "$ROOT_DIR/build"

# 安装系统依赖
echo "[*] 安装系统依赖..."
if [[ "$OS" == "Linux" ]]; then
    if [[ "$PKG_MANAGER" == "apt-get" ]]; then
        sudo apt-get update
        sudo apt-get install -y \
            build-essential \
            libncurses5-dev \
            libssl-dev \
            flex \
            bison \
            libelf-dev \
            libdw-dev \
            libdwarf-dev \
            zlib1g-dev \
            binutils-dev \
            libiberty-dev \
            git \
            ccache \
            curl \
            wget \
            unzip \
            python3 \
            python3-pip \
            rsync \
            bc \
            dwarves
    elif [[ "$PKG_MANAGER" == "dnf" ]]; then
        sudo dnf install -y \
            gcc-c++ \
            ncurses-devel \
            openssl-devel \
            flex \
            bison \
            elfutils-libelf-devel \
            elfutils-devel \
            zlib-devel \
            binutils-devel \
            git \
            ccache \
            curl \
            wget \
            unzip \
            python3 \
            python3-pip \
            rsync \
            bc \
            dwarves
    elif [[ "$PKG_MANAGER" == "pacman" ]]; then
        sudo pacman -Syu --noconfirm \
            base-devel \
            ncurses \
            openssl \
            flex \
            bison \
            elfutils \
            zlib \
            binutils \
            git \
            ccache \
            curl \
            wget \
            unzip \
            python \
            python-pip \
            rsync \
            bc \
            dwarves
    fi
elif [[ "$OS" == "macOS" ]]; then
    brew install \
        autoconf \
        automake \
        libtool \
        pkg-config \
        flex \
        bison \
        ccache \
        git \
        curl \
        wget \
        unzip \
        python \
        rsync \
        openssl
fi

# 安装Python依赖
echo "[*] 安装Python依赖..."
python3 -m pip install --upgrade pip
python3 -m pip install pyelftools

# 配置ccache
echo "[*] 配置ccache..."
export CCACHE_DIR="$ROOT_DIR/.ccache"
mkdir -p "$CCACHE_DIR"
ccache --max-size=50G

# 配置环境变量
echo "[*] 配置环境变量..."
cat > "$ROOT_DIR/.env" << EOF
# Xiaomi Pad 6S Pro 构建环境变量
DEVICE=sheng
KERNEL_VERSION=5.15
ARCH=arm64
CROSS_COMPILE=aarch64-linux-gnu-
CROSS_COMPILE_ARM32=arm-linux-gnueabi-
CCACHE_DIR=$CCACHE_DIR
TOOLCHAIN_DIR=$ROOT_DIR/toolchains
OUTPUT_DIR=$ROOT_DIR/out
KERNEL_DIR=$ROOT_DIR/kernel
EOF

echo "==================================================="
echo "环境设置完成！"
echo "接下来请执行:"
echo "  1. 下载工具链: bash scripts/download-toolchains.sh"
echo "  2. 下载依赖: bash scripts/download-qcom-deps.sh"
echo "  3. 构建内核: bash scripts/build-kernel.sh"
echo "==================================================="