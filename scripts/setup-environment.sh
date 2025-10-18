#!/bin/bash
# Android 内核构建环境设置脚本 - 增强版

set -e

echo "🔧 开始设置 Android 内核构建环境..."

# 设置环境变量
export ARCH=arm64
export SUBARCH=arm64
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
export CCACHE_DIR="$GITHUB_WORKSPACE/.ccache"
export CCACHE_MAXSIZE=5G

# 设置构建目录
export KERNEL_DIR="$GITHUB_WORKSPACE"
export TOOLCHAIN_DIR="$GITHUB_WORKSPACE/toolchains"
export OUT_DIR="$GITHUB_WORKSPACE/out"
export CONFIG_DIR="$GITHUB_WORKSPACE/configs"
export QCOM_DIR="$GITHUB_WORKSPACE/qcom-dependencies"

# 创建必要的目录
mkdir -p $TOOLCHAIN_DIR $OUT_DIR $CONFIG_DIR $CCACHE_DIR $QCOM_DIR

# 更新系统包并安装依赖
echo "📦 安装系统依赖包..."
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    git \
    curl \
    wget \
    python3 \
    python3-pip \
    make \
    bc \
    bison \
    flex \
    libssl-dev \
    libelf-dev \
    libncurses-dev \
    device-tree-compiler \
    lz4 \
    lzop \
    zip \
    tar \
    ccache \
    patchelf \
    rsync \
    gcc-aarch64-linux-gnu \
    gcc-arm-linux-gnueabi \
    gcc-11-aarch64-linux-gnu \
    g++-11-aarch64-linux-gnu \
    xmlstarlet \
    openssl \
    file \
    cpio \
    kmod

# 设置较新的GCC为默认（如果需要）
sudo update-alternatives --install /usr/bin/aarch64-linux-gnu-gcc aarch64-linux-gnu-gcc /usr/bin/aarch64-linux-gnu-gcc-11 100

# 安装 Python 依赖
echo "🐍 安装 Python 依赖..."
pip3 install --upgrade pip
pip3 install \
    pycrypto \
    pyelftools \
    protobuf \
    google \
    requests

echo "✅ 环境设置完成!"
