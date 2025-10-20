#!/bin/bash

# Xiaomi Pad 6S Pro 工具链下载脚本
# 设备代号: sheng
# 内核版本: Linux 5.15.x

set -e

# 确保路径处理正确，兼容不同操作系统
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null || pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null || pwd)"

# 确保路径使用正确的分隔符
ROOT_DIR=$(echo "$ROOT_DIR" | sed 's/\\/\//g')
SCRIPT_DIR=$(echo "$SCRIPT_DIR" | sed 's/\\/\//g')

TOOLCHAIN_DIR="$ROOT_DIR/toolchains"

# 加载环境变量
if [ -f "$ROOT_DIR/.env" ]; then
    source "$ROOT_DIR/.env"
fi

echo "==================================================="
echo "下载 Xiaomi Pad 6S Pro 内核构建工具链"
echo "==================================================="

# 创建工具链目录
mkdir -p "$TOOLCHAIN_DIR"
cd "$TOOLCHAIN_DIR"

# 下载URLs
CLANG_URL="https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/main/clang-r463920c.tar.gz"
GCC_URL="https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/+archive/refs/heads/main.tar.gz"
GCC32_URL="https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/+archive/refs/heads/main.tar.gz"

# 下载并解压Clang工具链
echo "[*] 下载Clang工具链..."
if [ ! -d "clang" ]; then
    wget -qO- "$CLANG_URL" | tar -xzf -
    mkdir -p clang
    mv * clang/
    echo "[*] Clang工具链安装完成!"
else
    echo "[*] Clang工具链已存在，跳过下载。"
fi

# 下载并解压AArch64 GCC工具链
echo "[*] 下载AArch64 GCC工具链..."
if [ ! -d "aarch64-linux-android-4.9" ]; then
    wget -qO- "$GCC_URL" | tar -xzf -
    echo "[*] AArch64 GCC工具链安装完成!"
else
    echo "[*] AArch64 GCC工具链已存在，跳过下载。"
fi

# 下载并解压ARM32 GCC工具链
echo "[*] 下载ARM32 GCC工具链..."
if [ ! -d "arm-linux-androideabi-4.9" ]; then
    wget -qO- "$GCC32_URL" | tar -xzf -
    echo "[*] ARM32 GCC工具链安装完成!"
else
    echo "[*] ARM32 GCC工具链已存在，跳过下载。"
fi

# 更新环境变量文件
echo "[*] 更新环境变量..."
cat >> "$ROOT_DIR/.env" << EOF
CLANG_PATH=$TOOLCHAIN_DIR/clang/bin
GCC_PATH=$TOOLCHAIN_DIR/aarch64-linux-android-4.9/bin
GCC32_PATH=$TOOLCHAIN_DIR/arm-linux-androideabi-4.9/bin
PATH=$CLANG_PATH:$GCC_PATH:$GCC32_PATH:\$PATH
EOF

echo "==================================================="
echo "工具链下载完成！"
echo "工具链位置: $TOOLCHAIN_DIR"
echo "接下来请执行: bash scripts/download-qcom-deps.sh"
echo "==================================================="