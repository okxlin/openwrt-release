# Architecture / 架构说明

本仓库采用“配置驱动”的 OpenWrt 构建方式，而不是把所有逻辑塞进单个 workflow。  
This repository uses a configuration-driven OpenWrt build model instead of putting all logic into a single workflow.

## 核心原则 / Core Principles

1. workflow 只做编排。  
   Workflows only orchestrate.
2. 真正的构建逻辑放在 `scripts/`。  
   The actual build logic lives in `scripts/`.
3. 设备/版本/包配置放在 `configs/`。  
   Device, version, and package configuration lives in `configs/`.
4. 默认文件覆盖放在 `files/`。  
   Default file overlays live in `files/`.
5. 第三方 feed 独立管理。  
   Third-party feeds are managed separately.

## 两条构建路径 / Two Build Paths

### ImageBuilder

适用于：  
Best suited for:

- 增删软件包 / Adding or removing packages
- 默认配置覆盖 / Default configuration overlays
- 设备 profile 组合 / Device profile combinations
- GitHub Actions 自动编译 / Automatic builds in GitHub Actions

### Full source

适用于：  
Best suited for:

- 自定义补丁 / Custom patches
- 深度 feed 集成 / Deep feed integration
- 需要完整 `.config` / Full `.config` requirements
- 修改内核或底层包 / Kernel or low-level package changes

## 为什么这样分层 / Why the Repository Is Layered This Way

这种设计更接近在线定制 OpenWrt 服务的后端输入模型：  
This design is closer to the backend input model used by online OpenWrt customization services:

- `configs/` 定义构建参数 / `configs/` defines build parameters
- `packages/` 与 `feeds/` 定义扩展能力 / `packages/` and `feeds/` define extension capability
- `files/` 定义系统默认状态 / `files/` defines the default system state
- `scripts/` 保证本地与 CI 的一致行为 / `scripts/` keeps local and CI behavior aligned
