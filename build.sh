#!/bin/bash


#请将kernel文件夹改名为kernel4.19-202506
#请将kernel下面的脚本文件变为build_kernel.sh
#请将buildroot下面的脚本文件变为build_rootfs.sh


SDK_PATH=$(pwd)

# 交叉编译工具链路径（根据实际情况调整）
export PATH=/opt/ls_2k0300_env/loongson-gnu-toolchain-8.3-x86_64-loongarch64-linux-gnu-rc1.6/bin:$PATH
export CROSSTOOL_FLAG=1

# 颜色定义（增强输出可读性）
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
NC='\033[0m' # No Color

# 组件目录映射（核心修改：指定kernel对应的实际目录）
declare -A COMPONENT_DIRS=(
    ["kernel"]="kernel4.19-202506"  # 内核目录（与外层脚本同级）
    ["rootfs"]="buildroot-2405"      # 请根据实际rootfs目录名修改
)

usage()
{
    echo -e "\033[32mInvalid argument. Example Usage: \033[0m"
    echo -e "\033[33m ./build.sh {all   |all_clean                     }\033[0m"
    #echo -e "\033[33m ./build.sh {uboot |uboot_clean |uboot_menuconfig }\033[0m"
    echo -e "\033[33m ./build.sh {kernel|kernel_clean|kernel_menuconfig}\033[0m"
    echo -e "\033[33m ./build.sh {rootfs|rootfs_clean|rootfs_menuconfig}\033[0m"
}

check_target_dir()
{
    local target_dir="$SDK_PATH/long_target"
    if [ ! -d "$target_dir" ]; then
        echo "directory $target_dir does not exist. creating it now."
        mkdir -p "$target_dir"
    fi
}

cp_target()
{
    local type=$1
    local path=$2

    if [ "$type" = "kernel" ]; then
        # 修正1：统一目录名为long_target（去掉横线）
        
        local zimage_path="$path/vmlinuz"
        
        if [ -f "$zimage_path" ]; then
            cp "$zimage_path" "$SDK_PATH/long_target/"
            echo -e "${GREEN}已复制 zImage 到 long_target 目录${NC}"
        else
            echo -e "${RED}错误：zImage 文件不存在 ($zimage_path)${NC}"
            exit 1
        fi

        

    elif [ "$type" = "rootfs" ]; then
        cp "$path/output/images/rootfs.tar.gz" "$SDK_PATH/long_target/"
    fi
}

rm_target()
{
    local type=$1
    echo -e "${YELLOW}开始清理 $type 编译产物...${NC}"

    if [ "$type" = "kernel" ]; then
        rm -f "$SDK_PATH/long_target/zImage"
    elif [ "$type" = "rootfs" ]; then
        rm -f "$SDK_PATH/long_target/rootfs.tar.gz"
    fi
    echo -e "${GREEN}$type 编译产物清理完成！${NC}"
}

execute_command()
{
    local path=$1
    local cmd=$2
    
    # 检查目录是否存在
    if [ ! -d "$path" ]; then
        echo -e "${RED}错误：目录 $path 不存在${NC}"
        exit 1
    fi

    cd "$path" || {
        echo -e "${RED}Failed to enter $path${NC}"
        exit 1
    }
    echo -e "${YELLOW}Entering $path and executing: $cmd${NC}"
    eval "$cmd" || {
        echo -e "${RED}命令执行失败：$cmd${NC}"
        exit 1
    }
}



build_function()
{
    case "$1" in
        kernel|rootfs)
            echo -e "\n${YELLOW}===== 开始编译 $1 =====${NC}"
            
            # 获取组件对应的实际目录
            local component_dir=${COMPONENT_DIRS[$1]}
            local action="build_${1}.sh"
            
            # 执行编译脚本
            execute_command "$SDK_PATH/$component_dir" "./$action"
            check_target_dir
            cp_target "$1" "$SDK_PATH/$component_dir"
            echo -e "${GREEN}===== $1 编译并复制完成！=====${NC}"
            ;;
        kernel_clean|rootfs_clean)
            local component=${1%_clean}
            echo -e "\n${YELLOW}===== 开始清理 $component =====${NC}"
            
            local component_dir=${COMPONENT_DIRS[$component]}
            local action="build_${component}.sh clean"
            
            execute_command "$SDK_PATH/$component_dir" "./$action"
            rm_target "$component"
            echo -e "${GREEN}===== $component 清理完成！=====${NC}"
            ;;
        kernel_menuconfig|rootfs_menuconfig)
            local component=${1%_menuconfig}
            echo -e "\n${YELLOW}===== 打开 $component menuconfig 配置界面 =====${NC}"

            # 获取组件对应的实际目录
            local component_dir=${COMPONENT_DIRS[$component]}
            local action="make ARCH=loongarch menuconfig"

            # 执行命令（复用现有execute_command函数）
            execute_command "$SDK_PATH/$component_dir" "$action"
            echo -e "${GREEN}===== $component 配置界面操作完成！=====${NC}"
            ;;
        all)
            echo -e "\n${YELLOW}===== 开始全量编译（uboot + kernel + rootfs）=====${NC}"
            for component in kernel rootfs; do
                local component_dir=${COMPONENT_DIRS[$component]}
                local action="build_$component.sh"
                
                execute_command "$SDK_PATH/$component_dir" "./$action"
                check_target_dir
                cp_target "$component" "$SDK_PATH/$component_dir"
            done
            echo -e "\n${GREEN}===== 全量编译完成！所有产物已复制到 long_target 目录 =====${NC}"
            ;;
        all_clean)
            echo -e "\n${YELLOW}===== 开始全量清理（uboot + kernel + rootfs）=====${NC}"
            for component in kernel rootfs; do
                local component_dir=${COMPONENT_DIRS[$component]}
                local action="build_${component}.sh clean"
                
                execute_command "$SDK_PATH/$component_dir" "./$action"
                check_target_dir
                rm_target "$component"
            done
            echo -e "\n${GREEN}===== 全量清理完成！=====${NC}"
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

# 检查交叉编译工具链
if [ "$CROSSTOOL_FLAG" != "1" ];then
    echo -e "\033[31m###### Please exec cmd to init crosstool: source imx-crosstool/imx-crosstool-env-init #######\033[0m"
    exit 1
else
    echo -e "\033[32m########## crosstool has been initialized previously #########\033[0m"
    # 检查参数
    if [ $# -ne 1 ]; then
        usage
        exit 1
    fi
    build_function "$1"
fi