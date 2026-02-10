#!/bin/bash

# 顶层目录 (假设脚本在源码根目录)
TOP_DIR=$(pwd)

# 输出目录
OUTPUT_DIR="${TOP_DIR}/output"

# 源码目录名称
KERNEL_DIR="${TOP_DIR}/linux-4.19-202506"
BUILDROOT_DIR="${TOP_DIR}/buildroot-2405"

# 编译器与架构设置
COMPILE_ARCH="loongarch"  # 编译架构
CROSS_COMPILE="loongarch64-linux-gnu-"  # 交叉编译工具链前缀
COMPILE_THREADS=$(nproc)        # 编译线程数
OUTPUT_FILE="vmlinuz"     # 编译产物文件名
TOOLCHAIN_PATH="/opt/ls_2k0300_env/loongson-gnu-toolchain-8.3-x86_64-loongarch64-linux-gnu-rc1.6/bin"

# 默认配置文件 (defconfig)
KERNEL_DEFCONFIG="sun8iw20p1smp_t113_auto_defconfig"
BUILDROOT_DEFCONFIG="sun8iw20p1_t113_defconfig"

# CPU 核心数 (用于多线程编译)
CORES=$(nproc)

# ==============================================================================
# 颜色定义 & 日志函数
# ==============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO] $1 ${NC}"
}

log_start() {
    echo -e "${CYAN}============================================================${NC}"
    echo -e "${BLUE}[STARTED] 正在开始: $1 ...${NC}"
    echo -e "${CYAN}============================================================${NC}"
}

log_success() {
    echo -e "${GREEN}[SUCCESS] $1 ✅ 编译处理成功!${NC}"
}

log_error() {
    echo -e "${RED}[ERROR] $1 ❌失败! 请检查错误日志。${NC}"
    exit 1
}

log_warn() {
    echo -e "${YELLOW}[WARN] $1 ${NC}"
}

# ==============================================================================
# 核心编译函数
# ==============================================================================

# 通用函数：配置 (config)
# 参数 1: 目录, 参数 2: 模块名, 参数 3: defconfig文件名
check_config() {
    local dir=$1
    local name=$2
    local defconfig=$3

    if [  -f "${dir}/.config" ]; then
        # 情况 1: .config 存在 -> 保留现有配置
        echo -e "${GREEN}[CONFIG] ${name}: 🔍 检测到现有 .config 文件，跳过 defconfig，使用当前配置。${NC}"
    else
        # 情况 2: .config 不存在 -> 加载默认配置
        echo -e "${YELLOW}[CONFIG] ${name}: ⚠️ 未找到 .config 文件，正在加载默认配置: ${defconfig}...${NC}"
        make -C "${dir}" "${defconfig}" || log_error "${name} 默认配置加载"
        echo -e "${GREEN}[CONFIG] ${name}: 默认配置加载完成。${NC}"
    fi
}



# ------------------- Kernel -------------------
build_kernel() {
    local action=$1

    if [ ! -d "$KERNEL_DIR" ]; then log_error "找不到 Kernel 目录: $KERNEL_DIR"; fi

    export ARCH="${COMPILE_ARCH}"
    export CROSS_COMPILE="${CROSS_COMPILE}"
    export PATH="${TOOLCHAIN_PATH}:$PATH"

    case "$action" in
        clean)
            log_warn "正在清理 Kernel..."
            make -C "$KERNEL_DIR" clean
            log_success "Kernel 清理"
            ;;
        menuconfig)
            check_config "$KERNEL_DIR" "Kernel" "$KERNEL_DEFCONFIG"
            make -C "$KERNEL_DIR" menuconfig
            ;;
        *)
            log_start "编译 Linux Kernel"
            # 1. 检查工具链路径并配置环境变量
            echo -e "\033[33m[步骤1/4] 配置编译环境...\033[0m"
            if [ ! -d "${TOOLCHAIN_PATH}" ]; then
                echo -e "\033[31m[错误] 工具链路径不存在！路径：${TOOLCHAIN_PATH}\033[0m"
                exit 1
            fi
            export PATH="${TOOLCHAIN_PATH}:$PATH"
            echo -e "\033[32m工具链环境配置完成\033[0m"

            # 2. 执行内核编译（核心步骤，先完成编译）
            echo -e "\033[33m[步骤2/4] 开始编译内核（线程数：${COMPILE_THREADS}）...\033[0m"
            if ! make -C "${KERNEL_DIR}" ARCH="${COMPILE_ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" -j"${COMPILE_THREADS}"; then
                echo -e "\033[31m[错误] 内核编译失败！\033[0m"
                echo "       排查方向："
                echo "         1. 交叉编译工具链是否正确（当前：${CROSS_COMPILE}）"
                echo "         2. 内核配置文件（.config）是否适配LoongArch架构"
                echo "         3. 源码是否完整（是否缺失arch/loongarch目录）"
                exit 1
            fi
            echo -e "\033[32m内核编译完成\033[0m"

            # 3. 检查编译产物是否存在
            echo -e "\033[33m[步骤3/4] 检查编译产物...\033[0m"
            if [ ! -f "${KERNEL_DIR}/${OUTPUT_FILE}" ]; then
                echo -e "\033[31m[错误] 编译产物 ${OUTPUT_FILE} 不存在！\033[0m"
                echo "       可能原因："
                echo "         1. 编译产物路径错误（当前查找：$(pwd)/${KERNEL_DIR}/${OUTPUT_FILE}）"
                echo "         2. 内核配置未开启vmlinuz生成"
                exit 1
            fi
            echo -e "\033[32m编译产物 ${OUTPUT_FILE} 检测通过\033[0m"
            log_success "Kernel"
            ;;
    esac
}

# ------------------- Buildroot -------------------
build_buildroot() {
    local action=$1
    
    # Buildroot 通常不需要外部设置 CROSS_COMPILE，它自己管理工具链
    # 但如果是外部工具链，保持环境变量即可。这里暂时unset避免干扰，视情况而定
    # unset ARCH CROSS_COMPILE 

    if [ ! -d "$BUILDROOT_DIR" ]; then log_error "找不到 Buildroot 目录: $BUILDROOT_DIR"; fi

    export ARCH="${COMPILE_ARCH}"
    export CROSS_COMPILE="${CROSS_COMPILE}"
    export PATH="${TOOLCHAIN_PATH}:$PATH"

    case "$action" in
        clean)
            log_warn "正在清理 Buildroot..."
            make -C "$BUILDROOT_DIR" clean
            log_success "Buildroot 清理"
            ;;
        menuconfig)
            check_config "$BUILDROOT_DIR" "Buildroot" "$BUILDROOT_DEFCONFIG"
            make -C "$BUILDROOT_DIR" menuconfig
            ;;
        *)
            log_start "编译 Buildroot (这可能需要很长时间)"
            check_config "$BUILDROOT_DIR" "Buildroot" "$BUILDROOT_DEFCONFIG"
            make -C "$BUILDROOT_DIR" -j"${CORES}" || log_error "Buildroot 编译"
            log_success "Buildroot"
            ;;
    esac
}

# ------------------- 打包 Output -------------------
pack_output() {
    log_start "打包固件到 output/"
    
    mkdir -p "${OUTPUT_DIR}"

    # 复制 Kernel (根据架构可能是 Image, zImage, uImage)
    # 假设是 arm64 的 Image
    if [ -f "${KERNEL_DIR}/vmlinuz" ]; then
        cp "${KERNEL_DIR}/vmlinuz" "${OUTPUT_DIR}/"
        log_info "已复制 Kernel Image"
    else
        log_warn "未找到 Kernel Image，跳过复制"
    fi

    # 复制 Buildroot Rootfs
    if [ -f "${BUILDROOT_DIR}/output/images/rootfs.tar" ]; then
        cp "${BUILDROOT_DIR}/output/images/rootfs.tar" "${OUTPUT_DIR}/"
        log_info "已复制 rootfs"
    else
        log_warn "未找到 rootfs，跳过复制"
    fi

    log_success "固件打包"
    echo -e "${GREEN}==> 所有文件已生成至: ${OUTPUT_DIR}${NC}"
}

# ------------------- 全部清理 -------------------
clean_all() {
    log_start "清理所有项目"
    build_kernel clean
    build_buildroot clean
    rm -rf "${OUTPUT_DIR}"
    log_success "所有项目清理"
}

# ==============================================================================
# 主逻辑入口 (Main)
# ==============================================================================

help_msg() {
    echo -e "${YELLOW}使用方法:${NC}"
    echo -e "  ./build.sh                     : 编译所有 (Kernel, Buildroot) 并打包"
    echo -e "  ./build.sh clean               : 清除所有编译生成的文件"
    echo -e "  ./build.sh [module]            : 单独编译模块 (kernel, buildroot)"
    echo -e "  ./build.sh [module] clean      : 单独清除模块"
    echo -e "  ./build.sh [module] menuconfig : 打开模块的图形化配置"
    echo -e ""
    echo -e "${YELLOW}示例:${NC}"
    echo -e "  ./build.sh kernel"
    echo -e "  ./build.sh kernel menuconfig"
}

# 参数解析
TARGET=$1
ACTION=$2

case "$TARGET" in
    "")
        # 没有任何参数 -> 编译所有并打包
    build_kernel
        build_buildroot
        pack_output
        ;;
    
    "clean")
        # 清理所有
        clean_all
        ;;

    "kernel")
        build_kernel "$ACTION"
        ;;

    "buildroot")
        build_buildroot "$ACTION"
        ;;
    "firmware")
        # 执行单独的固件打包逻辑，忽略 ACTION 参数
        pack_output
        ;;
    "help"|"-h"|"--help")
        help_msg
        ;;

    *)
        log_error "未知参数: $TARGET"
        help_msg
        exit 1
        ;;
esac