<!-- SPECTRA:START v1.0.2 -->

# Spectra Instructions

This project uses Spectra for Spec-Driven Development(SDD). Specs live in `openspec/specs/`, change proposals in `openspec/changes/`.

## Use `$spectra-*` skills when:

- A discussion needs structure before coding → `$spectra-discuss`
- User wants to plan, propose, or design a change → `$spectra-propose`
- Tasks are ready to implement → `$spectra-apply`
- There's an in-progress change to continue → `$spectra-ingest`
- User asks about specs or how something works → `$spectra-ask`
- Implementation is done → `$spectra-archive`
- Commit only files related to a specific change → `$spectra-commit`

## Workflow

discuss? → propose → apply ⇄ ingest → archive

- `discuss` is optional — skip if requirements are clear
- Requirements change mid-work? `ingest` → resume `apply`

## Parked Changes

Changes can be parked（暫存）— temporarily moved out of `openspec/changes/`. Parked changes won't appear in `spectra list` but can be found with `spectra list --parked`. To restore: `spectra unpark <name>`. The `$spectra-apply` and `$spectra-ingest` skills handle parked changes automatically.

<!-- SPECTRA:END -->

# 儲存庫指引

## 專案結構與模組組織

此儲存庫已建立 Xcode Multiplatform 專案，目標平台為 iOS、iPadOS 與 macOS。專案主要技術棧為 Swift 6 + SwiftUI、TCA（Swift Composable Architecture）、SwiftData + CloudKit 與 Swift Charts。Xcode 專案檔位於 `BuyLedger/BuyLedger.xcodeproj`，scheme 名稱為 `BuyLedger`。

目前主要結構如下：

- `BuyLedger/BuyLedger.xcodeproj/`：Xcode 專案檔。`project.pbxproj` 應納入版本控制，`xcuserdata/` 不應提交。
- `BuyLedger/BuyLedger/`：正式 App 原始碼、SwiftUI View、SwiftData Model、資產與 entitlements。
- `BuyLedger/BuyLedger/BuyLedgerApp.swift`：App 進入點與 SwiftData `ModelContainer` 設定。
- `BuyLedger/BuyLedger/ContentView.swift`：目前的起始畫面。
- `BuyLedger/BuyLedger/Item.swift`：目前 Xcode 範本產生的 SwiftData model。
- `BuyLedger/BuyLedger/Assets.xcassets/`：App icon、顏色與圖片資產。
- `BuyLedger/BuyLedgerTests/`：單元測試。
- `BuyLedger/BuyLedgerUITests/`：UI 測試與啟動畫面測試。
- `Package.swift`：只有在導入共用 Swift package，或採用 package-first 佈局時才需要加入。

請勿將建置輸出、本機 Xcode 狀態、密鑰、簽署憑證或 provisioning profile 納入 Git。若未來建立 shared scheme，應提交 `xcshareddata/xcschemes/`。

## 主要技術棧

- Swift 6 + SwiftUI：新程式碼應以 Swift 6 concurrency 檢查為準，優先使用 SwiftUI、`async/await`、`@MainActor` 與平台原生 SwiftUI API。
- TCA（Swift Composable Architecture）：功能狀態、商業邏輯、副作用與依賴注入應放在 reducer 與 dependency 中；SwiftUI View 保持宣告式與輕量。
- SwiftData + CloudKit：SwiftData model 是本機持久化核心，CloudKit 同步相關 schema、entitlements、container 與 migration 需要同步檢查。
- Swift Charts：圖表 View 只負責呈現，資料彙總、分組、排序與格式化應放在可測試的 feature/domain 層。

## 建置、測試與開發指令

常用指令如下：

- `xcodebuild -list -project BuyLedger/BuyLedger.xcodeproj`：檢查 schemes 與 targets。
- `xcodebuild -showdestinations -project BuyLedger/BuyLedger.xcodeproj -scheme BuyLedger`：檢查可用的 iOS、iPadOS 與 macOS destinations。
- `xcodebuild -project BuyLedger/BuyLedger.xcodeproj -scheme BuyLedger -destination 'platform=iOS Simulator,name=iPhone 16' build`：建置 iOS simulator 版本。
- `xcodebuild -project BuyLedger/BuyLedger.xcodeproj -scheme BuyLedger -destination 'platform=iOS Simulator,name=iPad Pro (13-inch) (M4)' build`：建置 iPadOS simulator 版本。
- `xcodebuild -project BuyLedger/BuyLedger.xcodeproj -scheme BuyLedger -destination 'platform=macOS' build`：建置 macOS 版本。
- `xcodebuild -project BuyLedger/BuyLedger.xcodeproj -scheme BuyLedger -destination 'platform=iOS Simulator,name=iPhone 16' test`：執行測試。
- `swift test`：當專案含有 `Package.swift` 且模組可由 SwiftPM 測試時使用。

提交前請先執行 `git status --short`，確認只包含本次變更需要的檔案。

## 程式風格與命名慣例

Swift 程式碼請遵循 Swift API Design Guidelines。型別名稱使用 `UpperCamelCase`，屬性與函式使用 `lowerCamelCase`，測試方法名稱應清楚描述情境與預期結果。

命名請具體表達責任，例如 `TransactionListView`、`LedgerRepository`、`CurrencyFormatterService`。Swift 縮排使用四個空格。SwiftUI View 應保持小而聚焦，重複使用的 UI 請拆成獨立元件。

跨平台 UI 應優先使用 SwiftUI 條件編譯與平台慣用容器，例如 `#if os(macOS)`、`NavigationSplitView` 與 iOS/iPadOS 的 toolbar placement。TCA feature 應以 `Feature`、`State`、`Action`、`Reducer`、`Dependency` 清楚切分，避免把商業邏輯放在 SwiftUI View 中。SwiftData schema 或持久化行為變更時，應同步檢查 migration、preview 與測試資料。

避免提交本機 IDE 設定、產生的 archive、環境設定檔或任何只屬於開發機器的狀態檔。

## 測試準則

單元測試放在 `BuyLedger/BuyLedgerTests/`，UI 流程測試放在 `BuyLedger/BuyLedgerUITests/`。測試檔名應對應被測試的型別或功能，例如 `LedgerRepositoryTests.swift` 或 `AddTransactionFlowTests.swift`。

影響帳本餘額、資料持久化、CloudKit 同步、金額格式化、圖表資料彙總、跨平台 UI 行為與主要使用者流程的變更都應加入測試。TCA reducer 應使用 `TestStore` 驗證 action flow、state mutation 與 effects；SwiftData 測試應優先使用 in-memory container；CloudKit 相關邏輯應透過 dependency 抽象，避免單元測試直接依賴真實 iCloud 狀態。開啟 pull request 前，請執行完整測試指令並在 PR 說明中列出結果。

## Commit 與 Pull Request 準則

請使用簡潔的 Conventional Commit 風格訊息，例如 `feat: add transaction list` 或 `docs: update contributor guide`。

Pull request 應包含簡短摘要、測試結果、相關 issue 連結，以及可見 UI 變更的截圖或 simulator 錄影。每個 PR 應聚焦在單一功能或修正。

## 安全性與設定注意事項

絕對不要提交 `.env`、私鑰、provisioning profile、簽署憑證或其他敏感資料。CloudKit container、iCloud capability 與 entitlements 的變更需要在 PR 中明確說明。請提交 `Package.resolved` 等 lock file，讓 TCA 等相依套件解析結果可重現。

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
