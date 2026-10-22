## Context

- 訂單編輯表單是 `OrdersView` 以 `.sheet(item:)` 呈現的 `OrderEditView`，表單內的選擇器 (訂單來源、類別、開團、付款方式、對帳狀態、幣別) 與照片檢視依 `sheet-nested-presentation` 以推入方式呈現在同一個 `NavigationStack(path:)` 上，路由是 `OrderEditPickersFeature.State.pickerRoute`。
- 表單由容器直接呼叫 `OrdersPresentationFeature.State.present(_:)` 呈現 (`ios-navigation.md` 的「同一次更新內必須完成的呈現」例外)，關閉靠 `OrderEditFeature` 的 `@Dependency(\.dismiss)`：取消時未修改直接 `dismiss()`，儲存時先送 `delegate(.saveRequested)` 再 `dismiss()`。
- 根因見 proposal：容器直接改 `destination` 時，TCA `PresentationReducer` 的 dismiss 長效 effect 延到第一個送進呈現 reducer 的 action 才啟動，而那個 action 是表單 `.task` 內 `await store.send(.view(.task)).finish()`；推入選擇器取消 `.task` 時 dismiss effect 一起被取消。
- 同型盤點 (2026-10-17 以程式碼確認)：使用 `@Dependency(\.dismiss)` 的四個 Feature 中，`CampaignEditView` 與 `OrderMergeCandidateSheet` 沒有 `.task`，`AISummaryView` 有 `await … .finish()` 但畫面內沒有推入目的地，`.task` 只在 sheet 關閉時結束，都不受影響。
- 種子 `BLUITestSeedData` 屬 App target 的 `#if DEBUG` 組裝根 (`App/Testing/`)，`seed(_:into:referenceDate:)` 為 internal，單元測試可以直接呼叫並讀回記憶體容器。

## Goals / Non-Goals

**Goals:**

- 訂單編輯表單不論是否推入過選擇器或照片檢視，取消 (未修改) 與儲存都會關閉表單。
- 以 UI 測試守住上述行為，並以變異證明測試在缺陷存在時會失敗。
- UI 測試種子與 SwiftUI Preview 假資料中的付款方式名稱恢復為使用者資料 (中文名稱)，並以單元測試守住種子不再出現本地化 key 形狀的資料值。
- 把這條 TCA 呈現生命週期的 gotcha 寫進 `.claude/rules/ios-navigation.md`。

**Non-Goals:**

- 不改呈現架構：容器仍以 `present(_:)` 直接設定 `destination`，不改成經呈現 reducer 的 action。
- 不改 `AISummaryView` 的 `.task`：它的 `.view(.task)` 會啟動摘要串流，等待完成讓串流隨畫面取消是刻意的，且畫面內沒有推入目的地。
- 不還原單元測試中被 `f03a82c` 換成 key 形狀的測試資料 (約 20 個測試檔、30 餘處)：那些字串只是測試內的任意名稱，不出現在畫面上也不影響斷言語意，且 6c 已大幅重整相關測試檔；另案清理由使用者決定。
- 不處理表單 `.task` 在每次從選擇器返回時重新觸發的焦點行為 (新訂單在焦點為 `nil` 時會回到客戶名稱)，本 change 只移除等待完成，送出的 action 與 reducer 邏輯不變。

## Decisions

### 表單 `.task` 改為只送出 `.view(.task)` 不等待完成

`OrderEditView` 的 `.task` 由 `await store.send(.view(.task)).finish()` 改成 `store.send(.view(.task))`。`.view(.task)` 在 reducer 內只做「新訂單且尚無焦點時設定客戶名稱焦點」並回傳 `.none`，沒有需要隨畫面取消的 effect；不等待完成後，第一次送進呈現 reducer 時啟動的 dismiss effect 由 store 持有，不再隨 `.task` 取消。

替代方案：

- **容器改送 action 給呈現子 Feature 來呈現**：讓 `ifLet` 在呈現當下啟動 dismiss effect，從架構上消除延遲啟動。但要改 `ios-navigation.md` 已定的「容器直接呼叫子 State 的 `mutating` 方法」例外，且 Root 開新訂單需要在同一次更新內切分頁並掛上 sheet，改動面與風險都遠大於缺陷本身，不採用。
- **在表單 `.task` 之外另送一個無作用 action 喚醒呈現 reducer**：依賴 TCA 內部的延遲啟動細節，讀程式碼的人看不出用意，不採用。
- **自行以 `destination = nil` 取代 `dismiss()`**：要讓表單知道父層結構，違反「子層以 delegate 交父層」的規則，不採用。

### 以 UI 測試守住選擇器返回後的關閉行為

缺陷發生在 SwiftUI 取消 `.task` 的生命週期，`TestStore` 無法重現畫面消失，所以守門放在 UI 測試：

- 在 `OrderEditDirtyTests` (訂單編輯表單的取消流程測試) 新增「進過選擇器返回且未修改，取消會關閉表單」：開新訂單、推入訂單來源選擇器、按返回、按取消，斷言表單根元素消失且回到訂單清單。放這裡而不放 `OrderCreateTests`，是因為後者已 265 行、加入後逼近 300 行上限，且取消情境與本檔主題一致；依測試命名規則，改到的本檔既有兩條測試同時改為 `<方法>_<情境>_<預期>` 三段式並補 Given／When／Then 標記。
- 加強既有 `testCreateOrder_填寫並儲存訂單_清單出現新訂單`：它已經經過訂單來源與類別兩個選擇器再儲存，補上「儲存後表單根元素消失」的斷言，放在查清單之前；不然清單一直存在於 sheet 底下，表單沒關也會通過。
- 返回鍵由 `OptionPickerScreen` 新增的返回操作點擊，定位 `BLAccessibilityID.Common.backButton` (系統返回鍵語言無關的 identifier)。sheet 底層畫面 (如從推入的訂單詳情開啟編輯) 的返回鍵仍在可及性樹上，所以只點畫面上可互動的那一個 (比照 `ios-ui-tests.md` 對 sheet 內重複系統元件的處理)，逾時找不到就附診斷失敗。

### 種子資料值以單元測試掃描所有 profile

新增 `BLUITestSeedDataTests`，對 `BLUITestSeedProfile.allCases` 每個 profile 以記憶體容器呼叫 `BLUITestSeedData.seed`，讀回四種主檔記錄的名稱與訂單的訂單來源、類別、付款方式、對帳狀態，斷言沒有任何值符合 String Catalog 結構化 key 的形狀：沿用 `LocalizationCatalogTests.structuredKeysFormat_結構化英文Key_符合點記號與小駝峰規範` 的格式 `^[a-z]+(\.[a-z][a-zA-Z0-9]*){2,3}$` (三或四段點記號、小寫開頭)。以形狀判定而非列舉特定 key，任何一筆被批次替換成 key 都會被抓到；目前種子值 (中文、`LINE Pay`、`Apple Pay`、`Instagram` 等) 都不含點號，不會誤判。

### 只還原 App target 內被誤換的資料值

還原 `BLUITestSeedData` 的兩筆付款方式名稱，以及四處 Preview 假資料 (`LookupManagementView` 與 `LookupItemList` 的付款方式管理預覽、`OrderFilterPreviewFixtures`、`PaymentMethodEditorSheet` 編輯預覽的 `initialName`；最後一處由 review 補抓) 中的 `"銀行匯款"`、`"貨到付款"`，值以 `f03a82c` 之前的原文為準。`LookupItemList` 預覽內依名稱回傳旗標的 `switch` 分支一併還原，維持名稱與旗標對應。

### 種子檔依整檔對齊裁決拆檔

apply 時 style 檢查顯示 `BLUITestSeedData.swift` 不含檔頭與空行 754 行、另有 64 筆既有違規。依使用者 2026-10-09 裁決「改到的檔一律整檔對齊，不因只改一行延後」(登記例外已被否決過)，本 change 改到這個檔就要整檔對齊：依職責拆成主檔與 `+Orders`、`+Campaigns`、`+Analytics`、`+Builders` 四個 extension 檔 (一檔一個頂層型別的擴充，比照專案既有 `<型別>+<功能>.swift`)，跨檔使用的 helper 與常數改 internal，並修正全部既有違規。只動排版與檔案歸屬，每個 profile 寫入的資料不變。3.2 style 閘門另依 coding-style 條文修正出錯路徑：寫入失敗由只 `print` 改為 `fatalError`，商品 UUID 與日期推導失敗由 `??` 退回預設值改為 `preconditionFailure`，並刪除因此不再使用的 `fallbackItemID` 與單一呼叫點的 `decimal(_:)` (`cardFeeRate` 內聯為等值的 `Decimal(sign: .plus, exponent: -3, significand: 15)`)；正常路徑寫入的資料不變。

替代方案：登記行數例外只修兩個字面值 (違反裁決，不採用)；把種子改成資料檔讀取 (改變載入機制，超出本 change)。

### 把呈現生命週期的 gotcha 寫進導覽規則

`.claude/rules/ios-navigation.md` 的「呈現」節加一條：容器直接設定 `destination` 時 dismiss effect 延到第一個送進呈現 reducer 的 action 才啟動，sheet 內有推入目的地的畫面不可在 `.task` 內 `await store.send(...).finish()`。刪掉它會讓下一個在 sheet 內加推入導覽的畫面重蹈覆轍，符合「刪掉會讓 Claude 出錯」的條件。

### 付款方式編輯器送出只由編輯器自己返回

`PaymentMethodEditorSheet.submitDraft()` 送出後自己呼叫 `dismiss()` 退回選擇器；`OptionPickerSheet` 傳入的送出 closure 不再呼叫選擇器的 `dismiss()`，否則同一次送出 dismiss 兩次，第二次會關掉訂單表單 sheet。以 `OrderEditAddOptionTests` 守住，並以變異 (加回 `dismiss()`) 證明測試會失敗。

### 選擇器介面依模式分組

使用者 2026-10-17 裁決 `#Preview` 與本體同檔 (kit `formatting.md` 的 Preview 區在檔尾)，並要求評估 init。原 init 有 19 個參數，把互斥模式寫成平行參數 (單選的 `selected`／`onSelect`／`clearOption` 與多選的 `multiSelection` 並存；`allowsAdd` 預設 `true` 但新增文案預設空字串；`onAdd` 與 `onAddPaymentMethod` 靠後者是否為 `nil` 切換)，且有過度轉接 (`OptionPickerList` 只有一個呼叫端卻原樣收 8 個參數、清除列要重包一層加 `dismiss()`、付款方式送出 closure 經選擇器轉手)。改為 `Selection` (單選／多選) 與 `Addition` (alert／付款方式編輯器) 兩個 enum，加上 `AddPrompt`、`EmptyState`、`Labeling` 三個值型別，不合法的組合無法編譯；選取與清除後的關閉移到 `OptionPickerList`，付款方式送出 closure 直接交給編輯器；4 個幣別呼叫端共用 `CurrencyDisplayName.optionLabeling(locale:)`。

替代方案：單一 Configuration struct 收原本 19 個欄位 (只是搬家，不合法組合照樣寫得出來，不採用)；`PaymentMethodEditorSheet.SubmitAction` 的 4 個 Bool 改成 struct (會牽動主檔管理頁，使用者決定這次不動)。

## Implementation Contract

**行為**：

- 訂單編輯表單 (新增與編輯既有訂單皆同) 推入任一選擇器或照片檢視再返回後，未修改時按取消立即關閉表單；必填齊備時按儲存寫入並關閉表單。有未儲存變更時按取消仍先出現捨棄確認，行為不變。
- 以 UI 測試模式啟動任何種子 profile，主檔管理與訂單編輯顯示的付款方式名稱都是中文資料值 (「信用卡」「銀行轉帳」「無卡」「貨到付款」「LINE Pay」「Apple Pay」)。

**介面**：

- `OptionPickerScreen` 新增返回操作 `tapBack(file:line:)`：在 10 秒內輪詢導覽列中 identifier 為 `BLAccessibilityID.Common.backButton` 且畫面上可互動的返回鍵並點擊，找不到時以 `failWithDiagnostics` 失敗。
- 新 UI 測試 `OrderEditDirtyTests.testCancel_進過選擇器返回且未修改_關閉表單`；同檔既有兩條改名為 `testCancel_有變更後選繼續編輯_停留在表單`、`testCancel_有變更後選捨棄變更_關閉表單並回到清單` (斷言不變)；`OrderCreateTests.testCreateOrder_填寫並儲存訂單_清單出現新訂單` 名稱不變、補「表單關閉」斷言。
- 新單元測試檔 `BuyLedgerTests/BLUITestSeedDataTests.swift`：參數化測試 `seed_各種子組合_主檔與訂單欄位不含本地化Key` (Swift Testing，`arguments: BLUITestSeedProfile.allCases`)，以及逐列比對規格範例表的 `seed_主檔種子組合_付款方式名稱與旗標符合規格範例` (verify 後補)。

**失敗模式**：

- UI 測試在表單未關閉時以 `failWithDiagnostics` 附截圖與可及性樹失敗，不以 `XCTSkip` 掩蓋。
- 種子測試失敗訊息列出 profile、欄位與違規值。

**驗收**：

- 修正前：新 UI 測試與加強後的建立訂單測試在 iPhone 17 失敗 (表單未關閉)。修正後兩條通過；把 `.task` 暫時改回 `await … .finish()` 時兩條再次失敗，還原後 `cmp` 與修正版相同。
- 種子測試修正前失敗 (列出兩筆付款方式)、修正後通過；暫時把一筆名稱改回 key 時失敗。
- `mobilebuildmcp ui-automation` 以 `lookupsOnly` 種子讀取付款方式管理清單，含「無卡」「貨到付款」且無 key 字串。
- 完整單元回歸、iPhone 17 UI 主回歸通過；iPad 執行 `OrderCreateTests` 與 `OrderEditDirtyTests` 通過。

**範圍**：

- 範圍內：`OrderEditView` 的 `.task`、上述 UI 與單元測試、`OptionPickerScreen` 返回操作 (含同檔整檔對齊)、種子與三處 Preview 的資料值、`BLUITestSeedData` 拆檔與整檔對齊、`ios-navigation.md` 一條 gotcha、`OptionPickerSheet` 的付款方式送出修正與依模式重整 (含 `OptionPickerList`、`CurrencyDisplayName` 與 5 個呼叫端檔的整檔對齊)、build number。
- 範圍外：Non-Goals 所列各項；其他 sheet 的 `.task`；`OrdersPresentationFeature` 與 `OrderEditFeature` 的 reducer 邏輯。

## Risks / Trade-offs

- [不等待完成後，`.view(.task)` 日後若加入長效 effect，會在表單關閉後繼續執行] → gotcha 條目寫明理由；需要長效 effect 時改由 reducer 以可取消 id 管理，或把啟動呈現改成經呈現 reducer 的 action。
- [UI 測試依賴系統返回鍵 identifier `BackButton`] → 專案已在 `ios-ui-tests.md` 記錄這是語言無關的系統 identifier，`PhotoViewerScreen` 與 `CampaignDetailScreen` 已在用。
- [形狀判定可能把含兩到三個點號、各段小寫開頭的真實名稱誤判為 key] → 目前種子沒有這類名稱；日後若需要，測試的失敗訊息會指出該值，再調整種子或判定。
