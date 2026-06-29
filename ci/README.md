# CI / App Store 发布

## 本地配置

| 路径 | 用途 |
|------|------|
| `Config/P12证书.p12` | Apple Distribution 签名证书 |
| `Config/Usr-P8/AuthKey_*.p8` | App Store Connect API 密钥（上传 TestFlight） |
| `docs/配置信息.md` | P12 密码、Issuer ID、密钥 ID |

证书与密钥**不会**提交到 Git，仅通过 GitHub Secrets 注入 CI。

## 一次性：同步 Secrets 到 GitHub

```bash
bash ci/scripts/setup-github-secrets.sh
```

脚本会读取本地 `Config/` 与 `docs/配置信息.md`，并写入以下 Secrets：

- `BUILD_CERTIFICATE_BASE64` / `P12_PASSWORD` / `KEYCHAIN_PASSWORD`
- `APPLE_TEAM_ID`
- `APPSTORE_ISSUER_ID` / `APPSTORE_KEY_ID` / `APPSTORE_PRIVATE_KEY`

## 触发打包

1. **手动**：GitHub → Actions → **App Store Release** → Run workflow
2. **Tag**：`git tag v1.0.0 && git push origin v1.0.0`

## 流程说明

CI 使用 **Xcode 云签名**（`-allowProvisioningUpdates` + App Store Connect API），无需本地 `.mobileprovision` 文件。

1. 导入 P12 证书到临时 Keychain
2. 准备 API 密钥文件
3. `xcodebuild archive` + `exportArchive` 生成 IPA
4. `altool` 上传到 TestFlight / App Store Connect
