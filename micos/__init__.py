# MICOS-2024: Metagenomic Intelligence and Comprehensive Omics Suite

# 统一从 _version.py 导入版本号（由 setuptools-scm 自动生成）。
# _version.py 不纳入版本控制（见 .gitignore），fresh clone 后未安装包时
# 走 except 分支回退到 "0.0.0+unknown"，避免 ImportError。
try:
    from micos._version import __version__  # noqa: F401
except ImportError:
    __version__ = "0.0.0+unknown"

__all__ = ["__version__"]
