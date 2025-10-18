#!/bin/bash
# Android 内核构建工具链下载脚本
# 下载所有必要的编译工具链

set -e

echo "⬇️  开始下载工具链..."

TOOLCHAIN_DIR="$GITHUB_WORKSPACE/toolchains"
mkdir -p $TOOLCHAIN_DIR
cd $TOOLCHAIN_DIR

# 1. 下载 AOSP Clang (推荐用于 Android 内核)
echo "📥 下载 AOSP Clang 工具链..."
if [ ! -d "aosp-clang" ]; then
    git clone --depth=1 https://github.com/kdrag0n/proton-clang aosp-clang
fi

# 2. 下载 GCC 工具链 (备用)
echo "📥 下载 GCC 交叉编译工具链..."

# ARM64 GCC
if [ ! -d "gcc-arm64" ]; then
    wget -q https://releases.linaro.org/components/toolchain/binaries/latest-7/aarch64-linux-gnu/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu.tar.xz
    tar -xf gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu.tar.xz
    mv gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu gcc-arm64
    rm gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu.tar.xz
fi

# ARM GCC
if [ ! -d "gcc-arm" ]; then
    wget -q https://releases.linaro.org/components/toolchain/binaries/latest-7/arm-linux-gnueabi/gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabi.tar.xz
    tar -xf gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabi.tar.xz
    mv gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabi gcc-arm
    rm gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabi.tar.xz
fi

# 3. 下载 AnyKernel3 (刷机脚本模板)
echo "📥 下载 AnyKernel3..."
if [ ! -d "AnyKernel3" ]; then
    git clone --depth=1 https://github.com/osm0sis/AnyKernel3.git
fi

echo "✅ 工具链下载完成!"
