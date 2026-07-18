## Why

BuyLedger 目前只有正體中文硬編碼介面，無法讓偏好英文的使用者閱讀，也無法在 App 內選擇語言。導入 String Catalog 與可持久化的語言偏好後，使用者可在設定頁立即切換正體中文或英文，而不必修改系統語言。

## What Changes

- 新增 String Catalog，提供正體中文 (預設) 與英文的使用者可見字串
- 新增可持久化的 App 語言偏好，預設為正體中文
- 在「更多 → 設定」加入語言 Picker，互動形式比照現有介面模式 Picker
- 在 App 根層注入所選 locale，使切換立即更新 SwiftUI 介面與 locale-aware 格式
- 修正 English 實機模式中跨頁面殘留正體中文的問題，並以全頁面 runtime traversal 驗證靜態文案與日期／數值格式均跟隨 App 語言
- 補齊 More、Lookup 選擇器、訂單新增／編輯與訂單詳情流程中回報的殘留靜態正體中文，並把這些流程納入英文 runtime 覆蓋契約
- 補上 reducer、持久化與語言顯示值測試，並以實機 build-and-run 驗收

## Capabilities

### New Capabilities

- `app-localization`: 定義 App 支援語言、預設語言、設定頁切換、持久化及即時套用行為

### Modified Capabilities

(none)

## Impact

- Affected specs: app-localization
- Affected code:
  - New: apps/ios/BuyLedger/Resources/Localizable.xcstrings, apps/ios/BuyLedger/Features/Settings/AppLanguage.swift
  - Modified: apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift, apps/ios/BuyLedger/Features/Settings/SettingsView.swift, apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift, apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift, apps/ios/BuyLedger/Features/App/RootView.swift, apps/ios/BuyLedger/Features/More/MoreView.swift, apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift, apps/ios/BuyLedger/Features/Orders/**/*.swift 的 presentation boundaries 與 locale-aware formatting、apps/ios/BuyLedgerTests/SettingsFeatureTests.swift、apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift、apps/ios/BuyLedger.xcodeproj/project.pbxproj、apps/ios/BuyLedger/Resources/Info.plist
  - Removed: none
