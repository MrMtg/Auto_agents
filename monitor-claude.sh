#!/bin/bash

# =============================================================================
# monitor-claude.sh - Background Monitor for Claude Code
# =============================================================================
# Monitors whether Claude is running in the current project directory.
# When Claude stops, automatically starts the next session.
#
# Features:
# - Detects if Claude process is running in current directory
# - Checks for blocking markers before starting new session
# - Pauses when blocking is detected, resumes when resolved
# - Stops when all tasks are complete
#
# Usage: ./monitor-claude.sh [--start|--stop|--status]
#   --start:  Start monitor in background
#   --stop:   Stop running monitor
#   --status: Show monitor status
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

# Files
MONITOR_PID_FILE=".monitor.pid"
MONITOR_LOG_FILE="monitor.log"
SESSION_RUNNER="./run-claude-loop.sh"
BLOCKING_RESOLVED_FILE=".blocking-resolved"

# Check intervals
CHECK_INTERVAL=5          # Seconds between checks when Claude is running
POST_SESSION_WAIT=2       # Seconds to wait after Claude exits
BLOCKING_CHECK_WAIT=10    # Seconds between checks when blocking is detected

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
    echo "$msg" >> "$MONITOR_LOG_FILE"
    echo -e "${BLUE}[MONITOR]${NC} $msg"
}

# Check if Claude is running
is_claude_running() {
    # Check for Claude processes
    if command -v pgrep >/dev/null 2>&1; then
        pgrep -f "claude" >/dev/null 2>&1 && return 0
    fi

    # Alternative: check using ps
    if ps aux 2>/dev/null | grep -v grep | grep -q "claude"; then
        return 0
    fi

    return 1
}

# Check if monitor is running
is_monitor_running() {
    if [ ! -f "$MONITOR_PID_FILE" ]; then
        return 1
    fi

    local pid=$(cat "$MONITOR_PID_FILE" 2>/dev/null)
    if [ -z "$pid" ]; then
        return 1
    fi

    # Check if process is running
    if kill -0 "$pid" 2>/dev/null; then
        return 0
    fi

    # PID file exists but process is not running - clean up
    rm -f "$MONITOR_PID_FILE"
    return 1
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

# Count remaining tasks
count_remaining_tasks() {
    if [ ! -f "task.json" ]; then
        echo "0"
        return
    fi
    local count=$(grep -c '"passes": false' task.json 2>/dev/null || echo "0")
    echo "$count"
}

# Start monitor
start_monitor() {
    if is_monitor_running; then
        echo -e "${YELLOW}⚠️  Monitor is already running${NC}"
        echo -e "PID: $(cat $MONITOR_PID_FILE)"
        return 1
    fi

    # Check required files
    if [ ! -f "CLAUDE.md" ] || [ ! -f "task.json" ]; then
        echo -e "${RED}Error: CLAUDE.md or task.json not found${NC}"
        echo "Please run this script in a project directory with CLAUDE.md"
        return 1
    fi

    print_header "Starting Claude Monitor"

    echo -e "${BOLD}Project:${NC} $(pwd)"
    echo -e "${BOLD}Log file:${NC} $MONITOR_LOG_FILE"
    echo ""

    # Start monitor in background
    nohup "$0" --daemon >> "$MONITOR_LOG_FILE" 2>&1 &
    local pid=$!
    echo "$pid" > "$MONITOR_PID_FILE"

    echo -e "${GREEN}✓ Monitor started${NC}"
    echo -e "${GREEN}PID: $pid${NC}"
    echo ""
    echo -e "To view logs: ${CYAN}tail -f $MONITOR_LOG_FILE${NC}"
    echo -e "To stop monitor: ${CYAN}$0 --stop${NC}"
    echo -e "To check status: ${CYAN}$0 --status${NC}"
}

# Stop monitor
stop_monitor() {
    if ! is_monitor_running; then
        echo -e "${YELLOW}⚠️  Monitor is not running${NC}"
        return 1
    fi

    local pid=$(cat "$MONITOR_PID_FILE")
    kill "$pid" 2>/dev/null || true
    rm -f "$MONITOR_PID_FILE"

    echo -e "${GREEN}✓ Monitor stopped${NC}"
}

# Show monitor status
show_status() {
    print_header "Monitor Status"

    if is_monitor_running; then
        local pid=$(cat "$MONITOR_PID_FILE")
        echo -e "${GREEN}● Monitor is running${NC}"
        echo -e "${BOLD}PID:${NC} $pid"
        echo ""

        # Show last few log lines
        if [ -f "$MONITOR_LOG_FILE" ]; then
            echo -e "${BOLD}Recent log entries:${NC}"
            tail -5 "$MONITOR_LOG_FILE"
        fi
    else
        echo -e "${YELLOW}○ Monitor is not running${NC}"
    fi

    echo ""
    echo -e "${BOLD}Claude Status:${NC}"
    if is_claude_running; then
        echo -e "${GREEN}● Claude is running${NC}"
    else
        echo -e "${YELLOW}○ Claude is not running${NC}"
    fi

    echo ""
    echo -e "${BOLD}Task Status:${NC}"
    if [ -f "task.json" ]; then
        local remaining=$(count_remaining_tasks)
        local total=$(jq '.tasks | length' task.json 2>/dev/null || echo "?")
        local completed=$((total - remaining))
        echo "  Completed: $completed / $total"
        echo "  Remaining: $remaining"
    else
        echo -e "${RED}  No task.json found${NC}"
    fi

    echo ""
    echo -e "${BOLD}Blocking Status:${NC}"
    if check_blocking; then
        echo -e "${RED}● Blocking detected in progress.txt${NC}"
    else
        echo -e "${GREEN}○ No blocking${NC}"
    fi
}

# Daemon mode - runs in background
run_daemon() {
    log_message "=== Monitor started ==="

    # Check if Claude is already running
    if is_claude_running; then
        log_message "Claude is already running, waiting..."
    else
        log_message "Claude is not running, will start first session"
    fi

    local was_blocking=false

    while true; do
        # Check if all tasks are complete
        local remaining=$(count_remaining_tasks)
        if [ "$remaining" -eq 0 ]; then
            log_message "=== All tasks complete! Monitor stopping. ==="
            break
        fi

        # Check for blocking
        if check_blocking; then
            if [ "$was_blocking" = false ]; then
                log_message "=== BLOCKING DETECTED === Monitor pausing."
                was_blocking=true

                # Notify user (if possible)
                echo ""
                echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════════╗${NC}"
                echo -e "${YELLOW}║                  ⚠️  BLOCKING DETECTED ⚠️                         ║${NC}"
                echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════════╝${NC}"
                echo ""
                echo -e "${RED}Monitor has paused due to blocking issue.${NC}"
                echo "Please check progress.txt for details."
                echo ""
                echo "After resolving the issue:"
                echo "  1. Remove the blocking marker (🚫) from progress.txt"
                echo "  2. Run: $0 --resume"
                echo ""
            fi

            sleep "$BLOCKING_CHECK_WAIT"
            continue
        fi

        # Was blocking, now resolved
        if [ "$was_blocking" = true ]; then
            log_message "=== Blocking resolved! Resuming monitor. ==="
            was_blocking=false
        fi

        # Check if Claude is running
        if is_claude_running; then
            log_message "Claude is running, waiting..."
            sleep "$CHECK_INTERVAL"
        else
            log_message "Claude is not running, checking if session should start..."

            # Check if all tasks are complete
            remaining=$(count_remaining_tasks)
            if [ "$remaining" -eq 0 ]; then
                log_message "=== All tasks complete! Monitor stopping. ==="
                break
            fi

            # No blocking and Claude not running - start new session
            log_message "Starting new Claude session..."

            # Clear the resolved flag
            rm -f "$BLOCKING_RESOLVED_FILE"

            # Run the session
            if "$SESSION_RUNNER"; then
                log_message "Session completed successfully"
            else
                local exit_code=$?
                if [ $exit_code -eq 1 ]; then
                    log_message "All tasks complete, monitor stopping"
                    break
                else
                    log_message "Session exited with code $exit_code, continuing..."
                fi
            fi

            # Wait before checking again
            sleep "$POST_SESSION_WAIT"
        fi
    done

    # Clean up
    rm -f "$MONITOR_PID_FILE"
    log_message "=== Monitor stopped ==="
}

# Resume after blocking resolved
resume_monitor() {
    if ! is_monitor_running; then
        echo -e "${RED}Monitor is not running${NC}"
        echo "Start it first with: $0 --start"
        return 1
    fi

    # Create the resolved flag
    touch "$BLOCKING_RESOLVED_FILE"

    echo -e "${GREEN}✓ Monitor will resume after blocking check${NC}"
    log_message "User requested resume after blocking resolved"
}

# =============================================================================
# Main Script
# =============================================================================

main() {
    local command="${1:-}"

    case "$command" in
        --start|-s)
            start_monitor
            ;;
        --stop|--kill)
            stop_monitor
            ;;
        --status|--info)
            show_status
            ;;
        --resume)
            resume_monitor
            ;;
        --daemon)
            run_daemon
            ;;
        "")
            echo "Claude Code Monitor - Background monitor for automated development"
            echo ""
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  --start     Start monitor in background"
            echo "  --stop      Stop running monitor"
            echo "  --status    Show monitor status"
            echo "  --resume    Resume monitor after resolving blocking"
            echo ""
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown command: $command${NC}"
            echo "Run '$0' for usage"
            exit 1
            ;;
    esac
}

main "$@"
