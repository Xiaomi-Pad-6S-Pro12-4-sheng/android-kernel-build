#!/bin/bash
# 设备特定的 Docker 配置

set -e

DEVICE=$1
if [ -z "$DEVICE" ]; then
    echo "❌ 错误: 必须指定设备"
    echo "使用方法: $0 [mondrian|vermeer|sheng]"
    exit 1
fi

echo "🔧 为设备 $DEVICE 配置 Docker 支持..."

case $DEVICE in
    "mondrian")
        # 红米 K60 - 骁龙8+ Gen 1 特定配置
        ./scripts/config --set-val CONFIG_NR_CPUS 8
        ./scripts/config --enable CONFIG_ARM64_4K_PAGES
        ./scripts/config --enable CONFIG_CPUFREQ_DT
        ;;
    "vermeer"|"sheng")
        # 红米 K70/小米 Pad 6S Pro - 骁龙8 Gen 2 特定配置
        ./scripts/config --set-val CONFIG_NR_CPUS 8
        ./scripts/config --enable CONFIG_ARM64_4K_PAGES
        ./scripts/config --enable CONFIG_CPUFREQ_DT
        ./scripts/config --enable CONFIG_ARM64_PTR_AUTH
        ;;
    *)
        echo "❌ 错误: 不支持的设备 $DEVICE"
        exit 1
        ;;
esac

# 启用大内存支持 (所有设备)
./scripts/config --enable CONFIG_HUGETLBFS
./scripts/config --enable CONFIG_HUGETLB_PAGE
./scripts/config --set-val CONFIG_TRANSPARENT_HUGEPAGE_ALWAYS n
./scripts/config --set-val CONFIG_TRANSPARENT_HUGEPAGE_MADVISE y

# 启用交换支持
./scripts/config --enable CONFIG_SWAP
./scripts/config --enable CONFIG_ZSWAP
./scripts/config --enable CONFIG_ZRAM
./scripts/config --enable CONFIG_ZSMALLOC

echo "✅ 设备 $DEVICE 的 Docker 配置完成!"
