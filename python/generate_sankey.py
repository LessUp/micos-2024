import pandas as pd
import plotly.graph_objects as go

# 读取 Kraken2 报告文件
kraken_report_file = "/media/shuai/TOSHBA/mm-dev/ResultData/kraken_taxonomy_m11213.report"
kraken_report = pd.read_csv(kraken_report_file, sep='\t', header=None, names=["percent", "reads", "taxReads", "rank", "taxID", "name"])

# 过滤无效行
kraken_report = kraken_report[kraken_report["rank"] != "U"]

# 创建层级关系
def create_hierarchy(df):
    hierarchy = {}
    for i, row in df.iterrows():
        lineage = row["name"].split('|')
        parent = None
        for node in lineage:
            if parent:
                if parent not in hierarchy:
                    hierarchy[parent] = []
                if node not in hierarchy[parent]:
                    hierarchy[parent].append(node)
            parent = node
    return hierarchy

hierarchy = create_hierarchy(kraken_report)

# 生成节点和链接数据
nodes = []
links = []

def add_to_sankey(parent, children, source_idx):
    for child in children:
        if child not in nodes:
            nodes.append(child)
        target_idx = nodes.index(child)
        links.append({
            "source": source_idx,
            "target": target_idx,
            "value": kraken_report[kraken_report["name"] == child]["taxReads"].sum()
        })
        if child in hierarchy:
            add_to_sankey(child, hierarchy[child], target_idx)

# 根节点处理
root_nodes = kraken_report[kraken_report["rank"] == "D"]["name"].unique()
for root_node in root_nodes:
    if root_node not in nodes:
        nodes.append(root_node)
    root_idx = nodes.index(root_node)
    if root_node in hierarchy:
        add_to_sankey(root_node, hierarchy[root_node], root_idx)

# 生成 Sankey 图
fig = go.Figure(data=[go.Sankey(
    node=dict(
        pad=15,
        thickness=20,
        line=dict(color="black", width=0.5),
        label=nodes
    ),
    link=dict(
        source=[link["source"] for link in links],
        target=[link["target"] for link in links],
        value=[link["value"] for link in links]
    )
)])

# 更新图表布局
fig.update_layout(title_text="Kraken2 Sankey Diagram", font_size=10)

# 保存 Sankey 图为 HTML 文件
fig.write_html("sankey_diagram.html")

# 保存 Sankey 图为 PNG 文件
fig.write_image("sankey_diagram.png")
