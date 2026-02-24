#!/bin/bash

# =============================================================================
# init-project.sh - Global Project Initialization Script
# =============================================================================
# This script initializes a new project with the long-running-agent system.
# Install it globally, then run it in any empty directory.
#
# Installation:
#   1. Copy this file to ~/bin/init-project.sh
#   2. chmod +x ~/bin/init-project.sh
#   3. Add ~/bin to PATH (or create an alias)
#
# Usage:
#   mkdir my-project && cd my-project
#   init-project.sh
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Auto_agents directory (adjust this path)
AUTO_AGENTS_DIR="C:/work/claude-agent-system"

print_header() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${BLUE}▶ $1${NC}"
}

# Check if directory is empty
check_directory() {
    local files=$(ls -A 2>/dev/null | grep -v "^\." | wc -l)
    if [ "$files" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Warning: Directory is not empty${NC}"
        echo "Files found:"
        ls -A | grep -v "^\." | head -5
        echo ""
        read -p "Continue anyway? [y/N]: " continue
        if [[ ! "$continue" =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
}

# Select mode
select_mode() {
    print_header "选择初始化模式"

    echo "请选择初始化模式："
    echo ""
    echo "  ${GREEN}1${NC}) 规格驱动模式 (推荐)"
    echo "     适用于复杂项目或需求不明确的场景"
    echo "     AI 会系统性提问澄清需求"
    echo ""
    echo "  ${GREEN}2${NC}) 传统对话模式"
    echo "     适用于需求明确的场景"
    echo "     直接通过对话收集需求"
    echo ""
    echo "  ${GREEN}3${NC}) 现有项目模式"
    echo "     适用于老项目继续开发"
    echo "     自动扫描现有代码库"
    echo ""
    read -p "请选择 (1-3): " mode

    case $mode in
        1)
            return 1  # Spec-driven
            ;;
        2)
            return 2  # Traditional
            ;;
        3)
            return 3  # Existing
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            exit 1
            ;;
    esac
}

# Copy scripts
copy_scripts() {
    print_section "复制脚本文件"

    # Copy essential scripts
    cp "$AUTO_AGENTS_DIR/monitor-claude.sh" . 2>/dev/null || {
        echo -e "${RED}Error: Cannot find monitor-claude.sh${NC}"
        echo "Expected location: $AUTO_AGENTS_DIR"
        exit 1
    }

    cp "$AUTO_AGENTS_DIR/run-claude-loop.sh" .
    chmod +x monitor-claude.sh run-claude-loop.sh

    echo -e "${GREEN}✓ 复制监控脚本${NC}"
}

# Spec-driven mode init
init_spec_driven() {
    print_header "规格驱动模式初始化"

    # Copy the spec-driven script
    cp "$AUTO_AGENTS_DIR/spec-driven-init.sh" .
    chmod +x spec-driven-init.sh

    # Run it
    ./spec-driven-init.sh
}

# Traditional mode init
init_traditional() {
    print_header "传统对话模式初始化"

    echo "这个模式会直接通过对话收集需求。"
    echo ""
    echo "下一步："
    echo -e "  ${GREEN}1. 对 Claude 说：\"帮我初始化一个新项目\"${NC}"
    echo -e "  ${GREEN}2. Claude 会问你项目信息，逐一回答${NC}"
    echo -e "  ${GREEN}3. 确认后，Claude 生成所有约束文件${NC}"
    echo ""
    echo "脚本已复制到当前目录，监控脚本已就绪。"
}

# Existing project mode init
init_existing() {
    print_header "现有项目模式初始化"

    # Copy the scan script
    cp "$AUTO_AGENTS_DIR/scan-existing-project.sh" .
    chmod +x scan-existing-project.sh

    echo "运行扫描脚本..."
    ./scan-existing-project.sh
}

# Main function
main() {
    clear

    # Check if Auto_agents directory exists
    if [ ! -d "$AUTO_AGENTS_DIR" ]; then
        echo -e "${RED}Error: Auto_agents directory not found${NC}"
        echo "Expected: $AUTO_AGENTS_DIR"
        echo ""
        echo "Please update the AUTO_AGENTS_DIR variable in this script"
        exit 1
    fi

    print_header "项目初始化"
    echo -e "${BOLD}当前目录:${NC} $(pwd)"
    echo ""

    # Check if we should check for empty directory
    if [ "$1" != "--force" ]; then
        check_directory
    fi

    # Select mode
    select_mode
    local mode=$?

    # Copy common scripts first
    copy_scripts

    # Run mode-specific init
    case $mode in
        1)
            init_spec_driven
            ;;
        2)
            init_traditional
            ;;
        3)
            init_existing
            ;;
    esac

    # Final instructions
    print_header "初始化完成"

    echo -e "${GREEN}脚本已复制到当前目录：${NC}"
    echo "  - monitor-claude.sh"
    echo "  - run-claude-loop.sh"
    echo ""

    echo -e "${BOLD}监控命令：${NC}"
    echo "  ./monitor-claude.sh --start   # 启动监控"
    echo "  ./monitor-claude.sh --status   # 查看状态"
    echo "  ./monitor-claude.sh --stop    # 停止监控"
    echo ""

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

main "$@"
