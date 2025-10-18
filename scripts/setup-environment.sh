#!/bin/bash
# Android 内核构建环境设置脚本
# 设置构建环境变量和安装系统依赖

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
export KERNEL_DIR="$GITHUB_WORKSPACE/kernel"
export TOOLCHAIN_DIR="$GITHUB_WORKSPACE/toolchains"
export OUT_DIR="$GITHUB_WORKSPACE/out"
export CONFIG_DIR="$GITHUB_WORKSPACE/configs"

# 创建必要的目录
mkdir -p $TOOLCHAIN_DIR $OUT_DIR $CONFIG_DIR $CCACHE_DIR

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
    zip \
    tar \
    ccache \
    patchelf \
    rsync \
    gcc-aarch64-linux-gnu \
    gcc-arm-linux-gnueabi

# 安装 Python 依赖
echo "🐍 安装 Python 依赖..."
pip3 install --upgrade pip
pip3 install \
    pycrypto \
    pyelftools \
    protobuf \
    google

echo "✅ 环境设置完成!"
