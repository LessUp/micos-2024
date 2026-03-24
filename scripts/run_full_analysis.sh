#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$PROJECT_ROOT/config/analysis.yaml"
THREADS=""
INPUT_DIR=""
RESULTS_DIR=""
UNSUPPORTED_SKIP=""
UNSUPPORTED_RESUME=""

show_usage() {
    echo "用法: $0 [options]"
    echo ""
    echo "此脚本是 micos full-run 的兼容包装层。"
    echo ""
    echo "选项:"
    echo "  -c, --config FILE       指定配置文件 (默认: config/analysis.yaml)"
    echo "  -i, --input-dir DIR     指定输入目录"
    echo "  -o, --results-dir DIR   指定结果目录"
    echo "  -t, --threads NUM       指定线程数"
    echo "  -s, --skip MODULES      当前不再支持，建议直接使用 micos CLI"
    echo "  -r, --resume-from STEP  当前不再支持，建议直接使用 micos CLI"
    echo "  -h, --help              显示此帮助信息"
}

run_micos() {
    if command -v micos >/dev/null 2>&1; then
        micos "$@"
    else
        PYTHONPATH="$PROJECT_ROOT${PYTHONPATH:+:$PYTHONPATH}" python3 -m micos.cli "$@"
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -i|--input-dir)
            INPUT_DIR="$2"
            shift 2
            ;;
        -o|--results-dir)
            RESULTS_DIR="$2"
            shift 2
            ;;
        -t|--threads)
            THREADS="$2"
            shift 2
            ;;
        -s|--skip)
            UNSUPPORTED_SKIP="$2"
            shift 2
            ;;
        -r|--resume-from)
            UNSUPPORTED_RESUME="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "未知参数: $1" >&2
            show_usage
            exit 1
            ;;
    esac
done

if [[ -n "$UNSUPPORTED_SKIP" || -n "$UNSUPPORTED_RESUME" ]]; then
    echo "run_full_analysis.sh 已收缩为 micos full-run 的薄包装层，--skip/--resume-from 当前不再支持。" >&2
    exit 1
fi

ARGS=(--config "$CONFIG_FILE" full-run)
if [[ -n "$INPUT_DIR" ]]; then
    ARGS+=(--input-dir "$INPUT_DIR")
fi
if [[ -n "$RESULTS_DIR" ]]; then
    ARGS+=(--results-dir "$RESULTS_DIR")
fi
if [[ -n "$THREADS" ]]; then
    ARGS+=(--threads "$THREADS")
fi

run_micos "${ARGS[@]}"
