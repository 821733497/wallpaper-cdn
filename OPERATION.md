# 壁纸 CDN 维护操作文档

## 1. 适用范围
- 本地表盘清单：`wallpapers/` + `index.json`
- 在线壁纸清单：`wallpapers-online/` + `index-online.json`
- 直链使用 tag 版本化，避免 CDN 缓存刷新不及时

## 2. 目录与命名规范
- 原图目录：`wallpapers/full/`、`wallpapers-online/full/`
- 预览目录：`wallpapers/preview/`、`wallpapers-online/preview/`
- 文件名即 `id`（不含扩展名），原图与预览图建议同名

## 3. 版本策略（tag +1）
- 采用语义化版本：`vX.Y.Z`（默认只递增 patch，如 `v1.0.0 -> v1.0.1`）
- 任意素材或索引变更都必须升 tag
- 不复用旧 tag（需要修复时用新 tag）

## 4. 新增/更新图片
### 4.1 表盘（wallpapers）
1. 把原图放入 `wallpapers/full/`
2. 可选：把预览图放入 `wallpapers/preview/`（同名）
3. 若只放原图，后续脚本可自动生成预览图

### 4.2 在线壁纸（wallpapers-online）
1. 把原图放入 `wallpapers-online/full/`
2. 可选：把预览图放入 `wallpapers-online/preview/`（同名）
3. 若只放原图，后续脚本可自动生成预览图

## 5. 生成缩略图/预览图
默认行为：预览图缺失时自动生成，尺寸上限 800x800，格式 png。  
常用参数说明：
- 强制重建：`-ForcePreview`
- 跳过预览：`-SkipPreview`
- 自定义尺寸：`-PreviewMaxWidth`、`-PreviewMaxHeight`
- 自定义格式：`-PreviewFormat`（如 `png`/`jpg`）

建议：一般保持默认即可；如果需要统一质量/格式，再使用 `-ForcePreview` 重建全部预览图。

## 6. 生成索引（版本化 URL）
### 6.1 选择新 tag
示例：`v1.0.1`（每次发布前先确定新 tag）

### 6.2 生成表盘索引（index.json）
```powershell
.\tools\generate-index.ps1 -Owner 821733497 -Repo wallpaper-cdn -UseJsdelivr -Ref v1.0.1
```

### 6.3 生成在线壁纸索引（index-online.json）
```powershell
.\tools\generate-index.ps1 -Owner 821733497 -Repo wallpaper-cdn -UseJsdelivr -Ref v1.0.1 -ContentDir wallpapers-online -Output index-online.json
```

### 6.4 只改一类时的规则
- 只改表盘：只执行 6.2
- 只改在线壁纸：只执行 6.3
- 两边都改：6.2 和 6.3 都执行

## 7. 提交与发布（tag）
```powershell
git add index.json index-online.json
git commit -m "Release v1.0.1 indexes"
git tag -a v1.0.1 -m "release v1.0.1"
git push origin main
git push origin v1.0.1
```

## 8. 验证清单
- `index.json` / `index-online.json` 的 `generated_at` 已更新
- 抽样打开 3~5 张图片直链（URL 中应包含 `@v1.0.1`）
- App 端访问正常

## 9. 失败修复与回滚
- 不要重用旧 tag
- 修复后提升新 tag（如 `v1.0.2`），重新生成索引并发布
