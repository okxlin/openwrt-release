# Customization / 定制说明

## 80/20 组件矩阵 / 80/20 Component Matrix

当前模板不再只依赖一个静态包清单，而是支持按分类组合生成最终固件包单。  
The template no longer depends on a single static package list only. It now supports generating the final firmware manifest from categorized component bundles.

当前 80/20 分类包括：  
The current 80/20 categories include:

- 主题 / Themes
- 代理套件 / Proxy suites
- DNS 套件 / DNS suites
- 系统工具扩展 / System tools extras（extras：frpc、frps、ttyd 等 / includes frpc, frps, ttyd, etc.）
- Docker / 存储 / Docker and storage
- 常用系统工具 / Common system tools
- 网络增强 / Network enhancements
- 旁路由预设 / Bypass-router preset

这些分类文件位于 `configs/imagebuilder/categories/`。  
These category files live under `configs/imagebuilder/categories/`.
这些分类文件位于 `configs/imagebuilder/categories/`。
These category files live under `configs/imagebuilder/categories/`.

所有包的去重合集请参考 `categories/all.txt`。
The deduplicated union of all packages is in `categories/all.txt`.

## 分类包清单 / Category Package Manifests

模板会把多个分类文件组合成最终的 `generated-packages.txt`。  
The template combines multiple category files into the final `generated-packages.txt` manifest.

例如：  
For example:

- `base.txt`：基础 LuCI 与系统工具 / Base LuCI and system utilities
- `theme-stock.txt`、`theme-argon.txt`：主题选择 / Theme selection
- `network-enhanced.txt`：常用网络增强 / Common network enhancements
- `storage-docker.txt`：Docker 与磁盘相关组件 / Docker and storage components
- `dns-adguard.txt`、`dns-mosdns.txt`：DNS 套件 / DNS suites
- `proxy-homeproxy.txt`、`proxy-openclash.txt`、`proxy-passwall2.txt`：代理套件 / Proxy suites

## 预设文件 / Preset Files

预设文件位于 `configs/imagebuilder/presets/`，用于组合常见能力集。  
Preset files live under `configs/imagebuilder/presets/` and are used to combine common capability sets.

当前提供：  
Currently provided:

- `generic-router.env`：通用主路由预设 / Generic main-router preset
- `bypass-router.env`：旁路由预设 / Bypass-router preset

你可以在 profile env 中通过 `PRESET_FILE` 引用它们。  
You can reference them through `PRESET_FILE` in a profile env file.

## 组件开关 / Component Toggles

`configs/imagebuilder/example-x86_64.env` 现在支持以下开关：  
`configs/imagebuilder/example-x86_64.env` now supports the following toggles:

- `COMPONENT_THEMES=stock|argon`
- `COMPONENT_PROXY=none|dae|homeproxy|openclash|passwall2`
- `COMPONENT_STORAGE=common|docker`
- `COMPONENT_NETWORK=enhanced`
- `COMPONENT_DNS=none|adguard|mosdns`
- `COMPONENT_EXTRAS=none|extras`
- `PRESET_FILE=configs/imagebuilder/presets/*.env`

生成逻辑由 `scripts/generate-imagebuilder-manifest.sh` 负责。  
The generation logic is handled by `scripts/generate-imagebuilder-manifest.sh`.

### 开关与分类文件的映射 / Toggle-to-Category Mapping

每个开关值决定载入哪个 `categories/<name>.txt`：
Each toggle value determines which `categories/<name>.txt` is loaded:

| 开关 / Toggle | 值 / Value | 载入文件 / Loaded File |
|---|---|---|
| `COMPONENT_THEMES` | `stock` | `theme-stock.txt` |
| | `argon` | `theme-argon.txt` |
| `COMPONENT_PROXY` | `none` | 跳过 / skipped |
| | `dae` | `proxy-dae.txt` |
| | `homeproxy` | `proxy-homeproxy.txt` |
| | `openclash` | `proxy-openclash.txt` |
|| `passwall2` | `proxy-passwall2.txt` |
|| `COMPONENT_DNS` | `none` | 跳过 / skipped |
|| | `adguard` | `dns-adguard.txt` |
|| | `mosdns` | `dns-mosdns.txt` |
| `COMPONENT_STORAGE` | `common` | `storage-common.txt` |
| | `docker` | `storage-docker.txt` |
| `COMPONENT_NETWORK` | `enhanced` | `network-enhanced.txt` |
| `COMPONENT_BYPASS` | `off` | 跳过 / skipped |
| | `on` | `network-bypass.txt` |
| `COMPONENT_EXTRAS` | `none` | 跳过 / skipped |
| | `extras` | `tools-extras.txt` |

拼装顺序（`generate-imagebuilder-manifest.sh`）：
Assembly order (`generate-imagebuilder-manifest.sh`):

1. `base.txt` — 始终 / always
2. `tools-common.txt` — 始终 / always
3. 主题 category（如 `theme-stock.txt`）
4. 网络 category（如 `network-enhanced.txt`）
5. 存储 category（如 `storage-common.txt`）
6. DNS category（如 `dns-adguard.txt`），仅在值非 `none` 时
7. 工具 extras category（如 `tools-extras.txt`），仅在值非 `none` 时
8. 代理 category（如 `proxy-dae.txt`），仅在值非 `none` 时
9. 旁路由 category（`network-bypass.txt`），仅在值 = `on` 时

最终合并后的包单去重排序，写入 `generated-packages.txt`。
The merged package list is deduplicated, sorted, and written to `generated-packages.txt`.
## 添加默认软件包 / Add Default Packages

如果你只想补一个简单包，可以继续直接改 `configs/imagebuilder/packages-base.txt`；但更推荐把它归类到 `categories/` 里。  
If you only want to add a simple package, you can still edit `configs/imagebuilder/packages-base.txt` directly, but it is recommended to place it in `categories/` instead.

## 添加第三方 feeds / Add Third-Party Feeds

编辑 `feeds/custom-feeds.conf`，推荐固定到 commit，避免构建漂移。  
Edit `feeds/custom-feeds.conf`. Pin feeds to commits whenever possible to avoid build drift.

代理套件、DNS 套件、系统工具扩展和社区主题通常依赖第三方 feed。当前 6 个活跃 feed 从 `feeds/custom-feeds.conf` 控制：passwall-packages、passwall2、openclash、mosdns（v5 分支）、sbwml_pkgs 和 easytier。详细信息请参阅该文件注释。
Proxy suites, DNS suites, system tool extras, and community themes usually require third-party feeds. Currently 6 active feeds are controlled from `feeds/custom-feeds.conf`: passwall-packages, passwall2, openclash, mosdns (v5 branch), sbwml_pkgs, and easytier. See that file's comments for details.

## 添加覆盖文件 / Add Overlay Files

将文件放入 `files/`，路径结构需与 OpenWrt 根文件系统一致。  
Place files under `files/`, and keep the path structure consistent with the OpenWrt root filesystem.

例如 / For example:

- `files/etc/banner`
- `files/etc/uci-defaults/99-template-defaults`

旁路由预设还会使用 `files/presets/bypass-router/` 中的覆盖文件。  
The bypass-router preset also uses overlay files under `files/presets/bypass-router/`.

## 新增设备配置 / Add a New Device Profile

复制一个 `configs/imagebuilder/*.env` 文件，修改：  
Copy an existing `configs/imagebuilder/*.env` file and update:

- `OPENWRT_TARGET`
- `OPENWRT_SUBTARGET`
- `OPENWRT_PROFILE`
- `IMAGEBUILDER_NAME`
- `PRESET_FILE`
  - 各 COMPONENT 开关 / Component toggles


## GitHub Actions 输入 / GitHub Actions Inputs

`imagebuilder.yml` 现在支持以下手动输入：  
`imagebuilder.yml` now supports these manual inputs:

- `profile`
- `preset`
- `themes`
- `proxy`
- `dns`
- `tools`
- `build_tag`
- `storage`
- `network`
- `bypass`

这意味着你可以在不改仓库文件的情况下，直接在 Actions 页面做常见组合。  
This means you can assemble common combinations directly from the Actions page without editing repository files.

## 何时改用 full source / When to Switch to Full Source

满足以下任一条件时建议切换：  
Switch when any of the following applies:

- 需要打补丁 / You need patches
- 需要完整 `.config` / You need a full `.config`
- 需要编译不适合 ImageBuilder 的内容 / You need to build content not suitable for ImageBuilder
- 需要更细粒度的 target 控制 / You need finer control over the target

## 本地执行约束 / Local Execution Constraints

OpenWrt 的 `ImageBuilder` 和 `full source` 本地执行都要求 Linux 主机。Windows、PowerShell 或 MSYS 环境可以维护仓库内容，但不应作为最终构建环境。  
Local execution of both OpenWrt `ImageBuilder` and `full source` requires a Linux host. Windows, PowerShell, or MSYS environments can maintain the repository contents, but should not be used as the final build environment.

如需一个面向 Linux 的本地配套入口，可以使用 `bash scripts/linux-build.sh [profile-env]`。该脚本会先执行仓库校验，再调用 ImageBuilder 构建。  
If you need a Linux-oriented local helper entrypoint, use `bash scripts/linux-build.sh [profile-env]`. It runs repository validation first and then calls the ImageBuilder build.

## 安全提醒 / Security Notes

`packages/` 中的自定义包配置（如 homeproxy、daed）为模板文件，所有敏感字段默认为空值或占位符。
Custom package configurations under `packages/` (e.g., homeproxy, daed) are template files; all sensitive fields default to empty or placeholder values.

**不要提交包含真实数据的配置文件。** 包括但不限于：
**Do not commit configuration files with real data.**  This includes but is not limited to:

- `github_token`、API token、密钥 / API tokens, secret keys
- 节点地址、订阅链接 / Node addresses, subscription URLs
- Wi‑Fi 密码 / Wi‑Fi passwords
- 私有 DNS 地址 / Private DNS addresses
