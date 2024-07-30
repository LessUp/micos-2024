import pandas as pd

# 读取Kraken2的report文件
report_file = "/media/shuai/TOSHBA/mm-dev/ResultData/m11213.kraken.tsv"
taxonomy_file = "m11213.taxonomy.tsv"

# 初始化DataFrame
data = pd.read_csv(report_file, sep='\t', header=None, comment='#')

# 根据实际列数设置列名
data.columns = ['rank_code', 'sequence_id', 'name', 'score', 'taxonomy']

# 过滤掉未分类的条目
data = data[data['rank_code'] != 'U']

# 生成完整的taxonomy字符串
data['taxonomy'] = data.apply(lambda row: row['name'].replace(' ', '; '), axis=1)

# 提取特征ID和分类路径
taxonomy_df = data[['sequence_id', 'taxonomy']]

# 保存为无表头的TSV文件
taxonomy_df.to_csv(taxonomy_file, sep='\t', index=False, header=False)