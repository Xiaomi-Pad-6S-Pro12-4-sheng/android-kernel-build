#!/bin/bash
# 统一内核构建脚本 - 修复版

set -e

# 显示用法说明
show_usage() {
    echo "使用方法: $0 [选项]"
    echo "选项:"
    echo "  -d, --device DEVICE    指定设备 (mondrian|vermeer|sheng)"
    echo "  -t, --toolchain TOOLCHAIN 指定工具链 (clang|gcc)"
    echo "  -c, --clean            清洁构建"
    echo "  -j, --jobs NUM         并行作业数"
    echo "  -p, --apply-patches    应用优化补丁"
    echo "  --enable-docker        启用 Docker 容器支持"
    echo "  -h, --help            显示此帮助信息"
    echo ""
    echo "支持的设备:"
    echo "  mondrian - 红米 K60 (骁龙8+ Gen 1)"
    echo "  vermeer  - 红米 K70 (骁龙8 Gen 2)"
    echo "  sheng    - 小米 Pad 6S Pro (骁龙8 Gen 2)"
}

# 默认参数
DEVICE=""
TOOLCHAIN="clang"
CLEAN_BUILD=false
APPLY_PATCHES=true
ENABLE_DOCKER=false
JOBS=$(nproc)

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--device)
            DEVICE="$2"
            shift 2
            ;;
        -t|--toolchain)
            TOOLCHAIN="$2"
            shift 2
            ;;
        -c|--clean)
            CLEAN_BUILD=true
            shift
            ;;
        -j|--jobs)
            JOBS="$2"
            shift 2
            ;;
        -p|--apply-patches)
            APPLY_PATCHES=$2
            shift 2
            ;;
        --enable-docker)
            ENABLE_DOCKER=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "未知参数: $1"
            show_usage
            exit 1
            ;;
    esac
done

# 验证设备参数
if [ -z "$DEVICE" ]; then
    echo "❌ 错误: 必须指定设备"
    show_usage
    exit 1
fi

case $DEVICE in
    "mondrian"|"vermeer"|"sheng")
        ;;
    *)
        echo "❌ 错误: 不支持的设备 '$DEVICE'"
        show_usage
        exit 1
        ;;
esac

# 设置构建环境
echo "🔧 设置构建环境..."
source scripts/setup-environment.sh

# 下载工具链和依赖
echo "📥 下载构建依赖..."
bash scripts/download-toolchains.sh
bash scripts/download-qcom-deps.sh

echo "🏗️  开始构建 $DEVICE 内核..."
echo "📋 构建配置:"
echo "  - 设备: $DEVICE"
echo "  - 工具链: $TOOLCHAIN"
echo "  - 并行作业: $JOBS"
echo "  - 清洁构建: $CLEAN_BUILD"
echo "  - 应用补丁: $APPLY_PATCHES"
echo "  - Docker 支持: $ENABLE_DOCKER"

# 设置高通设备环境
source $QCOM_DIR/environment-setup.sh $DEVICE

# 设置工具链
case $TOOLCHAIN in
    "clang")
        export CLANG_TRIPLE=aarch64-linux-gnu-
        export CROSS_COMPILE=$TOOLCHAIN_DIR/gcc-arm64/bin/aarch64-linux-gnu-
        export CROSS_COMPILE_ARM32=$TOOLCHAIN_DIR/gcc-arm/bin/arm-linux-gnueabi-
        export CC=$TOOLCHAIN_DIR/aosp-clang/bin/clang
        export LD_LIBRARY_PATH=$TOOLCHAIN_DIR/aosp-clang/lib64:$LD_LIBRARY_PATH
        ;;
    "gcc")
        export CROSS_COMPILE=$TOOLCHAIN_DIR/gcc-arm64/bin/aarch64-linux-gnu-
        export CROSS_COMPILE_ARM32=$TOOLCHAIN_DIR/gcc-arm/bin/arm-linux-gnueabi-
        export CC=${CROSS_COMPILE}gcc
        ;;
    *)
        echo "❌ 错误: 不支持的工具链 '$TOOLCHAIN'"
        exit 1
        ;;
esac

# 设置输出目录
export OUT_DIR_DEVICE=$OUT_DIR/$DEVICE
mkdir -p $OUT_DIR_DEVICE

# 清洁构建（如果请求）
if [ "$CLEAN_BUILD" = true ]; then
    echo "🧹 执行清洁构建..."
    make mrproper || true
    rm -rf $OUT_DIR_DEVICE
    mkdir -p $OUT_DIR_DEVICE
fi

# 检查 defconfig 文件是否存在
DEFCONFIG_FILE="arch/arm64/configs/${DEVICE}_defconfig"
if [ ! -f "$DEFCONFIG_FILE" ]; then
    echo "⚠️  警告: 设备 $DEVICE 的 defconfig 文件不存在: $DEFCONFIG_FILE"
    echo "📝 创建默认 defconfig..."
    
    # 创建设备特定的默认配置
    case $DEVICE in
        "mondrian")
            # 红米 K60 默认配置
            make O=$OUT_DIR_DEVICE vendor/sm8475_defconfig || make O=$OUT_DIR_DEVICE defconfig
            ;;
        "vermeer"|"sheng")
            # 红米 K70/小米 Pad 6S Pro 默认配置
            make O=$OUT_DIR_DEVICE vendor/sm8550_defconfig || make O=$OUT_DIR_DEVICE defconfig
            ;;
    esac
else
    echo "✅ 使用 defconfig: $DEFCONFIG_FILE"
    make O=$OUT_DIR_DEVICE ${DEVICE}_defconfig
fi

# 应用平台优化补丁
if [ "$APPLY_PATCHES" = true ]; then
    echo "🔧 应用平台优化补丁..."
    case $QCOM_SOC in
        "sm8550")
            if [ -f "$QCOM_DIR/kernel-patches/sm8550-cpu-optimization.patch" ]; then
                patch -p1 < $QCOM_DIR/kernel-patches/sm8550-cpu-optimization.patch || echo "⚠️  补丁应用失败，继续构建..."
            fi
            ;;
        "sm8475")
            if [ -f "$QCOM_DIR/kernel-patches/sm8475-gpu-optimization.patch" ]; then
                patch -p1 < $QCOM_DIR/kernel-patches/sm8475-gpu-optimization.patch || echo "⚠️  补丁应用失败，继续构建..."
            fi
            ;;
    esac
fi

# 启用 Docker 支持（如果请求）
if [ "$ENABLE_DOCKER" = true ]; then
    echo "🐳 启用 Docker 容器支持..."
    bash scripts/enable-docker-support.sh
    bash scripts/device-docker-config.sh $DEVICE
    
    # 重新生成配置依赖
    make O=$OUT_DIR_DEVICE olddefconfig
fi

# 针对不同设备进行特定配置
case $DEVICE in
    "sheng")
        # 平板设备特定配置
        echo "CONFIG_INPUT_TOUCHSCREEN=y" >> $OUT_DIR_DEVICE/.config
        echo "CONFIG_TABLET_SPECIFIC=y" >> $OUT_DIR_DEVICE/.config
        ;;
    "mondrian"|"vermeer")
        # 手机设备特定配置
        echo "CONFIG_MOBILE_OPTIMIZATIONS=y" >> $OUT_DIR_DEVICE/.config
        ;;
esac

# 最终配置确认
make O=$OUT_DIR_DEVICE olddefconfig

# 开始构建内核
echo "🔨 开始编译内核..."
if ! make -j$JOBS O=$OUT_DIR_DEVICE \
    ARCH=$ARCH \
    CC="$CC" \
    CROSS_COMPILE=$CROSS_COMPILE \
    CROSS_COMPILE_ARM32=$CROSS_COMPILE_ARM32; then
    echo "❌ 内核编译失败!"
    echo "🔍 调试信息:"
    echo "ARCH: $ARCH"
    echo "CROSS_COMPILE: $CROSS_COMPILE"
    echo "CC: $CC"
    exit 1
fi

# 构建模块
echo "🔨 编译内核模块..."
make -j$JOBS O=$OUT_DIR_DEVICE \
    ARCH=$ARCH \
    CC="$CC" \
    CROSS_COMPILE=$CROSS_COMPILE \
    CROSS_COMPILE_ARM32=$CROSS_COMPILE_ARM32 \
    modules || echo "⚠️  模块编译失败，继续..."

# 构建设备树
echo "🔨 编译设备树..."
make -j$JOBS O=$OUT_DIR_DEVICE \
    ARCH=$ARCH \
    CC="$CC" \
    CROSS_COMPILE=$CROSS_COMPILE \
    dtbs || echo "⚠️  设备树编译失败，继续..."

# 验证构建产物
echo "🔍 验证构建产物..."
if [ -f "$OUT_DIR_DEVICE/arch/arm64/boot/Image.gz-dtb" ]; then
    echo "✅ 内核镜像构建成功: $OUT_DIR_DEVICE/arch/arm64/boot/Image.gz-dtb"
    ls -lh "$OUT_DIR_DEVICE/arch/arm64/boot/Image.gz-dtb"
elif [ -f "$OUT_DIR_DEVICE/arch/arm64/boot/Image" ]; then
    echo "✅ 内核镜像构建成功: $OUT_DIR_DEVICE/arch/arm64/boot/Image"
    ls -lh "$OUT_DIR_DEVICE/arch/arm64/boot/Image"
else
    echo "❌ 错误: 内核镜像未找到!"
    echo "📁 输出目录内容:"
    ls -la "$OUT_DIR_DEVICE/arch/arm64/boot/"
    exit 1
fi

echo "✅ 内核构建完成!"
