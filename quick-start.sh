#!/bin/bash
# 快速启动构建脚本

set -e

echo "🚀 Android 内核构建快速启动"

# 检查是否在正确的目录
if [ ! -f "scripts/build-kernel.sh" ]; then
    echo "❌ 错误: 请在项目根目录运行此脚本"
    exit 1
fi

# 创建设备选择菜单
echo ""
echo "📱 请选择要构建的设备:"
echo "1. 红米 K60 (mondrian)"
echo "2. 红米 K70 (vermeer)" 
echo "3. 小米 Pad 6S Pro (sheng)"
echo "4. 全部设备"
echo ""

read -p "请输入选择 (1-4): " choice

case $choice in
    1)
        DEVICE="mondrian"
        ;;
    2)
        DEVICE="vermeer"
        ;;
    3)
        DEVICE="sheng"
        ;;
    4)
        echo "🔨 构建所有设备..."
        for device in mondrian vermeer sheng; do
            echo "构建设备: $device"
            bash scripts/build-kernel.sh --device $device --toolchain clang
        done
        exit 0
        ;;
    *)
        echo "❌ 无效选择"
        exit 1
        ;;
esac

# 创建基础配置（如果不存在）
if [ ! -f "arch/arm64/configs/${DEVICE}_defconfig" ]; then
    echo "📝 创建基础配置文件..."
    bash scripts/create-default-configs.sh
fi

# 开始构建
echo "🔨 开始构建 $DEVICE 内核..."
bash scripts/build-kernel.sh \
    --device $DEVICE \
    --toolchain clang \
    --jobs $(nproc)

echo "✅ 构建完成!"
