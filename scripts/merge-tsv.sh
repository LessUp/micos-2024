#!/bin/bash

# 检查是否提供了至少一个文件作为参数
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 file1.tsv [file2.tsv ...]"
  exit 1
fi

# 合并指定的文件并去除重复行
cat "$@" | awk '!seen[$0]++' > merged_taxonomy.tsv