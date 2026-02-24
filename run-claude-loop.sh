#!/bin/bash

# =============================================================================
# run-claude-loop.sh - Single Session Claude Code Runner
# =============================================================================
# Runs Claude Code for ONE session only.
# This script is called by monitor-claude.sh when Claude is not running.
#
# Usage: ./run-claude-loop.sh [--once]
#   --once: Run one session and exit (don't check for monitor)
# =============================================================================

set -e

# =============================================================================
# Configuration
# =============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# Log files
LOG_FILE="claude-loop.log"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
SESSION_LOG_FILE="claude-session-${TIMESTAMP}.log"
MONITOR_PID_FILE=".monitor.pid"
MONITOR_LOG_FILE="monitor.log"

# Claude Code command
CLAUDE_CMD="claude"

# Current directory
PROJECT_DIR="$(pwd)"

# =============================================================================
# Helper Functions
# =============================================================================

print_header() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

log_message() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg" >> "$LOG_FILE"
}

# Check if required files exist
check_required_files() {
    if [ ! -f "CLAUDE.md" ]; then
        echo -e "${RED}Error: CLAUDE.md not found in current directory${NC}"
        echo "Please run this script in a project directory with CLAUDE.md"
        exit 1
    fi

    if [ ! -f "task.json" ]; then
        echo -e "${RED}Error: task.json not found in current directory${NC}"
        exit 1
    fi
}

# Count remaining tasks
count_remaining_tasks() {
    if [ ! -f "task.json" ]; then
        echo "0"
        return
    fi
    local count=$(grep -c '"passes": false' task.json 2>/dev/null || echo "0")
    echo "$count"
}

# Count completed tasks
count_completed_tasks() {
    if [ ! -f "task.json" ]; then
        echo "0"
        return
    fi
    local count=$(grep -c '"passes": true' task.json 2>/dev/null || echo "0")
    echo "$count"
}

# Get current task info
get_current_task_info() {
    if [ ! -f "task.json" ]; then
        echo "No task.json found"
        return
    fi

    # Find the first pending task
    local task_id=$(jq -r '.tasks[] | select(.passes == false) | .id' task.json 2>/dev/null | head -n 1)

    if [ -z "$task_id" ] || [ "$task_id" = "null" ]; then
        echo "No pending tasks"
        return
    fi

    local title=$(jq -r ".tasks[] | select(.id == $task_id) | .title" task.json 2>/dev/null)
    local priority=$(jq -r ".tasks[] | select(.id == $task_id) | .priority" task.json 2>/dev/null)

    echo "#$task_id: $title ($priority)"
}

# Check for blocking marker
check_blocking() {
    if [ -f "progress.txt" ]; then
        if grep -q "🚫" progress.txt 2>/dev/null; then
            return 0  # Blocking detected
        fi
    fi
    return 1  # No blocking
}

# Get the prompt for Claude
get_claude_prompt() {
    cat << 'INTERNAL_EOF'
请开始一个新的开发会话。

**重要：你必须严格遵循 CLAUDE.md 中定义的工作流程。**

请执行以下步骤：

1. **读取 CLAUDE.md** - 了解完整的工作流程和约束

2. **运行 init.sh** - 初始化开发环境

3. **读取 task.json** - 选择下一个任务
   - 只选择 passes: false 的任务
   - 优先级：critical > high > medium > low
   - 确保所有依赖任务（dependencies）已完成

4. **实现任务** - 按照 task.json 中的 steps 逐一实现

5. **测试验证** - 根据 testing.md 中的规则进行测试
   - 大幅修改：浏览器测试
   - 小修改：lint + build

6. **更新 progress.txt** - 记录工作内容

7. **更新 task.json** - 只修改 passes: false → passes: true

8. **Git 提交** - 提交所有更改
   - 代码修改
   - progress.txt
   - task.json
   - Commit 格式: "[ID] [标题] - completed"

⚠️ **阻塞处理**：
如果遇到以下情况，必须在 progress.txt 中记录阻塞信息并停止：
- 缺少环境配置（API密钥、数据库等）
- 外部服务不可用
- 测试无法进行
- 需求不明确

阻塞信息格式：
🚫 任务阻塞 - 需要人工介入
**当前任务**: [任务ID - 任务标题]
**阻塞原因**: [具体原因]

请现在开始执行，首先告诉我你选择了哪个任务。

完成所有步骤后，明确说明"本次会话任务完成，退出"。
INTERNAL_EOF
}

# Run single Claude session
run_single_session() {
    print_header "Claude Code Session"

    # Log session start
    log_message "=== Starting Claude Session ==="

    # Show current status
    local remaining=$(count_remaining_tasks)
    local completed=$(count_completed_tasks)
    local current_task=$(get_current_task_info)

    echo -e "${BOLD}Current Status:${NC}"
    echo "  ✓ Completed tasks: $completed"
    echo "  ○ Remaining tasks: $remaining"
    echo "  → Next task: $current_task"
    echo ""

    log_message "Status: $completed completed, $remaining remaining, Next: $current_task"

    # Check if all tasks are done
    if [ "$remaining" -eq 0 ]; then
        echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                    🎉 ALL TASKS COMPLETE! 🎉                       ║${NC}"
        echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
        log_message "All tasks complete - no session needed"
        return 1
    fi

    # Check for blocking
    if check_blocking; then
        echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║                  ⚠️  BLOCKING DETECTED ⚠️                         ║${NC}"
        echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${RED}A blocking issue was found in progress.txt${NC}"
        echo ""
        echo "Please resolve the blocking issue first:"
        echo "  1. Check progress.txt for details"
        echo "  2. Resolve the issue"
        echo "  3. Remove the blocking marker (🚫) from progress.txt"
        echo ""
        log_message "Blocking detected - session not started"
        return 2
    fi

    # Run Claude Code
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Starting Claude Code...${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Save current state for comparison
    local before_remaining=$remaining
    local before_completed=$completed

    # Execute claude with the prompt
    local prompt=$(get_claude_prompt)

    # Run Claude interactively
    if echo "$prompt" | $CLAUDE_CMD --permission-mode acceptEdits; then
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}✓ Claude Code session completed${NC}"

        # Check results
        local new_remaining=$(count_remaining_tasks)
        local new_completed=$(count_completed_tasks)

        echo ""
        echo -e "${BOLD}Session Results:${NC}"
        echo "  Tasks before: $before_remaining remaining, $before_completed completed"
        echo "  Tasks after:  $new_remaining remaining, $new_completed completed"

        if [ "$new_completed" -gt "$before_completed" ]; then
            local tasks_done=$((new_completed - before_completed))
            echo -e "${GREEN}  ✓ $tasks_done task(s) completed!${NC}"
            log_message "Session completed: $tasks_done task(s) done ($before_remaining → $new_remaining remaining)"
        else
            echo -e "${YELLOW}  ⚠ No task was marked as complete${NC}"
            log_message "Session completed but no task marked as done"
        fi

        # Show latest commit if exists
        if git rev-parse --git-dir > /dev/null 2>&1; then
            echo ""
            echo -e "${BOLD}Latest Git Commit:${NC}"
            git log --oneline -1 2>/dev/null || echo "  No commits yet"
        fi

        log_message "=== Session completed ==="
        return 0
    else
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}✗ Claude Code session exited with error${NC}"
        log_message "Session failed with error code $?"
        return 1
    fi
}

# =============================================================================
# Main Script
# =============================================================================

main() {
    # Parse arguments
    local RUN_ONCE=false
    if [ "$1" = "--once" ]; then
        RUN_ONCE=true
    fi

    # Initialize log
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ========== Claude Session Started ==========" >> "$LOG_FILE"

    # Print banner
    clear
    print_header "Claude Code - Single Session Runner"
    echo -e "${BOLD}Project:${NC} $PROJECT_DIR"
    echo -e "${BOLD}Log file:${NC} $LOG_FILE"
    echo ""

    # Check required files
    check_required_files

    # Show status
    local total_tasks=$(jq '.tasks | length' task.json 2>/dev/null || echo "unknown")
    local initial_remaining=$(count_remaining_tasks)
    local initial_completed=$(count_completed_tasks)

    echo -e "${BOLD}Task Overview:${NC}"
    echo "  Total tasks:      $total_tasks"
    echo "  Completed tasks:  $initial_completed"
    echo "  Remaining tasks:  $initial_remaining"
    echo ""

    # Run the session
    run_single_session
    local exit_code=$?

    # Check for blocking after session
    if check_blocking; then
        echo ""
        echo -e "${YELLOW}⚠️  Blocking detected after session. Monitor will pause.${NC}"
    fi

    # If not running in once mode, check if monitor should continue
    if [ "$RUN_ONCE" = false ]; then
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}Session Complete. Monitor will check for Claude status...${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    fi

    exit $exit_code
}

# Run main
main "$@"
