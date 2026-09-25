## Why

測試資產的數量給人的印象遠高於它實際的保護力。逐一檢視後，每一道守門都只驗「作者當時想到的那些」，而不是「全部」：

**七十三處關閉了狀態窮舉檢查。** 分佈於十三個測試檔，其中訂單功能的測試檔就佔三十處。關閉之後，非預期的狀態突變不會讓測試失敗，等於只驗證了作者明確寫出來的那幾個欄位有變，其餘欄位被意外改動時測試照樣通過。

**效能測試沒有任何基準檔。** 測試使用會與基準比較的量測機制，但專案裡一個基準檔都沒有。沒有基準就沒有比較對象，這些量測永遠不會失敗，只是在跑。

**一支介面測試在它守護的機制被移除後變成恆真。** 該測試的文件註解描述了一套「沿視圖階層逐層過濾、由背景層承接收鍵盤」的手勢實作，而那套實作已在鍵盤收起改寫時整個移除。註解引用的過濾函式在全專案已不存在，測試卻仍斷言「點擊後鍵盤仍在」。機制都沒了，鍵盤當然不會被收起，這條斷言再也不可能失敗。

**本地化守門靠硬編字串清單。** 測試逐一檢查一份人工維護的必備字串清單是否在目錄中完整，因此只保護清單裡的那些。平台指引自己也記載了這個限制：它抓不到「程式碼有用但目錄沒收錄」的漏字，而那正是英文模式露出中文的成因。

**對比守門的掃描對象是具名色彩資源。** 測試對主卡漸層的兩個具名資源做斷言，而全專案的漸層資源也確實只有這兩個。真正的缺口不是漏掉哪個資源，而是畫面上直接以系統色組出的漸層根本不在資源清單裡，因而完全不在掃描範圍內。

## What Changes

- 恢復十三個測試檔中關閉的狀態窮舉檢查。確有並行副作用而必須關閉時，改為在關閉處以註解寫明並行效果的名稱，使關閉成為有理由的例外而非預設。
- 新增一道守門，把關閉窮舉檢查的處數上限鎖在定案值，使這個數字只能下降不能上升。
- 為效能測試建立基準檔，讓量測真的有比較對象；同時在測試計畫層面確認效能測試不在主回歸中執行。
- 修復那支恆真的介面測試：移除描述已不存在機制的註解，並把斷言改為驗證現行的三條收起路徑，使它重新具備失敗的能力。
- 本地化守門改為以掃描程式碼中的字串字面值為基礎，找出「程式碼有用但目錄沒收錄」的漏字，取代人工維護的必備清單。
- 對比守門的涵蓋範圍由具名色彩資源擴及畫面上直接以系統色組成的漸層，使不經資源目錄的配色也受同一條地板約束。

## Non-Goals

- 不新增功能面的測試案例。本次修的是既有守門的有效性，不是覆蓋率的廣度。
- 不改動任何產品程式碼的行為。對比守門擴大範圍後若揭露不合規的配色，該配色的修正屬報價頁清算的範圍，本次只讓它被測出來。
- 不把效能測試納入持續整合的自動執行。
- 不改寫快照測試的比對方式或重錄任何基準圖。
- 不調整測試計畫的語言與地區設定，那屬於最小持續整合的範圍。

## Capabilities

### New Capabilities

- `test-guard-effectiveness`: 測試守門必須具備的有效性條件，涵蓋狀態窮舉檢查的預設立場、量測型測試必須有比較對象、守門不得在其守護的機制消失後仍然通過，以及列舉式守門與掃描式守門的適用邊界。

### Modified Capabilities

（無）

## Impact

- Affected specs: `test-guard-effectiveness`（新增）
- Affected code:
  - New:
    - apps/ios/BuyLedgerTests/TestSuiteIntegrityTests.swift
  - Modified:
    - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
    - apps/ios/BuyLedgerTests/RootFeatureTests.swift
    - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
    - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
    - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
    - apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift
    - apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift
    - apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift
    - apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift
    - apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift
    - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
    - apps/ios/BuyLedgerTests/SettingsFeatureTests.swift
    - apps/ios/BuyLedgerTests/OrderEditFocusTests.swift
    - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift
    - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
    - apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift
    - apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
  - Removed: （無）
- 不涉及產品程式碼、SwiftData schema 或資料形狀。
- 次序約束：本變更必須排在所有寫入路徑改寫之後，否則同一批測試會被改兩次；亦排在報價頁清算之前，讓擴大後的對比守門先揭露該頁的配色問題。
