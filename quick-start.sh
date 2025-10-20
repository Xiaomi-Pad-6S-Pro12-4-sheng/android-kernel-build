#!/bin/bash

# Xiaomi Pad 6S Pro 内核构建快速启动脚本
# 设备代号: sheng
# 处理器: 骁龙 8 Gen 2
# 内核版本: Linux 5.15.x

echo "==================================================="
echo "Xiaomi Pad 6S Pro 内核构建工具"
echo "设备: sheng | 处理器: 骁龙 8 Gen 2 | 内核: 5.15.x"
echo "==================================================="

# 检查脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "\n请选择您要执行的操作:"
echo "1. 设置构建环境"
echo "2. 下载依赖和工具链"
echo "3. 构建标准内核"
echo "4. 构建支持Docker的内核"
echo "5. 在线构建内核（查看GitHub Actions）"
echo "0. 退出"

read -p "请输入选项 [0-5]: " choice

case "$choice" in
    1)
        echo -e "\n[*] 设置构建环境..."
        bash scripts/setup-environment.sh
        ;;
    2)
        echo -e "\n[*] 下载工具链..."
        bash scripts/download-toolchains.sh
        echo -e "\n[*] 下载高通依赖..."
        bash scripts/download-qcom-deps.sh
        ;;
    3)
        echo -e "\n[*] 构建标准内核..."
        bash scripts/build-kernel.sh -d sheng -k 5.15
        ;;
    4)
        echo -e "\n[*] 构建支持Docker的内核..."
        bash scripts/build-kernel.sh -d sheng -k 5.15 --enable-docker
        ;;
    5)
        echo -e "\n[*] 打开GitHub Actions页面..."
        echo "请访问项目的GitHub仓库，进入Actions标签页运行构建工作流"
        echo "URL: https://github.com/[您的用户名]/android-kernel-build/actions"
        ;;
    0)
        echo -e "\n感谢使用，再见！"
        exit 0
        ;;
    *)
        echo -e "\n无效选项，请重新运行脚本并选择有效的选项。"
        exit 1
        ;;
esac

echo -e "\n[*] 操作完成！"