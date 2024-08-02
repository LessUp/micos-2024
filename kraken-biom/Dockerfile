FROM python:3.6.15-buster

WORKDIR /

# 升级 pip 并安装 biom-format，克隆 kraken-biom 仓库，然后安装 kraken-biom
RUN python -m pip install --upgrade pip && \
    pip install --default-timeout=100 -i https://pypi.tuna.tsinghua.edu.cn/simple biom-format==2.1.10 && \
    git clone https://github.com/smdabdoub/kraken-biom.git && \
    cd kraken-biom && \
    python setup.py install && \
    cd .. && \
    rm -rf kraken-biom

# ENTRYPOINT ["kraken-biom"]