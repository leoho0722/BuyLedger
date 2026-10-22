## Why

**沒有隱私資訊清單，而 App 使用了需具名理由的 API。** 專案沒有 `PrivacyInfo.xcprivacy`，但設定的儲存直接讀寫使用者預設值，那是 Apple 明訂必須在清單中宣告使用理由的類別。缺件會在送審時被擋。

**遙測的實際狀態與設定不符。** Firebase 設定檔中的分析啟用旗標被設為關閉，但依官方文件，iOS 端控制分析收集的是主資訊清單中的另一個鍵，或執行期的設定方法；設定檔中的那個旗標不是 iOS 的控制項。而本專案的主資訊清單沒有那個鍵。也就是說：**分析收集實際上是開著的，而設定檔看起來像是關的**。這比單純沒關更糟，因為它會讓人以為已經關了。

**使用者沒有任何關閉遙測的入口，也看不到收了什麼。** 三支遙測 SDK 在啟動時初始化，設定頁沒有任何相關開關或說明。

**AI 總結把訂單資料送往第三方雲端，介面上沒有任何揭露。** 送出的內容是目前列表的商品明細，每行為類別、商品名稱、數量、單價與幣別；不含客戶姓名。使用者在按下按鈕時無從得知資料會離開裝置。

## What Changes

- 新增隱私資訊清單，宣告需具名理由的 API 使用（使用者預設值），並依實際保留的遙測 SDK 宣告其蒐集的資料類型與追蹤網域。
- 修正遙測的實際狀態與設定不符：改以主資訊清單的正確鍵與執行期設定方法控制三支 SDK 的收集狀態，讓設定真的生效。預設維持現行行為（收集啟用）。
- 設定頁新增「隱私」區塊：提供遙測開關與一段說明，寫明收集了什麼、用途為何。開關的狀態持久化並在啟動時套用。
- AI 總結的呈現處常駐揭露：說明按下後會把目前列表的商品明細（類別、品名、數量、單價、幣別）送往第三方雲端服務，且不含客戶姓名。揭露內容與實際送出的欄位綁定，欄位改變時揭露必須同步。

## Non-Goals

- 不移除任何 Firebase SDK。四個產品全部保留。
- 不改變遙測的預設狀態。維持現行的啟用，開關供使用者自行關閉。
- 不新增任何自訂事件、使用者屬性或效能追蹤。目前零自訂埋點，本次不增加。
- 不改變 AI 總結送出的內容。揭露描述現況，不縮減也不擴大送出範圍。
- 不處理 API 金鑰隨產物出貨的暴露面，那屬於金鑰暴露緩解的範圍。
- 不做首次啟動的同意流程。

## Capabilities

### New Capabilities

- `telemetry-transparency`: 遙測與第三方資料外送的透明度契約，涵蓋隱私資訊清單必須隨產物出貨、遙測狀態的宣告必須與實際行為一致、使用者必須有可抵達的關閉入口，以及外送資料的揭露必須與實際送出的欄位一致。

### Modified Capabilities

（無）

## Impact

- Affected specs: `telemetry-transparency`（新增）
- Affected code:
  - New:
    - apps/ios/BuyLedger/Resources/PrivacyInfo.xcprivacy
  - Modified:
    - apps/ios/BuyLedger/Resources/Info.plist
    - apps/ios/BuyLedger/App/AppLaunchConfigurator.swift
    - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
    - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
    - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
    - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
    - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID.swift
    - apps/ios/BuyLedger.xcodeproj/project.pbxproj
    - apps/ios/BuyLedger/Resources/Localizable.xcstrings
    - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
    - apps/ios/CLAUDE.md
    - apps/ios/README.md
  - Removed: （無）
- 不涉及 SwiftData schema 或資料形狀。
- 已查證的實作約束：效能監測的自動埋點開關必須在 Firebase 初始化之前設定，因此遙測偏好的讀取必須早於初始化；分析的執行期設定會持久化並覆寫資訊清單的值。
- 次序約束：本變更與金鑰暴露緩解、App 鎖定兩案都會改動設定頁，三者分屬不同批次且各自只新增自己的區塊，不重排既有列。
