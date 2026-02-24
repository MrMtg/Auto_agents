@echo off
REM =============================================================================
REM init-project.bat - Windows Project Initialization Script
REM =============================================================================
REM
REM Installation:
REM   1. Copy this file to a directory in your PATH (e.g., C:\Windows\Scripts)
REM   2. Or create a batch file alias
REM
REM Usage:
REM   mkdir my-project
REM   cd my-project
REM   init-project
REM =============================================================================

setlocal enabledelayedexpansion

REM Auto_agents directory (adjust this path)
set "AUTO_AGENTS_DIR=C:\work\claude-agent-system"

REM Colors (Windows 10+)
for /F %%A in ('echo prompt $E ^| cmd') do set "ESC=%%A"
set "GREEN=%ESC%[92m"
set "CYAN=%ESC%[96m"
set "YELLOW=%ESC%[93m"
set "RED=%ESC%[91m"
set "NC=%ESC%[0m"

REM Check Auto_agents directory
if not exist "%AUTO_AGENTS_DIR%" (
    echo %RED%Error: Auto_agents directory not found%NC%
    echo Expected: %AUTO_AGENTS_DIR%
    echo.
    echo Please update the AUTO_AGENTS_DIR variable in this script
    pause
    exit /b 1
)

echo.
echo %CYAN%━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%NC%
echo %CYAN%  项目初始化%NC%
echo %CYAN%━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%NC%
echo.
echo 当前目录: %CD%
echo.

REM Select mode
echo 请选择初始化模式：
echo.
echo   1) 规格驱动模式 (推荐)
echo      适用于复杂项目或需求不明确的场景
echo      AI 会系统性提问澄清需求
echo.
echo   2) 传统对话模式
echo      适用于需求明确的场景
echo      直接通过对话收集需求
echo.
echo   3) 现有项目模式
echo      适用于老项目继续开发
echo      自动扫描现有代码库
echo.

set /p mode="请选择 (1-3): "

REM Copy scripts
echo.
echo 复制脚本文件...
copy "%AUTO_AGENTS_DIR%\monitor-claude.sh" . >nul 2>&1
copy "%AUTO_AGENTS_DIR%\run-claude-loop.sh" . >nul 2>&1

if errorlevel 1 (
    echo %RED%Error: Cannot copy scripts from Auto_agents directory%NC%
    pause
    exit /b 1
)

echo %GREEN%✓ 脚本复制完成%NC%
echo.

REM Run mode-specific init
if "%mode%"=="1" (
    echo 规格驱动模式初始化...
    copy "%AUTO_AGENTS_DIR%\spec-driven-init.sh" . >nul
    bash spec-driven-init.sh
) else if "%mode%"=="2" (
    echo 传统对话模式初始化...
    echo.
    echo 下一步：
    echo   1. 对 Claude 说："帮我初始化一个新项目"
    echo   2. Claude 会问你项目信息，逐一回答
    echo   3. 确认后，Claude 生成所有约束文件
) else if "%mode%"=="3" (
    echo 现有项目模式初始化...
    copy "%AUTO_AGENTS_DIR%\scan-existing-project.sh" . >nul
    bash scan-existing-project.sh
) else (
    echo %RED%Invalid choice%NC%
    pause
    exit /b 1
)

echo.
echo %CYAN%━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%NC%
echo.
echo %GREEN%初始化完成！%NC%
echo.
echo 脚本已复制到当前目录：
echo   - monitor-claude.sh
echo   - run-claude-loop.sh
echo.
echo 监控命令：
echo   ./monitor-claude.sh --start   # 启动监控
echo   ./monitor-claude.sh --status   # 查看状态
echo   ./monitor-claude.sh --stop    # 停止监控
echo.

pause
