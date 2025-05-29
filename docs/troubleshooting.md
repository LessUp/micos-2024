# 🔧 MICOS-2024 故障排除指南

## 📋 目录

1. [安装问题](#安装问题)
2. [配置问题](#配置问题)
3. [运行时错误](#运行时错误)
4. [性能问题](#性能问题)
5. [数据问题](#数据问题)
6. [输出问题](#输出问题)
7. [常见错误代码](#常见错误代码)
8. [获取帮助](#获取帮助)

## 🚀 安装问题

### 问题1: Conda环境创建失败

**症状**: 
```bash
CondaEnvException: Pip failed
```

**解决方案**:
```bash
# 1. 清理conda缓存
conda clean --all

# 2. 更新conda
conda update conda

# 3. 使用mamba替代conda
conda install mamba -c conda-forge
mamba env create -f environment.yml

# 4. 如果仍然失败，分步安装
conda create -n micos-2024 python=3.9
conda activate micos-2024
mamba install -c bioconda -c conda-forge --file requirements.txt
```

### 问题2: Docker权限错误

**症状**:
```bash
permission denied while trying to connect to the Docker daemon socket
```

**解决方案**:
```bash
# 1. 将用户添加到docker组
sudo usermod -aG docker $USER

# 2. 重新登录或重启
newgrp docker

# 3. 验证权限
docker run hello-world
```

### 问题3: 内存不足

**症状**:
```bash
MemoryError: Unable to allocate array
```

**解决方案**:
```bash
# 1. 检查可用内存
free -h

# 2. 增加swap空间
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 3. 调整分析参数
# 在config/analysis.yaml中减少并行度
resources:
  max_threads: 8
  max_memory: "16GB"
```

### 问题4: 网络连接问题

**症状**:
```bash
URLError: <urlopen error [Errno -2] Name or service not known>
```

**解决方案**:
```bash
# 1. 检查网络连接
ping google.com

# 2. 配置代理（如果需要）
export http_proxy=http://proxy.example.com:8080
export https_proxy=http://proxy.example.com:8080

# 3. 使用镜像源
# 在environment.yml中添加国内镜像
channels:
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/bioconda
```

## ⚙️ 配置问题

### 问题5: 数据库路径错误

**症状**:
```bash
FileNotFoundError: [Errno 2] No such file or directory: '/path/to/kraken2_db'
```

**解决方案**:
```bash
# 1. 检查数据库是否存在
ls -la /path/to/kraken2_db

# 2. 下载缺失的数据库
./scripts/download_databases.sh

# 3. 更新配置文件
nano config/databases.yaml
# 确保路径正确

# 4. 验证数据库完整性
./scripts/verify_databases.sh
```

### 问题6: 样本元数据格式错误

**症状**:
```bash
ValueError: Sample metadata file format error
```

**解决方案**:
```bash
# 1. 检查文件格式
head config/samples.tsv

# 2. 确保使用制表符分隔
sed 's/,/\t/g' samples.csv > samples.tsv

# 3. 验证必需列
# 确保包含: sample-id, group等必需列

# 4. 检查特殊字符
# 避免使用空格、特殊符号
```

## 🏃 运行时错误

### 问题7: Kraken2分类失败

**症状**:
```bash
kraken2: database ("/path/to/db") does not contain necessary file hash.k2d
```

**解决方案**:
```bash
# 1. 重新下载数据库
kraken2-build --download-taxonomy --db kraken2_db
kraken2-build --download-library bacteria --db kraken2_db
kraken2-build --build --db kraken2_db

# 2. 检查数据库完整性
ls kraken2_db/
# 应包含: hash.k2d, opts.k2d, taxo.k2d

# 3. 验证数据库
kraken2 --db kraken2_db --report test.report test.fastq
```

### 问题8: QIIME2导入失败

**症状**:
```bash
ValueError: BIOM file appears to be empty
```

**解决方案**:
```bash
# 1. 检查BIOM文件
biom summarize-table -i feature-table.biom

# 2. 重新生成BIOM文件
kraken-biom *.report --fmt hdf5 -o new-table.biom

# 3. 验证BIOM格式
biom validate-table -i new-table.biom

# 4. 转换格式（如果需要）
biom convert -i table.biom -o table.txt --to-tsv
```

### 问题9: 工作流中断

**症状**:
```bash
WorkflowFailedException: Workflow failed
```

**解决方案**:
```bash
# 1. 检查日志文件
tail -n 100 logs/cromwell.log

# 2. 重启失败的任务
cromwell run workflow.wdl --inputs inputs.json --options options.json

# 3. 使用断点续传
# 在options.json中添加:
{
  "write_to_cache": true,
  "read_from_cache": true
}

# 4. 手动运行失败步骤
./scripts/run_module.sh failed_module
```

## 🚀 性能问题

### 问题10: 分析速度慢

**症状**: 分析时间过长

**解决方案**:
```bash
# 1. 增加线程数
# 在config/analysis.yaml中:
resources:
  max_threads: 32  # 根据CPU核心数调整

# 2. 使用SSD存储
# 将临时文件放在SSD上
temp_dir: "/ssd/tmp"

# 3. 优化内存使用
# 增加可用内存
resources:
  max_memory: "64GB"

# 4. 使用预过滤
# 对大数据集进行预过滤
quality_control:
  kneaddata:
    min_quality: 25  # 提高质量阈值
```

### 问题11: 磁盘空间不足

**症状**:
```bash
OSError: [Errno 28] No space left on device
```

**解决方案**:
```bash
# 1. 清理临时文件
rm -rf tmp/*
rm -rf logs/*.tmp

# 2. 压缩中间结果
gzip results/intermediate/*.fastq

# 3. 使用外部存储
# 将结果目录链接到外部存储
ln -s /external/storage/results results

# 4. 启用自动清理
# 在config/analysis.yaml中:
cleanup:
  remove_intermediate: true
  compress_results: true
```

## 📊 数据问题

### 问题12: 测序质量差

**症状**: FastQC报告显示质量较差

**解决方案**:
```bash
# 1. 调整质量过滤参数
quality_control:
  kneaddata:
    min_quality: 25
    min_length: 75

# 2. 使用更严格的过滤
trimmomatic:
  leading: 20
  trailing: 20
  slidingwindow: "4:20"
  minlen: 50

# 3. 检查原始数据
fastqc raw_data/*.fastq.gz
multiqc fastqc_results/
```

### 问题13: 分类结果异常

**症状**: 大量序列未分类

**解决方案**:
```bash
# 1. 检查数据库版本
kraken2 --db kraken2_db --report-zero-counts test.fastq

# 2. 降低置信度阈值
kraken2:
  confidence: 0.05  # 从0.1降低到0.05

# 3. 使用更大的数据库
# 下载完整的标准数据库而不是mini版本

# 4. 检查序列长度
# 确保序列长度足够进行分类
```

## 📈 输出问题

### 问题14: 图表生成失败

**症状**:
```bash
ModuleNotFoundError: No module named 'matplotlib'
```

**解决方案**:
```bash
# 1. 安装缺失的包
conda install matplotlib seaborn plotly

# 2. 更新R包
R -e "install.packages(c('ggplot2', 'plotly'))"

# 3. 检查图形后端
export MPLBACKEND=Agg

# 4. 重新生成图表
./scripts/generate_plots.sh
```

### 问题15: 报告生成失败

**症状**: HTML报告为空或损坏

**解决方案**:
```bash
# 1. 检查模板文件
ls templates/

# 2. 重新生成报告
./scripts/generate_report.sh --force

# 3. 检查依赖
pip install jinja2 weasyprint

# 4. 手动生成
python scripts/generate_html_report.py
```

## ⚠️ 常见错误代码

| 错误代码 | 含义 | 解决方案 |
|:---:|:---|:---|
| **Exit 1** | 一般错误 | 检查日志文件 |
| **Exit 2** | 文件不存在 | 检查文件路径 |
| **Exit 126** | 权限错误 | 修改文件权限 |
| **Exit 127** | 命令未找到 | 检查PATH环境变量 |
| **Exit 130** | 用户中断 | 正常，用户按Ctrl+C |
| **Exit 137** | 内存不足 | 增加内存或减少并行度 |

## 🆘 获取帮助

### 自助诊断

```bash
# 1. 运行诊断脚本
./scripts/diagnose_issues.sh

# 2. 检查系统状态
./scripts/system_check.sh

# 3. 验证安装
./scripts/verify_installation.sh

# 4. 生成诊断报告
./scripts/generate_diagnostic_report.sh
```

### 日志分析

```bash
# 1. 查看最新错误
tail -n 50 logs/error.log

# 2. 搜索特定错误
grep -i "error" logs/*.log

# 3. 分析工作流日志
less logs/cromwell.log

# 4. 检查容器日志
docker-compose logs --tail=100
```

### 社区支持

1. **GitHub Issues**: [提交问题](https://github.com/YOUR_USERNAME/MICOS-2024/issues)
2. **讨论区**: [参与讨论](https://github.com/YOUR_USERNAME/MICOS-2024/discussions)
3. **邮件支持**: micos2024@example.com

### 问题报告模板

提交问题时请包含以下信息：

```markdown
**环境信息**
- 操作系统: [e.g., Ubuntu 20.04]
- Python版本: [e.g., 3.9.0]
- MICOS版本: [e.g., 1.0.0]
- 安装方式: [Docker/Conda/源码]

**问题描述**
[详细描述遇到的问题]

**重现步骤**
1. [第一步]
2. [第二步]
3. [看到错误]

**错误日志**
```
[粘贴相关的错误信息]
```

**期望行为**
[描述期望的正确行为]

**额外信息**
[任何其他相关信息]
```

---

💡 **提示**: 大多数问题都可以通过仔细阅读错误信息和检查配置文件来解决。如果问题持续存在，请不要犹豫寻求社区帮助！
