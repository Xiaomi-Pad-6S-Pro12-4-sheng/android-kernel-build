#!/bin/bash
# 启用 Android 内核 Docker 支持
# 配置容器、命名空间和 cgroup 功能

set -e

echo "🐳 启用 Android 内核 Docker 支持..."

# 检查是否在内核构建目录
if [ ! -f ".config" ]; then
    echo "❌ 错误: 不在内核源码目录或未配置内核"
    exit 1
fi

# 备份原始配置
cp .config .config.backup.docker

echo "🔧 配置容器和命名空间支持..."

# 启用命名空间支持
./scripts/config --enable CONFIG_NAMESPACES
./scripts/config --enable CONFIG_UTS_NS
./scripts/config --enable CONFIG_IPC_NS
./scripts --enable CONFIG_USER_NS
./scripts/config --enable CONFIG_PID_NS
./scripts/config --enable CONFIG_NET_NS

# 启用控制组 (cgroup) 支持
./scripts/config --enable CONFIG_CGROUPS
./scripts/config --enable CONFIG_CGROUP_CPUACCT
./scripts/config --enable CONFIG_CGROUP_DEVICE
./scripts/config --enable CONFIG_CGROUP_FREEZER
./scripts/config --enable CONFIG_CGROUP_SCHED
./scripts/config --enable CONFIG_CGROUP_PERF
./scripts/config --enable CONFIG_CGROUP_BPF
./scripts/config --enable CONFIG_CGROUP_MISC
./scripts/config --enable CONFIG_CGROUP_HUGETLB
./scripts/config --enable CONFIG_CGROUP_PIDS
./scripts/config --enable CONFIG_CGROUP_RDMA

# 启用内存控制组
./scripts/config --enable CONFIG_MEMCG
./scripts/config --enable CONFIG_MEMCG_SWAP
./scripts/config --enable CONFIG_MEMCG_KMEM

# 启用设备映射器 (Device Mapper) - Docker 存储驱动需要
./scripts/config --enable CONFIG_BLK_DEV_DM
./scripts/config --enable CONFIG_DM_THIN_PROVISIONING
./scripts/config --enable CONFIG_DM_SNAPSHOT
./scripts/config --enable CONFIG_DM_MIRROR
./scripts/config --enable CONFIG_DM_LOG_WRITES
./scripts/config --enable CONFIG_DM_INTEGRITY

# 启用 OverlayFS - Docker 常用存储驱动
./scripts/config --enable CONFIG_OVERLAY_FS

# 启用 AUFS 支持 (可选)
./scripts/config --module CONFIG_AUFS_FS
./scripts/config --enable CONFIG_ECRYPT_FS

# 启用网络功能
./scripts/config --enable CONFIG_VETH
./scripts/config --enable CONFIG_BRIDGE
./scripts/config --enable CONFIG_BRIDGE_NETFILTER
./scripts/config --enable CONFIG_IP_NF_FILTER
./scripts/config --enable CONFIG_IP_NF_TARGET_MASQUERADE
./scripts/config --enable CONFIG_NETFILTER_XT_MATCH_ADDRTYPE
./scripts/config --enable CONFIG_NETFILTER_XT_MATCH_CONNTRACK
./scripts/config --enable CONFIG_NF_NAT
./scripts/config --enable CONFIG_NF_NAT_NEEDED

# 启用文件系统支持
./scripts/config --enable CONFIG_EXT4_FS
./scripts/config --enable CONFIG_EXT4_FS_POSIX_ACL
./scripts/config --enable CONFIG_EXT4_FS_SECURITY
./scripts/config --enable CONFIG_FANOTIFY
./scripts/config --enable CONFIG_FHANDLE
./scripts/config --enable CONFIG_INOTIFY_USER
./scripts/config --enable CONFIG_POSIX_MQUEUE

# 启用安全模块
./scripts/config --enable CONFIG_SECCOMP
./scripts/config --enable CONFIG_SECCOMP_FILTER
./scripts/config --enable CONFIG_SECURITY
./scripts/config --enable CONFIG_SECURITY_SELINUX
./scripts/config --enable CONFIG_SECURITY_APPARMOR

# 启用其他容器相关功能
./scripts/config --enable CONFIG_CPUSETS
./scripts/config --enable CONFIG_PROC_PID_CPUSET
./scripts/config --enable CONFIG_IKCONFIG
./scripts/config --enable CONFIG_IKCONFIG_PROC
./scripts/config --enable CONFIG_TMPFS
./scripts/config --enable CONFIG_TMPFS_POSIX_ACL
./scripts/config --enable CONFIG_TMPFS_XATTR
./scripts/config --enable CONFIG_SQUASHFS
./scripts/config --enable CONFIG_SQUASHFS_XATTR
./scripts/config --enable CONFIG_SQUASHFS_ZLIB

# 启用性能监控
./scripts/config --enable CONFIG_DEBUG_FS
./scripts/config --enable CONFIG_KPROBES
./scripts/config --enable CONFIG_TRACEPOINTS

# 启用块设备支持
./scripts/config --enable CONFIG_BLK_CGROUP
./scripts/config --enable CONFIG_BLK_DEV_BSG
./scripts/config --enable CONFIG_IOSCHED_CFQ
./scripts/config --enable CONFIG_CFQ_GROUP_IOSCHED

echo "✅ Docker 支持配置完成!"

# 显示配置状态
echo ""
echo "📋 Docker 功能配置状态:"
echo "命名空间支持:"
grep -E "CONFIG_(NAMESPACES|UTS_NS|IPC_NS|USER_NS|PID_NS|NET_NS)=y" .config || echo "部分命名空间未启用"

echo ""
echo "控制组支持:"
grep -E "CONFIG_CGROUP.*=y" .config | head -10

echo ""
echo "存储驱动支持:"
grep -E "CONFIG_(OVERLAY_FS|AUFS_FS|BLK_DEV_DM)=y" .config

echo ""
echo "下一步: 重新编译内核以使 Docker 支持生效"
echo "运行: make -j\$(nproc)"
