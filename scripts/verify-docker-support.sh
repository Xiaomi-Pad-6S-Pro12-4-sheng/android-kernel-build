#!/bin/bash
# 验证内核 Docker 支持功能

set -e

echo "🔍 验证内核 Docker 支持..."

KERNEL_IMAGE="$1"
if [ -z "$KERNEL_IMAGE" ]; then
    echo "使用方法: $0 <内核镜像路径>"
    exit 1
fi

# 提取内核配置
echo "📋 提取内核配置..."
if file "$KERNEL_IMAGE" | grep -q "compressed"; then
    # 如果是压缩的内核镜像
    zcat "$KERNEL_IMAGE" | strings | grep "CONFIG_" > kernel_config.txt
else
    strings "$KERNEL_IMAGE" | grep "CONFIG_" > kernel_config.txt
fi

# 检查关键 Docker 功能
check_feature() {
    local feature=$1
    local description=$2
    if grep -q "$feature=y" kernel_config.txt; then
        echo "✅ $description: 已启用"
        return 0
    elif grep -q "$feature=m" kernel_config.txt; then
        echo "⚠️  $description: 模块方式启用"
        return 0
    else
        echo "❌ $description: 未启用"
        return 1
    fi
}

echo ""
echo "🐳 Docker 支持功能检查:"

echo ""
echo "命名空间支持:"
check_feature CONFIG_NAMESPACES "命名空间"
check_feature CONFIG_USER_NS "用户命名空间"
check_feature CONFIG_PID_NS "PID 命名空间"
check_feature CONFIG_NET_NS "网络命名空间"

echo ""
echo "控制组支持:"
check_feature CONFIG_CGROUPS "控制组"
check_feature CONFIG_MEMCG "内存控制组"
check_feature CONFIG_CGROUP_SCHED "CPU 调度控制组"

echo ""
echo "存储驱动:"
check_feature CONFIG_OVERLAY_FS "OverlayFS"
check_feature CONFIG_BLK_DEV_DM "设备映射器"

echo ""
echo "网络功能:"
check_feature CONFIG_VETH "虚拟以太网设备"
check_feature CONFIG_BRIDGE "网桥支持"
check_feature CONFIG_NF_NAT "NAT 支持"

echo ""
echo "安全功能:"
check_feature CONFIG_SECCOMP "Seccomp 过滤"
check_feature CONFIG_SECCOMP_FILTER "Seccomp 过滤器"

# 清理
rm -f kernel_config.txt

echo ""
echo "📊 总结:"
echo "如果所有必需功能都启用，内核应该支持运行 Docker 容器"
echo "在 Android 上运行 Docker 还需要额外的用户空间设置"
