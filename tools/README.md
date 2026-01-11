# 工具说明

`generate-index.ps1` 用于扫描 `wallpapers/full/` 和 `wallpapers/preview/`，生成 `index.json`。

参数说明：
- Owner: GitHub 用户或组织名
- Repo: 仓库名
- Branch: 分支名，默认 `main`
- UseJsdelivr: 使用 jsDelivr 直链（不传则默认使用占位地址）
- OutputPath: 输出清单文件名或路径，默认 `index.json`
- PurgeJsdelivr: 生成后刷新 jsDelivr 缓存（需同时使用 `UseJsdelivr`）
- PreviewMaxWidth: 预览图最大宽度，默认 800
- PreviewMaxHeight: 预览图最大高度，默认 800
- PreviewFormat: 预览图格式，默认 png
- ForcePreview: 强制覆盖已存在的预览图（默认关闭）
- SkipPreview: 跳过预览图生成，仅生成清单

说明：
- 预览图建议与原图同名，脚本会标记缺失的预览图。
- 如果未提供 Owner/Repo，URL 会保留占位符，方便后续替换。
- 分开生成清单示例：将 `ContentDir` 指向不同目录，并用 `OutputPath` 指定不同的清单文件名。
- 脚本会对 URL 中的路径进行编码，避免中文或空格导致直链失效。

独立生成预览图：
- 使用 `tools/generate-previews.ps1` 仅生成预览图，不生成清单。
- 支持分批处理：`BatchSize` 每批数量，`BatchIndex` 从 0 开始。
