# OpenWrt GitHub Actions Build Template

这个仓库模板用于搭建一个适合 GitHub、Linux 环境、LF 换行符规范的 OpenWrt 自动编译仓库。  
This repository template is designed for building an OpenWrt automation repository that fits GitHub, Linux environments, and LF line ending requirements.

它默认采用两条构建路径：  
It uses two build paths by default:

- `ImageBuilder`：适合大多数“选设备 + 加减包 + 覆盖配置文件”的场景，速度快，最适合 GitHub Actions。  
  `ImageBuilder`: suitable for most use cases that combine device selection, package changes, and overlay files; fast and ideal for GitHub Actions.
- `full-source`：适合需要自定义 feeds、补丁、内核模块或完整 `.config` 的高级场景。  
  `full-source`: suitable for advanced cases that require custom feeds, patches, kernel modules, or a full `.config`.

## 设计目标 / Design Goals

- 公开仓库可维护 / Keep the public repository maintainable
- GitHub Actions 自动编译 / Support automatic builds with GitHub Actions
- Linux runner 兼容 / Stay compatible with Linux runners
- LF 换行符一致 / Enforce LF line endings consistently
- 输入与产物分离 / Separate build inputs from generated outputs
- 可追踪 OpenWrt 版本、feeds 与包清单 / Track OpenWrt versions, feeds, and package manifests

## 目录结构 / Repository Layout

```text
.
├─ .github/workflows/
├─ configs/
│  ├─ imagebuilder/
│  └─ source/
├─ docs/
├─ feeds/
├─ files/
├─ packages/
├─ patches/openwrt/
├─ scripts/
├─ .editorconfig
├─ .gitattributes
├─ Makefile
└─ README.md
```

## 快速开始 / Quick Start

### 1. 直接用于 GitHub Actions / Use It Directly on GitHub Actions

1. 新建 GitHub 仓库并推送本模板。  
   Create a new GitHub repository and push this template.
2. 修改 `configs/imagebuilder/example-x86_64.env`。  
   Update `configs/imagebuilder/example-x86_64.env`.
3. 按需修改 `files/`、`feeds/custom-feeds.conf`、`packages/`。  
   Modify `files/`, `feeds/custom-feeds.conf`, and `packages/` as needed.
4. 在 GitHub Actions 中手动运行 `ImageBuilder OpenWrt`。  
   Manually run `ImageBuilder OpenWrt` in GitHub Actions.

### 2. 本地 Linux 验证 / Local Linux Validation

本地构建仅支持 Linux 主机；Windows 或 MSYS 环境只适合编辑和静态校验，不适合执行 OpenWrt 的 ImageBuilder 或完整源码构建。  
Local builds are supported only on Linux hosts. Windows or MSYS environments are suitable for editing and static validation, but not for running OpenWrt ImageBuilder or full source builds.

如果你希望在 Linux 主机上一键完成“校验 + ImageBuilder 构建”，可以直接运行下面的配套脚本：  
If you want a single Linux entrypoint that runs validation and then performs the ImageBuilder build, use the helper script below:

```bash
bash scripts/linux-build.sh
```

也可以传入自定义的 profile env 文件：  
You can also pass a custom profile env file:

```bash
bash scripts/linux-build.sh configs/imagebuilder/example-x86_64.env
```

如果你希望分步执行，也可以直接调用底层命令：  
If you prefer running the steps separately, you can call the underlying commands directly:

```bash
make qa
```

```bash
make imagebuilder
```

完整源码编译（需要 daed 等内核模块时使用）：  
Full source builds (use when daed or kernel modules are needed):

```bash
# Homeproxy build (sing-box proxy)
make source-build CONFIG_FILE=configs/source/proxy-x86_64.config

# DNS build (AdGuard Home + MosDNS)
make source-build CONFIG_FILE=configs/source/dns-x86_64.config

# All-in-one build (55+ packages, complete)
make source-build CONFIG_FILE=configs/source/all-x86_64.config
```

Non-x86 targets work the same way: just switch the env file.
Example for Raspberry Pi 4 (ARM64):
  make imagebuilder PROFILE=configs/imagebuilder/example-bcm2711.env
See docs/usage.md for more ARM devices.

## 推荐使用方式 / Recommended Usage

如果你的目标是复刻大量组件组合能力，建议：  
If your goal is to reproduce a large number of component combinations, the recommended approach is:

- 用 `configs/imagebuilder/*.env` 表达不同设备或功能组合  
  Use `configs/imagebuilder/*.env` to represent different device or feature combinations
- 用 `configs/imagebuilder/categories/` 管理 80/20 组件池  
  Use `configs/imagebuilder/categories/` to manage the 80/20 component bundles
- 用 `configs/imagebuilder/presets/` 管理常见场景预设  
  Use `configs/imagebuilder/presets/` to manage common scenario presets
- 用 `packages/` 存放自定义包（如 luci-app-homeproxy、luci-app-daed、luci-app-adguardhome、luci-theme-argon）
  Use `packages/` to store custom packages (e.g., luci-app-homeproxy, luci-app-daed, luci-app-adguardhome, luci-theme-argon)
- 用 `files/` 提供默认配置和 overlay  
  Use `files/` to provide default configuration and overlay files
- 用 `feeds/custom-feeds.conf` 管理第三方 feed  
  Use `feeds/custom-feeds.conf` to manage third-party feeds
- 必须修改源码时再使用 `source-build.yml`  
  Use `source-build.yml` only when source-level changes are necessary

## 80/20 组件分类 / 80/20 Component Categories

当前模板已经内置一版 80/20 能力矩阵，覆盖以下方向：  
The template now includes an 80/20 capability matrix covering the following areas:

- 主题 / Themes（stock、argon）
- 代理套件 / Proxy suites（daed、homeproxy、openclash、passwall2）
- DNS 服务 / DNS services（adguard、mosdns）
- 系统工具扩展 / System tools extras（frpc、frps、ttyd 等）
- Docker / 存储 / Docker and storage（common、docker）
- 常用系统工具 / Common system tools
- 网络增强 / Network enhancements（基础包 + ddns、wireguard、upnp 等）
- 旁路由预设 / Bypass-router preset

社区包（daed、luci-app-adguardhome、luci-theme-argon）通过 `packages/` 本地安装，无需外部 feed。这些需要完整源码编译（`make source`），不适合 ImageBuilder。
Community packages (daed, luci-app-adguardhome, luci-theme-argon) are installed locally via `packages/`, no external feeds required. They need full source builds (`make source`), not ImageBuilder.

默认仍然保持保守：主路径使用 ImageBuilder，小而稳的基础包为默认值，社区主题与代理套件作为可选组件暴露。  
The default remains conservative: the main path still uses ImageBuilder, a small stable base package set remains default, and community themes plus proxy suites are exposed as optional bundles.

## 产物与元数据 / Outputs and Metadata

工作流会输出：  
The workflows generate:

- 固件产物 / Firmware artifacts
- `sha256` 校验文件 / `sha256` checksum files
- 包清单 / Package manifests
- OpenWrt 版本与 feed 元数据 / OpenWrt version and feed metadata

## 相关文档 / Related Documents

- `docs/architecture.md`
- `docs/usage.md`
- `docs/customization.md`
- `docs/ci.md`
- `docs/reproducibility.md`

## 注意事项 / Notes

- 不要把密码、私钥、Wi‑Fi 凭据提交进仓库。  
  Do not commit passwords, private keys, or Wi‑Fi credentials into the repository.
- 公开发布固件时，应保留上游许可证与源码归属说明。  
  When distributing firmware publicly, keep upstream licensing and source attribution notices.
- OpenWrt 构建步骤要求原生 Linux 主机或 GitHub Actions Linux runner。  
  OpenWrt build steps require a native Linux host or a GitHub Actions Linux runner.
- `ImageBuilder` 是默认主路径；只有在必要时才启用完整源码编译。  
  `ImageBuilder` is the default path; use full source compilation only when needed.
