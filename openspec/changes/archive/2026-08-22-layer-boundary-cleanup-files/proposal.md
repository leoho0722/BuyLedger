## Summary

把 Core 與 Shared 對 Features 的上行依賴清成零：三類寄居在 Features 下的檔案下沉到它們該在的層，並新增一條全樹掃描的測試，把「Core 與 Shared 不認識 Features」從人工紀律變成機器守門。

## Motivation

**分層前提已經被打破，而且不只一處。** 稽核原本記載只有一處 Core 對 Features 的上行依賴 (幣別中繼資料 repository 取用匯率 client)。以「列出 Features 下全部頂層宣告名，再回頭掃 Core 與 Shared」的方式全樹重驗後，實際是三處：

- 幣別中繼資料 repository 取用匯率 client
- 領域層的匯率快照直接讀取匯率 fallback 表 (該表定義在 FX feature 下)
- 介面測試的相依覆寫檔同時依賴匯率 client、AI client、設定儲存、設定快照與語言型別共五個 Features 型別

只搬第一處不會讓 Core 乾淨。「Core 不知道 Features 存在」是分層的前提，也是未來要做真模組化時第一個會爆掉的點。

**跨模組共用的 UI 元件寄居在單一 feature 下。** 選項選擇器 (609 行) 被設定、報價、匯率、訂單與訂單編輯共 13 個呼叫點使用，付款方式編輯器被主檔管理與選項選擇器共用，兩者都住在訂單 feature 的元件目錄下。語言型別與其導覽標題修飾子住在設定 feature 下，但使用者遍及六個根畫面、設定儲存、根畫面與介面測試組裝。

**規範沒有機器強制力。** 上述每一條都對應到已經寫明或可推導的分層原則，卻仍然存在。守門一旦落地，後續改動就無法再讓上行依賴悄悄長回來。

## Proposed Solution

**一、Core 上行依賴歸零。** 匯率 client 與其傳輸物件下沉到 Core 的網路層 (與它組合的 HTTP client、設定讀取與錯誤型別同層，因為它是 API client 而非 repository)；匯率 fallback 表下沉到 Core 的領域層 (唯一使用者就是領域層的匯率快照)；介面測試的五支組裝檔整個目錄移出 Core，改與呼叫它的啟動設定同層。此步不改任何符號名，所有相依注入的用法零改動。

**二、共用元件與語言型別下沉到 Shared。** 選項選擇器與付款方式編輯器移到共用設計系統的對應子目錄；語言型別連同其導覽標題修飾子整檔下沉到共用層的本地化目錄。呼叫端因同模組編譯故零改動。

**三、補上全樹掃描的守門測試。** 以自身檔案路徑定位原始碼根目錄，用正則抓出 Features 下全部縮排為零的頂層宣告名，去掉註解後掃 Core 與 Shared 下每一支檔，命中即失敗並印出檔名、行號與型別名。這是全樹列舉而非示範點列舉。

## Non-Goals

- **不做 store 邊界的收斂。** 五個畫面直接吃根 store 的問題與根 feature 的狀態形狀改變屬另一個 change：本案是純搬檔加一條守門測試、零行為風險，兩者的回歸面積完全不同，混在同一次提交裡出問題時難以二分定位。
- **不搬設定儲存。** 它已被訂單 feature 跨模組依賴，搬動會讓範圍失控。
- **不拆 build target 做真模組化。**
- **不把上遷的兩個元件改名加前綴。** 前綴是既有元件的一致慣例但不是明文規則；改名要動 13 個呼叫點、平台指引三處敘述、規格與介面測試的頁面物件註解，收益只有目錄內命名整齊。
- **不改任何符號名、可及性識別碼或版面。**

## Alternatives Considered

- **只把導覽標題修飾子搬到共用擴充檔，語言型別留在設定 feature。** 已否決：該修飾子的參數型別就是語言型別，只搬函式不搬型別等於把要修的病從 Core 移植到 Shared，本案新增的守門測試會立刻抓紅。且專案自訂判準寫著「與特定功能耦合的 extension 留在該型別檔」，函式與型別不該拆散。語言型別只 import SwiftUI、無任何 Feature 依賴，本來就不是設定專屬。
- **介面測試組裝檔留在 Core，在守門測試加白名單。** 已否決：守門測試一開始就帶著例外，例外會長大。該目錄唯一的呼叫端是啟動設定，職責就是在啟動時把所有 feature 的相依換成替身，這正是組裝根的定義；錯的是它掛在 Core 底下，不是它認識 features。
- **把 AI client、設定儲存與設定快照也一併下沉到 Core，讓組裝檔留在 Core 也乾淨。** 已否決：設定儲存已被訂單 feature 跨模組依賴，下沉會牽動本案明列的不做項，範圍失控。

## Impact

- Affected specs: `app-layer-boundaries` (新增)
- Affected code:
  - New:
    - apps/ios/BuyLedgerTests/LayerBoundaryTests.swift
  - Modified:
    - apps/ios/BuyLedger/Core/Dependencies/CurrencyMetadataRepository.swift
    - apps/ios/README.md
    - apps/ios/CLAUDE.md
  - Removed:
    - apps/ios/BuyLedger/Features/FX/ExchangeRateClient.swift
    - apps/ios/BuyLedger/Features/FX/ExchangeRateDTO.swift
    - apps/ios/BuyLedger/Features/FX/FxRates.swift
    - apps/ios/BuyLedger/Features/Settings/AppLanguage.swift
    - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
    - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
    - apps/ios/BuyLedger/Core/Testing/BLUITestConfiguration.swift
    - apps/ios/BuyLedger/Core/Testing/BLUITestDependencyOverrides.swift
    - apps/ios/BuyLedger/Core/Testing/BLUITestHarness.swift
    - apps/ios/BuyLedger/Core/Testing/BLUITestSeedData.swift
    - apps/ios/BuyLedger/Core/Testing/BLUITestSeedProfile.swift
