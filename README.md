# Android 内核构建 - 设备介绍

本文档详细介绍了本项目支持的设备规格、芯片特性和构建配置。

## 📋 设备概览

| 设备代号 | 设备名称 | 芯片平台 | 状态 | 内核版本 |
|---------|----------|----------|------|----------|
| `mondrian` | Redmi K60 | 骁龙 8+ Gen 1 | ✅ 支持 | 5.10+ |
| `vermeer` | Redmi K70 | 骁龙 8 Gen 2 | ✅ 支持 | 5.15+ |
| `sheng` | Xiaomi Pad 6S Pro | 骁龙 8 Gen 2 | ✅ 支持 | 5.15+ |

## 📱 设备详情

### 🎯 Redmi K60 (mondrian)

![Redmi K60](https://cdn.cnbj0.fds.api.mi-img.com/b2c-shopapi-pms/pms_1672970663.79242913.png)

#### 规格参数
- **设备代号**: `mondrian`
- **发布名称**: Redmi K60
- **SoC 平台**: 骁龙 8+ Gen 1 (SM8475)
- **CPU**: 1×3.0GHz X2 + 3×2.5GHz A710 + 4×1.8GHz A510
- **GPU**: Adreno 730
- **内存**: 8GB/12GB/16GB LPDDR5
- **存储**: 128GB/256GB/512GB UFS 3.1
- **屏幕**: 6.67" 2K OLED, 120Hz
- **摄像头**: 
  - 主摄: 64MP (OV64B)
  - 超广角: 8MP
  - 微距: 2MP
- **电池**: 5500mAh, 67W快充

#### 内核特性
```bash
# 设备特定配置
CONFIG_MACH_XIAOMI_MONDRIAN=y
CONFIG_QCOM_SM8475=y
CONFIG_ARM64_VA_BITS_39=y
