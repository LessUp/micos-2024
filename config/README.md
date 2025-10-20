# 配置使用说明

- 复制模板并根据环境修改：
```bash
cp config/analysis.yaml.template config/analysis.yaml
cp config/databases.yaml.template config/databases.yaml
cp config/samples.tsv.template config/samples.tsv
```
- 在 `analysis.yaml` 中设置输入/输出路径与线程数。
- 在 `databases.yaml` 中设置 Kraken2/KneadData 等数据库路径。
- 在 `samples.tsv` 中填写样本元数据。
