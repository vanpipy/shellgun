#!/usr/bin/env bash
#
# Phase: Constitution generation (dynamic by language)
# Source this from the main script, don't run directly
#

# ============================================================
# Constitution generation (dynamic by language)
# ============================================================
phase_constitution() {
    local project_dir="$1"
    local lang="$2"
    local docs_lang="$3"
    local constitution_file="$project_dir/.specify/memory/constitution.md"

    print_info "Creating constitution for $lang (docs: $docs_lang)..."

    mkdir -p "$(dirname "$constitution_file")"

    # Get language-specific test framework info
    IFS='|' read -r test_framework doc_framework static_analysis <<< "${LANG_CONFIG[$lang]}"

    if [[ "$docs_lang" == "zh" ]]; then
        cat > "$constitution_file" << EOF
# 项目宪章

## 核心原则

### 1. 类型安全与内存安全
- **${lang}** 特定的安全实践：
  $(case $lang in
    rust) echo "  - 禁止使用 \`unsafe\` 代码块，除非经过明确审查和批准";
          echo "  - 优先使用编译时安全检查而非运行时检查";
          echo "  - 使用 \`Arc<Mutex<>>\` 或更好的无锁结构处理共享状态";;
    python) echo "  - 使用 Type Hints 标注所有函数参数和返回值";
            echo "  - 运行 \`mypy\` 进行静态类型检查";
            echo "  - 避免使用 \`object\`、\`Any\` 等模糊类型";;
    go) echo "  - 利用 Go 的强类型系统，避免使用 \`interface{}\`";
        echo "  - 使用 \`go vet\` 检测可疑构造";
        echo "  - 遵循 \_Effective Go\_ 中的安全模式";;
    java) echo "  - 使用 Optional 避免 null 指针";
          echo "  - 优先使用不可变类 (immutable classes)";
          echo "  - 启用 SpotBugs 检测潜在安全漏洞";;
    csharp) echo "  - 使用 nullable reference types 避免 null 引用";
            echo "  - 优先使用 readonly struct 和 record type";
            echo "  - 启用 Roslyn 分析器进行代码审查";;
    *) echo "  - 遵循 ${lang} 社区的最佳安全实践";;
  esac)

### 2. 零成本抽象
- $(case $lang in
    rust) echo "使用泛型、迭代器和 trait bounds，避免不必要的堆分配";;
    python) echo "使用生成器 (generators) 和列表推导式，避免过度的对象创建";;
    go) echo "使用接口 (interfaces) 和嵌入 (embedding) 而非继承";;
    java) echo "使用 Stream API 和 Lambda 表达式，避免过度装箱";;
    csharp) echo "使用 LINQ 和异步流 (IAsyncEnumerable)";;
    *) echo "利用 ${lang} 的语言特性实现零成本或低成本抽象";;
  esac)

### 3. TDD（测试驱动开发）
- **测试先行**：实现代码前先编写失败的测试
- **红-绿-重构**：严格遵循 TDD 循环
- **测试命名**：\`test_<函数>_<场景>_<预期结果>\`
- **测试框架**：使用 **${test_framework}**
- **文档测试**：公共 API 必须有 $(case $lang in
    rust) echo "文档测试 (doc-tests)";;
    python) echo "doctest 示例";;
    go) echo "Example 函数";;
    java) echo "Javadoc 中的 @example 标记";;
    *) echo "示例代码";;
  esac)
- **静态分析**：使用 **${static_analysis}** 保证代码质量

### 4. 错误处理
$(case $lang in
  rust) cat << 'RUST'
- 库代码使用 `thiserror`
- 应用代码使用 `anyhow`
- 永不忽略 `Result`
RUST
  ;;
  python) cat << 'PYTHON'
- 定义具体的异常类型，继承自 `Exception`
- 使用 `try/except` 而非裸 `except:`
- 使用 `contextlib.suppress` 处理预期的忽略异常
PYTHON
  ;;
  go) cat << 'GO'
- 永远不忽略 error 返回值
- 使用 `fmt.Errorf` 或 `errors.Wrap` 添加上下文
- 定义哨兵错误变量 (sentinel errors)
GO
  ;;
  java) cat << 'JAVA'
- 定义具体的 checked/unchecked 异常
- 使用 try-with-resources 自动管理资源
- 避免吞没异常 (empty catch block)
JAVA
  ;;
  *) echo "- 遵循 ${lang} 社区的错误处理最佳实践";;
esac)

### 5. 性能要求
- 低延迟、高并发
$(case $lang in
  rust) echo "- 使用 \`tokio\` 异步运行时";;
  python) echo "- 使用 \`asyncio\` 进行异步编程";;
  go) echo "- 利用 goroutines 和 channels 实现并发";;
  java) echo "- 使用虚拟线程 (Project Loom) 或 CompletableFuture";;
  csharp) echo "- 使用 \`async/await\` 和 \`Task\`";;
  *) echo "- 使用 ${lang} 的并发原语";;
esac)
- 避免关键路径上的锁竞争和阻塞操作

### 6. 治理规则
- 所有公共 API 必须有 $(case $lang in
    rust) echo "文档测试 (doc-test)";;
    python) echo "docstring 和 doctest";;
    go) echo "godoc 注释";;
    java) echo "Javadoc 注释";;
    *) echo "完整的文档注释";;
  esac)
- $(case $lang in
    rust) echo "关键模块必须通过 \`miri\` 校验";;
    python) echo "关键模块必须通过 \`mypy --strict\` 和 \`pytest --cov\`";;
    go) echo "关键模块必须通过 \`go test -race\` 和 \`go vet\`";;
    java) echo "关键模块必须通过 SpotBugs 和 JaCoCo 覆盖率检查";;
    *) echo "关键模块必须有充分的测试覆盖率和静态分析";;
  esac)
- 代码审查必须验证测试先于实现

## 语言配置
- 编程语言: ${lang}
- 测试框架: ${test_framework}
- 文档框架: ${doc_framework}
- 静态分析: ${static_analysis}
- 代码注释语言: 英文
- 文档语言: ${docs_lang}
- 文件/路径命名: 英文
EOF
    else
        # English version
        cat > "$constitution_file" << EOF
# Project Constitution

## Core Principles

### 1. Type & Memory Safety
- **${lang}**-specific safety practices:
  $(case $lang in
    rust) echo "  - No \`unsafe\` code blocks without explicit review and approval";
          echo "  - Prefer compile-time checks over runtime checks";
          echo "  - Use \`Arc<Mutex<>>\` or better lock-free structures for shared state";;
    python) echo "  - Use Type Hints for all function parameters and return values";
            echo "  - Run \`mypy\` for static type checking";
            echo "  - Avoid vague types like \`object\`, \`Any\`";;
    go) echo "  - Leverage Go's strong type system, avoid \`interface{}\`";
        echo "  - Use \`go vet\` to detect suspicious constructs";
        echo "  - Follow security patterns from \_Effective Go\_";;
    java) echo "  - Use Optional to avoid null pointers";
          echo "  - Prefer immutable classes";
          echo "  - Enable SpotBugs to detect potential security vulnerabilities";;
    csharp) echo "  - Use nullable reference types to avoid null references";
            echo "  - Prefer readonly struct and record types";
            echo "  - Enable Roslyn analyzers for code review";;
    *) echo "  - Follow ${lang} community best practices for safety";;
  esac)

### 2. Zero-Cost Abstractions
- $(case $lang in
    rust) echo "Use generics, iterators, and trait bounds, avoid unnecessary allocations";;
    python) echo "Use generators and list comprehensions, avoid excessive object creation";;
    go) echo "Use interfaces and embedding instead of inheritance";;
    java) echo "Use Stream API and Lambda expressions, avoid excessive boxing";;
    csharp) echo "Use LINQ and async streams (IAsyncEnumerable)";;
    *) echo "Leverage ${lang} language features for zero or low-cost abstractions";;
  esac)

### 3. TDD (Test-Driven Development)
- **Test First**: Write failing tests before implementation
- **Red-Green-Refactor**: Strictly follow TDD cycle
- **Test Naming**: \`test_<function>_<scenario>_<expected_outcome>\`
- **Test Framework**: Use **${test_framework}**
- **Doc Testing**: Public APIs must have $(case $lang in
    rust) echo "doc-tests";;
    python) echo "doctest examples";;
    go) echo "Example functions";;
    java) echo "@example tags in Javadoc";;
    *) echo "example code blocks";;
  esac)
- **Static Analysis**: Use **${static_analysis}** for code quality

### 4. Error Handling
$(case $lang in
  rust) cat << 'RUST'
- Use `thiserror` for libraries
- Use `anyhow` for applications
- Never ignore `Result`
RUST
  ;;
  python) cat << 'PYTHON'
- Define specific exception types inheriting from `Exception`
- Use `try/except` instead of bare `except:`
- Use `contextlib.suppress` for expected ignored exceptions
PYTHON
  ;;
  go) cat << 'GO'
- Never ignore error return values
- Use `fmt.Errorf` or `errors.Wrap` to add context
- Define sentinel error variables
GO
  ;;
  java) cat << 'JAVA'
- Define specific checked/unchecked exceptions
- Use try-with-resources for automatic resource management
- Avoid swallowing exceptions (empty catch block)
JAVA
  ;;
  *) echo "- Follow ${lang} community best practices for error handling";;
esac)

### 5. Performance Requirements
- Low latency, high concurrency
$(case $lang in
  rust) echo "- Use \`tokio\` async runtime";;
  python) echo "- Use \`asyncio\` for async programming";;
  go) echo "- Leverage goroutines and channels for concurrency";;
  java) echo "- Use virtual threads (Project Loom) or CompletableFuture";;
  csharp) echo "- Use \`async/await\` and \`Task\`";;
  *) echo "- Use ${lang} concurrency primitives";;
esac)
- Avoid lock contention and blocking operations on critical paths

### 6. Governance Rules
- All public APIs must have $(case $lang in
    rust) echo "doc-tests";;
    python) echo "docstrings and doctests";;
    go) echo "godoc comments";;
    java) echo "Javadoc comments";;
    *) echo "complete documentation comments";;
  esac)
- $(case $lang in
    rust) echo "Critical modules must pass \`miri\` validation";;
    python) echo "Critical modules must pass \`mypy --strict\` and \`pytest --cov\`";;
    go) echo "Critical modules must pass \`go test -race\` and \`go vet\`";;
    java) echo "Critical modules must pass SpotBugs and JaCoCo coverage checks";;
    *) echo "Critical modules must have adequate test coverage and static analysis";;
  esac)
- Code reviews must verify tests precede implementation

## Language Configuration
- Programming Language: ${lang}
- Test Framework: ${test_framework}
- Documentation Framework: ${doc_framework}
- Static Analysis: ${static_analysis}
- Code Comments Language: English
- Documentation Language: ${docs_lang}
- File/Path Naming: English
EOF
    fi

    print_success "Constitution created at $constitution_file"
}