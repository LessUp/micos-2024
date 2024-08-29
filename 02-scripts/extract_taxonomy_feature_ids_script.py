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

# 提取特征ID
feature_ids = taxonomy_df['Feature ID']

# 保存到文本文件
feature_ids.to_csv("taxonomy_feature_ids.txt", index=False, header=False)