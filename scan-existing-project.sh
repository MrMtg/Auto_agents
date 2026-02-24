#!/bin/bash

# =============================================================================
# scan-existing-project.sh - Scan Existing Project and Generate Tasks
# =============================================================================
# For existing projects, this script scans the codebase and generates
# task.json and other constraint files based on the project state.
#
# Usage: ./scan-existing-project.sh
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

log_message() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg" >> "project-scan.log"
}

# Detect project type
detect_project_type() {
    print_header "Step 1: Detecting Project Type"

    local project_type="unknown"
    local framework="unknown"
    local language="unknown"

    # Check for package.json (Node.js)
    if [ -f "package.json" ]; then
        language="JavaScript/TypeScript"

        # Check framework
        if grep -q '"vite"' package.json 2>/dev/null; then
            framework="Vite"
        elif grep -q '"next"' package.json 2>/dev/null; then
            framework="Next.js"
        elif grep -q '"react"' package.json 2>/dev/null; then
            framework="React"
        elif grep -q '"vue"' package.json 2>/dev/null; then
            framework="Vue"
        elif grep -q '"nuxt"' package.json 2>/dev/null; then
            framework="Nuxt"
        elif grep -q '"@angular"' package.json 2>/dev/null; then
            framework="Angular"
        elif grep -q '"svelte"' package.json 2>/dev/null; then
            framework="Svelte"
        else
            framework="Node.js"
        fi
        project_type="frontend"
    fi

    # Check for requirements.txt (Python)
    if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
        language="Python"
        if [ -f "manage.py" ] || grep -q "django" requirements.txt 2>/dev/null; then
            framework="Django"
        elif grep -q "fastapi" requirements.txt 2>/dev/null || grep -q "fastapi" pyproject.toml 2>/dev/null; then
            framework="FastAPI"
        elif grep -q "flask" requirements.txt 2>/dev/null; then
            framework="Flask"
        else
            framework="Python"
        fi
        project_type="backend"
    fi

    # Check for go.mod (Go)
    if [ -f "go.mod" ]; then
        language="Go"
        framework="Go"
        project_type="backend"
    fi

    # Check for pom.xml (Java/Maven)
    if [ -f "pom.xml" ]; then
        language="Java"
        framework="Maven"
        project_type="backend"
    fi

    # Check for Cargo.toml (Rust)
    if [ -f "Cargo.toml" ]; then
        language="Rust"
        framework="Cargo"
        project_type="backend"
    fi

    echo -e "${BOLD}Language:${NC} $language"
    echo -e "${BOLD}Framework:${NC} $framework"
    echo -e "${BOLD}Type:${NC} $project_type"
    echo ""

    log_message "Detected: $language / $framework / $project_type"

    # Export for later use
    echo "LANGUAGE=$language" > .project-info
    echo "FRAMEWORK=$framework" >> .project-info
    echo "PROJECT_TYPE=$project_type" >> .project-info
}

# Analyze current state
analyze_current_state() {
    print_header "Step 2: Analyzing Current State"

    # Check for existing files
    echo -e "${BOLD}Existing Files:${NC}"

    local files=(
        "README.md"
        "package.json"
        "tsconfig.json"
        ".env"
        ".env.example"
        "CLAUDE.md"
        "task.json"
        "progress.txt"
    )

    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            echo -e "  ${GREEN}✓${NC} $file"
        else
            echo -e "  ${YELLOW}○${NC} $file (not found)"
        fi
    done

    echo ""

    # Count source files
    local src_count=0
    if [ -d "src" ]; then
        src_count=$(find src -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" -o -name "*.go" \) 2>/dev/null | wc -l)
    fi

    echo -e "${BOLD}Source Files:${NC} $src_count"
    echo ""

    # Check git status
    if [ -d ".git" ]; then
        local commit_count=$(git log --oneline 2>/dev/null | wc -l)
        echo -e "${BOLD}Git Commits:${NC} $commit_count"
        echo ""
    fi
}

# Generate default task.json
generate_task_json() {
    print_header "Step 3: Generating task.json"

    if [ -f "task.json" ]; then
        echo -e "${YELLOW}⚠️  task.json already exists${NC}"
        read -p "Overwrite? [y/N]: " overwrite
        if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
            echo "Skipping task.json generation"
            return
        fi
    fi

    # Read project info
    source .project-info 2>/dev/null || true

    cat > task.json << EOF
{
  "project": "$(basename $(pwd))",
  "description": "Existing project - continue development",
  "version": "1.0.0",
  "created_at": "$(date '+%Y-%m-%d')",
  "existing_project": true,
  "tasks": [
    {
      "id": 1,
      "title": "项目现状分析",
      "description": "分析现有代码库，了解项目结构和已完成的功能",
      "steps": [
        "阅读 README.md 了解项目概况",
        "查看 package.json 了解依赖和脚本",
        "分析 src/ 目录结构",
        "总结已完成的功能和待完成的任务"
      ],
      "passes": false,
      "priority": "critical",
      "dependencies": []
    },
    {
      "id": 2,
      "title": "代码审查和优化建议",
      "description": "审查现有代码，提出优化建议",
      "steps": [
        "检查代码风格一致性",
        "查找潜在的 bug 或问题",
        "检查是否有未使用的依赖",
        "列出优化建议"
      ],
      "passes": false,
      "priority": "high",
      "dependencies": [1]
    },
    {
      "id": 3,
      "title": "补充缺失的文档",
      "description": "补充或完善项目文档",
      "steps": [
        "更新 README.md",
        "添加代码注释",
        "创建 API 文档（如需要）"
      ],
      "passes": false,
      "priority": "medium",
      "dependencies": [2]
    }
  ]
}
EOF

    echo -e "${GREEN}✓ Generated task.json${NC}"
    echo ""
    echo "Note: This is a generic task.json. You should edit it to add"
    echo "      project-specific tasks based on your needs."
    echo ""
}

# Generate CLAUDE.md
generate_claude_md() {
    print_header "Step 4: Generating CLAUDE.md"

    if [ -f "CLAUDE.md" ]; then
        echo -e "${YELLOW}⚠️  CLAUDE.md already exists${NC}"
        read -p "Overwrite? [y/N]: " overwrite
        if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
            echo "Skipping CLAUDE.md generation"
            return
        fi
    fi

    # Read project info
    source .project-info 2>/dev/null || true

    cat > CLAUDE.md << 'EOF'
# 项目工作流程 - Agent 约束

## 项目上下文

这是一个**现有项目**，继续开发需要了解现有代码库。

## ⚠️ 强制工作流程

**Claude Code 执行时必须严格遵守以下流程：**

---

## STEP 1: 了解现有代码库

```bash
# 阅读项目文档
cat README.md

# 了解项目结构
find . -type f -name "*.ts" -o -name "*.tsx" -o -name "*.js" | head -20

# 查看依赖
cat package.json
```

---

## STEP 2: 初始化环境

```bash
./init.sh
```

如果 init.sh 不存在，手动初始化：
```bash
npm install
npm run dev
```

---

## STEP 3: 选择下一个任务

读取 `task.json` 并选择**一个** `passes: false` 的任务。

---

## STEP 4: 实现任务

- 仔细阅读任务的 `title`、`description` 和 `steps`
- 遵循现有代码风格
- 参考项目中已有的类似代码

---

## STEP 5: 测试和验证

| 修改类型 | 测试要求 |
|---------|---------|
| **大幅修改** | 浏览器测试 + lint + build |
| **小修改** | lint + build |

---

## STEP 6: 更新进度和任务文件

### 6.1 更新 progress.txt

```markdown
## [YYYY-MM-DD] - Task: [任务标题]

### What was done:
- [具体修改]

### Testing:
- [测试结果]

### Notes:
- [注意事项]
```

### 6.2 更新 task.json

**只能修改 `passes` 字段！**
```json
"passes": false  →  "passes": true
```

---

## STEP 7: Git 提交代码

```bash
git add .
git commit -m "[ID] [标题] - completed"
```

---

## 🚫 阻塞处理

遇到以下情况必须停止并请求帮助：
- 现有代码逻辑不清楚
- 需要了解业务背景
- 需要添加新依赖但不确定版本
- 测试环境配置问题

---

## 项目特定规则

- 保持现有代码风格
- 参考现有组件/模块的模式
- 不随意重构未涉及的任务代码
- 修改前先了解设计意图
EOF

    echo -e "${GREEN}✓ Generated CLAUDE.md${NC}"
}

# Main function
main() {
    clear
    print_header "Existing Project Scanner"

    echo "This script will scan your existing project and generate"
    echo "the necessary files for the long-running agent system."
    echo ""
    echo -e "${YELLOW}Note:${NC} This works best for web projects (React, Vue, Next.js, etc.)"
    echo ""
    read -p "Press Enter to continue..."

    echo ""
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ========== Project Scan Started ==========" > "project-scan.log"

    detect_project_type
    analyze_current_state
    generate_task_json
    generate_claude_md

    print_header "Scan Complete"

    echo -e "${GREEN}Generated files:${NC}"
    echo "  - task.json       (edit this to add your specific tasks)"
    echo "  - CLAUDE.md       (workflow constraints)"
    echo "  - .project-info   (detected project info)"
    echo "  - project-scan.log (scan log)"
    echo ""

    echo -e "${BOLD}Next steps:${NC}"
    echo "  1. Edit task.json to add project-specific tasks"
    echo "  2. Review and customize CLAUDE.md if needed"
    echo "  3. Run: ./monitor-claude.sh --start"
    echo "  4. Start Claude and begin work"
    echo ""

    log_message "========== Project Scan Complete =========="
}

main "$@"
