#!/bin/bash

# MICOS-2024 完整分析流程脚本
# 作者: MICOS-2024 团队
# 版本: 1.0.0

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
CONFIG_DIR="$PROJECT_ROOT/config"
RESULTS_DIR="$PROJECT_ROOT/results"
LOGS_DIR="$PROJECT_ROOT/logs"

# 默认参数
CONFIG_FILE="$CONFIG_DIR/analysis.yaml"
THREADS=16
SKIP_MODULES=""
RESUME_FROM=""

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
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
║                    🧬 MICOS-2024 完整分析流程 🧬                            ║
║                                                                              ║
║              宏基因组综合分析套件 - 自动化分析流程                           ║
║                                                                              ║
║  流程步骤:                                                                   ║
║  1. 质量控制 (FastQC + KneadData)                                           ║
║  2. 物种分类 (Kraken2 + Krona)                                              ║
║  3. 多样性分析 (QIIME2)                                                     ║
║  4. 功能分析 (HUMAnN) [可选]                                                ║
║  5. 可视化生成                                                               ║
║  6. 报告生成                                                                 ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# 显示使用说明
show_usage() {
    echo "用法: $0 [options]"
    echo ""
    echo "选项:"
    echo "  -c, --config FILE       指定配置文件 (默认: config/analysis.yaml)"
    echo "  -t, --threads NUM       指定线程数 (默认: 16)"
    echo "  -s, --skip MODULES      跳过指定模块 (用逗号分隔)"
    echo "  -r, --resume-from STEP  从指定步骤开始运行"
    echo "  -h, --help             显示此帮助信息"
    echo ""
    echo "可跳过的模块:"
    echo "  quality_control, taxonomic_profiling, diversity_analysis,"
    echo "  functional_analysis, visualization, report_generation"
    echo ""
    echo "可恢复的步骤:"
    echo "  1, 2, 3, 4, 5, 6 (对应上述模块)"
    echo ""
    echo "示例:"
    echo "  $0                                    # 运行完整流程"
    echo "  $0 --threads 32                      # 使用32线程"
    echo "  $0 --skip functional_analysis        # 跳过功能分析"
    echo "  $0 --resume-from 3                   # 从多样性分析开始"
}

# 检查前置条件
check_prerequisites() {
    log_step "检查前置条件..."
    
    # 检查配置文件
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "配置文件不存在: $CONFIG_FILE"
        log_info "请复制模板文件: cp config/analysis.yaml.template config/analysis.yaml"
        exit 1
    fi
    
    # 检查输入数据
    if [[ ! -d "$PROJECT_ROOT/data/raw_input" ]] || [[ -z "$(ls -A "$PROJECT_ROOT/data/raw_input" 2>/dev/null)" ]]; then
        log_error "输入数据目录为空: $PROJECT_ROOT/data/raw_input"
        log_info "请将FASTQ文件放入 data/raw_input/ 目录"
        exit 1
    fi
    
    # 检查样本元数据
    if [[ ! -f "$CONFIG_DIR/samples.tsv" ]]; then
        log_warning "样本元数据文件不存在: $CONFIG_DIR/samples.tsv"
        log_info "请创建样本元数据文件或复制模板: cp config/samples.tsv.template config/samples.tsv"
    fi
    
    # 创建必要目录
    mkdir -p "$RESULTS_DIR" "$LOGS_DIR"
    
    log_success "前置条件检查完成"
}

# 检查模块是否应该跳过
should_skip_module() {
    local module=$1
    [[ ",$SKIP_MODULES," == *",$module,"* ]]
}

# 检查是否应该从此步骤开始
should_resume_from() {
    local step=$1
    [[ -z "$RESUME_FROM" ]] || [[ "$step" -ge "$RESUME_FROM" ]]
}

# 运行分析步骤
run_analysis_step() {
    local step_num=$1
    local module_name=$2
    local description=$3
    
    if ! should_resume_from "$step_num"; then
        log_info "跳过步骤 $step_num: $description (恢复点设置)"
        return 0
    fi
    
    if should_skip_module "$module_name"; then
        log_warning "跳过步骤 $step_num: $description (用户指定)"
        return 0
    fi
    
    log_step "步骤 $step_num: $description"
    
    # 记录开始时间
    local start_time=$(date +%s)
    
    # 运行模块
    if "$SCRIPT_DIR/run_module.sh" "$module_name" --config "$CONFIG_FILE" --threads "$THREADS"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log_success "步骤 $step_num 完成 (耗时: ${duration}秒)"
        
        # 记录检查点
        echo "$step_num" > "$LOGS_DIR/last_completed_step"
    else
        log_error "步骤 $step_num 失败"
        exit 1
    fi
}

# 生成分析摘要
generate_summary() {
    log_step "生成分析摘要..."
    
    local summary_file="$RESULTS_DIR/analysis_summary.txt"
    
    cat > "$summary_file" << EOF
MICOS-2024 分析摘要
==================

分析时间: $(date)
配置文件: $CONFIG_FILE
线程数: $THREADS

输入数据:
$(find "$PROJECT_ROOT/data/raw_input" -name "*.fastq.gz" | wc -l) 个FASTQ文件

输出结果:
- 质量控制报告: results/quality_control/
- 物种分类结果: results/taxonomic_profiling/
- 多样性分析: results/diversity_analysis/
- 可视化图表: results/visualization/
- 分析报告: results/reports/

主要文件:
$(find "$RESULTS_DIR" -name "*.html" -o -name "*.qza" -o -name "*.biom" | head -10)

分析完成时间: $(date)
EOF
    
    log_success "分析摘要已保存到: $summary_file"
}

# 清理临时文件
cleanup_temp_files() {
    log_step "清理临时文件..."
    
    # 清理大型中间文件（如果配置允许）
    if grep -q "remove_intermediate.*true" "$CONFIG_FILE" 2>/dev/null; then
        find "$RESULTS_DIR" -name "*.tmp" -delete 2>/dev/null || true
        find "$RESULTS_DIR" -name "temp_*" -delete 2>/dev/null || true
        log_success "临时文件清理完成"
    else
        log_info "保留中间文件（根据配置设置）"
    fi
}

# 主函数
main() {
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -t|--threads)
                THREADS="$2"
                shift 2
                ;;
            -s|--skip)
                SKIP_MODULES="$2"
                shift 2
                ;;
            -r|--resume-from)
                RESUME_FROM="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # 显示横幅
    show_banner
    
    # 记录开始时间
    local total_start_time=$(date +%s)
    
    # 检查前置条件
    check_prerequisites
    
    # 运行分析流程
    log_info "开始MICOS-2024完整分析流程..."
    log_info "配置文件: $CONFIG_FILE"
    log_info "线程数: $THREADS"
    [[ -n "$SKIP_MODULES" ]] && log_info "跳过模块: $SKIP_MODULES"
    [[ -n "$RESUME_FROM" ]] && log_info "从步骤 $RESUME_FROM 开始"
    echo ""
    
    # 执行分析步骤
    run_analysis_step 1 "quality_control" "质量控制分析"
    run_analysis_step 2 "taxonomic_profiling" "物种分类分析"
    run_analysis_step 3 "diversity_analysis" "多样性分析"
    run_analysis_step 4 "functional_analysis" "功能分析"
    run_analysis_step 5 "visualization" "可视化生成"
    run_analysis_step 6 "report_generation" "报告生成"
    
    # 生成摘要和清理
    generate_summary
    cleanup_temp_files
    
    # 计算总耗时
    local total_end_time=$(date +%s)
    local total_duration=$((total_end_time - total_start_time))
    local hours=$((total_duration / 3600))
    local minutes=$(((total_duration % 3600) / 60))
    local seconds=$((total_duration % 60))
    
    # 显示完成信息
    echo ""
    echo -e "${GREEN}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║                        🎉 分析完成！ 🎉                                     ║
║                                                                              ║
║  MICOS-2024 完整分析流程已成功完成！                                        ║
║                                                                              ║
║  查看结果:                                                                   ║
║  • 主要报告: results/reports/analysis_report.html                           ║
║  • 分析摘要: results/analysis_summary.txt                                   ║
║  • 所有结果: results/ 目录                                                  ║
║                                                                              ║
║  获取帮助:                                                                   ║
║  • 文档: docs/                                                              ║
║  • 问题反馈: GitHub Issues                                                  ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    log_success "总耗时: ${hours}小时 ${minutes}分钟 ${seconds}秒"
    log_info "主要结果文件: results/reports/analysis_report.html"
    log_info "分析摘要: results/analysis_summary.txt"
    
    echo ""
    log_info "感谢使用MICOS-2024！如果觉得有用，请给项目加星⭐"
}

# 错误处理
trap 'log_error "分析过程中发生错误，请检查日志文件"; exit 1' ERR

# 运行主函数
main "$@"
