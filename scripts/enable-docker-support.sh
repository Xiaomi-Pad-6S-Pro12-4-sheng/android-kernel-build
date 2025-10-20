#!/bin/bash

# 启用Docker支持的内核配置脚本
# 为Xiaomi Pad 6S Pro内核添加Docker必需的功能

set -e

# 确保路径处理正确，兼容不同操作系统
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null || pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null || pwd)"

# 确保路径使用正确的分隔符
ROOT_DIR=$(echo "$ROOT_DIR" | sed 's/\\/\//g')
SCRIPT_DIR=$(echo "$SCRIPT_DIR" | sed 's/\\/\//g')

# 加载环境变量
if [ -f "$ROOT_DIR/.env" ]; then
    source "$ROOT_DIR/.env"
fi

DEVICE="${DEVICE:-sheng}"
CONFIG_FILE="${CONFIG_FILE:-$ROOT_DIR/kernel/$DEVICE/.config}"

echo "==================================================="
echo "为 $DEVICE 启用Docker支持"
echo "==================================================="

# 检查配置文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
    echo "[!] 配置文件不存在: $CONFIG_FILE"
    echo "[!] 请先运行 'make $DEVICE\_defconfig' 生成配置文件"
    exit 1
fi

echo "[*] 正在修改内核配置以支持Docker..."

# Docker必需的内核功能配置
CONFIGS=( 
    # 命名空间支持
    "CONFIG_NAMESPACES=y"
    "CONFIG_UTS_NS=y"
    "CONFIG_IPC_NS=y"
    "CONFIG_USER_NS=y"
    "CONFIG_PID_NS=y"
    "CONFIG_NET_NS=y"
    
    # 控制组支持
    "CONFIG_CGROUPS=y"
    "CONFIG_CGROUP_CPUACCT=y"
    "CONFIG_CGROUP_DEVICE=y"
    "CONFIG_CGROUP_FREEZER=y"
    "CONFIG_CGROUP_SCHED=y"
    "CONFIG_CPUSETS=y"
    "CONFIG_MEMCG=y"
    "CONFIG_KEYS=y"
    "CONFIG_VETH=y"
    "CONFIG_BRIDGE=y"
    "CONFIG_BRIDGE_NETFILTER=y"
    "CONFIG_IP_NF_FILTER=y"
    "CONFIG_IP_NF_TARGET_MASQUERADE=y"
    "CONFIG_NETFILTER_XT_MATCH_ADDRTYPE=y"
    "CONFIG_NETFILTER_XT_MATCH_CONNTRACK=y"
    "CONFIG_NETFILTER_XT_MATCH_IPVS=y"
    "CONFIG_IP_NF_NAT=y"
    "CONFIG_NF_NAT=y"
    "CONFIG_POSIX_MQUEUE=y"
    
    # OverlayFS支持
    "CONFIG_OVERLAY_FS=y"
    "CONFIG_OVERLAY_FS_REDIRECT_DIR=y"
    
    # Device Mapper支持
    "CONFIG_BLK_DEV_DM=y"
    "CONFIG_DM_THIN_PROVISIONING=y"
    
    # 网络功能
    "CONFIG_VXLAN=y"
    "CONFIG_IPVLAN=y"
    "CONFIG_MACVLAN=y"
    "CONFIG_DUMMY=y"
    "CONFIG_OPENVSWITCH=y"
    "CONFIG_GENEVE=y"
    "CONFIG_STP=y"
    
    # 安全功能
    "CONFIG_SECURITY_SELINUX=y"
    "CONFIG_SECURITY_APPARMOR=y"
    "CONFIG_DEFAULT_SECURITY_SELINUX=y"
    "CONFIG_SECURITY=y"
    "CONFIG_SECURITYFS=y"
    "CONFIG_SECURITY_NETWORK=y"
    "CONFIG_SECURITY_PATH=y"
    
    # 其他Docker相关功能
    "CONFIG_CGROUP_PIDS=y"
    "CONFIG_CGROUP_PERF=y"
    "CONFIG_CGROUP_HUGETLB=y"
    "CONFIG_NET_CLS_CGROUP=y"
    "CONFIG_CGROUP_NET_PRIO=y"
    "CONFIG_BLK_CGROUP=y"
    "CONFIG_CGROUP_IO=y"
    "CONFIG_CGROUP_BPF=y"
    "CONFIG_USERFAULTFD=y"
    "CONFIG_HAVE_ARCH_SECCOMP_FILTER=y"
    "CONFIG_SECCOMP_FILTER=y"
    "CONFIG_CHECKPOINT_RESTORE=y"
    "CONFIG_FANOTIFY=y"
    "CONFIG_FANOTIFY_ACCESS_PERMISSIONS=y"
    "CONFIG_EPOLL=y"
    "CONFIG_UNIX_DIAG=y"
    "CONFIG_INET_DIAG=y"
    "CONFIG_PACKET_DIAG=y"
    "CONFIG_NETLINK_DIAG=y"
)

# 应用所有配置
for config in "${CONFIGS[@]}"; do
    # 提取配置名称
    config_name=$(echo "$config" | cut -d'=' -f1)
    
    # 检查并更新配置
    if grep -q "^$config_name=" "$CONFIG_FILE"; then
        sed -i "s/^$config_name=.*/$config/g" "$CONFIG_FILE"
        echo "[*] 更新: $config"
    else
        echo "$config" >> "$CONFIG_FILE"
        echo "[*] 添加: $config"
    fi
done

echo "[*] 正在禁用可能导致问题的选项..."
# 禁用某些可能导致问题的选项
disabled_configs=(
    "CONFIG_RT_GROUP_SCHED"
    "CONFIG_PREEMPT_RT_BASE"
)

for config in "${disabled_configs[@]}"; do
    if grep -q "^$config=y" "$CONFIG_FILE"; then
        sed -i "s/^$config=y/# $config is not set/g" "$CONFIG_FILE"
        echo "[*] 禁用: $config"
    fi
done

# 创建Docker支持验证脚本
echo "[*] 创建Docker支持验证脚本..."
cat > "$ROOT_DIR/scripts/verify-docker-support.sh" << 'EOF'
#!/bin/bash

# Docker支持验证脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${1:-$SCRIPT_DIR/../kernel/$DEVICE/.config}"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "错误: 配置文件不存在: $CONFIG_FILE"
    exit 1
fi

echo "==================================================="
echo "验证Docker支持配置"
echo "==================================================="

# 必需的Docker功能
required_features=(
    # 命名空间
    "CONFIG_NAMESPACES=y"
    "CONFIG_UTS_NS=y"
    "CONFIG_IPC_NS=y"
    "CONFIG_USER_NS=y"
    "CONFIG_PID_NS=y"
    "CONFIG_NET_NS=y"
    
    # 控制组
    "CONFIG_CGROUPS=y"
    "CONFIG_CGROUP_CPUACCT=y"
    "CONFIG_CGROUP_DEVICE=y"
    "CONFIG_CGROUP_FREEZER=y"
    "CONFIG_CGROUP_SCHED=y"
    "CONFIG_CPUSETS=y"
    "CONFIG_MEMCG=y"
    
    # 存储
    "CONFIG_OVERLAY_FS=y"
    "CONFIG_BLK_DEV_DM=y"
    
    # 网络
    "CONFIG_VETH=y"
    "CONFIG_BRIDGE=y"
    "CONFIG_IP_NF_FILTER=y"
    "CONFIG_IP_NF_TARGET_MASQUERADE=y"
)

# 检查功能
echo "[*] 检查必需的Docker功能..."
missing_features=()

for feature in "${required_features[@]}"; do
    if ! grep -q "^$feature" "$CONFIG_FILE"; then
        missing_features+=("$feature")
    fi
done

if [ ${#missing_features[@]} -eq 0 ]; then
    echo "✅ 所有必需的Docker功能都已启用！"
    exit 0
else
    echo "❌ 以下Docker必需功能缺失:"
    for missing in "${missing_features[@]}"; do
        echo "  - $missing"
    done
    echo ""
    echo "请运行 'bash scripts/enable-docker-support.sh' 来启用这些功能"
    exit 1
fi
EOF

chmod +x "$ROOT_DIR/scripts/verify-docker-support.sh"

echo "==================================================="
echo "Docker支持已启用！"
echo "配置文件已更新: $CONFIG_FILE"
echo "可以运行 'bash scripts/verify-docker-support.sh' 来验证配置"
echo "==================================================="