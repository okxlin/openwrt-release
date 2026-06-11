# Reproducibility / 可复现性

为了尽量提高可复现性，本仓库建议固定以下输入：  
To improve reproducibility as much as possible, this repository recommends pinning the following inputs:

- OpenWrt 版本 / OpenWrt version
- ImageBuilder 名称与下载路径 / ImageBuilder name and download path
- feed 地址与 commit / Feed URLs and commits
- 包清单文件 / Package manifest files
- overlay 文件 / Overlay files

## 元数据输出 / Metadata Outputs

构建后应保留：  
After each build, keep:

- `sha256sums`
- 包清单 / Package manifest
- 构建配置快照 / Build configuration snapshots
- 上游版本信息 / Upstream version information

## 注意 / Notes

完全字节级一致未必总能保证，但输入要尽量固定并可追踪。  
Byte-for-byte reproducibility cannot always be guaranteed, but inputs should be pinned and traceable whenever possible.
