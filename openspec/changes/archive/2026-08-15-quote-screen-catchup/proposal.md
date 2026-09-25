## Why

報價試算頁是全 App 唯一不接觸本機資料庫、也不在主要流程上的畫面。歷次的介面規範、設計系統與財務語意改造掃過時全部跳過了它，因此別處已經修掉的問題在這裡完整保留。

**主卡的白字違反專案早已訂下的對比地板。** 該卡底色是在畫面內直接以兩個系統色組成的漸層，而非設計系統中已壓暗並受測試保護的具名資源。實測白字對兩端的比值：淺色外觀下為 2.22 比 1 與 2.57 比 1，深色外觀下更低，為 2.02 比 1 與 1.99 比 1。專案的地板是 4.5 比 1。部分文字另外套了不透明度調整，實際值更低。

值得注意的是，規則本身早就涵蓋這個情形：對比要求明訂是對「它實際疊合的背景」計算，也明訂不得以降低不透明度表達層級。設計系統中既有的主卡漸層資源實測為 5.42 比 1 與 6.09 比 1，本來就是為此壓暗過的。報價頁單純沒有遵守，也沒有用那份資源。

**匯率不可用時只顯示破折號。** 不顯示假數字符合政策，但沒有說明原因也沒有重試途徑。專案的規則同樣早已要求「載入失敗的畫面須在畫面內提供重試」，而該規則的既有情境只寫到匯率頁，報價頁沒有比照。

**設計系統的採用落後。** 該頁自行組色、自行格式化金額，而非取用設計系統的語意色與共用格式化。

## What Changes

- 主卡底色改用設計系統中既有、已壓暗且受對比測試保護的主卡漸層資源，取代畫面內直接以系統色組成的漸層。
- 移除主卡文字上會進一步降低對比的不透明度調整；層級改由字重與字級表達。
- 匯率不可用時補上原因說明與畫面內的重試途徑，取代目前只有破折號的呈現。
- 該頁改用設計系統的語意色與共用金額格式化，不自行組色也不自行格式化。

## Non-Goals

- 不修改對比規則本身。查證後確認既有規則已明訂「對實際疊合的背景計算」且「不得以不透明度表達層級」，報價頁屬違規而非規則缺漏；再新增一條指名此頁的條款只會多一個示範點。
- 不擴大對比守門的受測範圍。把受測對象由具名資源全面擴及任意畫面內組成的配色 (不論來源)、或改為原始碼掃描等一般化機制，屬測試有效性修復的範圍。本變更僅因把 hero 卡底色抽成單一 `ViewModifier` 而需要讓既有的白字漸層斷言改綁到新入口，這是隨底色搬家而來的機械性更新，不引入新的一般化守門機制。
- 不改動報價的計算公式與欄位語意。那些由財務公式定調的變更處理，本變更排在其後只承接結果。
- 不改變報價頁的資訊架構或欄位順序。
- 不處理匯率取得本身的韌性（逾時、重試策略），那屬於網路層韌性的範圍。
- 不重新設計主卡的視覺語言，只把它換成既有的受測資源。

## Capabilities

### New Capabilities

（無）

### Modified Capabilities

- `content-truthfulness`: 畫面內重試的既有要求補上報價頁的情境，使該規則不再只以匯率頁為例。

## Impact

- Affected specs: `content-truthfulness`（修改）
- Affected code:
  - Modified:
    - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
    - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
    - apps/ios/BuyLedgerTests/QuoteFeatureTests.swift
    - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
    - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
    - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
    - apps/ios/BuyLedgerTests/SnapshotTests.swift
    - apps/ios/BuyLedgerUITests/Screens/QuoteScreen.swift
    - apps/ios/CLAUDE.md
  - New:
    - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLHeroCardBackground.swift
  - Removed: （無）
- 不涉及 SwiftData schema 或資料形狀。
- 報價頁的視覺快照需重錄。
- 對比規則與其守門皆不在本變更內：規則已足夠，守門的擴大由測試有效性修復負責，本變更排在其後，因此該守門會直接驗證這一頁的修正結果。
- 次序約束：本變更必須排在財務公式定調之後（該變更改動同頁的計算與型別），並排在共用格式化收斂與設計 token 收斂之前，使報價頁只被改一次結構。
