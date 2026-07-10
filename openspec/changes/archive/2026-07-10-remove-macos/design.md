## Context

BuyLedger 的 Apple app (apps/apple) 是單一 multiplatform target，同時支援 iOS / iPadOS / macOS (原生 macOS、SUPPORTS_MACCATALYST=NO)。macOS 的實作幾乎全部藏在 `#if os(macOS)` 條件編譯 (約 22 檔) 與 2 個整檔 macOS-only view (OrdersMacView、SettingsMacView)；iPhone (compact size class) 與 iPad (regular size class) 的路徑走 `#else`，與 macOS 分支完全獨立。

產品方向收斂為只維護 iPhone / iPad 版本。因為 iOS 家族路徑與 macOS 分支獨立，移除 macOS 是一次乾淨的減法。已用多路平行分析 + iPad 防線稽核界定範圍，使用者已拍板 3 決策 (見 Decisions)。

## Goals / Non-Goals

**Goals:**

- App target 停止支援 macOS (pbxproj 縮平台 + 移除 macOS-only build setting)，維持 iPhone + iPad。
- 拆除所有 `#if os(macOS)` / `#if !os(macOS)` / `canImport(AppKit)` 條件編譯與 2 個 macOS-only 檔，使程式碼成為真正的純 iOS。
- 移除 macOS 資產、entitlements、孤兒死碼。
- test/UITest target 平台收斂；文件與 openspec 同步。
- 三平台 build 驗證改為 iPhone + iPad 兩佈局。

**Non-Goals:**

- 不移除 iPad。iPad regular 佈局 (RootSidebarLayout / regularSplitContent) 是完整功能，TARGETED_DEVICE_FAMILY 維持 "1,2"。
- 不動 Firebase 遙測、`-ObjC` linker flag、Crashlytics 符號上傳 build phase。
- 不動 SwiftData V12 / CloudKit (與平台數無關)。
- 不動跨平台通用的 Networking / DesignSystem / data-model 層。

## Decisions

**D1 — entitlements 整檔刪 + 成批移除 CODE_SIGN_ENTITLEMENTS 與沙盒設定。**
BuyLedger.entitlements 只含 `com.apple.security.network.client` (macOS App Sandbox 用，iOS 忽略)。刪整檔，並在 pbxproj 同批移除 `CODE_SIGN_ENTITLEMENTS`、`ENABLE_APP_SANDBOX`、`ENABLE_HARDENED_RUNTIME`、`ENABLE_USER_SELECTED_FILES`。
- 理由：iOS 目前無任何 entitlement 需求 (CloudKit `.disabled`、無推播、無 App Group)。
- 硬前提：刪檔與移 CODE_SIGN_ENTITLEMENTS 必須同批，否則 codesign 指向已刪檔而失敗。
- 替代方案 (未採)：保留空 entitlements 檔——多一個空檔雜訊。

**D2 — 清除所有 macOS 相關 guard，含 canImport(AppKit) 分支。**
除了 `os(macOS)` 條件外，連 Image+PhotoData.swift 與 RootFeature.swift 的 `canImport(AppKit)` 分支也拆掉：Image+PhotoData 只留 `canImport(UIKit)` 實作、RootFeature 移除 `#if canImport(AppKit) import AppKit`。
- 理由：目標是真正純 iOS，不保留跨平台寫法的雜訊。
- 風險：拆 canImport 時務必保留 UIKit 主分支，勿誤刪。

**D3 — test/UITest target 平台收斂 + build 驗證規範改寫。**
Tests/UITests 的 `SUPPORTED_PLATFORMS` 一併去 `macosx` 與未使用的 `xros xrsimulator` (visionOS)。「三平台 build」驗證改為單一 iOS target、iPhone + iPad simulator 各 build 一次確認 compact / regular 兩佈局。
- 理由：app target 不支援 visionOS，test 帶著只會讓 scheme 誤選 destination。

## Implementation Contract

**完成後可觀察的狀態 (acceptance criteria)：**

- iPhone (compact) 與 iPad (regular) simulator 皆 build-and-run 成功；BuyLedgerTests 全數通過；不再有任何 macOS build target/destination。
- iPhone 走 RootTabLayout (底部 TabView) + OrdersCompactView；iPad 走 RootSidebarLayout (NavigationSplitView 兩欄) + regularSplitContent (清單 + 詳情，含全選/批次改狀態/已選筆數多選工具列)——兩者行為與移除前一致。
- `grep -rE "os\(macOS\)|canImport\(AppKit\)|OrdersMacView|SettingsMacView|NSApp" apps/apple/BuyLedger` 於程式碼 (非 archive/歷史) 無殘留。
- App target 的 `SUPPORTED_PLATFORMS` 為 `iphoneos iphonesimulator`；無 MACOSX_DEPLOYMENT_TARGET / SUPPORTS_MACCATALYST / App Sandbox 系列 / CODE_SIGN_ENTITLEMENTS；`TARGETED_DEVICE_FAMILY` 仍為 `1,2`。
- BuyLedger.entitlements 與 10 個 AppIcon-mac 檔、assets/macos-intro.png 不存在；AppIcon Contents.json 只剩 universal 條目、asset catalog 編譯無缺檔。
- 文件 (README×2、CLAUDE×2、config.yaml) 與 monorepo-layout spec 無殘留 macOS 敘述、且仍保留 iPad regular 指引。

**iPad 防線 (最關鍵契約)：**

- 每個 `#if os(macOS) … #else … #endif` 只刪 `#if` 那半、保留 `#else`；`#else` 承載的 compact/regular 路由是 iPhone+iPad 實際畫面。
- RootSidebarLayout、OrdersView.regularSplitContent、OrdersCompactView、RootTabLayout、SettingsView、horizontalSizeClass、DashboardView.titleHeader 全數保留 (只剝其中 macOS 子分支)。

**Scope 邊界：**

- 明確在範圍內：上述 Removed/Modified 檔案與 spec、pbxproj 平台收斂、資產、entitlements、文件同步、test target 收斂。
- 明確不在範圍內：移除 iPad、動 Firebase/-ObjC/Crashlytics build phase、動 SwiftData/CloudKit、動 device family。

## Risks / Trade-offs

- [把 iPad 的 #else 當 macOS 刪掉，導致 iPad 失去佈局] → 鐵律「保留 #else、只刪 #if os(macOS)」；以 iPad simulator build-and-run 當關卡。
- [刪各檔 macOS 分支卻未同步縮 pbxproj 的 macosx，macOS 目標改用 iOS-only API 直接 build 失敗] → 拆分支與縮平台同批完成。
- [刪 entitlements 卻留 CODE_SIGN_ENTITLEMENTS 指向 → codesign 失敗] → 兩者同批移除。
- [InsightsView.titleHeader 移除 macOS 分支後變孤兒殘留] → 連函式一起刪；勿誤刪同名的 DashboardView.titleHeader (有無條件呼叫)。
- [誤動 TARGETED_DEVICE_FAMILY "2" → 砍掉 iPad] → 明列禁止；縮平台只動 SUPPORTED_PLATFORMS。
- [拆 canImport(AppKit) 時誤刪 UIKit 主分支] → 只刪 AppKit 分支、保留 canImport(UIKit) 實作。

## Migration Plan

1. 開本 change (proposal/design/specs/tasks)，monorepo-layout spec delta 於 archive 時套用。
2. 刪 2 個 macOS-only 檔與 macOS 資產 (file-system-synchronized group，刪檔自動更新)。
3. 拆 22 檔 Swift 條件編譯 (保留 #else / 去 !os(macOS) guard / 刪 macOS .frame 塊 / 拆 canImport(AppKit))；刪 InsightsView.titleHeader 孤兒；拆進入點 (留 Firebase configure)；去 RootFeatureTests guard。
4. 縮 Xcode 平台設定 (8 處 SUPPORTED_PLATFORMS、macOS-only build setting、CODE_SIGN_ENTITLEMENTS)，與步驟 3 同批；勿動 device family。
5. iPhone + iPad 兩佈局 build-and-run + 測試驗證 (build number 遞增規則見 apps/apple/CLAUDE.md)。
6. 文件與 spec 同步；apply 後 archive 套用 delta。

回滾策略：本 change 以刪除/拆分支為主，回滾即 git revert；不涉及資料或 schema 變更，回滾風險低。

## Open Questions

- 無阻塞性未決問題。
