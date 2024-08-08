FROM quay.io/biocontainers/kneaddata:0.12.0--pyhdfd78af_1

# 修复原版的错误，删除旧的 trimmomatic 链接并创建新的符号链接
RUN rm /usr/local/bin/trimmomatic && \
    ln -s /usr/local/share/trimmomatic-0.39-2/trimmomatic.jar /usr/local/bin/trimmomatic

# 设置默认命令
CMD ["/bin/bash"]