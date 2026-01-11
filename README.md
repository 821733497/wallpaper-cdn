# wallpaper-cdn

用于应用壁纸直链下载的静态仓库，建议通过 GitHub Public + jsDelivr 使用。

目录结构：
- wallpapers/full/ 原图（约 2MB）
- wallpapers/preview/ 预览图（50~150KB）
- index.json 表盘清单
- wallpapers-online/full/ 原图（在线壁纸）
- wallpapers-online/preview/ 预览图（在线壁纸）
- index-online.json 在线壁纸清单

直链说明：
- GitHub Raw：https://raw.githubusercontent.com/<owner>/<repo>/main/
- jsDelivr：https://cdn.jsdelivr.net/gh/<owner>/<repo>@main/

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
2. 运行 `tools/generate-index.ps1` 生成/更新 `index.json`
3. 推送到 GitHub，App 端按直链访问
4. 若使用 jsDelivr，可在脚本中加 `-PurgeJsdelivr` 刷新缓存

如果中国大陆访问较慢，可用 fastly 生成直链：
- `tools/generate-index.ps1 -Owner <owner> -Repo <repo> -UseJsdelivr -JsdelivrHost fastly.jsdelivr.net`

更新流程（在线壁纸）：
1. 上传新图片到 `wallpapers-online/full/` 和 `wallpapers-online/preview/`
2. 运行 `tools/generate-index.ps1 -ContentDir wallpapers-online -OutputPath index-online.json`
3. 推送到 GitHub，App 端按直链访问

只上传原图也可以：
- 脚本会在 `wallpapers/preview/` 缺少同名文件时自动生成预览图
- 默认生成 PNG，最大尺寸 800x800，且会覆盖同名预览图，可通过参数调整
