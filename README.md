# wallpaper-cdn

用于应用壁纸直链下载的静态仓库，建议通过 GitHub Public + jsDelivr 使用。

目录结构：
- wallpapers/full/ 原图（约 2MB）
- wallpapers/preview/ 预览图（50~150KB）
- index.json 表盘清单
- wallpapers-online/full/ 原图（在线壁纸）
- wallpapers-online/preview/ 预览图（在线壁纸）
- index-online.json 在线壁纸清单

直链说明（ref 可为分支 / tag / commit）：
- GitHub Raw：https://raw.githubusercontent.com/<owner>/<repo>/<ref>/
- jsDelivr：https://cdn.jsdelivr.net/gh/<owner>/<repo>@<ref>/

例如：
- 预览图：`wallpapers/preview/w-0001.jpg`
- 原图：`wallpapers/full/w-0001.jpg`

清单字段说明（index.json）：
- schema_version: 清单版本
- generated_at: 生成时间（ISO 8601）
- items: 壁纸数组
  - id: 唯一 ID（建议与文件名一致）
  - title: 标题
  - category: 分类
  - preview_url: 预览图直链
  - full_url: 原图直链
  - size_bytes: 原图大小（字节）
  - hash_sha256: 原图 SHA256
  - width: 原图宽度
  - height: 原图高度
  - updated_at: 更新时间（ISO 8601）

更新流程（表盘）：
1. 上传新图片到 `wallpapers/full/` 和 `wallpapers/preview/`
2. 运行 `tools/generate-index.ps1` 生成/更新 `index.json`（如需版本化直链可加 `-Ref <tag|commit>`）
3. 推送到 GitHub，App 端按直链访问
4. 若未版本化且使用 jsDelivr，可在脚本中加 `-PurgeJsdelivr` 刷新缓存

版本化直链（推荐，避免 CDN 缓存刷新）：
- 在脚本中指定 `-Ref <tag|commit>`，生成的 URL 会固定到该版本
- 版本化后通常不需要 `-PurgeJsdelivr`

Tag 发布流程（推荐）：
1. 选择 tag（建议语义化版本，如 `v1.0.0`；首次可用 `v1.0.0`）
2. 使用 `-Ref <tag>` 重新生成索引
3. 提交索引与相关改动
4. 创建并推送 tag，再推送分支

下次 tag +1 规则：
- 默认只递增 patch（例如 `v1.0.0` -> `v1.0.1`）
- 如果有不兼容改动，再升级 minor/major

如果中国大陆访问较慢，可用 fastly 生成直链：
- `tools/generate-index.ps1 -Owner <owner> -Repo <repo> -UseJsdelivr -JsdelivrHost fastly.jsdelivr.net -Ref <tag|commit>`

更新流程（在线壁纸）：
1. 上传新图片到 `wallpapers-online/full/` 和 `wallpapers-online/preview/`
2. 运行 `tools/generate-index.ps1 -ContentDir wallpapers-online -Output index-online.json`（如需版本化直链可加 `-Ref <tag|commit>`）
3. 推送到 GitHub，App 端按直链访问

只上传原图也可以：
- 脚本会在 `wallpapers/preview/` 缺少同名文件时自动生成预览图
- 默认生成 PNG，最大尺寸 800x800，且会覆盖同名预览图，可通过参数调整
