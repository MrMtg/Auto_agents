#!/bin/bash

# =============================================================================
# spec-driven-init.sh - Spec-Driven Development Initialization
# =============================================================================
# Interactive initialization for Spec-Driven Development mode.
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
BOLD='\033[1m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Main function
main() {
    clear
    print_header "规格驱动开发模式初始化"

    echo "这个模式适用于复杂项目或需求不明确的场景。"
    echo ""
    echo "流程："
    echo "  1. 你用一句话描述项目"
    echo "  2. AI 系统性地提问澄清需求"
    echo "  3. 生成完整的技术规格"
    echo "  4. 新会话，只看规格，AI 自主开发"
    echo ""

    # Step 1: Get minimal spec
    echo -e "${BOLD}请用一句话描述你想要构建的项目：${NC}"
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

    # Save minimal spec
    echo "$minimal_spec" > MINIMAL_SPEC.txt
    echo ""
    echo -e "${GREEN}✓ 已保存最小规格${NC}"
    cat MINIMAL_SPEC.txt
    echo ""

    # Create/update CLAUDE.md with spec-driven prompt
    print_header "配置工作流程"

    cat > CLAUDE.md << 'EOF'
# 规格驱动开发模式

## 项目状态

**当前模式：** 规格驱动开发

**最小规格：** 见 MINIMAL_SPEC.txt

---

## ⚠️ 规格澄清模式激活

当用户说 **"开始规格澄清"** 或 **"开始采访"** 时：

1. **自动读取 MINIMAL_SPEC.txt**
2. **像产品经理一样系统性提问**，涵盖：
   - 功能范围（核心功能、MVP、后续版本）
   - 边缘案例（空输入、超长输入、并发、大数据量）
   - 错误处理（各种错误的响应方式）
   - 数据设计（存储什么、关系、持久化）
   - 接口设计（端点、请求方式、认证）
   - 性能要求（响应时间、并发、缓存）
   - 安全要求（认证、数据保护）
   - 测试要求（测试类型、覆盖率）

3. **提问方式**：
   - 一次问一类问题
   - 用户回答简略时主动追问
   - 不确定时举例说明
   - 定期总结理解，让用户确认

4. **完成采访后**：
   - 生成完整的 **SPEC.md** 文件
   - 包含：需求描述、边缘案例、错误处理、接口设计、数据模型、测试要求

---

## 实施阶段

规格澄清完成后，用户会启动新的干净会话。

届时只需要：
1. 阅读 SPEC.md
2. 严格按照规格自主开发
3. 遇到规格未明确的问题，在 progress.txt 中记录并停止
EOF

    echo -e "${GREEN}✓ 已配置 CLAUDE.md${NC}"
    echo ""

    # Create inquiry guide for reference
    cat > SPEC_INQUIRY_GUIDE.md << 'EOF'
# 规格澄清采访清单（AI 参考）

## 采访流程

使用 AskUserQuestion 工具向用户询问以下方面：

### 1. 功能范围
- 核心功能有哪些？
- 哪些是 MVP 必须的？
- 哪些可以后续再做？
- 有哪些明确不想做的？

### 2. 边缘案例
- 输入为空时怎么办？
- 输入超长时怎么办？
- 并发操作时怎么处理？
- 数据量很大时怎么处理？
- 网络断开时怎么办？

### 3. 错误处理
- 各种错误返回什么信息？
- 需要重试机制吗？
- 需要错误日志吗？
- 用户如何知道出错了？

### 4. 数据设计
- 需要存储哪些数据？
- 数据之间的关系？
- 如何持久化？
- 需要数据迁移吗？

### 5. 接口设计
- API 端点是什么？
- 请求方式（GET/POST/PUT/DELETE）？
- 请求/响应格式？
- 需要认证吗？
- 需要版本控制吗？

### 6. 性能要求
- 响应时间要求？
- 并发用户数预期？
- 需要缓存吗？
- 需要异步处理吗？

### 7. 安全要求
- 需要用户认证吗？
- 如何保护敏感数据？
- 如何防止常见攻击？
- 需要审计日志吗？

### 8. 测试要求
- 需要哪些测试类型？
- 测试覆盖率要求？
- 如何进行手动测试？

## 输出格式

完成采访后，生成 SPEC.md，包含：

```markdown
# 项目规格

## 1. 项目概述
[项目描述]

## 2. 功能需求
### 2.1 核心功能
- 功能1：[描述]
- 功能2：[描述]

### 2.2 边缘案例处理
- [边缘情况1]：[处理方式]
- [边缘情况2]：[处理方式]

## 3. 非功能需求
### 3.1 性能要求
- [具体要求]

### 3.2 安全要求
- [具体要求]

## 4. 数据模型
[数据结构]

## 5. 接口设计
[API 设计]

## 6. 错误处理
[错误处理策略]

## 7. 测试要求
[测试类型和覆盖率]
```
EOF

    echo -e "${GREEN}✓ 已创建采访清单: SPEC_INQUIRY_GUIDE.md${NC}"
    echo ""

    # Final instructions
    print_header "初始化完成"

    echo -e "${BOLD}已生成的文件：${NC}"
    echo "  - MINIMAL_SPEC.txt         (你的最小规格)"
    echo "  - CLAUDE.md                (工作流程配置)"
    echo "  - SPEC_INQUIRY_GUIDE.md    (采访清单)"
    echo ""

    echo -e "${BOLD}下一步操作：${NC}"
    echo ""
    echo -e "${GREEN}1. 直接对 Claude 说：${NC} \"开始规格澄清\""
    echo -e "${GREEN}2. Claude 会自动读取 MINIMAL_SPEC.txt 并开始提问${NC}"
    echo -e "${GREEN}3. 回答问题，Claude 会生成完整的 SPEC.md${NC}"
    echo ""
    echo -e "${YELLOW}提示：你不需要记住文件名，直接说 \"开始规格澄清\" 即可${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

main "$@"
