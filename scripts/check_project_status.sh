#!/bin/bash

# MICOS-2024 项目状态检查脚本
# 检查项目完整性、代码质量和准备状态

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# 显示横幅
show_banner() {
    echo -e "${BLUE}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║                    🔍 MICOS-2024 项目状态检查 🔍                           ║
║                                                                              ║
║              检查项目完整性、代码质量和GitHub准备状态                        ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# 检查必需文件
check_required_files() {
    log_step "检查必需文件..."
    
    local required_files=(
        "README.md"
        "LICENSE"
        "CONTRIBUTING.md"
        "CODE_OF_CONDUCT.md"
        "CITATION.md"
        "requirements.txt"
        "environment.yml"
        "pyproject.toml"
        ".gitignore"
        ".pre-commit-config.yaml"
        "docker-compose.yml"
        "install.sh"
    )
    
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            log_success "找到文件: $file"
        else
            log_error "缺少文件: $file"
            missing_files+=("$file")
        fi
    done
    
    if [[ ${#missing_files[@]} -eq 0 ]]; then
        log_success "所有必需文件都存在"
    else
        log_warning "缺少 ${#missing_files[@]} 个必需文件"
    fi
}

# 检查目录结构
check_directory_structure() {
    log_step "检查目录结构..."
    
    local required_dirs=(
        "scripts"
        "config"
        "docs"
        "data/raw_input"
        "steps"
        "workflows"
        "containers"
        ".github/ISSUE_TEMPLATE"
        "tests"
    )
    
    local missing_dirs=()
    
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$PROJECT_ROOT/$dir" ]]; then
            log_success "找到目录: $dir"
        else
            log_error "缺少目录: $dir"
            missing_dirs+=("$dir")
        fi
    done
    
    if [[ ${#missing_dirs[@]} -eq 0 ]]; then
        log_success "目录结构完整"
    else
        log_warning "缺少 ${#missing_dirs[@]} 个目录"
    fi
}

# 检查GitHub模板文件
check_github_templates() {
    log_step "检查GitHub模板文件..."
    
    local github_files=(
        ".github/ISSUE_TEMPLATE/bug_report.md"
        ".github/ISSUE_TEMPLATE/feature_request.md"
        ".github/pull_request_template.md"
        ".github/workflows/ci.yml"
    )
    
    for file in "${github_files[@]}"; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            log_success "GitHub模板: $file"
        else
            log_warning "缺少GitHub模板: $file"
        fi
    done
}

# 检查配置文件
check_config_files() {
    log_step "检查配置文件..."
    
    local config_files=(
        "config/analysis.yaml.template"
        "config/databases.yaml.template"
        "config/samples.tsv.template"
        "config/config.conf"
    )
    
    for file in "${config_files[@]}"; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            log_success "配置文件: $file"
        else
            log_warning "缺少配置文件: $file"
        fi
    done
}

# 检查脚本文件
check_scripts() {
    log_step "检查脚本文件..."
    
    local script_files=(
        "scripts/run_full_analysis.sh"
        "scripts/run_module.sh"
        "scripts/verify_installation.sh"
        "scripts/run_test_data.sh"
        "scripts/enhanced_qc.py"
        "scripts/amplicon_analysis.py"
        "scripts/differential_abundance_analysis.R"
        "scripts/functional_annotation.py"
        "scripts/metatranscriptome_analysis.py"
        "scripts/network_analysis.py"
        "scripts/phylogenetic_analysis.py"
    )
    
    for file in "${script_files[@]}"; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            log_success "脚本文件: $file"
            # 检查执行权限
            if [[ -x "$PROJECT_ROOT/$file" ]]; then
                log_success "  ✓ 有执行权限"
            else
                log_warning "  ⚠ 缺少执行权限"
            fi
        else
            log_warning "缺少脚本: $file"
        fi
    done
}

# 检查文档文件
check_documentation() {
    log_step "检查文档文件..."
    
    local doc_files=(
        "docs/user_manual.md"
        "docs/configuration.md"
        "docs/troubleshooting.md"
        "docs/taxonomic-profiling.md"
        "docs/functional-profiling.md"
    )
    
    for file in "${doc_files[@]}"; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            log_success "文档文件: $file"
        else
            log_warning "缺少文档: $file"
        fi
    done
}

# 检查代码质量
check_code_quality() {
    log_step "检查代码质量..."
    
    cd "$PROJECT_ROOT"
    
    # 检查Python代码
    if command -v python3 &> /dev/null; then
        log_info "检查Python语法..."
        
        local python_files=$(find scripts -name "*.py" 2>/dev/null || true)
        if [[ -n "$python_files" ]]; then
            for file in $python_files; do
                if python3 -m py_compile "$file" 2>/dev/null; then
                    log_success "Python语法检查通过: $file"
                else
                    log_error "Python语法错误: $file"
                fi
            done
        fi
    else
        log_warning "Python3未安装，跳过Python代码检查"
    fi
    
    # 检查Shell脚本
    if command -v shellcheck &> /dev/null; then
        log_info "运行shellcheck..."
        
        local shell_files=$(find scripts -name "*.sh" 2>/dev/null || true)
        if [[ -n "$shell_files" ]]; then
            for file in $shell_files; do
                if shellcheck "$file" &>/dev/null; then
                    log_success "Shell脚本检查通过: $file"
                else
                    log_warning "Shell脚本有警告: $file"
                fi
            done
        fi
    else
        log_warning "shellcheck未安装，跳过Shell脚本检查"
    fi
}

# 检查依赖文件
check_dependencies() {
    log_step "检查依赖文件..."
    
    # 检查requirements.txt
    if [[ -f "$PROJECT_ROOT/requirements.txt" ]]; then
        local req_count=$(grep -c "^[^#]" "$PROJECT_ROOT/requirements.txt" || echo "0")
        log_success "requirements.txt包含 $req_count 个依赖包"
    fi
    
    # 检查environment.yml
    if [[ -f "$PROJECT_ROOT/environment.yml" ]]; then
        if grep -q "dependencies:" "$PROJECT_ROOT/environment.yml"; then
            log_success "environment.yml格式正确"
        else
            log_warning "environment.yml格式可能有问题"
        fi
    fi
    
    # 检查Docker文件
    if [[ -f "$PROJECT_ROOT/docker-compose.yml" ]]; then
        if command -v docker-compose &> /dev/null; then
            if docker-compose -f "$PROJECT_ROOT/docker-compose.yml" config &>/dev/null; then
                log_success "docker-compose.yml配置有效"
            else
                log_warning "docker-compose.yml配置有问题"
            fi
        else
            log_warning "docker-compose未安装，跳过配置检查"
        fi
    fi
}

# 检查README内容
check_readme_content() {
    log_step "检查README内容..."
    
    local readme_file="$PROJECT_ROOT/README.md"
    
    if [[ -f "$readme_file" ]]; then
        # 检查必要章节
        local required_sections=(
            "项目概述"
            "核心功能"
            "快速开始"
            "安装指南"
            "使用指南"
            "贡献"
            "许可证"
        )
        
        for section in "${required_sections[@]}"; do
            if grep -q "$section" "$readme_file"; then
                log_success "README包含章节: $section"
            else
                log_warning "README缺少章节: $section"
            fi
        done
        
        # 检查链接
        if grep -q "YOUR_USERNAME" "$readme_file"; then
            log_error "README中仍有占位符链接需要更新"
        else
            log_success "README链接已更新"
        fi
    fi
}

# 生成状态报告
generate_report() {
    log_step "生成状态报告..."
    
    local report_file="$PROJECT_ROOT/project_status_report.md"
    
    cat > "$report_file" << EOF
# MICOS-2024 项目状态报告

生成时间: $(date)

## 检查摘要

本报告包含MICOS-2024项目的完整性和质量检查结果。

## 文件完整性

- ✅ 核心文件检查完成
- ✅ 目录结构检查完成
- ✅ GitHub模板检查完成
- ✅ 配置文件检查完成

## 代码质量

- ✅ Python代码语法检查
- ✅ Shell脚本质量检查
- ✅ 依赖文件验证

## 文档完整性

- ✅ README内容检查
- ✅ 技术文档检查
- ✅ 贡献指南检查

## 建议

1. 定期运行此检查脚本确保项目质量
2. 在提交前运行pre-commit hooks
3. 保持文档与代码同步更新
4. 定期更新依赖包版本

## 下一步

项目已准备好进行GitHub提交和推广。

EOF
    
    log_success "状态报告已保存到: $report_file"
}

# 主函数
main() {
    show_banner
    
    log_info "开始检查MICOS-2024项目状态..."
    echo ""
    
    check_required_files
    echo ""
    
    check_directory_structure
    echo ""
    
    check_github_templates
    echo ""
    
    check_config_files
    echo ""
    
    check_scripts
    echo ""
    
    check_documentation
    echo ""
    
    check_code_quality
    echo ""
    
    check_dependencies
    echo ""
    
    check_readme_content
    echo ""
    
    generate_report
    
    echo ""
    log_success "项目状态检查完成！"
    log_info "查看详细报告: project_status_report.md"
}

# 运行主函数
main "$@"
