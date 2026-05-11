# 故障排除 (Troubleshooting)

本页面列出了 MICOS-2024 常见问题及其解决方案。

---

## 安装问题

### Q: 安装依赖时出现版本冲突

**A:** 建议使用 conda 创建独立环境：

```bash
conda create -n micos python=3.10
conda activate micos
pip install -e .
```

### Q: Kraken2 数据库下载失败

**A:** Kraken2 标准数据库较大（~8GB），可以尝试：

1. 使用 MiniKraken 数据库（较小）：
```bash
wget https://genome-idx.s3.amazonaws.com/kraken/minikraken2_v2_8GB.tar.gz
```

2. 或使用国内镜像源下载

---

## 运行问题

### Q: 运行时提示 "command not found"

**A:** 确保所有依赖工具已安装并添加到 PATH：
- FastQC
- KneadData
- Kraken2
- HUMAnN
- QIIME2

可以使用 `micos --help` 检查环境是否正确配置。

### Q: 内存不足错误

**A:** 可以通过以下方式减少内存使用：
- 减少并行线程数：`--threads 4`
- 使用较小的数据库（MiniKraken）
- 分批处理样本

### Q: KneadData 运行时间过长

**A:** KneadData 需要比对宿主基因组，建议：
- 使用 SSD 存储数据库
- 增加线程数
- 确保数据库路径正确

---

## 数据问题

### Q: 输入文件格式要求

**A:** MICOS-2024 支持：
- FASTQ 格式（.fastq, .fq, .fastq.gz, .fq.gz）
- 配对端测序数据命名格式：`{sample}_1.fastq` 和 `{sample}_2.fastq`

### Q: 样本命名规范

**A:** 样本名应遵循以下规则：
- 只使用字母、数字和下划线
- 避免特殊字符和空格
- 以字母开头

---

## 输出问题

### Q: 结果文件在哪里？

**A:** 默认输出结构：
```
results/
├── quality_control/
├── taxonomic_profiling/
├── functional_annotation/
├── diversity_analysis/
└── micos_summary_report.html
```

### Q: 报告生成失败

**A:** 确保前面的步骤都成功完成，检查：
- 各模块输出目录是否存在
- 日志文件中是否有错误信息

---

## 其他问题

如果以上内容未能解决您的问题，请：

1. 查看 [GitHub Issues](https://github.com/BGI-MICOS/MICOS-2024/issues)
2. 提交新的 Issue，包含：
   - 错误信息
   - 运行命令
   - 系统环境信息
