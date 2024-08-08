import pandas as pd
import sys

def convert_kraken2_to_qiime2(kraken2_tsv, output_file):
    # 读取Kraken2输出的TSV文件
    df = pd.read_csv(kraken2_tsv, sep='\t', header=None)
    
    # 检查列数并相应地定义列名
    if df.shape[1] == 5:
        df.columns = ['status', 'read_id', 'taxonomy', 'sequence_length', 'taxonomy_detail']
    elif df.shape[1] == 6:
        df.columns = ['status', 'read_id', 'taxonomy', 'sequence_length', 'taxonomy_detail', 'additional_info']
    else:
        raise ValueError("Unexpected number of columns in the Kraken2 output file.")
    
    # 提取需要的列进行转换
    qiime2_df = df[['read_id', 'taxonomy']].copy()
    qiime2_df.columns = ['Feature ID', 'Taxon']
    
    # 保存为Qiime2兼容的TSV文件
    qiime2_df.to_csv(output_file, sep='\t', index=False)
    
    print(f"转换完成，输出文件保存为：{output_file}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("用法：python convert_kraken2_to_qiime2.py <kraken2_tsv> <output_file>")
    else:
        kraken2_tsv = sys.argv[1]
        output_file = sys.argv[2]
        convert_kraken2_to_qiime2(kraken2_tsv, output_file)
