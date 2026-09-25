## Summary

把 `apps/ios/BuyLedger/Features/` 下六個小型 Feature (FX、Quote、Settings、AISummary、Customers、More) 的 17 個 Swift 檔與 6 個對應單元測試檔對齊 `/ios-dev-kit`，並把 TCA 的 Action 分組、父子溝通與 View 邊界定型成第 4 至 8 步照抄的範本。這是 ios-dev-kit 修正順序十步計劃的第 3 步，前兩步 `core-codegen-style-compliance` 與 `shared-designsystem-style-compliance` 已結案。

## Motivation

2026-09-14 全庫審查在這六個區域記錄 **491 筆待修項** (實測值，由報告資料集依區域與測試檔名篩出，已排除 commit `291d841` 修掉的尾隨空白)：production 17 檔 281 筆、單元測試 6 檔 210 筆；合計必擋 184、違規 274、建議 25、已登記例外 8。

排在第 3 位的理由是**範圍小、彼此獨立，適合先把 TCA 寫法定型**。後面的 Lookups、Campaigns、Orders、Dashboard 都要做同樣的 Action 分組與 View 瘦身，範本若在大 Feature 上才摸索，會在 8,000 行的 Orders 裡反覆重做。

四類問題必須現在處理：

1. **Action 沒有分組，父層直接操作子層**：五個 reducer 的使用者操作、內部回應與交給父層的結果全部平放；`FxView` 的重試鍵送的是畫面出現用的 `.task`；`CustomersView` 直接送 `.delegate`；`RootFeature` 在啟動與總覽下拉重整時送 `.settings(.task)`，又直接攔截 `.customers(.task)`。`tca-architecture.md` 規定使用者操作只能由對應 View 送出、父層只處理子層的 `.delegate`，目前沒有任何守門。
2. **View 承擔格式化與業務判斷**：`FxView` 在 View 內格式化匯率與時間 (兩份相同的日期樣式)、過濾清單 (連帶一個永遠不會執行的分支)；`QuoteView` 在 View 內決定建議售價顯示破折號或金額；`CustomersView` 自寫日期格式化，與 `OrderFormatters.shortDate` 是同一條規則的第二份實作。`FxView` 393 行、`QuoteView` 444 行 (2026-09-21 實測，不含檔頭與空行)，超過單檔 300 行上限。
3. **設定頁有一個實際缺陷**：月度淨獲利目標的註解、`SettingsSnapshot.default` 與 State 預設都寫 80,000，但讀取用 `UserDefaults.double(forKey:)`，key 不存在時回 0，專案也沒有 `register(defaults:)`，新安裝實際拿到 0，總覽不顯示進度條。
4. **位置與命名偏離規範**：`OllamaClient` 這個遠端服務入口放在 `Features/AISummary/`，還偽造 `NSURLErrorDomain` 錯誤 (違反 `apps/ios/CLAUDE.md`)；`SettingsStorage` 不是已定義的角色後綴；`...Twd`、`useAiSummary` 違反縮寫大小寫與 Bool 命名；另有 60 筆非規範 MARK、64 筆缺 doc comment、60 個測試缺 Given／When／Then。

## Proposed Solution

依使用者 2026-09-21 三項裁決與 2026-09-14 的四項既有裁決執行。

**TCA 分組定型 (範本)**

- 五個 reducer 的 `Action` 依 `binding` → `view(View)` → `delegate(Delegate)` → 子 Feature／`destination` → 內部回應 (字母序) 排列；View 只送 `.view(...)`，焦點與表單值改用 `$store` 綁定，不再手組 `.binding(.set(...))`。
- `body` 只組合 reducer，邏輯移到 `core(state:action:)`；超過十行的分支抽成回傳 `Effect<Action>` 的 Private Method；`@Dependency` 一律在 `Dependencies` 區宣告。
- 同一次請求的成功與失敗合併成單一 `...Response(Result<..., ...>)` case。`FxFeature` 與 `QuoteFeature` 的 `Action` 因此不再遵循 `Equatable`，`RootFeature.Action` 跟著移除 `Equatable` (必要連帶，只改這一個遵循)。
- FX 與報價的幣別選擇 sheet 改由 `@Presents var destination` 驅動，不再用 `showsCurrencySheet` 布林。
- **父層不送子層 action (使用者裁決)**：啟動時已讀出的設定快照與 App 版本字串整份交給 `SettingsFeature.State` 建構，`RootFeature` 不再送 `.settings(.task)`；客戶頁的載入需求改以 `.delegate(.ordersLoadRequested)` 交給 `RootFeature` 轉發。新增原始碼掃描守門：已遷移 Feature 的 View 只送 `.view(...)`、任何 reducer 都不送或攔截子層的 `.view(...)`。

**View 瘦身與格式化收斂**

- `FxView`、`QuoteView` 以獨立 View 型別拆分 (不用跨檔 extension)，所有 `body` 只放大框架，body 內不再宣告區域變數。
- 格式化移出 View：月日短日期收斂到新的 `BLFormatters.shortDate(_:locale:)` (`OrderFormatters.shortDate` 改為轉呼叫它)；匯率、快照時間與預設金額收進新的 `FxFormatters`；報價的建議售價改由 State 暴露原始 `Decimal?`，提示文字改由 State 的列舉決定。
- 匯率換算的重複實作收斂到 `FxRateSnapshot.twdRate(for:)`。

**缺陷修正與位置命名**

- **月度目標讀取修正 (使用者裁決)**：key 從未寫入時回 80,000，已寫入的值 (含 0) 照舊尊重；以可注入 `UserDefaults` 的純函式實作並補單元測試。
- `OllamaClient` 與其請求／回應型別搬到 `Core/Networking/`，型別改名 `OllamaChatRequest`／`OllamaChatResponse`，網址改為字面值常數、測試預設值改用自有錯誤 domain。
- `SettingsStorage` 改名 `SettingsStore` (留在 `Features/Settings/`，因為它引用 `AISummaryModelCatalog`)；`monthlyProfitGoalTwd` → `monthlyProfitGoalTWD`、`useAiSummary` → `isAISummaryEnabled`，**UserDefaults 的 key 字串一律不變**，既有使用者的設定不受影響。
- `CustomerRow` 獨立成檔；`AISummaryFeature` 對 Core `APIError` 的擴充收回 Feature 內部。

**測試跟著改**

- 六個測試檔補齊 doc comment 與 Given／When／Then、改用 case key path `receive`、參數化重複輸入、測試替身改用 `LockIsolated`、移除 `Task.yield` 輪詢；修掉 `FxFeatureTests` 用預設快照導致無法區分行為的假測試。
- 新增 `LedgerOrder.fixture(...)`，`AppLanguage` 與 `CustomerRow` 的測試各自獨立成檔。
- **測試方法維持單段 lowerCamel (使用者裁決)**，差異登記進 `apps/ios/CLAUDE.md`。

## Non-Goals

見 design.md 的 Goals / Non-Goals。

## Impact

- Affected specs: app-layer-boundaries, ai-order-summary, app-settings (新增)
- Affected code:
  - Modified:
    - apps/ios/BuyLedger/Features/FX/FxFeature.swift
    - apps/ios/BuyLedger/Features/FX/FxView.swift
    - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
    - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
    - apps/ios/BuyLedger/Features/Settings/AISummaryModelCatalog.swift
    - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
    - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
    - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
    - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
    - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
    - apps/ios/BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift
    - apps/ios/BuyLedger/Features/Customers/CustomersFeature.swift
    - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
    - apps/ios/BuyLedger/Features/More/MoreView.swift
    - apps/ios/BuyLedger/Features/App/RootFeature.swift (State 建構參數、移除兩處 `.settings(.task)`、客戶 delegate 轉發、onChange 改名、`Action` 移除 `Equatable`)
    - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift (只改 `SettingsStore` 與 `isAISummaryEnabled` 兩個名稱)
    - apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift (只改 `shortDate` 轉呼叫)
    - apps/ios/BuyLedger/App/BuyLedgerApp.swift
    - apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift (只改型別與欄位名稱)
    - apps/ios/BuyLedger/Core/Domain/FxRateSnapshot.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLFormatters.swift
    - apps/ios/BuyLedger/Shared/Extensions/Bundle+Extensions.swift
    - apps/ios/BuyLedgerTests/FxFeatureTests.swift
    - apps/ios/BuyLedgerTests/QuoteFeatureTests.swift
    - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
    - apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift
    - apps/ios/BuyLedgerTests/CustomersFeatureTests.swift
    - apps/ios/BuyLedgerTests/OllamaClientTests.swift
    - apps/ios/BuyLedgerTests/RootFeatureTests.swift (只改受 State 建構、設定載入與客戶 delegate 影響的測試)
    - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift (只改兩個名稱)
    - apps/ios/BuyLedgerTests/SnapshotTests.swift (開工前新增兩條匯率工具 snapshot 測試；實作時只改 `QuoteFeature.State` 的參數標籤)
    - apps/ios/BuyLedgerTests/BLFormattersTests.swift
    - apps/ios/CLAUDE.md
    - apps/ios/README.md
    - .claude/rules/ios-unit-tests.md
  - New:
    - apps/ios/BuyLedger/Features/FX/FxFormatters.swift
    - apps/ios/BuyLedger/Features/FX/Components/FxStatusBanner.swift
    - apps/ios/BuyLedger/Features/FX/Components/FxRatesList.swift
    - apps/ios/BuyLedger/Features/Quote/Components/QuoteStatusBanner.swift
    - apps/ios/BuyLedger/Features/Quote/Components/QuoteBreakdownCard.swift
    - apps/ios/BuyLedger/Features/Customers/CustomerRow.swift
    - apps/ios/BuyLedger/Features/Settings/SettingsStore.swift (由 SettingsStorage.swift 改名)
    - apps/ios/BuyLedger/Core/Networking/OllamaClient.swift (由 Features/AISummary 搬入)
    - apps/ios/BuyLedger/Core/Networking/OllamaChatRequest.swift
    - apps/ios/BuyLedger/Core/Networking/OllamaChatResponse.swift
    - apps/ios/BuyLedgerTests/ActionGroupingScanTests.swift
    - apps/ios/BuyLedgerTests/AppLanguageTests.swift
    - apps/ios/BuyLedgerTests/CustomerRowTests.swift
    - apps/ios/BuyLedgerTests/SettingsStoreTests.swift
    - apps/ios/BuyLedgerTests/LedgerOrder+Fixture.swift
    - apps/ios/BuyLedgerTests/FxRateSnapshotTests.swift
    - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ 下兩張匯率工具基準圖 (task 0.5 在改動前錄製)
  - Removed:
    - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
    - apps/ios/BuyLedger/Features/AISummary/OllamaClient.swift
    - apps/ios/BuyLedger/Features/AISummary/OllamaDTO.swift
    - apps/ios/BuyLedgerTests/BundleExtensionsTests.swift (使用者裁決把 `appVersion(from:)` 內聯後失去測試對象)
