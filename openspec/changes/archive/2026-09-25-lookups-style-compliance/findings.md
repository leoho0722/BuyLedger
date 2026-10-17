# 第 4 步範圍逐檔待修明細

來源：2026-09-14 全庫審查報告 (ios-dev-kit 1.1.0) 的資料集，取 `Features/Lookups/` 的 6 個 production 檔，加上跟著改的 2 個單元測試檔 (`LookupManagementFeatureTests`、`LookupCatalogTests`)，排除 commit `291d841` 已修的尾隨空白 (FM2)。

總計 **302 筆**，涵蓋 8 個檔案：必擋 119、違規 169、建議 8、已登記例外 6。其中 production 6 檔 191 筆、單元測試 2 檔 111 筆。

行號為 2026-09-14 當時的位置，之後前三步已改過其中數檔 (第 1 步的錯誤型別、第 2 步的 `PaymentMethodEditorSheet` 介面、全庫檔頭日期)，實作時以檔案內容為準、不依賴行號定位。檔名以報告當時為準：`LookupManagementDestination.swift` 本步改名為 `LookupManagementFeature+Destination.swift`，其中四個巢狀子 reducer 改為三個頂層表單 Feature 各自成檔；`LookupManagementFeatureTests.swift` 本步依職責拆檔。

每筆在實作完成後補上結論：`已修正 (task X.Y)` / `報告誤報 (理由)` / `登記例外 (理由)` / `依 design 不修 (理由)`。`待填` 代表尚未處理，驗收時不得殘留。判讀級項目的處置方向見 design 的「判讀級 findings 的逐筆處置」表，標為「修」的項目完工後填 `已修正` 並寫明負責的 task。

**已預先填好結論的項目 (17 筆，實作時照做、不要改掉)**：

- 8 筆 `H1`：報告用的是 `YYYY/MM/DD`，但 `apps/ios/CLAUDE.md` 已改為不補零，現況日期格式正確。
- 2 筆 `S·測試命名…`：使用者 2026-09-21 裁決維持單段 lowerCamel，不改名。
- 6 筆已登記例外：5 筆 `TC5` (`some Reducer<State, Action>`)、1 筆 `@Shared` 的 `.inMemory` key。
- 1 筆 `LookupNameEditorSheet` 的驗證邏輯抽出建議：依 design Non-Goals 不修。

## 規則代碼出現次數

| 代碼 | 規則 | 嚴重度 | 筆數 |
| --- | --- | --- | --- |
| `FM9` | switch 的 case 之間有空行 | 違規 | 33 |
| `TS3` | @Test 本體缺 Given / When / Then | 違規 | 33 |
| `MK1` | MARK 使用規範以外的分區名稱 | 必擋 | 30 |
| `D9` | enum case 的 associated value 缺 - Parameter | 必擋 | 29 |
| `D1` | 宣告缺 /// doc comment | 必擋 | 29 |
| `CL2` | 多行 closure 使用 $0 | 違規 | 17 |
| `MK5` | 型別本體內出現方法或 computed property (應放 extension) | 必擋 | 15 |
| `FM1` | 行寬超過 100 | 必擋 | 9 |
| `H1` | 檔頭格式不符 (檔名、target、日期 YYYY/MM/DD) | 違規 | 8 |
| `FM8` | switch 的 case 本體與 case 同行 | 違規 | 8 |
| `D6` | 註解結尾加中文句號 | 違規 | 8 |
| `CL1` | 兩個以上參數的 closure 用 $1 | 違規 | 5 |
| `TC5` | Reducer body 型別不是 some ReducerOf<Self> | 已登記例外 | 5 |
| `TC3` | body 內直接寫 Reduce 閉包而非 Reduce(core) | 違規 | 5 |
| `TC1` | @Dependency 與 var 寫在同一行 | 違規 | 5 |
| `D2` | 有參數卻缺 - Parameter | 必擋 | 3 |
| `S·doc 描述過時` | doc 描述過時 | 違規 | 3 |
| `FM4` | 單檔超過 300 行 (不含檔頭與空行) | 違規 | 2 |
| `IM3` | 重複 import 已被涵蓋的模組 | 違規 | 2 |
| `FM0` | 縮排不是 4 格 (開括號後一層) | 必擋 | 2 |
| `IM2` | @testable import 前缺空行 | 違規 | 2 |
| `S·doc comment 術語` | doc comment 術語 | 違規 | 2 |
| `S·Action 分 view／delegate` | Action 分 view／delegate | 違規 | 2 |
| `S·body 只放大框架` | body 只放大框架 | 違規 | 2 |
| `S·modifier 四組順序` | modifier 四組順序 | 違規 | 2 |
| `FN1` | 檔名與主要型別名稱不一致 | 違規 | 1 |
| `MK4` | extension 專屬分區寫在型別本體內 | 必擋 | 1 |
| `FM14` | 多行參數的右括號沒有單獨一行 | 違規 | 1 |
| `FM15` | 超過三個參數卻放在同一行 | 違規 | 1 |
| `C4` | @unchecked Sendable (Mock 與包裝非 Sendable 第三方物件以外) | 必擋 | 1 |
| `N6` | 單字母泛型參數 (確認是否為無語意工具函式) | 建議 | 1 |
| `S·@Shared 不用 .inMemory key` | @Shared 不用 .inMemory key | 已登記例外 | 1 |
| `S·enum 預設遵循` | enum 預設遵循 | 建議 | 1 |
| `S·doc 與命名描述過時` | doc 與命名描述過時 | 違規 | 1 |
| `S·doc comment 複述名稱` | doc comment 複述名稱 | 違規 | 1 |
| `S·doc comment 重複與不準` | doc comment 重複與不準 | 違規 | 1 |
| `S·無邏輯 reducer` | 無邏輯 reducer | 建議 | 1 |
| `S·Feature 超過 300 行未拆` | Feature 超過 300 行未拆 | 違規 | 1 |
| `S·非 UI 層不 import SwiftUI` | 非 UI 層不 import SwiftUI | 違規 | 1 |
| `S·State computed 放 stored 之後` | State computed 放 stored 之後 | 違規 | 1 |
| `S·避免執行期崩潰的建構方式` | 避免執行期崩潰的建構方式 | 建議 | 1 |
| `S·一個畫面只有一個 @Presents` | 一個畫面只有一個 @Presents | 違規 | 1 |
| `S·Result 不拆成兩個 case` | Result 不拆成兩個 case | 違規 | 1 |
| `S·跨 Feature 意圖走 delegate` | 跨 Feature 意圖走 delegate | 違規 | 1 |
| `S·寫入先落盤再改狀態` | 寫入先落盤再改狀態 | 違規 | 1 |
| `S·一次性失敗不共用載入錯誤欄位` | 一次性失敗不共用載入錯誤欄位 | 違規 | 1 |
| `S·case 超過十行抽 Private Method` | case 超過十行抽 Private Method | 違規 | 1 |
| `S·多行 closure 不用 $0` | 多行 closure 不用 $0 | 違規 | 1 |
| `S·父層只處理 delegate` | 父層只處理 delegate | 違規 | 1 |
| `S·未使用的 BindableAction` | 未使用的 BindableAction | 建議 | 1 |
| `S·View 只送 view action` | View 只送 view action | 違規 | 1 |
| `S·一個事件送一個 action` | 一個事件送一個 action | 違規 | 1 |
| `S·View Properties 順序` | View Properties 順序 | 違規 | 1 |
| `S·Private Method 只放純 UI 計算` | Private Method 只放純 UI 計算 | 建議 | 1 |
| `S·測試命名未依「行為_情境_預期」` | 測試命名未依「行為_情境_預期」 | 違規 | 1 |
| `S·測試沒有觸發名稱描述的行為` | 測試沒有觸發名稱描述的行為 | 違規 | 1 |
| `S·測試命名格式` | 測試命名格式 | 違規 | 1 |
| `S·斷言與註解宣稱不符` | 斷言與註解宣稱不符 | 違規 | 1 |
| `S·receive 依賴 Action: Equatable` | receive 依賴 Action: Equatable | 違規 | 1 |
| `S·同一邏輯多組輸入未參數化` | 同一邏輯多組輸入未參數化 | 違規 | 1 |
| `S·三元素 tuple` | 三元素 tuple | 違規 | 1 |
| `S·以迴圈取代參數化` | 以迴圈取代參數化 | 違規 | 1 |
| `S·泛型參數單字母` | 泛型參數單字母 | 違規 | 1 |
| `S·註解與程式碼不符` | 註解與程式碼不符 | 建議 | 1 |
| `S·替身記錄方式` | 替身記錄方式 | 建議 | 1 |
| `S·Fixture 命名與預設值` | Fixture 命名與預設值 | 違規 | 1 |

## 逐檔明細

### BuyLedger/Features/Lookups/LookupCatalog.swift

共 21 筆 (必擋 2、違規 18、建議 0、已登記例外 1)

- L1 `H1` 違規：檔頭格式不符 (檔名、target、日期 YYYY/MM/DD) (腳本掃描)
    - 現況：`// | //  LookupCatalog.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/8/1. | //`
    - 結論：報告規則已被推翻，不修：`apps/ios/CLAUDE.md` 規定檔頭日期一律不補零 `YYYY/M/D`；實作時確認四行結構與日期格式後標記
- L14 `MK1` 必擋：MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Data Properties`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift`)
- L38 `FM8` 違規：switch 的 case 本體與 case 同行 (腳本掃描)
    - 現況：`case .orderSource: orderSources`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift`)
- L39 `FM8` 違規：switch 的 case 本體與 case 同行 (腳本掃描)
    - 現況：`case .category: categories`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift`)
- L40 `FM8` 違規：switch 的 case 本體與 case 同行 (腳本掃描)
    - 現況：`case .paymentMethod: paymentMethods.map(\.name)`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift`)
- L41 `FM8` 違規：switch 的 case 本體與 case 同行 (腳本掃描)
    - 現況：`case .reconciliationStatus: reconciliationStatuses`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift`)
- L45 `S·doc comment 術語` 違規：doc comment 術語 (審查員判讀)
    - 問題：「trim 後若空字串視為 no-op」使用工程術語；L75「不存在視為 no-op」、L91「(未 trim)」同樣
    - 修法：改為「名稱去掉頭尾空白後若是空的，就不加入」
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift`)
- L81 `FM8` 違規：switch 的 case 本體與 case 同行 (腳本掃描)
    - 現況：`case .orderSource: orderSources.removeAll { $0 == name }`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift`)
- L82 `FM8` 違規：switch 的 case 本體與 case 同行 (腳本掃描)
    - 現況：`case .category: categories.removeAll { $0 == name }`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift`)
- L83 `FM8` 違規：switch 的 case 本體與 case 同行 (腳本掃描)
    - 現況：`case .paymentMethod: paymentMethods.removeAll { $0.name == name }`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift`)
- L84 `FM8` 違規：switch 的 case 本體與 case 同行 (腳本掃描)
    - 現況：`case .reconciliationStatus: reconciliationStatuses.removeAll { $0 == name }`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift`)
- L149 `CL1` 違規：兩個以上參數的 closure 用 $1 (腳本掃描)
    - 現況：`$0.localizedStandardCompare($1) == .orderedAscending`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift`)
- L149 `CL2` 違規：多行 closure 使用 $0 (腳本掃描)
    - 現況：`$0.localizedStandardCompare($1) == .orderedAscending`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift`)
- L166 `CL1` 違規：兩個以上參數的 closure 用 $1 (腳本掃描)
    - 現況：`$0.localizedStandardCompare($1) == .orderedAscending`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift`)
- L166 `CL2` 違規：多行 closure 使用 $0 (腳本掃描)
    - 現況：`$0.localizedStandardCompare($1) == .orderedAscending`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift`)
- L186 `CL1` 違規：兩個以上參數的 closure 用 $1 (腳本掃描)
    - 現況：`$0.name.localizedStandardCompare($1.name) == .orderedAscending`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift`)
- L186 `CL2` 違規：多行 closure 使用 $0 (腳本掃描)
    - 現況：`$0.name.localizedStandardCompare($1.name) == .orderedAscending`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift`)
- L213 `CL1` 違規：兩個以上參數的 closure 用 $1 (腳本掃描)
    - 現況：`$0.name.localizedStandardCompare($1.name) == .orderedAscending`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift`)
- L213 `CL2` 違規：多行 closure 使用 $0 (腳本掃描)
    - 現況：`$0.name.localizedStandardCompare($1.name) == .orderedAscending`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift`)
- L218 `MK1` 必擋：MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Shared Key`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift`)
- L224 `S·@Shared 不用 .inMemory key` 已登記例外：@Shared 不用 .inMemory key (審查員判讀)
    - 問題：`.inMemory("lookupCatalog")` 自訂 SharedKey，屬已登記的主檔目錄記憶體共享差異
    - 修法：維持現狀，直到另開 change 重構
    - 結論：已登記例外 (`apps/ios/CLAUDE.md`「ios-dev-kit 規範與既有差異」)，不修

### BuyLedger/Features/Lookups/LookupKind.swift

共 17 筆 (必擋 13、違規 3、建議 1、已登記例外 0)

- L1 `H1` 違規：檔頭格式不符 (檔名、target、日期 YYYY/MM/DD) (腳本掃描)
    - 現況：`// | //  LookupKind.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/5/23. | //`
    - 結論：報告規則已被推翻，不修：`apps/ios/CLAUDE.md` 規定檔頭日期一律不補零 `YYYY/M/D`；實作時確認四行結構與日期格式後標記
- L11 `S·enum 預設遵循` 建議：enum 預設遵循 (審查員判讀)
    - 問題：raw value enum 自動具備 `Equatable`、`Hashable`，明寫是冗餘；卻缺樣板預設的 `CaseIterable`
    - 修法：改為 `enum LookupKind: String, CaseIterable, Sendable`
    - 結論：已修正 (task 1.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupKind.swift`)
- L13 `MK1` 必擋：MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Cases`
    - 結論：已修正 (task 1.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupKind.swift`)
- L15 `S·doc comment 複述名稱` 違規：doc comment 複述名稱 (審查員判讀)
    - 問題：`/// 訂單來源主檔` 等四個 case 只複述名稱；L99「空狀態標題」、L113「空狀態描述」同樣
    - 修法：說明各主檔在訂單上的用途，例如「訂單從哪個管道進來，例如 IG、LINE」
    - 結論：已修正 (task 1.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupKind.swift`)
- L27 `MK1` 必擋：MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Display Properties`
    - 結論：已修正 (task 1.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupKind.swift`)
- L30 `MK5` 必擋：型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var title: String {`
    - 結論：已修正 (task 1.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupKind.swift`)
- L44 `MK5` 必擋：型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var entryTitle: String {`
    - 結論：已修正 (task 1.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupKind.swift`)
- L58 `MK5` 必擋：型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var entrySubtitle: String {`
    - 結論：已修正 (task 1.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupKind.swift`)
- L72 `MK5` 必擋：型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var systemImage: String {`
    - 結論：已修正 (task 1.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupKind.swift`)
- L86 `MK5` 必擋：型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var addButtonTitle: String {`
    - 結論：已修正 (task 1.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupKind.swift`)
- L100 `MK5` 必擋：型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var emptyTitle: String {`
    - 結論：已修正 (task 1.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupKind.swift`)
- L114 `MK5` 必擋：型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var emptyDescription: String {`
    - 結論：已修正 (task 1.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupKind.swift`)
- L127 `S·doc 與命名描述過時` 違規：doc 與命名描述過時 (審查員判讀)
    - 問題：`addAlertTitle`、`addFieldPlaceholder`、`addAlertMessage` 的 doc 仍寫「新增 alert」，實際已改由 `LookupNameEditorSheet` 表單呈現
    - 修法：doc 改為「新增表單的標題」等，屬性改名 `addFormTitle`、`addFormMessage`
    - 結論：已修正 (task 1.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupKind.swift`)
- L128 `MK5` 必擋：型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var addAlertTitle: String {`
    - 結論：已修正 (task 1.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupKind.swift`)
- L142 `MK5` 必擋：型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var addFieldPlaceholder: String {`
    - 結論：已修正 (task 1.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupKind.swift`)
- L156 `MK5` 必擋：型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var addAlertMessage: String {`
    - 結論：已修正 (task 1.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupKind.swift`)
- L170 `MK1` 必擋：MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Order Cascade`
    - 結論：已修正 (task 1.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupKind.swift`)

### BuyLedger/Features/Lookups/LookupManagementDestination.swift

共 33 筆 (必擋 18、違規 10、建議 1、已登記例外 4)

- L1 `H1` 違規：檔頭格式不符 (檔名、target、日期 YYYY/MM/DD) (腳本掃描)
    - 現況：`// | //  LookupManagementDestination.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/5/23. | //`
    - 結論：報告規則已被推翻，不修：`apps/ios/CLAUDE.md` 規定檔頭日期一律不補零 `YYYY/M/D`；實作時確認四行結構與日期格式後標記
- L1 `FN1` 違規：檔名與主要型別名稱不一致 (腳本掃描)
    - 現況：`檔名 LookupManagementDestination.swift 找不到型別 LookupManagementDestination`
    - 結論：已修正 (task 2.1／3.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature+Destination.swift`、`LookupAddFormFeature.swift`、`LookupRenameFormFeature.swift`、`PaymentMethodEditFormFeature.swift`)
- L11 `MK1` 必擋：MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Destination`
    - 結論：已修正 (task 2.1／3.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature+Destination.swift`、`LookupAddFormFeature.swift`、`LookupRenameFormFeature.swift`、`PaymentMethodEditFormFeature.swift`)
- L15 `S·doc 描述過時` 違規：doc 描述過時 (審查員判讀)
    - 問題：Destination 的 doc 只寫「改名 / 編輯付款方式」，實際還包含兩種新增表單
    - 修法：改為「主檔管理頁可開啟的表單：改名、編輯付款方式、新增項目」
    - 結論：已修正 (task 2.1／3.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature+Destination.swift`、`LookupAddFormFeature.swift`、`LookupRenameFormFeature.swift`、`PaymentMethodEditFormFeature.swift`)
- L20 `D9` 必擋：enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case rename(RenameFeature)`
    - 結論：已修正 (task 2.1／3.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature+Destination.swift`、`LookupAddFormFeature.swift`、`LookupRenameFormFeature.swift`、`PaymentMethodEditFormFeature.swift`)
- L23 `D9` 必擋：enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case editPaymentMethod(EditPaymentMethodFeature)`
    - 結論：已修正 (task 2.1／3.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature+Destination.swift`、`LookupAddFormFeature.swift`、`LookupRenameFormFeature.swift`、`PaymentMethodEditFormFeature.swift`)
- L26 `D9` 必擋：enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case addNameOnly(AddNameOnlyFeature)`
    - 結論：已修正 (task 2.1／3.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature+Destination.swift`、`LookupAddFormFeature.swift`、`LookupRenameFormFeature.swift`、`PaymentMethodEditFormFeature.swift`)
- L29 `D9` 必擋：enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case addPaymentMethod(AddPaymentMethodFeature)`
    - 結論：已修正 (task 2.1／3.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature+Destination.swift`、`LookupAddFormFeature.swift`、`LookupRenameFormFeature.swift`、`PaymentMethodEditFormFeature.swift`)
- L36 `MK1` 必擋：MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Rename Feature`
    - 結論：已修正 (task 2.1／3.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature+Destination.swift`、`LookupAddFormFeature.swift`、`LookupRenameFormFeature.swift`、`PaymentMethodEditFormFeature.swift`)
- L56 `MK4` 必擋：extension 專屬分區寫在型別本體內 (腳本掃描)
    - 現況：`// MARK: - Computed Properties`
    - 結論：已修正 (task 2.1／3.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature+Destination.swift`、`LookupAddFormFeature.swift`、`LookupRenameFormFeature.swift`、`PaymentMethodEditFormFeature.swift`)
- L59 `MK5` 必擋：型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var canSave: Bool {`
    - 結論：已修正 (task 2.1／3.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature+Destination.swift`、`LookupAddFormFeature.swift`、`LookupRenameFormFeature.swift`、`PaymentMethodEditFormFeature.swift`)
- L68 `S·Action 分 view／delegate` 違規：Action 分 view／delegate (審查員判讀)
    - 問題：四個子 reducer (RenameFeature L68、EditPaymentMethodFeature L119、AddNameOnlyFeature L159、AddPaymentMethodFeature L193) 的 Action 只有平放的 `saveButtonTapped`，由父層直接攔截
    - 修法：各自拆成 `view(View)` 與 `delegate(Delegate)`，送出結果改 `.delegate(.saved(...))`
    - 結論：已修正 (task 2.1／3.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature+Destination.swift`、`LookupAddFormFeature.swift`、`LookupRenameFormFeature.swift`、`PaymentMethodEditFormFeature.swift`)
- L71 `D9` 必擋：enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case draftChanged(String)`
    - 結論：已修正 (task 2.1／3.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature+Destination.swift`、`LookupAddFormFeature.swift`、`LookupRenameFormFeature.swift`、`PaymentMethodEditFormFeature.swift`)
- L77 `MK1` 必擋：MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Reducer Body`
    - 結論：已修正 (task 2.1／3.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature+Destination.swift`、`LookupAddFormFeature.swift`、`LookupRenameFormFeature.swift`、`PaymentMethodEditFormFeature.swift`)
- L80 `TC5` 已登記例外：Reducer body 型別不是 some ReducerOf<Self> (腳本掃描)
    - 現況：`var body: some Reducer<State, Action> {  ← apps/ios/CLAUDE.md 已登記：some ReducerOf<Self> 會 circular reference`
    - 結論：已登記例外 (`apps/ios/CLAUDE.md`「ios-dev-kit 規範與既有差異」)，不修
- L81 `TC3` 違規：body 內直接寫 Reduce 閉包而非 Reduce(core) (腳本掃描)
    - 現況：`Reduce { state, action in`
    - 結論：已修正 (task 2.1／3.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature+Destination.swift`、`LookupAddFormFeature.swift`、`LookupRenameFormFeature.swift`、`PaymentMethodEditFormFeature.swift`)
- L87 `FM9` 違規：switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case .saveButtonTapped:`
    - 結論：規則已推翻，不修：使用者 2026-09-24 裁決 switch case 之間空一行
- L95 `MK1` 必擋：MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Edit Payment Method Feature`
    - 結論：已修正 (task 2.1／3.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature+Destination.swift`、`LookupAddFormFeature.swift`、`LookupRenameFormFeature.swift`、`PaymentMethodEditFormFeature.swift`)
- L105 `S·doc comment 重複與不準` 違規：doc comment 重複與不準 (審查員判讀)
    - 問題：L99 型別 doc 與 L105 State doc 完全相同，且把 reducer 型別描述成「狀態」；L167「實際寫入 domain effect 由父層攔截」使用術語
    - 修法：型別寫它負責的事，State 寫保存的資料，L167 改為白話「按下儲存後由主檔管理頁寫入」
    - 結論：已修正 (task 2.1／3.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature+Destination.swift`、`LookupAddFormFeature.swift`、`LookupRenameFormFeature.swift`、`PaymentMethodEditFormFeature.swift`)
- L131 `MK1` 必擋：MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Reducer Body`
    - 結論：已修正 (task 2.1／3.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature+Destination.swift`、`LookupAddFormFeature.swift`、`LookupRenameFormFeature.swift`、`PaymentMethodEditFormFeature.swift`)
- L134 `TC5` 已登記例外：Reducer body 型別不是 some ReducerOf<Self> (腳本掃描)
    - 現況：`var body: some Reducer<State, Action> {  ← apps/ios/CLAUDE.md 已登記：some ReducerOf<Self> 會 circular reference`
    - 結論：已登記例外 (`apps/ios/CLAUDE.md`「ios-dev-kit 規範與既有差異」)，不修
- L135 `TC3` 違規：body 內直接寫 Reduce 閉包而非 Reduce(core) (腳本掃描)
    - 現況：`Reduce { _, _ in`
    - 結論：已修正 (task 2.1／3.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature+Destination.swift`、`LookupAddFormFeature.swift`、`LookupRenameFormFeature.swift`、`PaymentMethodEditFormFeature.swift`)
- L135 `S·無邏輯 reducer` 建議：無邏輯 reducer (審查員判讀)
    - 問題：三個子 reducer 的 body 只有 `Reduce { _, _ in .none }` (L135、L169、L206)
    - 修法：改為 `EmptyReducer()`，或補上 delegate 轉送後才保留 Reduce
    - 結論：已修正 (task 2.1／3.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature+Destination.swift`、`LookupAddFormFeature.swift`、`LookupRenameFormFeature.swift`、`PaymentMethodEditFormFeature.swift`)
- L142 `MK1` 必擋：MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Add Name Only Feature`
    - 結論：已修正 (task 2.1／3.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature+Destination.swift`、`LookupAddFormFeature.swift`、`LookupRenameFormFeature.swift`、`PaymentMethodEditFormFeature.swift`)
- L162 `D9` 必擋：enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case saveButtonTapped(name: String)`
    - 結論：已修正 (task 2.1／3.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature+Destination.swift`、`LookupAddFormFeature.swift`、`LookupRenameFormFeature.swift`、`PaymentMethodEditFormFeature.swift`)
- L165 `MK1` 必擋：MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Reducer Body`
    - 結論：已修正 (task 2.1／3.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature+Destination.swift`、`LookupAddFormFeature.swift`、`LookupRenameFormFeature.swift`、`PaymentMethodEditFormFeature.swift`)
- L168 `TC5` 已登記例外：Reducer body 型別不是 some ReducerOf<Self> (腳本掃描)
    - 現況：`var body: some Reducer<State, Action> {  ← apps/ios/CLAUDE.md 已登記：some ReducerOf<Self> 會 circular reference`
    - 結論：已登記例外 (`apps/ios/CLAUDE.md`「ios-dev-kit 規範與既有差異」)，不修
- L169 `TC3` 違規：body 內直接寫 Reduce 閉包而非 Reduce(core) (腳本掃描)
    - 現況：`Reduce { _, _ in`
    - 結論：已修正 (task 2.1／3.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature+Destination.swift`、`LookupAddFormFeature.swift`、`LookupRenameFormFeature.swift`、`PaymentMethodEditFormFeature.swift`)
- L176 `MK1` 必擋：MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Add Payment Method Feature`
    - 結論：已修正 (task 2.1／3.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature+Destination.swift`、`LookupAddFormFeature.swift`、`LookupRenameFormFeature.swift`、`PaymentMethodEditFormFeature.swift`)
- L196 `D9` 必擋：enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case saveButtonTapped(`
    - 結論：已修正 (task 2.1／3.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature+Destination.swift`、`LookupAddFormFeature.swift`、`LookupRenameFormFeature.swift`、`PaymentMethodEditFormFeature.swift`)
- L202 `MK1` 必擋：MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Reducer Body`
    - 結論：已修正 (task 2.1／3.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature+Destination.swift`、`LookupAddFormFeature.swift`、`LookupRenameFormFeature.swift`、`PaymentMethodEditFormFeature.swift`)
- L205 `TC5` 已登記例外：Reducer body 型別不是 some ReducerOf<Self> (腳本掃描)
    - 現況：`var body: some Reducer<State, Action> {  ← apps/ios/CLAUDE.md 已登記：some ReducerOf<Self> 會 circular reference`
    - 結論：已登記例外 (`apps/ios/CLAUDE.md`「ios-dev-kit 規範與既有差異」)，不修
- L206 `TC3` 違規：body 內直接寫 Reduce 閉包而非 Reduce(core) (腳本掃描)
    - 現況：`Reduce { _, _ in`
    - 結論：已修正 (task 2.1／3.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature+Destination.swift`、`LookupAddFormFeature.swift`、`LookupRenameFormFeature.swift`、`PaymentMethodEditFormFeature.swift`)

### BuyLedger/Features/Lookups/LookupManagementFeature.swift

共 98 筆 (必擋 34、違規 61、建議 2、已登記例外 1)

- L1 `H1` 違規：檔頭格式不符 (檔名、target、日期 YYYY/MM/DD) (腳本掃描)
    - 現況：`// | //  LookupManagementFeature.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/5/23. | //`
    - 結論：報告規則已被推翻，不修：`apps/ios/CLAUDE.md` 規定檔頭日期一律不補零 `YYYY/M/D`；實作時確認四行結構與日期格式後標記
- L1 `FM4` 違規：單檔超過 300 行 (不含檔頭與空行) (腳本掃描)
    - 現況：`546 行`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L8 `IM3` 違規：重複 import 已被涵蓋的模組 (腳本掃描)
    - 現況：`SwiftUI 已涵蓋 Foundation`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L10 `S·非 UI 層不 import SwiftUI` 違規：非 UI 層不 import SwiftUI (審查員判讀)
    - 問題：reducer 為了 `LocalizedStringKey` (L442、L491、L597) import SwiftUI
    - 修法：改用 `TextState` 組字串或 `String.LocalizationValue`，移除 `import SwiftUI`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L12 `S·doc 描述過時` 違規：doc 描述過時 (審查員判讀)
    - 問題：型別 doc 只提商品類別與付款方式，實際管四種主檔；L61「改名或編輯付款方式流程」漏新增、L92「含 isCardless 與 isBankTransfer」漏 isCashOnDelivery、L167 仍寫「新增流程的 alert / sheet 草稿文字」
    - 修法：逐一更新為目前行為
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L14 `S·Feature 超過 300 行未拆` 違規：Feature 超過 300 行未拆 (審查員判讀)
    - 問題：檔案 658 行，body 單一 switch 約 360 行
    - 修法：把新增、刪除、改名、付款方式編輯的 Effect 抽成同域輔助型別或 Private Method，Nested Types 另檔
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L29 `S·State computed 放 stored 之後` 違規：State computed 放 stored 之後 (審查員判讀)
    - 問題：`id`、`items` 與三個旗標對應表 computed property 夾在 `catalog` 與 `errorMessage`、`hasLoaded` 等 stored property 之間
    - 修法：把 L29-53 的 computed property 移到 L74 最後一個 stored property 之後
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L35 `MK5` 必擋：型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var paymentMethodIsCardless: [String: Bool] {`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L37 `S·避免執行期崩潰的建構方式` 建議：避免執行期崩潰的建構方式 (審查員判讀)
    - 問題：`Dictionary(uniqueKeysWithValues:)` 遇到同名付款方式會直接 trap，而 `paymentMethodInfosLoaded` 未保證去重
    - 修法：改用 `Dictionary(_:uniquingKeysWith:)`，或提供 `func flags(for name:)` 取代三張對應表
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L42 `MK5` 必擋：型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var paymentMethodIsBankTransfer: [String: Bool] {`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L49 `MK5` 必擋：型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var paymentMethodIsCashOnDelivery: [String: Bool] {`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L65 `S·一個畫面只有一個 @Presents` 違規：一個畫面只有一個 @Presents (審查員判讀)
    - 問題：除了 `destination` 又有 `deletionConfirmation`、`retroactiveConfirmation`、`writeFailureAlert` 三個 `@Presents`
    - 修法：把三個 alert 併為 `Destination` 的 `alert(AlertState<Action.Alert>)` case
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L81 `S·Action 分 view／delegate` 違規：Action 分 view／delegate (審查員判讀)
    - 問題：使用者操作與內部回應全部平放，沒有 view／delegate；`binding` 排在最後而非 view 之前，`Alert` enum 夾在 case 中間
    - 修法：依 binding → view → delegate → destination/alert → 內部回應 重排並分組
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L87 `D9` 必擋：enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case orderSourceItemsLoaded([String])`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L90 `D9` 必擋：enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case categoryItemsLoaded([String])`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L93 `D9` 必擋：enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case paymentMethodInfosLoaded([PaymentMethodInfo])`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L96 `D9` 必擋：enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case reconciliationStatusItemsLoaded([String])`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L99 `D9` 必擋：enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case loadFailed(String)`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L99 `S·Result 不拆成兩個 case` 違規：Result 不拆成兩個 case (審查員判讀)
    - 問題：四個 `xxxItemsLoaded` 成功 case 搭配共用的 `loadFailed(String)`
    - 修法：改為 `itemsResponse(Result<[String], any Error>)` 與 `paymentMethodInfosResponse(Result<...>)`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L105 `D9` 必擋：enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case addConfirmed(`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L115 `D9` 必擋：enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case confirmDelete(String)`
    - 結論：已修正 (task 2.2／3.1／5.2／8.2，現況為 `LookupManagementFeature.Destination.Alert.confirmDelete(name:)`，見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature+Destination.swift`)
- L122 `D9` 必擋：enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case deleteButtonTapped(String)`
    - 結論：已修正 (task 2.2／3.1／5.2／8.2，現況為 `LookupManagementFeature.Action.View.deleteButtonTapped(name:)`，見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`)
- L125 `D9` 必擋：enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case deleteRequested(String)`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L128 `D9` 必擋：enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case deleteSucceeded(String)`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L131 `D9` 必擋：enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case deletionConfirmation(PresentationAction<Alert>)`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L134 `D9` 必擋：enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case renameButtonTapped(name: String)`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L137 `D9` 必擋：enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case renameRequested(from: String, to: String)`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L137 `S·跨 Feature 意圖走 delegate` 違規：跨 Feature 意圖走 delegate (審查員判讀)
    - 問題：RootFeature 直接攔截 `renameRequested` 與 `paymentMethodEditSucceeded` 做訂單同步，本 Feature 沒有 delegate
    - 修法：寫入成功後送 `.delegate(.renamed(kind:from:to:))`、`.delegate(.paymentMethodEdited(plan))`，Root 改攔截 delegate
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L140 `D9` 必擋：enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case editButtonTapped(name: String)`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L143 `D9` 必擋：enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case editConfirmed(`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L150 `D9` 必擋：enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case paymentMethodEditPrepared(PaymentMethodEditPlan)`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L153 `D9` 必擋：enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case paymentMethodEditSucceeded(PaymentMethodEditPlan)`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L156 `D9` 必擋：enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case paymentMethodEditFailed(String)`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L159 `D9` 必擋：enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case writeFailureAlert(PresentationAction<Alert>)`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L162 `D9` 必擋：enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case retroactiveConfirmation(PresentationAction<Alert>)`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L165 `D9` 必擋：enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case destination(PresentationAction<Destination.Action>)`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L168 `D9` 必擋：enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case binding(BindingAction<State>)`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L168 `S·未使用的 BindableAction` 建議：未使用的 BindableAction (審查員判讀)
    - 問題：View 只用 `$store.scope`，沒有任何 `$store.xxx` 欄位繫結，`BindableAction` 與 `BindingReducer()` 已無作用
    - 修法：移除 `BindableAction`、`case binding` 與 `BindingReducer()`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L171 `MK1` 必擋：MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Dependency Properties`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L174 `TC1` 違規：@Dependency 與 var 寫在同一行 (腳本掃描)
    - 現況：`@Dependency(OrderSourceRepository.self) private var orderSourceRepository`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L177 `TC1` 違規：@Dependency 與 var 寫在同一行 (腳本掃描)
    - 現況：`@Dependency(CategoryRepository.self) private var categoryRepository`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L180 `TC1` 違規：@Dependency 與 var 寫在同一行 (腳本掃描)
    - 現況：`@Dependency(PaymentMethodRepository.self) private var paymentMethodRepository`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L183 `TC1` 違規：@Dependency 與 var 寫在同一行 (腳本掃描)
    - 現況：`@Dependency(ReconciliationStatusRepository.self) private var reconciliationStatusRepository`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L186 `TC1` 違規：@Dependency 與 var 寫在同一行 (腳本掃描)
    - 現況：`@Dependency(OrderRepository.self) private var orderRepository`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L188 `MK1` 必擋：MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Reducer Body`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L191 `TC5` 已登記例外：Reducer body 型別不是 some ReducerOf<Self> (腳本掃描)
    - 現況：`var body: some Reducer<State, Action> {  ← apps/ios/CLAUDE.md 已登記：some ReducerOf<Self> 會 circular reference`
    - 結論：已登記例外 (`apps/ios/CLAUDE.md`「ios-dev-kit 規範與既有差異」)，不修
- L193 `TC3` 違規：body 內直接寫 Reduce 閉包而非 Reduce(core) (腳本掃描)
    - 現況：`Reduce {`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L203 `FM9` 違規：switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .orderSourceItemsLoaded(items):`
    - 結論：規則已推翻，不修：使用者 2026-09-24 裁決 switch case 之間空一行
- L209 `FM9` 違規：switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .categoryItemsLoaded(items):`
    - 結論：規則已推翻，不修：使用者 2026-09-24 裁決 switch case 之間空一行
- L215 `FM9` 違規：switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .paymentMethodInfosLoaded(infos):`
    - 結論：規則已推翻，不修：使用者 2026-09-24 裁決 switch case 之間空一行
- L218 `CL1` 違規：兩個以上參數的 closure 用 $1 (腳本掃描)
    - 現況：`$0.name.localizedStandardCompare($1.name) == .orderedAscending`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L218 `CL2` 違規：多行 closure 使用 $0 (腳本掃描)
    - 現況：`$0.name.localizedStandardCompare($1.name) == .orderedAscending`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L225 `FM9` 違規：switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .reconciliationStatusItemsLoaded(items):`
    - 結論：規則已推翻，不修：使用者 2026-09-24 裁決 switch case 之間空一行
- L231 `FM9` 違規：switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .loadFailed(message):`
    - 結論：規則已推翻，不修：使用者 2026-09-24 裁決 switch case 之間空一行
- L235 `FM9` 違規：switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case .addButtonTapped:`
    - 結論：規則已推翻，不修：使用者 2026-09-24 裁決 switch case 之間空一行
- L247 `FM9` 違規：switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .addConfirmed(name, flags):`
    - 結論：規則已推翻，不修：使用者 2026-09-24 裁決 switch case 之間空一行
- L254 `S·寫入先落盤再改狀態` 違規：寫入先落盤再改狀態 (審查員判讀)
    - 問題：`addConfirmed` 在寫入前先改 `catalog` (L254)，`renameRequested` 同樣先改 (L346)，寫入失敗時沒有回滾，畫面與資料庫不一致
    - 修法：比照 `deleteRequested`，寫入成功後才送 `addSucceeded`／`renameSucceeded` 更新 catalog
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L255 `CL2` 違規：多行 closure 使用 $0 (腳本掃描)
    - 現況：`$0.add(`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L279 `S·一次性失敗不共用載入錯誤欄位` 違規：一次性失敗不共用載入錯誤欄位 (審查員判讀)
    - 問題：新增、刪除 (L324)、改名 (L376) 失敗都送 `loadFailed`，寫進持續顯示的 `errorMessage`，且只有重新載入成功才清除
    - 修法：寫入失敗改送 `writeFailed(String)` 並以 `writeFailureAlert` 呈現
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L282 `FM9` 違規：switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .deleteButtonTapped(name):`
    - 結論：規則已推翻，不修：使用者 2026-09-24 裁決 switch case 之間空一行
- L297 `FM9` 違規：switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .deletionConfirmation(.presented(.confirmDelete(name))):`
    - 結論：規則已推翻，不修：使用者 2026-09-24 裁決 switch case 之間空一行
- L300 `FM9` 違規：switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case .deletionConfirmation:`
    - 結論：規則已推翻，不修：使用者 2026-09-24 裁決 switch case 之間空一行
- L303 `FM9` 違規：switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .deleteRequested(name):`
    - 結論：規則已推翻，不修：使用者 2026-09-24 裁決 switch case 之間空一行
- L304 `D6` 違規：註解結尾加中文句號 (腳本掃描)
    - 現況：`// 先寫後改；刪除不是高頻操作，不需要樂觀更新。`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L327 `FM9` 違規：switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .deleteSucceeded(name):`
    - 結論：規則已推翻，不修：使用者 2026-09-24 裁決 switch case 之間空一行
- L331 `FM9` 違規：switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .renameButtonTapped(name):`
    - 結論：規則已推翻，不修：使用者 2026-09-24 裁決 switch case 之間空一行
- L333 `FM14` 違規：多行參數的右括號沒有單獨一行 (腳本掃描)
    - 現況：`Destination.RenameFeature.State(originalName: name, draft: name))`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L336 `FM9` 違規：switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .renameRequested(from, to):`
    - 結論：規則已推翻，不修：使用者 2026-09-24 裁決 switch case 之間空一行
- L342 `FM0` 必擋：縮排不是 4 格 (開括號後一層) (腳本掃描)
    - 現況：`預期縮排 26，實際 20`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L345 `D6` 違規：註解結尾加中文句號 (腳本掃描)
    - 現況：`// 由 catalog.rename 統一合併付款方式旗標。`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L347 `CL2` 違規：多行 closure 使用 $0 (腳本掃描)
    - 現況：`$0.rename(`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L369 `FM1` 必擋：行寬超過 100 (腳本掃描)
    - 現況：`101 字元`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L372 `FM1` 必擋：行寬超過 100 (腳本掃描)
    - 現況：`115 字元`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L373 `FM1` 必擋：行寬超過 100 (腳本掃描)
    - 現況：`105 字元`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L379 `FM9` 違規：switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .editButtonTapped(name):`
    - 結論：規則已推翻，不修：使用者 2026-09-24 裁決 switch case 之間空一行
- L391 `FM9` 違規：switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .editConfirmed(originalName, rawName, flags):`
    - 結論：規則已推翻，不修：使用者 2026-09-24 裁決 switch case 之間空一行
- L391 `S·case 超過十行抽 Private Method` 違規：case 超過十行抽 Private Method (審查員判讀)
    - 問題：`editConfirmed` (L391-432)、`addConfirmed` (L247-280)、`renameRequested` (L336-377)、`paymentMethodEditPrepared` (L434-455) 皆超過十行
    - 修法：抽成 `prepareEdit(...)`、`addEffect(...)`、`renameEffect(...)`、`retroactiveAlert(count:)` 等方法
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L409 `D6` 違規：註解結尾加中文句號 (腳本掃描)
    - 現況：`// 確認文案與寫入資料共用同一個 plan。`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L413 `S·多行 closure 不用 $0` 違規：多行 closure 不用 $0 (審查員判讀)
    - 問題：`.map {` 內跨四行串接 `$0.renamingPaymentMethod(...).applyingPaymentMethodFlags(...)`
    - 修法：改為 `.map { order in order.renamingPaymentMethod(to: trimmedNew).applyingPaymentMethodFlags(flags: flags) }`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L414 `CL2` 違規：多行 closure 使用 $0 (腳本掃描)
    - 現況：`$0`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L434 `FM9` 違規：switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .paymentMethodEditPrepared(plan):`
    - 結論：規則已推翻，不修：使用者 2026-09-24 裁決 switch case 之間空一行
- L457 `FM9` 違規：switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case .retroactiveConfirmation(.presented(.confirmPaymentMethodEdit)):`
    - 結論：規則已推翻，不修：使用者 2026-09-24 裁決 switch case 之間空一行
- L464 `FM9` 違規：switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case .retroactiveConfirmation(.dismiss):`
    - 結論：規則已推翻，不修：使用者 2026-09-24 裁決 switch case 之間空一行
- L469 `FM9` 違規：switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case .retroactiveConfirmation:`
    - 結論：規則已推翻，不修：使用者 2026-09-24 裁決 switch case 之間空一行
- L472 `FM9` 違規：switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .paymentMethodEditSucceeded(plan):`
    - 結論：規則已推翻，不修：使用者 2026-09-24 裁決 switch case 之間空一行
- L476 `CL2` 違規：多行 closure 使用 $0 (腳本掃描)
    - 現況：`$0.add(`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L488 `FM9` 違規：switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .paymentMethodEditFailed(message):`
    - 結論：規則已推翻，不修：使用者 2026-09-24 裁決 switch case 之間空一行
- L494 `FM9` 違規：switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case .writeFailureAlert:`
    - 結論：規則已推翻，不修：使用者 2026-09-24 裁決 switch case 之間空一行
- L497 `FM9` 違規：switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .destination(.presented(.addNameOnly(.saveButtonTapped(name)))):`
    - 結論：規則已推翻，不修：使用者 2026-09-24 裁決 switch case 之間空一行
- L497 `S·父層只處理 delegate` 違規：父層只處理 delegate (審查員判讀)
    - 問題：父層攔截四種子表單的 `.presented(... .saveButtonTapped)` 使用者操作並讀取子層 State
    - 修法：子表單送 delegate，父層改攔截 `.destination(.presented(.rename(.delegate(.saved(...)))))`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L506 `FM9` 違規：switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .destination(`
    - 結論：規則已推翻，不修：使用者 2026-09-24 裁決 switch case 之間空一行
- L517 `FM9` 違規：switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case .destination(.presented(.rename(.saveButtonTapped))):`
    - 結論：規則已推翻，不修：使用者 2026-09-24 裁決 switch case 之間空一行
- L521 `FM0` 必擋：縮排不是 4 格 (開括號後一層) (腳本掃描)
    - 現況：`預期縮排 26，實際 20`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L524 `FM1` 必擋：行寬超過 100 (腳本掃描)
    - 現況：`101 字元`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)
- L526 `FM9` 違規：switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .destination(`
    - 結論：規則已推翻，不修：使用者 2026-09-24 裁決 switch case 之間空一行
- L540 `FM9` 違規：switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case .destination:`
    - 結論：規則已推翻，不修：使用者 2026-09-24 裁決 switch case 之間空一行
- L543 `FM9` 違規：switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case .binding:`
    - 結論：規則已推翻，不修：使用者 2026-09-24 裁決 switch case 之間空一行
- L650 `FM1` 必擋：行寬超過 100 (腳本掃描)
    - 現況：`102 字元`
    - 結論：已修正 (task 2.2／3.1／5.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift`、`LookupItemOperations.swift`、`PaymentMethodCorrectionFeature.swift`、`LookupManagementFeature+Destination.swift`)

### BuyLedger/Features/Lookups/LookupManagementView.swift

共 14 筆 (必擋 4、違規 10、建議 0、已登記例外 0)

- L1 `H1` 違規：檔頭格式不符 (檔名、target、日期 YYYY/MM/DD) (腳本掃描)
    - 現況：`// | //  LookupManagementView.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/5/23. | //`
    - 結論：報告規則已被推翻，不修：`apps/ios/CLAUDE.md` 規定檔頭日期一律不補零 `YYYY/M/D`；實作時確認四行結構與日期格式後標記
- L11 `S·doc 描述過時` 違規：doc 描述過時 (審查員判讀)
    - 問題：型別 doc 列三種主檔漏了對帳狀態；L16「主檔管理 store」、L35「主檔管理畫面內容」只複述名稱
    - 修法：改為涵蓋四種主檔，並說明 store 來源
    - 結論：已修正 (task 4.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift`、`Components/LookupItemList.swift`、`Components/LookupItemRow.swift`)
- L14 `MK1` 必擋：MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Properties`
    - 結論：已修正 (task 4.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift`、`Components/LookupItemList.swift`、`Components/LookupItemRow.swift`)
- L20 `MK5` 必擋：型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`private var renameSheetTitle: LocalizedStringKey {`
    - 結論：已修正 (task 4.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift`、`Components/LookupItemList.swift`、`Components/LookupItemRow.swift`)
- L33 `MK1` 必擋：MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Body`
    - 結論：已修正 (task 4.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift`、`Components/LookupItemList.swift`、`Components/LookupItemRow.swift`)
- L43 `S·body 只放大框架` 違規：body 只放大框架 (審查員判讀)
    - 問題：`.toolbar` 內的新增按鈕 (Button、Label、labelStyle) 直接寫在 body
    - 修法：抽成 Private View `addButton`，body 寫 `.toolbar { ToolbarItem(placement: .primaryAction) { addButton } }`
    - 結論：已修正 (task 4.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift`、`Components/LookupItemList.swift`、`Components/LookupItemRow.swift`)
- L44 `S·View 只送 view action` 違規：View 只送 view action (審查員判讀)
    - 問題：送出平放的 `.addButtonTapped`、`.editButtonTapped`、`.renameButtonTapped`、`.deleteButtonTapped`、`.task`
    - 修法：Feature 補 `view` 分組後改送 `.view(...)`
    - 結論：已修正 (task 4.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift`、`Components/LookupItemList.swift`、`Components/LookupItemRow.swift`)
- L63 `S·modifier 四組順序` 違規：modifier 四組順序 (審查員判讀)
    - 問題：行為組 `.accessibilityIdentifier` 在導航組之前是對的，但 `.task` 排在 `.alert` 之後
    - 修法：把 `.task` 移到 `.accessibilityIdentifier` 之後、`.navigationTitle` 之前
    - 結論：已修正 (task 4.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift`、`Components/LookupItemList.swift`、`Components/LookupItemRow.swift`)
- L69 `MK1` 必擋：MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - ViewBuilder`
    - 結論：已修正 (task 4.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift`、`Components/LookupItemList.swift`、`Components/LookupItemRow.swift`)
- L89 `S·一個事件送一個 action` 違規：一個事件送一個 action (審查員判讀)
    - 問題：改名提交時連送 `.draftChanged(name)` 與 `.saveButtonTapped`，用兩個 action 拼出一次操作
    - 修法：改為單一 `.view(.saveButtonTapped(name:))`，由子 reducer 寫入草稿並送 delegate
    - 結論：已修正 (task 4.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift`、`Components/LookupItemList.swift`、`Components/LookupItemRow.swift`)
- L93 `FM9` 違規：switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .addNameOnly(addStore):`
    - 結論：規則已推翻，不修：使用者 2026-09-24 裁決 switch case 之間空一行
- L103 `FM9` 違規：switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .addPaymentMethod(addStore):`
    - 結論：規則已推翻，不修：使用者 2026-09-24 裁決 switch case 之間空一行
- L113 `FM9` 違規：switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .editPaymentMethod(editStore):`
    - 結論：規則已推翻，不修：使用者 2026-09-24 裁決 switch case 之間空一行
- L164 `S·modifier 四組順序` 違規：modifier 四組順序 (審查員判讀)
    - 問題：`classificationBadge` 的 `.padding` (版面) 排在 `.font`、`.foregroundStyle` (外觀) 之後
    - 修法：改為 `.padding(.horizontal)` → `.padding(.vertical)` → `.font` → `.foregroundStyle` → `.background`
    - 結論：已修正 (task 4.1，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift`、`Components/LookupItemList.swift`、`Components/LookupItemRow.swift`)

### BuyLedger/Features/Lookups/LookupNameEditorSheet.swift

共 8 筆 (必擋 3、違規 4、建議 1、已登記例外 0)

- L1 `H1` 違規：檔頭格式不符 (檔名、target、日期 YYYY/MM/DD) (腳本掃描)
    - 現況：`// | //  LookupNameEditorSheet.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/7/20. | //`
    - 結論：報告規則已被推翻，不修：`apps/ios/CLAUDE.md` 規定檔頭日期一律不補零 `YYYY/M/D`；實作時確認四行結構與日期格式後標記
- L13 `MK1` 必擋：MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Properties`
    - 結論：已修正 (task 4.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift`)
- L27 `S·doc comment 術語` 違規：doc comment 術語 (審查員判讀)
    - 問題：「callback；caller 拿到已 trim 的名稱」使用術語；L15「Sheet 的標題 (顯示在 navigation bar)」、L30「dismiss action」、L54「callback」同樣
    - 修法：改為「使用者按下儲存時交出去頭尾空白的名稱，由呼叫端決定如何寫入」
    - 結論：已修正 (task 4.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift`)
- L31 `S·View Properties 順序` 違規：View Properties 順序 (審查員判讀)
    - 問題：四個 `let` 與 `onSubmit` 排在 `@Environment`、`@State`、`@FocusState` 之前
    - 修法：依 @Environment → @State/@FocusState → let 重排
    - 結論：已修正 (task 4.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift`)
- L72 `MK1` 必擋：MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Body`
    - 結論：已修正 (task 4.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift`)
- L84 `S·body 只放大框架` 違規：body 只放大框架 (審查員判讀)
    - 問題：`.alert` 的兩顆按鈕與訊息文字直接寫在 body
    - 修法：抽成 Private View `discardAlertActions` 與 `discardAlertMessage`
    - 結論：已修正 (task 4.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift`)
- L96 `MK1` 必擋：MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - ViewBuilder`
    - 結論：已修正 (task 4.2，現況見 `apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift`)
- L158 `S·Private Method 只放純 UI 計算` 建議：Private Method 只放純 UI 計算 (審查員判讀)
    - 問題：`trimmedName` 回傳整理後字串、`canSubmit` 做輸入驗證，屬值得單元測試的邏輯；此元件不綁 store 屬專案允許範圍，但可抽出
    - 修法：抽成可測試的 static func (如 `NameDraftValidation.canSubmit(draft:initial:)`) 並補測試
    - 結論：依 design Non-Goals 不修：不綁 store 的可重用元件，按鈕停用屬 UI 判斷；送出後的名稱驗證由表單子 Feature 的 reducer 再做一次並有單元測試

### BuyLedgerTests/LookupCatalogTests.swift

共 28 筆 (必擋 13、違規 15、建議 0、已登記例外 0)

- L1 `H1` 違規：檔頭格式不符 (檔名、target、日期 YYYY/MM/DD) (腳本掃描)
    - 現況：`// | //  LookupCatalogTests.swift | //  BuyLedgerTests | // | //  Created by Leo Ho on 2026/8/1. | //`
    - 結論：報告規則已被推翻，不修：`apps/ios/CLAUDE.md` 規定檔頭日期一律不補零 `YYYY/M/D`；實作時確認四行結構與日期格式後標記
- L9 `IM2` 違規：@testable import 前缺空行 (腳本掃描)
    - 現況：`@testable import BuyLedger`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedgerTests/LookupCatalogTests.swift`)
- L14 `MK1` 必擋：MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Tests (Order Source / Category / Reconciliation Status)`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedgerTests/LookupCatalogTests.swift`)
- L17 `D1` 必擋：宣告缺 /// doc comment (腳本掃描)
    - 現況：`func addingNameOnlyKindInsertsSorted(kind: LookupKind) {`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedgerTests/LookupCatalogTests.swift`)
- L17 `TS3` 違規：@Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`func addingNameOnlyKindInsertsSorted(kind: LookupKind) {`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedgerTests/LookupCatalogTests.swift`)
- L17 `S·測試命名未依「行為_情境_預期」` 違規：測試命名未依「行為_情境_預期」 (審查員判讀)
    - 問題：10 個 @Test 都沒有三段式底線命名
    - 修法：例如 `add_nameOnlyKind_insertsSorted`
    - 結論：依使用者 2026-09-21 裁決不修：測試方法維持單段 lowerCamel，差異登記於 `apps/ios/CLAUDE.md` 的「ios-dev-kit 規範與既有差異」
- L22 `D6` 違規：註解結尾加中文句號 (腳本掃描)
    - 現況：`// zh-Hant 排序應將「香蕉」放在前面。`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedgerTests/LookupCatalogTests.swift`)
- L27 `D1` 必擋：宣告缺 /// doc comment (腳本掃描)
    - 現況：`func addingBlankNameIsNoOp(kind: LookupKind) {`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedgerTests/LookupCatalogTests.swift`)
- L27 `TS3` 違規：@Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`func addingBlankNameIsNoOp(kind: LookupKind) {`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedgerTests/LookupCatalogTests.swift`)
- L35 `D1` 必擋：宣告缺 /// doc comment (腳本掃描)
    - 現況：`func removingNameOnlyKindDeletesEntry(kind: LookupKind) {`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedgerTests/LookupCatalogTests.swift`)
- L35 `TS3` 違規：@Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`func removingNameOnlyKindDeletesEntry(kind: LookupKind) {`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedgerTests/LookupCatalogTests.swift`)
- L45 `D1` 必擋：宣告缺 /// doc comment (腳本掃描)
    - 現況：`func renamingNameOnlyKindReplacesOldName(kind: LookupKind) {`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedgerTests/LookupCatalogTests.swift`)
- L45 `TS3` 違規：@Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`func renamingNameOnlyKindReplacesOldName(kind: LookupKind) {`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedgerTests/LookupCatalogTests.swift`)
- L54 `MK1` 必擋：MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Tests (Payment Method)`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedgerTests/LookupCatalogTests.swift`)
- L56 `D1` 必擋：宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func addingPaymentMethodStoresFlags() {`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedgerTests/LookupCatalogTests.swift`)
- L56 `TS3` 違規：@Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func addingPaymentMethodStoresFlags() {`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedgerTests/LookupCatalogTests.swift`)
- L79 `D1` 必擋：宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func addingPaymentMethodSameNameOverwritesFlags() {`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedgerTests/LookupCatalogTests.swift`)
- L79 `TS3` 違規：@Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func addingPaymentMethodSameNameOverwritesFlags() {`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedgerTests/LookupCatalogTests.swift`)
- L100 `D1` 必擋：宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func removingPaymentMethodDeletesEntry() {`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedgerTests/LookupCatalogTests.swift`)
- L100 `TS3` 違規：@Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func removingPaymentMethodDeletesEntry() {`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedgerTests/LookupCatalogTests.swift`)
- L117 `D1` 必擋：宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func renamingPaymentMethodMergesFlagsWhenEitherSideIsTrue() {`
    - 結論：報告誤報 (現況方法前已有 `///` 文件註解與 `- Throws`，見 `LookupCatalogTests.swift:117-121`)
- L117 `TS3` 違規：@Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func renamingPaymentMethodMergesFlagsWhenEitherSideIsTrue() {`
    - 結論：報告誤報 (現況測試本體已有 Given、When、Then 標記及對應準備、呼叫與斷言，見 `LookupCatalogTests.swift:122-151`)
- L129 `S·測試沒有觸發名稱描述的行為` 違規：測試沒有觸發名稱描述的行為 (審查員判讀)
    - 問題：`renamingPaymentMethodMergesFlagsWhenEitherSideIsTrue` 的目標名稱「銀行匯款」原本不存在，所以沒有執行到 `renamedPaymentMethods` 的合併分支，驗證的只是改名後保留旗標
    - 修法：先分別加入「匯款 (isBankTransfer)」與「銀行匯款 (isCardless)」，改名後斷言剩一筆且兩個旗標都是 true
    - 結論：報告誤報 (現況先加入「匯款」與已存在的「銀行匯款」，改名後斷言只剩一筆且三個旗標皆為 true，會執行合併分支，見 `LookupCatalogTests.swift:123-151`)
- L135 `MK1` 必擋：MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Tests (Shared Early-Exit Semantics)`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedgerTests/LookupCatalogTests.swift`)
- L137 `D1` 必擋：宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func renamingToBlankNameIsNoOp() {`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedgerTests/LookupCatalogTests.swift`)
- L137 `TS3` 違規：@Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func renamingToBlankNameIsNoOp() {`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedgerTests/LookupCatalogTests.swift`)
- L146 `D1` 必擋：宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func renamingToSameNameIsNoOp() {`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedgerTests/LookupCatalogTests.swift`)
- L146 `TS3` 違規：@Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func renamingToSameNameIsNoOp() {`
    - 結論：已修正 (task 1.2，現況見 `apps/ios/BuyLedgerTests/LookupCatalogTests.swift`)

### BuyLedgerTests/LookupManagementFeatureTests.swift

共 83 筆 (必擋 32、違規 48、建議 3、已登記例外 0)

- L1 `H1` 違規：檔頭格式不符 (檔名、target、日期 YYYY/MM/DD) (腳本掃描)
    - 現況：`// | //  LookupManagementFeatureTests.swift | //  BuyLedgerTests | // | //  Created by Leo Ho on 2026/5/29. | //`
    - 結論：報告規則已被推翻，不修：`apps/ios/CLAUDE.md` 規定檔頭日期一律不補零 `YYYY/M/D`；實作時確認四行結構與日期格式後標記
- L1 `FM4` 違規：單檔超過 300 行 (不含檔頭與空行) (腳本掃描)
    - 現況：`913 行`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L8 `IM3` 違規：重複 import 已被涵蓋的模組 (腳本掃描)
    - 現況：`SwiftUI 已涵蓋 Foundation`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L12 `IM2` 違規：@testable import 前缺空行 (腳本掃描)
    - 現況：`@testable import BuyLedger`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L20 `D1` 必擋：宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func reconciliationStatusKindLoadsFromRepository() async {`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L20 `TS3` 違規：@Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func reconciliationStatusKindLoadsFromRepository() async {`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L20 `S·測試命名格式` 違規：測試命名格式 (審查員判讀)
    - 問題：23 個測試皆未依「行為_情境_預期」命名
    - 修法：改名如 `task_forReconciliationStatus_loadsItemsFromRepository`
    - 結論：依使用者 2026-09-21 裁決不修：測試方法維持單段 lowerCamel，差異登記於 `apps/ios/CLAUDE.md` 的「ios-dev-kit 規範與既有差異」
- L43 `D1` 必擋：宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func reconciliationStatusAddConfirmedAppendsItem() async {`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L43 `TS3` 違規：@Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func reconciliationStatusAddConfirmedAppendsItem() async {`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L61 `TS3` 違規：@Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func addConfirmedWritesThroughToTheSharedCatalogFromAStandaloneContainer() async {`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L73 `D6` 違規：註解結尾加中文句號 (腳本掃描)
    - 現況：`// 直接讀共享目錄，確認跨 feature 共用同一份儲存。`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L74 `S·斷言與註解宣稱不符` 違規：斷言與註解宣稱不符 (審查員判讀)
    - 問題：註解宣稱「直接讀共享目錄，確認跨 feature 共用同一份儲存」，但讀的是同一個 store 的 state，與 send 閉包已做的斷言重複，跨容器共享沒有被驗證
    - 修法：在同一個 `withIsolatedCatalog` scope 另宣告 `@Shared(.lookupCatalog)` 讀取並比對
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L79 `D1` 必擋：宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func editConfirmedRenamesPaymentMethodAndClearsFlag() async {`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L79 `TS3` 違規：@Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func editConfirmedRenamesPaymentMethodAndClearsFlag() async {`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L81 `D6` 違規：註解結尾加中文句號 (腳本掃描)
    - 現況：`// 改名同時取消銀行匯款旗標。`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L110 `CL2` 違規：多行 closure 使用 $0 (腳本掃描)
    - 現況：`$0.$catalog.withLock {`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L125 `D1` 必擋：宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func editConfirmedKeepsNameAndUpdatesFlags() async {`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L125 `TS3` 違規：@Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func editConfirmedKeepsNameAndUpdatesFlags() async {`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L159 `D6` 違規：註解結尾加中文句號 (腳本掃描)
    - 現況：`// 目錄變更會在此接收點反映。`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L161 `CL2` 違規：多行 closure 使用 $0 (腳本掃描)
    - 現況：`$0.$catalog.withLock {`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L176 `MK1` 必擋：MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - 新增流程 (addButtonTapped) Tests`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L179 `TS3` 違規：@Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func addButtonTappedForCategoryPresentsTheNameOnlyForm() async {`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L193 `D1` 必擋：宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func addButtonTappedForPaymentMethodPresentsThePaymentMethodForm() async {`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L193 `TS3` 違規：@Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func addButtonTappedForPaymentMethodPresentsThePaymentMethodForm() async {`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L195 `FM1` 必擋：行寬超過 100 (腳本掃描)
    - 現況：`102 字元`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L207 `D1` 必擋：宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func addButtonTappedForReconciliationStatusPresentsTheNameOnlyForm() async {`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L207 `TS3` 違規：@Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func addButtonTappedForReconciliationStatusPresentsTheNameOnlyForm() async {`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L223 `MK1` 必擋：MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - 刪除流程 Tests`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L226 `TS3` 違規：@Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func deleteButtonTappedPresentsConfirmationWithoutMutatingState() async {`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L254 `TS3` 違規：@Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func deleteFailureLeavesTheListUnchanged() async {`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L261 `FM1` 必擋：行寬超過 100 (腳本掃描)
    - 現況：`108 字元`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L274 `D1` 必擋：宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func deleteSuccessRemovesTheItem() async {`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L274 `TS3` 違規：@Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func deleteSuccessRemovesTheItem() async {`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L292 `MK1` 必擋：MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Destination (改名 / 編輯付款方式) Tests`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L294 `D1` 必擋：宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func renameCanSaveIsFalseWhenDraftEmptyOrUnchanged() {`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L294 `TS3` 違規：@Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func renameCanSaveIsFalseWhenDraftEmptyOrUnchanged() {`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L294 `S·同一邏輯多組輸入未參數化` 違規：同一邏輯多組輸入未參數化 (審查員判讀)
    - 問題：三組輸入寫在同一測試，名稱說「為 false」卻同時斷言 true 的情境
    - 修法：改為 `@Test(arguments:)` 以 (draft, 預期 canSave) 參數化並改名
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L314 `D1` 必擋：宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func renameButtonTappedPresentsRenameDestinationWithOriginalNameSnapshot() async {`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L314 `TS3` 違規：@Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func renameButtonTappedPresentsRenameDestinationWithOriginalNameSnapshot() async {`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L336 `D1` 必擋：宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func renameDestinationLifecycleUpdatesDraftSavesAndDismisses() async {`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L336 `TS3` 違規：@Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func renameDestinationLifecycleUpdatesDraftSavesAndDismisses() async {`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L381 `D1` 必擋：宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func renameSaveButtonTappedNoOpsWhenCannotSave() async {`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L381 `TS3` 違規：@Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func renameSaveButtonTappedNoOpsWhenCannotSave() async {`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L405 `D1` 必擋：宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func editButtonTappedPresentsEditPaymentMethodDestinationWithFlagSnapshot() async {`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L405 `TS3` 違規：@Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func editButtonTappedPresentsEditPaymentMethodDestinationWithFlagSnapshot() async {`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L441 `D1` 必擋：宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func editButtonTappedNoOpsForNonPaymentMethodKind() async {`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L441 `TS3` 違規：@Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func editButtonTappedNoOpsForNonPaymentMethodKind() async {`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L455 `D1` 必擋：宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func editPaymentMethodDestinationSaveTriggersEditConfirmedAndDismisses() async {`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L455 `TS3` 違規：@Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func editPaymentMethodDestinationSaveTriggersEditConfirmedAndDismisses() async {`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L490 `S·註解與程式碼不符` 建議：註解與程式碼不符 (審查員判讀)
    - 問題：註解寫「送出既有的重新命名 action」，實際送出的是付款方式編輯表單的儲存，會轉成 `editConfirmed`；是從 L369 複製
    - 修法：改為「儲存時轉送 editConfirmed，成功後關閉表單」
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L506 `CL2` 違規：多行 closure 使用 $0 (腳本掃描)
    - 現況：`$0.$catalog.withLock {`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L524 `MK1` 必擋：MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - 付款旗標更新 Tests`
    - 結論：已修正 (task 3.2，現況見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests*.swift` 拆分檔)
- L526 `D1` 必擋：宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func editConfirmedUsesOneFilteredSnapshotForCountAndPayloadAndConfirmation() async {`
    - 結論：已修正 (task 2.2／3.2，現況見 `apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift`、`LookupManagementFeatureTests+PaymentMethodCorrection.swift` 與其他拆分測試檔)
- L526 `TS3` 違規：@Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func editConfirmedUsesOneFilteredSnapshotForCountAndPayloadAndConfirmation() async {`
    - 結論：已修正 (task 2.2／3.2，現況見 `apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift`、`LookupManagementFeatureTests+PaymentMethodCorrection.swift` 與其他拆分測試檔)
- L579 `S·receive 依賴 Action: Equatable` 違規：receive 依賴 Action: Equatable (審查員判讀)
    - 問題：`store.receive(.paymentMethodEditPrepared(expectedPlan))` 以整個 action 值比對 (本檔 8 處：579、595、663、671、865、877、906、918)
    - 修法：改為 `store.receive(\.paymentMethodEditPrepared)`，在閉包內斷言 `pendingPaymentMethodEdit == expectedPlan`
    - 結論：已修正 (task 2.2／3.2，現況見 `apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift`、`LookupManagementFeatureTests+PaymentMethodCorrection.swift` 與其他拆分測試檔)
- L596 `CL2` 違規：多行 closure 使用 $0 (腳本掃描)
    - 現況：`$0.$catalog.withLock {`
    - 結論：已修正 (task 2.2／3.2，現況見 `apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift`、`LookupManagementFeatureTests+PaymentMethodCorrection.swift` 與其他拆分測試檔)
- L616 `D1` 必擋：宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func editConfirmationFailureLeavesLookupStateUntouched() async {`
    - 結論：已修正 (task 2.2／3.2，現況見 `apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift`、`LookupManagementFeatureTests+PaymentMethodCorrection.swift` 與其他拆分測試檔)
- L616 `TS3` 違規：@Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func editConfirmationFailureLeavesLookupStateUntouched() async {`
    - 結論：已修正 (task 2.2／3.2，現況見 `apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift`、`LookupManagementFeatureTests+PaymentMethodCorrection.swift` 與其他拆分測試檔)
- L638 `FM1` 必擋：行寬超過 100 (腳本掃描)
    - 現況：`192 字元`
    - 結論：已修正 (task 2.2／3.2，現況見 `apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift`、`LookupManagementFeatureTests+PaymentMethodCorrection.swift` 與其他拆分測試檔)
- L638 `FM15` 違規：超過三個參數卻放在同一行 (腳本掃描)
    - 現況：`$0[PaymentMethodRepository.self].applyPaymentMethodEdit = { [box] (_: String, _: String, _: PaymentMethodFlags, _: [LedgerOrder]) async throws(PaymentMethodPersistenceError) in`
    - 結論：已修正 (task 2.2／3.2，現況見 `apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift`、`LookupManagementFeatureTests+PaymentMethodCorrection.swift` 與其他拆分測試檔)
- L696 `D1` 必擋：宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func editWithNoAffectedOrdersAppliesFlagsWithoutConfirmation() async {`
    - 結論：已修正 (task 2.2／3.2，現況見 `apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift`、`LookupManagementFeatureTests+PaymentMethodCorrection.swift` 與其他拆分測試檔)
- L696 `TS3` 違規：@Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func editWithNoAffectedOrdersAppliesFlagsWithoutConfirmation() async {`
    - 結論：已修正 (task 2.2／3.2，現況見 `apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift`、`LookupManagementFeatureTests+PaymentMethodCorrection.swift` 與其他拆分測試檔)
- L733 `CL2` 違規：多行 closure 使用 $0 (腳本掃描)
    - 現況：`$0.$catalog.withLock {`
    - 結論：已修正 (task 2.2／3.2，現況見 `apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift`、`LookupManagementFeatureTests+PaymentMethodCorrection.swift` 與其他拆分測試檔)
- L754 `D1` 必擋：宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func editWithUnchangedFlagsRenamesWithoutRetroactiveConfirmation() async {`
    - 結論：已修正 (task 2.2／3.2，現況見 `apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift`、`LookupManagementFeatureTests+PaymentMethodCorrection.swift` 與其他拆分測試檔)
- L754 `TS3` 違規：@Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func editWithUnchangedFlagsRenamesWithoutRetroactiveConfirmation() async {`
    - 結論：已修正 (task 2.2／3.2，現況見 `apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift`、`LookupManagementFeatureTests+PaymentMethodCorrection.swift` 與其他拆分測試檔)
- L781 `D6` 違規：註解結尾加中文句號 (腳本掃描)
    - 現況：`// 只有改名且旗標未變更時，不顯示確認。`
    - 結論：已修正 (task 2.2／3.2，現況見 `apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift`、`LookupManagementFeatureTests+PaymentMethodCorrection.swift` 與其他拆分測試檔)
- L794 `CL2` 違規：多行 closure 使用 $0 (腳本掃描)
    - 現況：`$0.$catalog.withLock {`
    - 結論：已修正 (task 2.2／3.2，現況見 `apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift`、`LookupManagementFeatureTests+PaymentMethodCorrection.swift` 與其他拆分測試檔)
- L814 `D1` 必擋：宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func editFlagsChangedCoversEachFlagAndMissingStoredEntry() async {`
    - 結論：已修正 (task 2.2／3.2，現況見 `apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift`、`LookupManagementFeatureTests+PaymentMethodCorrection.swift` 與其他拆分測試檔)
- L814 `TS3` 違規：@Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func editFlagsChangedCoversEachFlagAndMissingStoredEntry() async {`
    - 結論：已修正 (task 2.2／3.2，現況見 `apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift`、`LookupManagementFeatureTests+PaymentMethodCorrection.swift` 與其他拆分測試檔)
- L815 `S·三元素 tuple` 違規：三元素 tuple (審查員判讀)
    - 問題：以 `(Bool, Bool, Bool)` 表達三個付款旗標，已有 `PaymentMethodFlags` 型別可用
    - 修法：改為 `[PaymentMethodFlags]`
    - 結論：已修正 (task 2.2／3.2，現況見 `apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift`、`LookupManagementFeatureTests+PaymentMethodCorrection.swift` 與其他拆分測試檔)
- L821 `S·以迴圈取代參數化` 違規：以迴圈取代參數化 (審查員判讀)
    - 問題：for 迴圈跑三組旗標後又附加「主檔缺少旗標」情境，一個測試涵蓋兩種行為
    - 修法：旗標情境改 `@Test(arguments:)`，缺少旗標拆成獨立測試
    - 結論：已修正 (task 2.2／3.2，現況見 `apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift`、`LookupManagementFeatureTests+PaymentMethodCorrection.swift` 與其他拆分測試檔)
- L866 `CL2` 違規：多行 closure 使用 $0 (腳本掃描)
    - 現況：`$0.$catalog.withLock {`
    - 結論：已修正 (task 2.2／3.2，現況見 `apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift`、`LookupManagementFeatureTests+PaymentMethodCorrection.swift` 與其他拆分測試檔)
- L907 `CL2` 違規：多行 closure 使用 $0 (腳本掃描)
    - 現況：`$0.$catalog.withLock {`
    - 結論：已修正 (task 2.2／3.2，現況見 `apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift`、`LookupManagementFeatureTests+PaymentMethodCorrection.swift` 與其他拆分測試檔)
- L924 `C4` 必擋：@unchecked Sendable (Mock 與包裝非 Sendable 第三方物件以外) (腳本掃描)
    - 現況：`private final class PaymentMethodEditTestBox: @unchecked Sendable {`
    - 結論：已修正 (task 2.2／3.2，現況見 `apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift`、`LookupManagementFeatureTests+PaymentMethodCorrection.swift` 與其他拆分測試檔)
- L924 `S·替身記錄方式` 建議：替身記錄方式 (審查員判讀)
    - 問題：替身以公開可寫的 `fetchCount`、`applyCount`、`appliedOrders` 記錄呼叫，命名不含方法名，也沒有唯讀保護
    - 修法：改名為 `fetchOrdersCallCount`、`applyPaymentMethodEditCallCount`、`applyPaymentMethodEditReceivedArguments`，或改用 `LockIsolated`
    - 結論：已修正 (task 2.2／3.2，現況見 `apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift`、`LookupManagementFeatureTests+PaymentMethodCorrection.swift` 與其他拆分測試檔)
- L926 `MK1` 必擋：MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Data Properties`
    - 結論：已修正 (task 2.2／3.2，現況見 `apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift`、`LookupManagementFeatureTests+PaymentMethodCorrection.swift` 與其他拆分測試檔)
- L943 `D2` 必擋：有參數卻缺 - Parameter (腳本掃描)
    - 現況：`init(fetchResults: [[LedgerOrder]]) {`
    - 結論：已修正 (task 2.2／3.2，現況見 `apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift`、`LookupManagementFeatureTests+Support.swift`)
- L968 `N6` 建議：單字母泛型參數 (確認是否為無語意工具函式) (腳本掃描)
    - 現況：`static func withIsolatedCatalog<R>(`
    - 結論：已修正 (task 3.2，泛型已改名為 `Output`，現況見 `apps/ios/BuyLedgerTests/LookupCatalog+TestIsolation.swift`)
- L968 `S·泛型參數單字母` 違規：泛型參數單字母 (審查員判讀)
    - 問題：`withIsolatedCatalog<R>` 使用單字母泛型參數
    - 修法：改為 `<Output>`
    - 結論：已修正 (task 3.2，泛型已改名為 `Output`，現況見 `apps/ios/BuyLedgerTests/LookupCatalog+TestIsolation.swift`)
- L980 `D2` 必擋：有參數卻缺 - Parameter (腳本掃描)
    - 現況：`static func makePaymentOrder(id: String, paymentMethod: String) -> LedgerOrder {`
    - 結論：已修正 (task 2.2／3.2，現況見 `apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift`、`LookupManagementFeatureTests+PaymentMethodCorrection.swift` 與其他拆分測試檔)
- L980 `S·Fixture 命名與預設值` 違規：Fixture 命名與預設值 (審查員判讀)
    - 問題：`makePaymentOrder` 不叫 fixture、參數無預設值，與 PaymentMethodPersistenceTests 的同名函式各自維護
    - 修法：改用共用 `LedgerOrder.fixture(...)`，覆寫付款相關欄位
    - 結論：已修正 (task 3.2，現況 helper 以共用 `LedgerOrder.fixture(...)` 建立訂單並覆寫付款測試欄位，見 `apps/ios/BuyLedgerTests/LookupManagementFeatureTests+Support.swift:86`)
- L1013 `FM1` 必擋：行寬超過 100 (腳本掃描)
    - 現況：`110 字元`
    - 結論：已修正 (task 2.2／3.2，現況見 `apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift`、`LookupManagementFeatureTests+Support.swift`)
- L1013 `D2` 必擋：有參數卻缺 - Parameter (腳本掃描)
    - 現況：`static func retroactiveConfirmationAlert(count: Int) -> AlertState<LookupManagementFeature.Action.Alert> {`
    - 結論：已修正 (task 2.2／3.2，現況見 `apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift`、`LookupManagementFeatureTests+Support.swift`)
