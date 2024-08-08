import pandas as pd
import argparse

# 设置命令行参数解析
parser = argparse.ArgumentParser(description='Convert Kraken2 report to taxonomy file.')
parser.add_argument('input_path', type=str, help='Path to the input Kraken2 report file.')
parser.add_argument('output_path', type=str, help='Path to the output taxonomy file.')

args = parser.parse_args()

# 读取Kraken2的report文件
report_file = args.input_path
taxonomy_file = args.output_path

# 初始化DataFrame
data = pd.read_csv(report_file, sep='\t', header=None, comment='#')

# 根据实际列数设置列名
data.columns = ['rank_code', 'sequence_id', 'name', 'score', 'taxonomy']

# 过滤掉未分类的条目
data = data[data['rank_code'] != 'U']

# 生成完整的taxonomy字符串
data['taxonomy'] = data.apply(lambda row: row['name'].replace(' ', ';'), axis=1)

# 提取特征ID和分类路径
taxonomy_df = data[['sequence_id', 'taxonomy']]

# 保存为TSV文件，并添加表头
taxonomy_df.to_csv(taxonomy_file, sep='\t', index=False, header=['Feature ID', 'Taxonomy'])
