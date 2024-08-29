import pandas as pd
import argparse

# 创建解析器对象
parser = argparse.ArgumentParser(description="Extract feature IDs from a taxonomy file.")

# 添加输入文件参数
parser.add_argument('input_file', type=str, help='Path to the input taxonomy file')

# 解析命令行参数
args = parser.parse_args()

# 使用解析后的文件路径来读取文件
taxonomy_df = pd.read_csv(args.input_file, sep='\t')

# 定义可能的列名
possible_ids = ['feature id', 'feature-id', 'featureid', 'id', 'sample id', 'sample-id', 'sampleid',
                '#OTU ID', '#OTUID', '#Sample ID', '#SampleID', 'sample_name']

# 检查文件中存在哪些可能的列名
column_found = None
for column in possible_ids:
    if column in taxonomy_df.columns:
        column_found = column
        break

if column_found:
    # 提取特征ID
    feature_ids = taxonomy_df[column_found]

    # 保存到文本文件
    feature_ids.to_csv("taxonomy_feature_ids.txt", index=False, header=False)
else:
    print("No valid feature ID column found.")
