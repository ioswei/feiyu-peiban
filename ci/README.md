# CI / App Store 发布

证书与配置直接存放在仓库内，GitHub Actions 检出后自动读取，**无需配置 GitHub Secrets**。

## 仓库内配置文件

| 路径 | 用途 |
|------|------|
| `Config/P12证书.p12` | Apple Distribution 签名证书 |
| `Config/Usr-P8/AuthKey_*.p8` | App Store Connect API 密钥 |
| `docs/配置信息.md` | P12 密码、Team ID、Issuer ID、密钥 ID |

## 触发打包

1. **手动**：GitHub → Actions → **App Store Release** → Run workflow
2. **Tag**：`git tag v1.0.0 && git push origin v1.0.0`

## CI 流程

1. `load-repo-config.sh` — 读取 `Config/` 与 `docs/配置信息.md`
2. `import-signing.sh` — 导入 P12 证书
3. `build-archive-cloud.sh` — Xcode 云签名打包
4. `upload-testflight.sh` — 上传到 TestFlight

## 安全提示

证书与 API 密钥已纳入版本库。请确保仓库为**私有**，并限制协作者访问权限。
