#!/bin/bash

# MICOS-2024 自动安装脚本
# 作者: MICOS-2024 团队
# 版本: 1.0.0

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 配置变量
MICOS_VERSION="1.0.0"
INSTALL_DIR="$HOME/micos-2024"
CONDA_ENV_NAME="micos-2024"

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

# 显示欢迎信息
show_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║                          🧬 MICOS-2024 安装程序 🧬                          ║
║                                                                              ║
║              智能化宏基因组分析平台 - 自动安装脚本                           ║
║                                                                              ║
║  🏆 华大基因"猛犸杯"参赛项目                                                ║
║  🚀 下一代宏基因组分析解决方案                                               ║
║                                                                              ║
║  特性:                                                                       ║
║  • 🔬 科研级精度的生物信息学工具链                                           ║
║  • ⚡ 高性能并行计算和容器化部署                                             ║
║  • 🎨 丰富的交互式可视化和报告                                               ║
║  • 🔄 基于WDL的完全可重现工作流                                              ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo ""
}

# 检测操作系统
detect_os() {
    log_step "检测操作系统..."

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            DISTRO=$ID
            VERSION=$VERSION_ID
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        DISTRO="macos"
        VERSION=$(sw_vers -productVersion)
    else
        log_error "不支持的操作系统: $OSTYPE"
        exit 1
    fi

    log_info "检测到操作系统: $OS ($DISTRO $VERSION)"
}

# 检查系统要求
check_requirements() {
    log_step "检查系统要求..."

    # 检查内存
    if [[ "$OS" == "linux" ]]; then
        MEMORY_GB=$(free -g | awk '/^Mem:/{print $2}')
    elif [[ "$OS" == "macos" ]]; then
        MEMORY_BYTES=$(sysctl -n hw.memsize)
        MEMORY_GB=$((MEMORY_BYTES / 1024 / 1024 / 1024))
    fi

    if [ "$MEMORY_GB" -lt 16 ]; then
        log_warning "内存不足16GB，可能影响性能 (当前: ${MEMORY_GB}GB)"
    else
        log_success "内存检查通过 (${MEMORY_GB}GB)"
    fi

    # 检查磁盘空间
    DISK_SPACE=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$DISK_SPACE" -lt 100 ]; then
        log_warning "磁盘空间不足100GB，可能影响数据库下载 (当前: ${DISK_SPACE}GB)"
    else
        log_success "磁盘空间检查通过 (${DISK_SPACE}GB可用)"
    fi
}

# 安装依赖
install_dependencies() {
    log_step "安装系统依赖..."

    if [[ "$OS" == "linux" ]]; then
        if [[ "$DISTRO" == "ubuntu" ]] || [[ "$DISTRO" == "debian" ]]; then
            sudo apt-get update
            sudo apt-get install -y curl wget git build-essential
        elif [[ "$DISTRO" == "centos" ]] || [[ "$DISTRO" == "rhel" ]]; then
            sudo yum update -y
            sudo yum install -y curl wget git gcc gcc-c++ make
        fi
    elif [[ "$OS" == "macos" ]]; then
        # 检查是否安装了Homebrew
        if ! command -v brew &> /dev/null; then
            log_info "安装Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install curl wget git
    fi

    log_success "系统依赖安装完成"
}

# 安装Docker
install_docker() {
    log_step "检查Docker安装..."

    if command -v docker &> /dev/null; then
        log_success "Docker已安装"
        return
    fi

    log_info "安装Docker..."

    if [[ "$OS" == "linux" ]]; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh

        # 安装Docker Compose
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose

    elif [[ "$OS" == "macos" ]]; then
        log_info "请手动安装Docker Desktop for Mac"
        log_info "下载地址: https://www.docker.com/products/docker-desktop"
        read -p "安装完成后按回车继续..."
    fi

    log_success "Docker安装完成"
}

# 安装Conda/Mamba
install_conda() {
    log_step "检查Conda/Mamba安装..."

    if command -v mamba &> /dev/null; then
        log_success "Mamba已安装"
        return
    elif command -v conda &> /dev/null; then
        log_success "Conda已安装"
        return
    fi

    log_info "安装Miniforge (包含Mamba)..."

    if [[ "$OS" == "linux" ]]; then
        MINIFORGE_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh"
    elif [[ "$OS" == "macos" ]]; then
        MINIFORGE_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-x86_64.sh"
    fi

    wget $MINIFORGE_URL -O miniforge.sh
    bash miniforge.sh -b -p $HOME/miniforge3
    rm miniforge.sh

    # 添加到PATH
    echo 'export PATH="$HOME/miniforge3/bin:$PATH"' >> ~/.bashrc
    export PATH="$HOME/miniforge3/bin:$PATH"

    # 初始化
    $HOME/miniforge3/bin/conda init bash

    log_success "Miniforge安装完成"
}

# 下载MICOS-2024
download_micos() {
    log_step "下载MICOS-2024..."

    if [ -d "$INSTALL_DIR" ]; then
        log_warning "目录已存在，正在更新..."
        cd "$INSTALL_DIR"
        git pull
    else
        log_info "克隆MICOS-2024仓库..."
        git clone https://github.com/BGI-MICOS/MICOS-2024.git "$INSTALL_DIR"
        cd "$INSTALL_DIR"
    fi

    log_success "MICOS-2024下载完成"
}

# 创建Conda环境
create_conda_env() {
    log_step "创建Conda环境..."

    # 确保conda可用
    source $HOME/miniforge3/etc/profile.d/conda.sh

    # 检查环境是否已存在
    if conda env list | grep -q "$CONDA_ENV_NAME"; then
        log_warning "环境已存在，正在更新..."
        conda env update -n "$CONDA_ENV_NAME" -f environment.yml
    else
        log_info "创建新环境..."
        mamba env create -f environment.yml
    fi

    log_success "Conda环境创建完成"
}

# 验证安装
verify_installation() {
    log_step "验证安装..."

    # 激活环境
    source $HOME/miniforge3/etc/profile.d/conda.sh
    conda activate "$CONDA_ENV_NAME"

    # 检查关键工具
    TOOLS=("kraken2" "kneaddata" "qiime" "fastqc")

    for tool in "${TOOLS[@]}"; do
        if command -v "$tool" &> /dev/null; then
            log_success "$tool 安装成功"
        else
            log_error "$tool 安装失败"
        fi
    done

    # 运行测试
    if [ -f "scripts/verify_installation.sh" ]; then
        log_info "运行安装验证脚本..."
        bash scripts/verify_installation.sh
    fi
}

# 显示完成信息
show_completion() {
    echo ""
    echo -e "${GREEN}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║                        🎉 安装完成！ 🎉                                     ║
║                                                                              ║
║  MICOS-2024 已成功安装到您的系统中！                                        ║
║                                                                              ║
║  下一步:                                                                     ║
║  1. 激活环境: conda activate micos-2024                                     ║
║  2. 下载数据库: ./scripts/download_databases.sh                             ║
║  3. 运行测试: ./scripts/run_test_data.sh                                    ║
║  4. 查看文档: docs/                                                          ║
║                                                                              ║
║  获取帮助:                                                                   ║
║  • GitHub: https://github.com/BGI-MICOS/MICOS-2024                          ║
║  • 文档: https://bgi-micos.github.io/MICOS-2024                             ║
║  • 问题反馈: https://github.com/BGI-MICOS/MICOS-2024/issues                 ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# 主函数
main() {
    show_banner

    log_info "开始安装MICOS-2024 v$MICOS_VERSION"
    echo ""

    detect_os
    check_requirements
    install_dependencies
    install_docker
    install_conda
    download_micos
    create_conda_env
    verify_installation

    show_completion
}

# 运行主函数
main "$@"
