#!/bin/bash 
echo "开始编译Buildroot"

export PATH=/opt/ls_2k0300_env/loongson-gnu-toolchain-8.3-x86_64-loongarch64-linux-gnu-rc1.6/bin:$PATH

# 检查并创建 output 目录
OUTPUT_DIR="./output"
if [ ! -d " $ OUTPUT_DIR" ]; then
    echo "正在创建输出目录:  $ OUTPUT_DIR"
    mkdir -p " $ OUTPUT_DIR" || { echo "错误：无法创建目录  $ OUTPUT_DIR"; exit 1; }
else
    echo "输出目录已存在:  $ OUTPUT_DIR"
fi

#make ARCH=loongarch64 CROSS_COMPILE=loongarch64-linux-gnu-  menuconfig

make ARCH=loongarch64 CROSS_COMPILE=loongarch64-linux-gnu- -j$(nproc) "$@"

# 检查上一步是否成功
if [  $? -eq 0 ]; then
    echo ""
    echo "=================================="
    echo "✅ 编译完成！"
    echo "输出目录: /buildroot-2405/output/images/"
    echo "=================================="
else
    echo ""
    echo "❌ 编译失败，请检查上述错误信息。"
    exit 1
fi