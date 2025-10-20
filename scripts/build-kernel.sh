#!/bin/bash

# Xiaomi Pad 6S Pro 内核构建脚本
# 设备代号: sheng
# 处理器: 骁龙 8 Gen 2
# 内核版本: Linux 5.15.x

set -e

# 确保路径处理正确，兼容不同操作系统
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null || pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null || pwd)"

# 确保路径使用正确的分隔符
ROOT_DIR=$(echo "$ROOT_DIR" | sed 's/\\/\//g')
SCRIPT_DIR=$(echo "$SCRIPT_DIR" | sed 's/\\/\//g')

# 默认参数
DEVICE="sheng"
KERNEL_VERSION="5.15"
CLEAN_BUILD=false
ENABLE_DOCKER=false
TOOLCHAIN="clang"

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--device)
            DEVICE="$2"
            shift 2
            ;;
        -k|--kernel-version)
            KERNEL_VERSION="$2"
            shift 2
            ;;
        -c|--clean)
            CLEAN_BUILD=true
            shift
            ;;
        --enable-docker)
            ENABLE_DOCKER=true
            shift
            ;;
        -t|--toolchain)
            TOOLCHAIN="$2"
            shift 2
            ;;
        *)
            echo "未知选项: $1"
            echo "使用方法: $0 [-d|--device 设备] [-k|--kernel-version 内核版本] [-c|--clean] [--enable-docker] [-t|--toolchain 工具链]"
            exit 1
            ;;
    esac
done

# 加载环境变量
echo "[*] 加载环境变量..."
if [ -f "$ROOT_DIR/.env" ]; then
    source "$ROOT_DIR/.env"
fi

if [ -f "$SCRIPT_DIR/environment-setup.sh" ]; then
    source "$SCRIPT_DIR/environment-setup.sh"
fi

# 设置路径和变量
export DEVICE=$DEVICE
export KERNEL_VERSION=$KERNEL_VERSION
export OUTPUT_DIR="$ROOT_DIR/out/$DEVICE"
export KERNEL_DIR="$ROOT_DIR/kernel/$DEVICE"
export DTB_DIR="$OUTPUT_DIR/dtb"
export MODULES_DIR="$OUTPUT_DIR/modules"
export IMAGE_NAME="Image.gz-dtb"

# 创建输出目录
echo "[*] 创建输出目录..."
mkdir -p "$OUTPUT_DIR" 2>/dev/null || true
mkdir -p "$DTB_DIR" 2>/dev/null || true
mkdir -p "$MODULES_DIR" 2>/dev/null || true

# 确保输出目录权限正确
chmod -R 755 "$OUTPUT_DIR" 2>/dev/null || true

# 显示构建信息
echo "==================================================="
echo "开始构建 Xiaomi Pad 6S Pro 内核"
echo "设备: $DEVICE"
echo "内核版本: $KERNEL_VERSION.x"
echo "处理器: 骁龙 8 Gen 2 (SM8550)"
echo "工具链: $TOOLCHAIN"
echo "Docker支持: $([ $ENABLE_DOCKER = true ] && echo "启用" || echo "禁用")"
echo "清洁构建: $([ $CLEAN_BUILD = true ] && echo "是" || echo "否")"
echo "==================================================="

# 进入内核目录
cd "$KERNEL_DIR"

# 清洁构建
if [ $CLEAN_BUILD = true ]; then
    echo "[*] 执行清洁构建..."
    make mrproper
fi

# 生成默认配置
echo "[*] 生成内核配置..."
if [ -f "arch/arm64/configs/${DEVICE}_defconfig" ]; then
    make O="$OUTPUT_DIR" ARCH=arm64 CROSS_COMPILE=aarch64-linux-android- ${DEVICE}_defconfig
else
    echo "[!] 未找到默认配置文件: arch/arm64/configs/${DEVICE}_defconfig"
    echo "[*] 尝试使用通用配置..."
    make O="$OUTPUT_DIR" ARCH=arm64 CROSS_COMPILE=aarch64-linux-android- defconfig
fi

# 启用Docker支持
if [ $ENABLE_DOCKER = true ]; then
    echo "[*] 启用Docker支持..."
    bash "$SCRIPT_DIR/enable-docker-support.sh"
    # 验证Docker支持
    bash "$SCRIPT_DIR/verify-docker-support.sh" "$OUTPUT_DIR/.config"
fi

# 设置构建命令
if [ "$TOOLCHAIN" = "clang" ]; then
    BUILD_CMD="make -j$(nproc) O=$OUTPUT_DIR \
        ARCH=arm64 \
        CC=clang \
        LD=ld.lld \
        AR=llvm-ar \
        NM=llvm-nm \
        OBJCOPY=llvm-objcopy \
        OBJDUMP=llvm-objdump \
        STRIP=llvm-strip \
        CROSS_COMPILE=aarch64-linux-android- \
        CROSS_COMPILE_ARM32=arm-linux-androideabi- \
        CLANG_TRIPLE=aarch64-linux-gnu-"
elif [ "$TOOLCHAIN" = "gcc" ]; then
    BUILD_CMD="make -j$(nproc) O=$OUTPUT_DIR \
        ARCH=arm64 \
        CROSS_COMPILE=aarch64-linux-android- \
        CROSS_COMPILE_ARM32=arm-linux-androideabi-"
fi

# 开始构建内核
echo "[*] 开始构建内核..."
echo "[*] 使用 $(nproc) 个线程进行编译"
time $BUILD_CMD || {
    echo "[!] 内核构建失败！"
    exit 1
}

# 构建设备树
echo "[*] 构建设备树..."
time $BUILD_CMD dtbs || {
    echo "[!] 设备树构建失败！"
    exit 1
}

# 构建内核模块
echo "[*] 构建内核模块..."
time $BUILD_CMD modules || {
    echo "[!] 内核模块构建失败！"
    exit 1
}

# 安装内核模块
echo "[*] 安装内核模块..."
time $BUILD_CMD O=$OUTPUT_DIR INSTALL_MOD_PATH=$MODULES_DIR modules_install || {
    echo "[!] 内核模块安装失败！"
    exit 1
}

# 复制内核镜像
echo "[*] 复制内核镜像..."
if [ -f "$OUTPUT_DIR/arch/arm64/boot/Image.gz-dtb" ]; then
    cp "$OUTPUT_DIR/arch/arm64/boot/Image.gz-dtb" "$OUTPUT_DIR/$IMAGE_NAME"
    echo "[*] 内核镜像: $OUTPUT_DIR/$IMAGE_NAME"
elif [ -f "$OUTPUT_DIR/arch/arm64/boot/Image.gz" ] && [ -f "$OUTPUT_DIR/arch/arm64/boot/dts/qcom/sm8550-xiaomi-${DEVICE}.dtb" ]; then
    # 如果Image.gz和dtb是分开的，尝试合并它们
    cat "$OUTPUT_DIR/arch/arm64/boot/Image.gz" "$OUTPUT_DIR/arch/arm64/boot/dts/qcom/sm8550-xiaomi-${DEVICE}.dtb" > "$OUTPUT_DIR/$IMAGE_NAME"
    echo "[*] 内核镜像已合并: $OUTPUT_DIR/$IMAGE_NAME"
else
    echo "[!] 找不到内核镜像文件！"
    exit 1
fi

# 复制设备树文件
echo "[*] 复制设备树文件..."
cp -r "$OUTPUT_DIR/arch/arm64/boot/dts/qcom"/* "$DTB_DIR/" 2>/dev/null || true

# 复制配置文件
echo "[*] 复制配置文件..."
cp "$OUTPUT_DIR/.config" "$OUTPUT_DIR/kernel_config"

# 生成构建信息文件
echo "[*] 生成构建信息..."
cat > "$OUTPUT_DIR/build-info.txt" << EOF
# Xiaomi Pad 6S Pro 内核构建信息
设备: $DEVICE (Xiaomi Pad 6S Pro)
处理器: 骁龙 8 Gen 2 (SM8550)
内核版本: Linux $KERNEL_VERSION.x
构建时间: $(date)
构建工具: $TOOLCHAIN
Docker支持: $([ $ENABLE_DOCKER = true ] && echo "是" || echo "否")
构建主机: $(hostname)
内核配置: kernel_config
内核镜像: $IMAGE_NAME
设备树目录: dtb/
模块目录: modules/
EOF

# 验证构建结果
echo "==================================================="
echo "构建验证:"
if [ -f "$OUTPUT_DIR/$IMAGE_NAME" ]; then
    echo "✅ 内核镜像: $OUTPUT_DIR/$IMAGE_NAME"
    echo "   大小: $(du -h "$OUTPUT_DIR/$IMAGE_NAME" | cut -f1)"
else
    echo "❌ 内核镜像不存在！"
fi

if [ -d "$DTB_DIR" ] && [ "$(ls -A "$DTB_DIR" 2>/dev/null)" ]; then
    echo "✅ 设备树文件: $DTB_DIR/"
    echo "   文件数: $(ls -1 "$DTB_DIR" | wc -l)"
else
    echo "⚠️  设备树目录可能为空"
fi

if [ -d "$MODULES_DIR/lib/modules" ]; then
    echo "✅ 内核模块: $MODULES_DIR/lib/modules/"
    echo "   模块数: $(find "$MODULES_DIR/lib/modules" -name "*.ko" | wc -l)"
else
    echo "⚠️  内核模块目录可能为空"
fi

echo "==================================================="
echo "构建完成！"
echo "所有构建产物位于: $OUTPUT_DIR"
echo "==================================================="
echo "您可以使用以下命令刷入内核:"
echo "fastboot flash boot $OUTPUT_DIR/$IMAGE_NAME"
echo "或者刷入到recovery分区:"
echo "fastboot flash recovery $OUTPUT_DIR/$IMAGE_NAME"
echo "==================================================="