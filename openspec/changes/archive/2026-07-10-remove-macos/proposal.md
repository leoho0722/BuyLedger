## Why

繼移除 Web 與 Backend 後，產品方向進一步收斂為只維護 iPhone 與 iPad (iOS/iPadOS 通用) 版本，不再支援 macOS。App 是單一 multiplatform target，macOS 幾乎全藏在條件編譯與 2 個 macOS-only 檔裡；保留它只是持續墊高 build 時間、UI 分支複雜度與文件負擔。此時移除單純，因為 iOS 家族 (iPhone compact / iPad regular) 的程式路徑與 macOS 分支完全獨立。

## What Changes

- **BREAKING** App target 停止支援 macOS：pbxproj 的 `SUPPORTED_PLATFORMS` 移除 `macosx`，並移除隨附的 macOS-only build setting (MACOSX_DEPLOYMENT_TARGET、LD_RUNPATH[sdk=macosx*]、SUPPORTS_MACCATALYST、App Sandbox / Hardened Runtime / User-Selected-Files、CODE_SIGN_ENTITLEMENTS)。TARGETED_DEVICE_FAMILY 維持 "1,2" (保留 iPad)。
- 刪除 2 個 macOS-only view (OrdersMacView、SettingsMacView)、10 個 macOS app icon 與 root 的 macOS 截圖素材、只含 macOS 沙盒 key 的 entitlements 檔。
- 拆除約 22 個 Swift 檔的 `#if os(macOS)` 條件編譯：二選一者保留 `#else` (iPhone/iPad 路徑)、`#if !os(macOS)` 去 guard 保留內容、macOS 視窗尺寸/樣式塊整刪。連 `canImport(AppKit)` 分支一併拆除 (只留 UIKit 實作)。移除進入點的 macOS Scene、選單機制與 delegate 分支 (保留 iOS 進入點與 Firebase 初始化)。
- 移除移除 macOS 分支後浮現的孤兒函式 (InsightsView.titleHeader)。
- test/UITest target 的 `SUPPORTED_PLATFORMS` 一併收斂 (去 macosx 與未使用的 visionOS xros/xrsimulator)。
- 文件與 openspec 同步：README、CLAUDE、config.yaml 的 macOS 措辭與段落，monorepo-layout spec 的三平台 build scenario。

## Non-Goals

- 不移除 iPad (iPadOS)。iPad 屬 iOS 家族、regular size class 佈局 (RootSidebarLayout / regularSplitContent) 完整保留；絕不改動 TARGETED_DEVICE_FAMILY 的 "2"。
- 不動 Firebase 遙測 (Core / Crashlytics / Analytics / Performance)、`OTHER_LDFLAGS = -ObjC` 與 Crashlytics 符號上傳 build phase (上一 change 已保留)。
- 不改動 SwiftData V12 schema 或 CloudKit 設定 (CloudKit `.disabled`、遷移 per-device forward-only、與支援平台數無關)。
- 不移除跨平台通用的 Networking / DesignSystem / data-model 產生層。

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `monorepo-layout`: 把「All three Apple platforms still build after relocation」scenario 由 iOS / iPadOS / macOS 三平台改為 iOS + iPadOS 兩平台 build 驗證

## Impact

- Affected specs: monorepo-layout (修改三平台 build scenario)
- Affected code:
  - Removed:
    - apps/apple/BuyLedger/Features/Orders/OrdersMacView.swift
    - apps/apple/BuyLedger/Features/Settings/SettingsMacView.swift
    - apps/apple/BuyLedger/Resources/BuyLedger.entitlements
    - apps/apple/BuyLedger/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-mac-16.png
    - apps/apple/BuyLedger/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-mac-16@2x.png
    - apps/apple/BuyLedger/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-mac-32.png
    - apps/apple/BuyLedger/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-mac-32@2x.png
    - apps/apple/BuyLedger/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-mac-128.png
    - apps/apple/BuyLedger/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-mac-128@2x.png
    - apps/apple/BuyLedger/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-mac-256.png
    - apps/apple/BuyLedger/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-mac-256@2x.png
    - apps/apple/BuyLedger/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-mac-512.png
    - apps/apple/BuyLedger/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-mac-512@2x.png
    - assets/macos-intro.png
  - Modified:
    - apps/apple/BuyLedger.xcodeproj/project.pbxproj
    - apps/apple/BuyLedger/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json
    - apps/apple/BuyLedger/App/BuyLedgerApp.swift
    - apps/apple/BuyLedger/App/AppDelegate.swift
    - apps/apple/BuyLedger/Features/App/RootFeature.swift
    - apps/apple/BuyLedger/Features/App/RootView.swift
    - apps/apple/BuyLedger/Features/App/RootSidebarLayout.swift
    - apps/apple/BuyLedger/Features/Orders/OrdersView.swift
    - apps/apple/BuyLedger/Features/Orders/OrdersCompactView.swift
    - apps/apple/BuyLedger/Features/Orders/OrderEditView.swift
    - apps/apple/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
    - apps/apple/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
    - apps/apple/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
    - apps/apple/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
    - apps/apple/BuyLedger/Features/Orders/Components/LookupItemEditorSheet.swift
    - apps/apple/BuyLedger/Features/Dashboard/DashboardView.swift
    - apps/apple/BuyLedger/Features/Insights/InsightsView.swift
    - apps/apple/BuyLedger/Features/More/MoreView.swift
    - apps/apple/BuyLedger/Features/AISummary/AISummaryView.swift
    - apps/apple/BuyLedger/Features/Settings/SettingsView.swift
    - apps/apple/BuyLedger/Features/FX/FxView.swift
    - apps/apple/BuyLedger/Features/Lookups/LookupManagementView.swift
    - apps/apple/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
    - apps/apple/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
    - apps/apple/BuyLedger/Shared/DesignSystem/Foundations/Image+PhotoData.swift
    - apps/apple/BuyLedger/Features/Campaigns/CampaignFeature.swift
    - apps/apple/BuyLedger/Features/Orders/Components/OrderDetailView.swift
    - apps/apple/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
    - apps/apple/BuyLedgerTests/RootFeatureTests.swift
    - apps/apple/README.md
    - apps/apple/CLAUDE.md
    - README.md
    - CLAUDE.md
    - openspec/config.yaml
