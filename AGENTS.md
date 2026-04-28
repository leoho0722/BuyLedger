# 儲存庫指引

## 專案結構與模組組織

此儲存庫仍處於初始化階段，目前尚未加入 Xcode 專案或 Swift 原始碼。現有忽略規則已針對 iOS、iPadOS、macOS 的 Apple multi-platform App 準備，並涵蓋 Xcode、Swift Package Manager 與常見相依套件工具。

新增 App 時，建議使用下列結構：

- `BuyLedger/`：放置正式 Swift 原始碼、功能模組、SwiftUI View、Model、Service 與 App 進入點。
- `BuyLedgerTests/`：放置單元測試。
- `BuyLedgerUITests/`：放置 UI 測試與端對端流程測試。
- `BuyLedger/Assets.xcassets/`：放置 App icon、顏色與圖片資產。
- `Package.swift`：只有在導入共用 Swift package，或採用 package-first 佈局時才需要加入。

請勿將建置輸出、本機 Xcode 狀態、密鑰、簽署憑證或 provisioning profile 納入 Git。

## 建置、測試與開發指令

目前尚未建立可建置的 target。加入 Xcode 專案後，可使用下列指令：

- `xcodebuild -list -project BuyLedger.xcodeproj`：檢查 schemes 與 targets。
- `xcodebuild -showdestinations -scheme BuyLedger`：檢查可用的 iOS、iPadOS 與 macOS destination。
- `xcodebuild -scheme BuyLedger -destination 'platform=iOS Simulator,name=iPhone 16' build`：建置 iOS simulator 版本。
- `xcodebuild -scheme BuyLedger -destination 'platform=iOS Simulator,name=iPad Pro (13-inch) (M4)' build`：建置 iPadOS simulator 版本。
- `xcodebuild -scheme BuyLedger -destination 'platform=macOS' build`：建置 macOS 版本。
- `xcodebuild -scheme BuyLedger -destination 'platform=iOS Simulator,name=iPhone 16' test`：執行測試。
- `swift test`：當專案含有 `Package.swift` 且模組可由 SwiftPM 測試時使用。

提交前請先執行 `git status --short`，確認只包含本次變更需要的檔案。

## 程式風格與命名慣例

Swift 程式碼請遵循 Swift API Design Guidelines。型別名稱使用 `UpperCamelCase`，屬性與函式使用 `lowerCamelCase`，測試方法名稱應清楚描述情境與預期結果。

命名請具體表達責任，例如 `TransactionListView`、`LedgerRepository`、`CurrencyFormatterService`。Swift 縮排使用四個空格。SwiftUI View 應保持小而聚焦，重複使用的 UI 請拆成獨立元件。

避免提交本機 IDE 設定、產生的 archive、環境設定檔或任何只屬於開發機器的狀態檔。

## 測試準則

單元測試放在 `BuyLedgerTests/`，UI 流程測試放在 `BuyLedgerUITests/`。測試檔名應對應被測試的型別或功能，例如 `LedgerRepositoryTests.swift` 或 `AddTransactionFlowTests.swift`。

影響帳本餘額、資料持久化、金額格式化、跨平台 UI 行為與主要使用者流程的變更都應加入測試。開啟 pull request 前，請執行完整測試指令並在 PR 說明中列出結果。

## Commit 與 Pull Request 準則

目前尚未有既有提交慣例。請使用簡潔的 Conventional Commit 風格訊息，例如 `feat: add transaction list` 或 `docs: add contributor guide`。

Pull request 應包含簡短摘要、測試結果、相關 issue 連結，以及可見 UI 變更的截圖或 simulator 錄影。每個 PR 應聚焦在單一功能或修正。

## 安全性與設定注意事項

絕對不要提交 `.env`、私鑰、provisioning profile、簽署憑證或其他敏感資料。請提交 `Package.resolved` 等 lock file，讓相依套件解析結果可重現。

## Commit 風格

使用正體中文撰寫 Conventional Commits：`<type>(<scope>): <描述>`

常用 type：`feat`（新功能）、`fix`（修正）、`refactor`（重構）、`docs`（文件）、`chore`（雜項）、`ci`（CI/CD）、`test`（測試）、`style`（排版）。

由 Codex 建立或 amend 的 commit，commit message 最後必須加入：

```text
Co-Authored-By: Codex (<model-name>) <codex@openai.com>
```

其中 `<model-name>` 必須替換為當次實際使用的模型名稱，例如 `gpt-5.5`。

description（body）使用列點格式，例如：

```text
refactor(settings-view): 設定頁面 Cupertino → Material 3 重構

- 移除所有 Cupertino 元件
- 統一採用 Material 3 Card.filled + ListTile 呈現
```
