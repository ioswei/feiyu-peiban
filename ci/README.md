# CI / App Store 发布

流程参考 `ios-testflight-toolkit`（**不含 Shorebird / Flutter**）。

## 仓库内配置

| 路径 | 用途 |
|------|------|
| `Config/P12证书.p12` | Apple Distribution 签名证书 |
| `Config/Usr-P8/AuthKey_*.p8` | App Store Connect API 密钥 |
| `docs/配置信息.md` | P12 密码、Team ID、Bundle ID、Issuer ID、密钥 ID |

## CI 步骤

1. `load-repo-config.sh` — 读取配置
2. `write-api-key-json.sh` — 生成 fastlane API Key JSON
3. `fetch-appstore-profiles.sh` — `fastlane sigh --force` 拉取 Profile
4. `import-signing.sh` — 导入 P12 + Apple 中间证书
5. `configure-manual-signing.sh` — 同步 xcodeproj + ExportOptions
6. `build-archive-cloud.sh` — xcodebuild archive + export
7. `distribute-testflight.sh` — pilot upload + 等待 + 外部分发 + Beta 审核

## 触发

- **手动**：Actions → App Store Release → Run workflow（可填外部测试组名）
- **Push main / Tag `v*`**：自动触发

GitHub 地址：https://github.com/ioswei/feiyu-peiban/actions/workflows/appstore.yml

## 与工具包差异

| ios-testflight-toolkit | 本项目 |
|------------------------|--------|
| Shorebird CI | ❌ 跳过 |
| Flutter build ipa | ❌ 原生 xcodebuild |
| 多扩展 Profile | ❌ 单 App |
| ensure_apple_capabilities | ❌ 无 Push/App Group 扩展 |
