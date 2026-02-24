#!/bin/bash

# =============================================================================
# spec-driven-init.sh - Spec-Driven Development Initialization
# =============================================================================
# Uses Spec-Driven Development approach to clarify requirements
# before generating constraint files.
#
# Three phases:
#   1. Minimal Spec - You write a brief description
#   2. AI Inquiry - Claude asks clarifying questions
#   3. Complete Spec - Generate full specification
#   4. Clean Session - New session with only the spec
#
# Usage: ./spec-driven-init.sh
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Phase 1: Minimal Spec
phase1_minimal_spec() {
    print_header "Phase 1: Minimal Spec"

    echo "请用一句话描述你想要构建的项目："
    echo ""
    echo "示例："
    echo "  - 一个待办事项管理应用"
    echo "  - 一个 Flask API，支持图片上传和处理"
    echo "  - 一个博客系统，支持 Markdown 写作"
    echo ""

    read -p "你的描述: " minimal_spec

    if [ -z "$minimal_spec" ]; then
        echo -e "${RED}Error: 描述不能为空${NC}"
        exit 1
    fi

    echo "$minimal_spec" > MINIMAL_SPEC.txt
    echo ""
    echo -e "${GREEN}✓ 已保存最小规格${NC}"
}

# Phase 2: AI Inquiry Instructions
phase2_inquiry_instructions() {
    print_header "Phase 2: AI 主动设问澄清"

    cat > SPEC_INQUIRY.md << 'EOF'
# 规格澄清 - AI 采访清单

你是一位资深产品经理和工程师。你的任务是通过对用户进行系统性的采访，将一个模糊的想法转化为一份完整、可执行的技术规格。

## 采访流程

请使用 AskUserQuestion 工具（或在对话中直接提问）向用户询问以下方面的问题：

### 1. 功能范围 (Scope)
- 核心功能有哪些？
- 哪些功能是 MVP（最小可行产品）必须的？
- 哪些功能可以留到后续版本？
- 有哪些明确不想做的功能？

### 2. 边缘案例 (Edge Cases)
- 输入为空时怎么办？
- 输入超长时怎么办？
- 并发操作时怎么处理？
- 数据量很大时怎么处理？
- 网络断开时怎么办？

### 3. 错误处理 (Error Handling)
- 各种错误场景需要返回什么信息？
- 是否需要错误重试机制？
- 是否需要错误日志记录？
- 用户如何知道出错了？

### 4. 数据设计 (Data Design)
- 需要存储哪些数据？
- 数据之间的关系是什么？
- 数据如何持久化？
- 是否需要数据迁移策略？

### 5. 接口设计 (Interface Design)
- API 端点路径是什么？
- 请求方式是什么（GET/POST/PUT/DELETE）？
- 请求/响应格式是什么？
- 是否需要认证？
- 是否需要版本控制？

### 6. 性能要求 (Performance)
- 响应时间要求是多少？
- 并发用户数预期是多少？
- 是否需要缓存？
- 是否需要异步处理？

### 7. 安全要求 (Security)
- 是否需要用户认证？
- 如何保护敏感数据？
- 如何防止常见攻击（XSS、CSRF、SQL注入）？
- 是否需要审计日志？

### 8. 测试要求 (Testing)
- 需要哪些类型的测试（单元/集成/E2E）？
- 测试覆盖率要求是多少？
- 如何进行手动测试？

## 采访技巧

1. **一次问一类问题** - 不要一次性问太多
2. **追问细节** - 用户回答简略时，主动追问
3. **举例说明** - 不确定用户理解时，给出例子
4. **确认理解** - 总结自己的理解，让用户确认

## 输出

完成采访后，生成一份完整的 `SPEC.md` 文件，包含：
- 项目概述
- 功能需求
- 非功能需求
- 边缘案例处理
- 错误处理策略
- 接口设计
- 数据模型
- 测试要求
EOF

    echo -e "${GREEN}✓ 已生成采访清单: SPEC_INQUIRY.md${NC}"
    echo ""
    echo -e "${YELLOW}下一步：${NC}"
    echo "1. 阅读 SPEC_INQUIRY.md 了解采访流程"
    echo "2. 对 Claude 说：\"请使用规格澄清模式，根据 MINIMAL_SPEC.txt 中的描述进行采访\""
    echo "3. Claude 会向你提问，请一一回答"
    echo "4. 采访完成后，Claude 会生成完整的 SPEC.md"
    echo ""
}

# Phase 3: Generate implementation prompt
phase3_implementation_prompt() {
    print_header "Phase 3: 实施阶段提示"

    if [ ! -f "SPEC.md" ]; then
        echo -e "${YELLOW}⚠️  SPEC.md 还未生成${NC}"
        echo "请先完成 Phase 2 的采访流程"
        echo ""
        return
    fi

    cat > IMPLEMENTATION_PROMPT.txt << 'EOF'
# 实施阶段提示

## 启动新的干净会话

规格澄清完成后，请启动一个新的 Claude 会话（清空上下文）。

## 初始 Prompt

在新的会话中，使用以下提示：

---

你是一位资深软件工程师。请严格按照 `SPEC.md` 中的规格说明，自主完成以下开发工作：

1. 阅读并理解 `SPEC.md` 中的完整规格
2. 设计数据模型和接口
3. 编写代码实现所有功能
4. 添加必要的测试
5. 运行测试并修复所有 bug
6. 确保所有测试通过

## 工作流程

- 遵循 `CLAUDE.md` 中定义的工作流程
- 按照 `task.json` 中的任务顺序执行
- 遇到规格中未明确说明的问题，在 `progress.txt` 中记录并停止

## 重要

- 不要偏离规格中的要求
- 不要添加未在规格中说明的功能
- 如果规格有歧义，选择最合理的解释并在代码注释中说明
- 所有技术选择都应在规格说明的指导下进行
EOF

    echo -e "${GREEN}✓ 已生成实施提示: IMPLEMENTATION_PROMPT.txt${NC}"
    echo ""
}

# Main function
main() {
    clear
    print_header "Spec-Driven Development Initialization"

    echo "规格驱动开发三阶段："
    echo ""
    echo "  Phase 1: 最小规格 - 你用一句话描述项目"
    echo "  Phase 2: AI 采访 - Claude 系统性地澄清需求"
    echo "  Phase 3: 完整规格 - 生成可执行的技术规格"
    echo "  Phase 4: 干净实施 - 新会话，只看规格，自主开发"
    echo ""

    read -p "Press Enter to start..."

    phase1_minimal_spec
    phase2_inquiry_instructions
    phase3_implementation_prompt

    print_header "初始化完成"

    echo -e "${GREEN}已生成的文件：${NC}"
    echo "  - MINIMAL_SPEC.txt        (你的最小规格)"
    echo "  - SPEC_INQUIRY.md         (AI 采访清单)"
    echo "  - IMPLEMENTATION_PROMPT.txt (实施阶段提示)"
    echo ""
    echo -e "${BOLD}下一步操作：${NC}"
    echo ""
    echo "1. 对 Claude 说："
    echo "   \"请使用规格澄清模式，根据 MINIMAL_SPEC.txt 中的描述进行采访\""
    echo ""
    echo "2. Claude 会向你提问，请一一回答"
    echo ""
    echo "3. 采访完成后，Claude 会生成完整的 SPEC.md"
    echo ""
    echo "4. 启动新的干净会话，使用 IMPLEMENTATION_PROMPT.txt 中的提示开始开发"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

main "$@"
