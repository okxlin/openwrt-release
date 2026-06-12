# Usage Guide / 使用指南

## 前置条件 / Prerequisites

| 方式 / Method | 要求 / Requirements |
|---|---|
| GitHub Actions | 零配置 — ubuntu-latest runner 自带所有依赖 |
| 本地 Linux | bash, curl, git, make, python3, PyYAML, xz, zstd |
| 本地源码编译 | 额外需要 Go 1.26+ (`/usr/local/go`)、clang/llvm、30GB 磁盘 |

Windows / macOS 不能用于构建，仅限于编辑仓库文件。

## 快速开始 / Quick Start

### 方式一：GitHub Actions（推荐）

1. Fork 或推送仓库到 GitHub。
2. Actions 页面 → `ImageBuilder OpenWrt` → Run workflow。
3. 可选：修改下拉参数切换 theme、proxy、storage 等组件组合。
4. 构建完成后在 Summary 页面下载 artifact。

### 方式二：本地 ImageBuilder 构建

```bash
# 校验仓库完整性
make qa

# 默认构建（base + tools + stock theme + enhanced network + common storage）
make imagebuilder

# 自定义 env 文件
bash scripts/build-imagebuilder.sh configs/imagebuilder/my-device.env
```

### 方式三：本地完整源码编译

```bash
# Homeproxy（sing-box 代理）
make source-build CONFIG_FILE=configs/source/proxy-x86_64.config

# Daed（eBPF 内核代理 + homeproxy）
make source-build CONFIG_FILE=configs/source/dae-x86_64.config

# DNS（AdGuard Home + MosDNS）
make source-build CONFIG_FILE=configs/source/dns-x86_64.config

# 全部（55+ 包，all-in-one）
make source-build CONFIG_FILE=configs/source/all-x86_64.config
```

源码编译需数小时，仅当需要内核模块（如 daed）时使用。

## 组件选择 / Component Selection

构建不直接指定包清单，而是通过**组件开关**自动拼装分类文件：

```
example-x86_64.env:
  COMPONENT_THEMES=argon      → 载入 theme-argon.txt
  COMPONENT_PROXY=homeproxy   → 载入 proxy-homeproxy.txt
  COMPONENT_STORAGE=docker    → 载入 storage-docker.txt
  COMPONENT_NETWORK=enhanced  → 载入 network-enhanced.txt
  COMPONENT_BYPASS=off        → 跳过 bypass 分类
```

最终由 `generate-imagebuilder-manifest.sh` 合并、去重、排序后生成 `generated-packages.txt`。

详细映射表见 `docs/customization.md`。

## 分类文件 / Category Files

位于 `configs/imagebuilder/categories/`，纯文本，一行一个包名：

```text
luci-theme-argon
```

编辑或新增分类文件后重新运行 `make imagebuilder` 即可生效。

`all.txt` 是所有分类的去重合集，供参考查看完整包清单，不直接用于构建。

## 自定义包 / Custom Packages

`packages/` 目录存放非官方 feed 的包（如 `luci-app-homeproxy`、`luci-app-daed`、`luci-app-adguardhome`、`luci-theme-argon`）。

- **ImageBuilder 不可用** — 自定义包仅适用于完整源码编译（`make source`）
- 构建时自动复制到 `package/custom/`，OpenWrt 递归扫描 Makefile
- 开发新包：直接在 `packages/<name>/` 下按 OpenWrt 规范写 `Makefile`

## 产物说明 / Artifacts

| 产物 | 说明 |
|---|---|
| `*-squashfs-combined*.img.gz` | squashfs 固件（只读根，推荐） |
| `*-ext4-combined*.img.gz` | ext4 固件（可写根，需较大空间） |
| `*-efi.img.gz` | UEFI 启动变体 |
| `*-rootfs.tar.gz` | 根文件系统归档 |
| `packages/` | 编译产出的全部 ipk 包 |
| `sha256sums` | 校验文件 |
| `profiles.json` | 设备 profile 元数据 |

## 发布固件 / Release

1. 先运行 `ImageBuilder OpenWrt` 或 `Full Source OpenWrt` 确认构建成功。
2. 运行 `Release Firmware` workflow，输入 `release_tag`（如 `v24.10.7-1`）。
3. 自动发布 GitHub Release，附加全部固件产物。

注意：`imagebuilder.yml` 和 `source-build.yml` **不会**自动发布 Release，产物仅保存在 Actions artifact（90 天过期）。

## ARM / 非 x86 设备 / ARM and Other Targets

构建系统与目标架构无关，只需更换 env 文件或 `.config`。以下为常用 ARM 设备示例：
The build system is target-agnostic. Examples for common ARM devices:

| 设备 | ImageBuilder env | Source config |
|---|---|---|
| Raspberry Pi 4 / CM4 | `configs/imagebuilder/example-bcm2711.env` | `configs/source/example-bcm2711.config` |
| Generic ARM64 (armsr) | 修改 env: `OPENWRT_TARGET=armsr, OPENWRT_SUBTARGET=armv8` | 修改 config: `CONFIG_TARGET_armsr=y, CONFIG_TARGET_armsr_armv8=y` |
| IPQ40xx (GL.iNet, etc.) | 修改 env: `OPENWRT_TARGET=ipq40xx, OPENWRT_SUBTARGET=generic` | 修改 config: `CONFIG_TARGET_ipq40xx=y, CONFIG_TARGET_ipq40xx_generic=y` |
| MTK Filogic (GL-MT6000, etc.) | 修改 env: `OPENWRT_TARGET=mediatek, OPENWRT_SUBTARGET=filogic` | 修改 config: `CONFIG_TARGET_mediatek=y, CONFIG_TARGET_mediatek_filogic=y` |
| Rockchip (NanoPi R5S, etc.) | 修改 env: `OPENWRT_TARGET=rockchip, OPENWRT_SUBTARGET=armv8` | 修改 config: `CONFIG_TARGET_rockchip=y, CONFIG_TARGET_rockchip_armv8=y` |

所有设备的包清单（`categories/*.txt`）完全通用，无需为不同架构修改。
## 常见问题 / FAQ

**Q: 怎么加一个新包？**
A: 找到对应的 `categories/<name>.txt`，添加包名到末尾。如果是社区包需额外配置 feed 或放入 `packages/`。

**Q: 怎么换设备？**
A: 复制 `configs/imagebuilder/example-x86_64.env` 或 `example-bcm2711.env`，修改 `OPENWRT_TARGET` / `OPENWRT_SUBTARGET` / `OPENWRT_PROFILE` / `IMAGEBUILDER_NAME`。详见上方 ARM 设备表格。

A: ImageBuilder（10 分钟）覆盖大多数场景。仅在需要内核模块（daed）、社区 feeds（openclash、passwall2、mosdns、easytier 等）、或社区包（luci-app-adguardhome、luci-theme-argon）时用 source build（数小时）。

A: daed 和 mosdns 的 v2dat 都依赖 Go >= 1.26，而 OpenWrt 24.10 默认 Go 1.23。`build-source.sh` 会自动检测 `CONFIG_PACKAGE_daed=y|CONFIG_PACKAGE_mosdns=y` 并 patch golang 到 1.26。确保系统已安装 Go 1.26.4 到 `/usr/local/go`。
