#!/bin/bash

# MICOS-2024 模块化运行脚本
# 作者: MICOS-2024 团队
# 版本: 1.0.0

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$PROJECT_ROOT/config"
RESULTS_DIR="$PROJECT_ROOT/results"
LOGS_DIR="$PROJECT_ROOT/logs"

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

# 显示使用说明
show_usage() {
    echo "用法: $0 <module_name> [options]"
    echo ""
    echo "可用模块:"
    echo "  quality_control         - 运行质量控制分析"
    echo "  enhanced_qc            - 运行增强质量控制分析"
    echo "  taxonomic_profiling    - 运行物种分类分析"
    echo "  diversity_analysis     - 运行多样性分析"
    echo "  functional_analysis    - 运行功能分析"
    echo "  functional_annotation  - 运行功能注释分析"
    echo "  differential_abundance - 运行差异丰度分析"
    echo "  phylogenetic_analysis  - 运行系统发育分析"
    echo "  amplicon_analysis      - 运行16S rRNA分析"
    echo "  metatranscriptome      - 运行宏转录组分析"
    echo "  network_analysis       - 运行网络分析"
    echo "  visualization          - 生成可视化图表"
    echo "  report_generation      - 生成分析报告"
    echo ""
    echo "选项:"
    echo "  -c, --config FILE    指定配置文件 (默认: config/analysis.yaml)"
    echo "  -o, --output DIR     指定输出目录 (默认: results/)"
    echo "  -t, --threads NUM    指定线程数 (默认: 16)"
    echo "  -h, --help          显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 quality_control"
    echo "  $0 taxonomic_profiling --threads 32"
    echo "  $0 diversity_analysis --config custom_config.yaml"
}

# 检查依赖
check_dependencies() {
    local module=$1

    case $module in
        "quality_control")
            command -v fastqc >/dev/null 2>&1 || { log_error "FastQC未安装"; exit 1; }
            command -v kneaddata >/dev/null 2>&1 || { log_error "KneadData未安装"; exit 1; }
            ;;
        "enhanced_qc")
            command -v python3 >/dev/null 2>&1 || { log_error "Python3未安装"; exit 1; }
            python3 -c "import pandas, matplotlib, seaborn, plotly" 2>/dev/null || { log_error "缺少Python依赖包"; exit 1; }
            ;;
        "taxonomic_profiling")
            command -v kraken2 >/dev/null 2>&1 || { log_error "Kraken2未安装"; exit 1; }
            command -v kraken-biom >/dev/null 2>&1 || { log_error "kraken-biom未安装"; exit 1; }
            ;;
        "diversity_analysis")
            command -v qiime >/dev/null 2>&1 || { log_error "QIIME2未安装"; exit 1; }
            ;;
        "functional_analysis")
            command -v humann >/dev/null 2>&1 || { log_warning "HUMAnN未安装，跳过功能分析"; }
            ;;
        "functional_annotation")
            command -v python3 >/dev/null 2>&1 || { log_error "Python3未安装"; exit 1; }
            ;;
        "differential_abundance")
            command -v Rscript >/dev/null 2>&1 || { log_error "R未安装"; exit 1; }
            ;;
        "phylogenetic_analysis")
            command -v python3 >/dev/null 2>&1 || { log_error "Python3未安装"; exit 1; }
            ;;
        "amplicon_analysis")
            command -v python3 >/dev/null 2>&1 || { log_error "Python3未安装"; exit 1; }
            ;;
        "metatranscriptome")
            command -v python3 >/dev/null 2>&1 || { log_error "Python3未安装"; exit 1; }
            ;;
        "network_analysis")
            command -v python3 >/dev/null 2>&1 || { log_error "Python3未安装"; exit 1; }
            python3 -c "import networkx, scipy" 2>/dev/null || { log_error "缺少网络分析依赖包"; exit 1; }
            ;;
    esac
}

# 运行质量控制
run_quality_control() {
    log_info "开始质量控制分析..."

    local input_dir="$PROJECT_ROOT/data/raw_input"
    local output_dir="$RESULTS_DIR/quality_control"

    mkdir -p "$output_dir"

    # 运行FastQC
    log_info "运行FastQC..."
    fastqc "$input_dir"/*.fastq.gz -o "$output_dir/fastqc_reports/" -t "$THREADS"

    # 运行KneadData
    log_info "运行KneadData..."
    for file in "$input_dir"/*_R1.fastq.gz; do
        base=$(basename "$file" _R1.fastq.gz)
        kneaddata --input "$input_dir/${base}_R1.fastq.gz" \
                  --input "$input_dir/${base}_R2.fastq.gz" \
                  --output "$output_dir/kneaddata/" \
                  --reference-db "$KNEADDATA_DB" \
                  --threads "$THREADS"
    done

    log_success "质量控制分析完成"
}

# 运行增强质量控制
run_enhanced_qc() {
    log_info "开始增强质量控制分析..."

    local input_dir="$PROJECT_ROOT/data/raw_input"
    local output_dir="$RESULTS_DIR/enhanced_qc"

    mkdir -p "$output_dir"

    # 运行增强质量控制脚本
    python3 "$SCRIPT_DIR/enhanced_qc.py" \
        "$input_dir"/*.fastq.gz \
        --config "$CONFIG_FILE" \
        --output "$output_dir" \
        --threads "$THREADS"

    log_success "增强质量控制分析完成"
}

# 运行物种分类
run_taxonomic_profiling() {
    log_info "开始物种分类分析..."

    local input_dir="$RESULTS_DIR/quality_control/kneaddata"
    local output_dir="$RESULTS_DIR/taxonomic_profiling"

    mkdir -p "$output_dir"

    # 运行Kraken2
    log_info "运行Kraken2分类..."
    for file in "$input_dir"/*_paired_1.fastq; do
        base=$(basename "$file" _paired_1.fastq)
        kraken2 --db "$KRAKEN2_DB" \
                --paired "$input_dir/${base}_paired_1.fastq" \
                        "$input_dir/${base}_paired_2.fastq" \
                --output "$output_dir/${base}.kraken" \
                --report "$output_dir/${base}.report" \
                --threads "$THREADS"
    done

    # 生成BIOM文件
    log_info "生成BIOM文件..."
    kraken-biom "$output_dir"/*.report -o "$output_dir/feature-table.biom"

    # 生成Krona图表
    log_info "生成Krona可视化..."
    for report in "$output_dir"/*.report; do
        base=$(basename "$report" .report)
        ktImportTaxonomy -q 2 -t 3 "$report" -o "$output_dir/${base}.krona.html"
    done

    log_success "物种分类分析完成"
}

# 运行多样性分析
run_diversity_analysis() {
    log_info "开始多样性分析..."

    local input_dir="$RESULTS_DIR/taxonomic_profiling"
    local output_dir="$RESULTS_DIR/diversity_analysis"

    mkdir -p "$output_dir"

    # QIIME2分析
    log_info "运行QIIME2多样性分析..."

    # 导入数据
    qiime tools import \
        --input-path "$input_dir/feature-table.biom" \
        --type 'FeatureTable[Frequency]' \
        --output-path "$output_dir/feature-table.qza"

    # Alpha多样性
    qiime diversity alpha \
        --i-table "$output_dir/feature-table.qza" \
        --p-metric shannon \
        --o-alpha-diversity "$output_dir/shannon.qza"

    # Beta多样性
    qiime diversity beta \
        --i-table "$output_dir/feature-table.qza" \
        --p-metric braycurtis \
        --o-distance-matrix "$output_dir/bray-curtis.qza"

    log_success "多样性分析完成"
}

# 运行功能分析
run_functional_analysis() {
    log_info "开始功能分析..."

    if ! command -v humann >/dev/null 2>&1; then
        log_warning "HUMAnN未安装，跳过功能分析"
        return
    fi

    local input_dir="$RESULTS_DIR/quality_control/kneaddata"
    local output_dir="$RESULTS_DIR/functional_analysis"

    mkdir -p "$output_dir"

    # 运行HUMAnN
    for file in "$input_dir"/*_paired_1.fastq; do
        base=$(basename "$file" _paired_1.fastq)
        cat "$input_dir/${base}_paired_1.fastq" "$input_dir/${base}_paired_2.fastq" > "$output_dir/${base}_concat.fastq"

        humann --input "$output_dir/${base}_concat.fastq" \
               --output "$output_dir/" \
               --nucleotide-database "$HUMANN_NUCLEOTIDE_DB" \
               --protein-database "$HUMANN_PROTEIN_DB" \
               --threads "$THREADS"
    done

    log_success "功能分析完成"
}

# 运行功能注释分析
run_functional_annotation() {
    log_info "开始功能注释分析..."

    local input_dir="$RESULTS_DIR/taxonomic_profiling"
    local output_dir="$RESULTS_DIR/functional_annotation"

    mkdir -p "$output_dir"

    # 运行功能注释脚本
    python3 "$SCRIPT_DIR/functional_annotation.py" \
        --config "$CONFIG_FILE" \
        --input "$input_dir/feature-table.biom" \
        --output "$output_dir" \
        --threads "$THREADS"

    log_success "功能注释分析完成"
}

# 运行差异丰度分析
run_differential_abundance() {
    log_info "开始差异丰度分析..."

    local input_dir="$RESULTS_DIR/taxonomic_profiling"
    local output_dir="$RESULTS_DIR/differential_abundance"

    mkdir -p "$output_dir"

    # 运行差异丰度分析脚本
    Rscript "$SCRIPT_DIR/differential_abundance_analysis.R" \
        --input "$input_dir/feature-table.biom" \
        --metadata "$PROJECT_ROOT/config/samples.tsv" \
        --output "$output_dir" \
        --config "$CONFIG_FILE"

    log_success "差异丰度分析完成"
}

# 运行系统发育分析
run_phylogenetic_analysis() {
    log_info "开始系统发育分析..."

    local input_dir="$RESULTS_DIR/taxonomic_profiling"
    local output_dir="$RESULTS_DIR/phylogenetic_analysis"

    mkdir -p "$output_dir"

    # 运行系统发育分析脚本
    python3 "$SCRIPT_DIR/phylogenetic_analysis.py" \
        --config "$CONFIG_FILE" \
        --input "$input_dir" \
        --output "$output_dir" \
        --threads "$THREADS"

    log_success "系统发育分析完成"
}

# 运行16S rRNA分析
run_amplicon_analysis() {
    log_info "开始16S rRNA分析..."

    local input_dir="$PROJECT_ROOT/data/raw_input"
    local output_dir="$RESULTS_DIR/amplicon_analysis"

    mkdir -p "$output_dir"

    # 运行16S分析脚本
    python3 "$SCRIPT_DIR/amplicon_analysis.py" \
        --config "$CONFIG_FILE" \
        --input "$input_dir" \
        --output "$output_dir" \
        --threads "$THREADS"

    log_success "16S rRNA分析完成"
}

# 运行宏转录组分析
run_metatranscriptome() {
    log_info "开始宏转录组分析..."

    local input_dir="$PROJECT_ROOT/data/raw_input"
    local output_dir="$RESULTS_DIR/metatranscriptome"

    mkdir -p "$output_dir"

    # 运行宏转录组分析脚本
    python3 "$SCRIPT_DIR/metatranscriptome_analysis.py" \
        --config "$CONFIG_FILE" \
        --input "$input_dir"/*.fastq.gz \
        --output "$output_dir" \
        --mode complete

    log_success "宏转录组分析完成"
}

# 运行网络分析
run_network_analysis() {
    log_info "开始网络分析..."

    local input_dir="$RESULTS_DIR/taxonomic_profiling"
    local output_dir="$RESULTS_DIR/network_analysis"

    mkdir -p "$output_dir"

    # 运行网络分析脚本
    python3 "$SCRIPT_DIR/network_analysis.py" \
        --config "$CONFIG_FILE" \
        --input "$input_dir/feature-table.biom" \
        --output "$output_dir" \
        --mode complete

    log_success "网络分析完成"
}

# 生成可视化
run_visualization() {
    log_info "生成可视化图表..."

    local output_dir="$RESULTS_DIR/visualization"
    mkdir -p "$output_dir"

    # 运行R脚本生成图表
    if command -v Rscript >/dev/null 2>&1; then
        Rscript "$SCRIPT_DIR/generate_plots.R" "$RESULTS_DIR" "$output_dir"
    else
        log_warning "R未安装，跳过R图表生成"
    fi

    log_success "可视化生成完成"
}

# 生成报告
run_report_generation() {
    log_info "生成分析报告..."

    local output_dir="$RESULTS_DIR/reports"
    mkdir -p "$output_dir"

    # 运行报告生成脚本
    python "$SCRIPT_DIR/generate_report.py" \
        --input "$RESULTS_DIR" \
        --output "$output_dir/analysis_report.html" \
        --config "$CONFIG_FILE"

    log_success "分析报告生成完成"
}

# 主函数
main() {
    # 默认参数
    MODULE=""
    CONFIG_FILE="$CONFIG_DIR/analysis.yaml"
    THREADS=16

    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -o|--output)
                RESULTS_DIR="$2"
                shift 2
                ;;
            -t|--threads)
                THREADS="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                if [[ -z "$MODULE" ]]; then
                    MODULE="$1"
                else
                    log_error "未知参数: $1"
                    show_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # 检查模块参数
    if [[ -z "$MODULE" ]]; then
        log_error "请指定要运行的模块"
        show_usage
        exit 1
    fi

    # 创建必要目录
    mkdir -p "$RESULTS_DIR" "$LOGS_DIR"

    # 加载配置
    if [[ -f "$CONFIG_FILE" ]]; then
        log_info "加载配置文件: $CONFIG_FILE"
        # 这里可以添加配置文件解析逻辑
    else
        log_warning "配置文件不存在: $CONFIG_FILE"
    fi

    # 检查依赖
    check_dependencies "$MODULE"

    # 运行指定模块
    case $MODULE in
        "quality_control")
            run_quality_control
            ;;
        "enhanced_qc")
            run_enhanced_qc
            ;;
        "taxonomic_profiling")
            run_taxonomic_profiling
            ;;
        "diversity_analysis")
            run_diversity_analysis
            ;;
        "functional_analysis")
            run_functional_analysis
            ;;
        "functional_annotation")
            run_functional_annotation
            ;;
        "differential_abundance")
            run_differential_abundance
            ;;
        "phylogenetic_analysis")
            run_phylogenetic_analysis
            ;;
        "amplicon_analysis")
            run_amplicon_analysis
            ;;
        "metatranscriptome")
            run_metatranscriptome
            ;;
        "network_analysis")
            run_network_analysis
            ;;
        "visualization")
            run_visualization
            ;;
        "report_generation")
            run_report_generation
            ;;
        *)
            log_error "未知模块: $MODULE"
            show_usage
            exit 1
            ;;
    esac

    log_success "模块 $MODULE 运行完成"
}

# 运行主函数
main "$@"
