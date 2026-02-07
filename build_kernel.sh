#!/bin/bash 
set -euo pipefail  # 严格模式：未定义变量/管道失败/出错立即退出
trap 'echo -e "\033[31m[错误] 脚本执行失败：$1\033[0m" >&2' ERR  # 全局错误捕获


export PATH=/opt/ls_2k0300_env/loongson-gnu-toolchain-8.3-x86_64-loongarch64-linux-gnu-rc1.6/bin:$PATH

# ===================== 配置区（按需修改）=====================
SSH_IP="192.168.2.33"    # 目标SSH地址
SSH_USER="root"           # SSH用户名
SSH_TARGET_DIR="/boot"    # 目标文件存放目录
COMPILE_ARCH="loongarch"  # 编译架构
CROSS_COMPILE="loongarch64-linux-gnu-"  # 交叉编译工具链前缀
COMPILE_THREADS=$(nproc)        # 编译线程数
OUTPUT_FILE="vmlinuz"     # 编译产物文件名
TOOLCHAIN_PATH="/opt/ls_2k0300_env/loongson-gnu-toolchain-8.3-x86_64-loongarch64-linux-gnu-rc1.6/bin"
# ==================================================================


if [ $# -ge 1 ] && [ "$1" = "clean" ]; then
    echo -e "\033[33m[清理模式] 执行内核清理操作...\033[0m"
    # 可选：根据需要选择清理级别
    make clean  # 轻量清理（保留.config）
    # make distclean  # 深度清理（删除.config，按需启用）
    # make mrproper   # 极致清理（按需启用）
    
    echo -e "\033[32m[成功] 内核编译文件清理完成！\033[0m"
    exit 0  # 清理完成后退出脚本，不执行后续编译逻辑
fi


echo -e "\033[32m===== 开始执行自动编译+SCP传输 =====\033[0m"

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
if ! make ARCH="${COMPILE_ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" -j"${COMPILE_THREADS}"; then
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
if [ ! -f "${OUTPUT_FILE}" ]; then
    echo -e "\033[31m[错误] 编译产物 ${OUTPUT_FILE} 不存在！\033[0m"
    echo "       可能原因："
    echo "         1. 编译产物路径错误（当前查找：$(pwd)/${OUTPUT_FILE}）"
    echo "         2. 内核配置未开启vmlinuz生成"
    exit 1
fi
echo -e "\033[32m编译产物 ${OUTPUT_FILE} 检测通过\033[0m"

# 4. 最后检测SSH连通性 + 执行传输（核心调整：此步骤移到最后）
#echo -e "\033[33m[步骤4/4] 检测SSH地址 ${SSH_IP} 连通性并传输...\033[0m"

# 4.1 检测SSH主机可达性（ping）
#if ! ping -c 3 -W 5 "${SSH_IP}" > /dev/null 2>&1; then
#    echo -e "\033[31m[错误] SSH地址 ${SSH_IP} 无法连接！\033[0m"
#    echo "       详细原因："
#    echo "         1. IP地址错误（当前配置：${SSH_IP}）"
#    echo "         2. 本地与目标机不在同一网段"
#    echo "         3. 目标机未开机/网线未连接"
#    echo "         4. 目标机禁用了ICMP/ping响应（可尝试跳过ping直接传）"
#    exit 1
#fi

# 4.2 检测SSH端口（22）是否开放
#if ! nc -z -w 5 "${SSH_IP}" 22 > /dev/null 2>&1; then
#    echo -e "\033[31m[错误] SSH地址 ${SSH_IP} 的22端口未开放！\033[0m"
#    echo "       详细原因："
#    echo "         1. 目标机SSH服务未启动（需执行：systemctl start sshd）"
#    echo "         2. 目标机防火墙/iptables拦截22端口"
#    echo "         3. 目标机SSH端口非22（需修改脚本端口配置）"
#    exit 1
#fi

# 4.3 执行SCP传输
#if ! scp -O "${OUTPUT_FILE}" "${SSH_USER}@${SSH_IP}:${SSH_TARGET_DIR}"; then
#    echo -e "\033[31m[错误] SCP传输失败！\033[0m"
#    echo "       详细原因："
#    echo "         1. 目标机用户名错误（当前：${SSH_USER}）"
#    echo "         2. 目标机${SSH_TARGET_DIR}目录无写入权限"
#    echo "         3. 目标机/boot目录只读（需执行：mount -o remount,rw /）"
#    echo "         4. SSH密钥未配置，需手动输入密码（脚本无交互）"
#    echo "         5. 目标机磁盘空间不足"
#    exit 1
#fi

# 5. 同步文件系统 + 完成提示
sync
echo -e "\033[32m===== 所有操作完成！=====\033[0m"
echo "  - 编译产物：${OUTPUT_FILE}"
echo "  - 传输目标：${SSH_USER}@${SSH_IP}:${SSH_TARGET_DIR}"
echo "  - 执行时间：$(date +'%Y-%m-%d %H:%M:%S')"
echo "✅ 编译完成！"
