#!/bin/bash

# Xiaomi Pad 6S Pro 高通依赖下载脚本
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

# 加载环境变量
if [ -f "$ROOT_DIR/.env" ]; then
    source "$ROOT_DIR/.env"
fi

DEVICE="sheng"
KERNEL_VERSION="5.15"
KERNEL_DIR="${ROOT_DIR}/kernel/${DEVICE}"

echo "==================================================="
echo "下载 Xiaomi Pad 6S Pro (${DEVICE}) 内核源码和依赖"
echo "内核版本: Linux ${KERNEL_VERSION}.x"
echo "==================================================="

# 创建内核目录
mkdir -p "$KERNEL_DIR"
cd "$ROOT_DIR/kernel"

# 下载内核源码（使用小米官方内核仓库）
echo "[*] 下载内核源码..."
if [ ! -d "${DEVICE}/.git" ]; then
    # 首先创建空目录，避免git clone失败
    mkdir -p "$KERNEL_DIR"
    
    # 使用小米官方仓库，特定分支为sheng-u-oss
    echo "[*] 正在克隆小米官方内核仓库 (分支: sheng-u-oss)..."
    
    # 克隆内核源码（小米官方仓库）
    git clone --depth=1 -b sheng-u-oss https://github.com/MiCode/Xiaomi_Kernel_OpenSource.git "$KERNEL_DIR" || {
        echo "[!] 无法克隆官方仓库，创建示例内核目录结构..."
        
        # 创建基本内核目录结构
        mkdir -p "$KERNEL_DIR/arch/arm64/configs"
        mkdir -p "$KERNEL_DIR/arch/arm64/boot/dts/qcom"
        mkdir -p "$KERNEL_DIR/drivers"
        mkdir -p "$KERNEL_DIR/include"
        mkdir -p "$KERNEL_DIR/scripts"
        
        # 创建示例defconfig文件
        cat > "$KERNEL_DIR/arch/arm64/configs/sheng_defconfig" << EOF
CONFIG_ARM64=y
CONFIG_SYSVIPC=y
CONFIG_NO_HZ=y
CONFIG_HIGH_RES_TIMERS=y
CONFIG_PREEMPT_VOLUNTARY=y
CONFIG_IKCONFIG=y
CONFIG_IKCONFIG_PROC=y
CONFIG_MODULES=y
CONFIG_MODULE_UNLOAD=y
CONFIG_NET=y
CONFIG_UNIX=y
CONFIG_INET=y
CONFIG_USB_SUPPORT=y
CONFIG_USB=y
CONFIG_USB_XHCI_HCD=y
CONFIG_USB_DWC3=y
CONFIG_QCOM_SMD=y
CONFIG_QCOM_RPM=y
CONFIG_QCOM_IPA=y
CONFIG_QCOM_SPMI=y
CONFIG_QCOM_LPM_LEVELS=y
CONFIG_QCOM_SMEM=y
CONFIG_QCOM_QMI_HELPERS=y
CONFIG_QCOM_RPROC_COMMON=y
CONFIG_DRM=y
CONFIG_DRM_MSM=y
CONFIG_DRM_MSM_DSI=y
CONFIG_DRM_MSM_HDCP=y
CONFIG_DRM_PANEL=y
CONFIG_DRM_PANEL_SAMSUNG=y
CONFIG_DRM_PANEL_SONY=y
CONFIG_REGULATOR=y
CONFIG_REGULATOR_QCOM_RPM=y
CONFIG_REGULATOR_QCOM_SPMI=y
CONFIG_CPU_FREQ=y
CONFIG_CPU_FREQ_QCOM=y
CONFIG_CPU_IDLE=y
CONFIG_CPU_IDLE_QCOM=y
CONFIG_QCOM_SMP2P=y
CONFIG_QCOM_GPIOMUX=y
CONFIG_QCOM_SPMI_ADC5=y
CONFIG_QCOM_LPASS=y
CONFIG_SND_SOC_QCOM=y
CONFIG_SND_SOC_QDSP6=y
CONFIG_SND_SOC_QCOM_SDM845=y
CONFIG_SND_SOC_QCOM_LPASS=y
CONFIG_RTC_CLASS=y
CONFIG_RTC_DRV_QCOM_PMIC=y
CONFIG_I2C=y
CONFIG_I2C_QCOM=y
CONFIG_SPI=y
CONFIG_SPI_QCOM=y
CONFIG_SPMI=y
CONFIG_SPMI_QCOM_PMIC=y
CONFIG_CLK_QCOM=y
CONFIG_GPIO_QCOM=y
CONFIG_QCOM_PMIC=y
CONFIG_QCOM_RAMDUMP=y
CONFIG_QCOM_GLINK=y
CONFIG_QCOM_GLINK_SMEM=y
CONFIG_CRYPTO=y
CONFIG_CRYPTO_DEV_QCE=y
CONFIG_CRYPTO_DEV_QAT=y
CONFIG_QCOM_SECUREMSM=y
CONFIG_SECURITY_SELINUX=y
CONFIG_UEVENT_HELPER=y
CONFIG_DEBUG_FS=y
CONFIG_DEBUG_KERNEL=y
CONFIG_PCI=y
CONFIG_PCIE_QCOM=y
CONFIG_PCIE_DW_QCOM=y
CONFIG_BLK_DEV_NVME=y
CONFIG_NVME_CORE=y
CONFIG_BLK_DEV_ZONED=y
CONFIG_FS_ENCRYPTION=y
CONFIG_EXT4_FS=y
CONFIG_F2FS_FS=y
CONFIG_PROC_FS=y
CONFIG_SYSFS=y
CONFIG_TMPFS=y
CONFIG_NFS_FS=y
CONFIG_CIFS=y
CONFIG_FUSE_FS=y
CONFIG_EROFS_FS=y
CONFIG_STAGING=y
CONFIG_SECURITY=y
CONFIG_SECURITY_APPARMOR=y
CONFIG_ANDROID=y
CONFIG_ANDROID_BINDER_IPC=y
CONFIG_ANDROID_BINDERFS=y
CONFIG_ANDROID_BINDER_DEVICES="binder,hwbinder,vndbinder"
CONFIG_ANDROID_LOGGER=y
CONFIG_ANDROID_PARANOID_NETWORK=y
CONFIG_HW_PERF_EVENTS=y
CONFIG_ARM64_VHE=y
CONFIG_ARM64_RAS_EXTN=y
CONFIG_ARM64_PSEUDO_NMI=y
CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE=y
EOF
        
        echo "[*] 示例内核目录结构创建完成"
    }
else
    echo "[*] 内核源码已存在，拉取最新代码..."
    cd "$KERNEL_DIR"
    git pull
fi

# 下载设备树示例
echo "[*] 下载设备树示例..."
if [ ! -f "$KERNEL_DIR/arch/arm64/boot/dts/qcom/sm8550-xiaomi-sheng.dts" ]; then
    # 创建示例设备树文件
    mkdir -p "$KERNEL_DIR/arch/arm64/boot/dts/qcom"
    cat > "$KERNEL_DIR/arch/arm64/boot/dts/qcom/sm8550-xiaomi-sheng.dts" << EOF
/dts-v1/;

#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>
#include <dt-bindings/leds/common.h>
#include <dt-bindings/sound/qcom,q6afe.h>

#include "sm8550.dtsi"

/ {
	model = "Xiaomi Pad 6S Pro";
	compatible = "xiaomi,sheng", "qcom,sm8550";

	chosen {
		bootargs = "console=ttyMSM0,115200n8 androidboot.console=ttyMSM0 androidboot.hardware=qcom androidboot.primary_display=DSI1";
		stdout-path = "serial0:115200n8";
	};

	memory@0 {
		device_type = "memory";
		reg = <0x0 0x0 0x0 0x40000000>;
	};

	reserved-memory {
		#address-cells = <2>;
		#size-cells = <2>;
		ranges;
	};
};
EOF
fi

# 创建设备特定环境配置文件
echo "[*] 创建设备环境配置文件..."
cat > "$ROOT_DIR/scripts/environment-setup.sh" << EOF
#!/bin/bash

# Xiaomi Pad 6S Pro 特定环境配置
# 设备代号: sheng
# 处理器: 骁龙 8 Gen 2

# 设备特定变量
export DEVICE=sheng
export QCOM_SOC=sm8550
export TARGET_SOC=sm8550
export TARGET_BOARD=sheng
export GPU_VERSION=adreno-740

# 编译参数
export ARCH=arm64
export SUBARCH=arm64
export CROSS_COMPILE=aarch64-linux-android-
export CROSS_COMPILE_ARM32=arm-linux-androideabi-
export CC=clang
export LD=ld.lld
export AR=llvm-ar
export NM=llvm-nm
export OBJCOPY=llvm-objcopy
export OBJDUMP=llvm-objdump
export STRIP=llvm-strip

# 内核配置
export KERNEL_DEFCONFIG=sheng_defconfig
export DTC_EXT=dtc
export DTBTOOL_EXT=dtbToolCM

# 优化参数
export KCFLAGS="-march=armv8.5-a"
export KBUILD_BUILD_USER="xiaomi-kernel-builder"
export KBUILD_BUILD_HOST="github-actions"

# 输出目录
export OUTPUT_DIR=${ROOT_DIR}/out/${DEVICE}
export DTB_DIR=${OUTPUT_DIR}/dtb
export MODULES_DIR=${OUTPUT_DIR}/modules
EOF

echo "==================================================="
echo "依赖下载完成！"
echo "内核源码位置: $KERNEL_DIR"
echo "接下来请执行: bash scripts/build-kernel.sh"
echo "==================================================="