# CI Workflows / 持续集成工作流

## lint.yml

用于校验：  
Used to validate:

- shell 脚本存在且语法可解析 / Shell scripts exist and can be parsed
- workflow 文件存在 / Workflow files exist
- 仓库结构完整 / Repository structure is complete

## imagebuilder.yml

默认构建路径。  
This is the default build path.

触发方式：  
Trigger modes:

- `workflow_dispatch` only / 仅手动触发


## source-build.yml

高级构建路径，默认仅手动触发。  
This is the advanced build path and is manual-only by default.

## release.yml

用于在 tag 或手动触发时重新构建 ImageBuilder 固件并发布 release。手动触发时需要显式提供 `release_tag`。
Used to rebuild ImageBuilder firmware and publish a release on tag pushes or manual dispatch. Manual dispatch requires an explicit `release_tag`.

所有构建路径（ImageBuilder / source-build / release）均支持可选的 `build_tag` 输入。设置后固件文件名将包含 `openwrt-OPENWRT_VERSION-BUILD_TAG-` 前缀。
All build paths (ImageBuilder / source-build / release) support an optional `build_tag` input. When set, firmware filenames will include an `openwrt-OPENWRT_VERSION-BUILD_TAG-` prefix.

## 设计建议 / Design Recommendations

- 使用 `concurrency` 防止重复构建 / Use `concurrency` to avoid duplicate builds
- 使用 artifact 保存固件与元数据 / Use artifacts to store firmware and metadata
- 使用 cache 缓存下载内容而不是最终产物 / Use cache for downloaded content rather than final outputs
