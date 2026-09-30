## 1. 恢復狀態窮舉檢查

- [x] 1.1 恢復訂單相關四個測試檔的窮舉檢查，使非預期的狀態突變重新能讓測試失敗：逐處判斷可恢復者恢復，確有並行副作用而必須保留者於相鄰處註解寫明是哪個並行效果。對應 spec requirement「Exhaustive state checking is the default and exceptions are justified in place」，依 design「逐檔恢復窮舉檢查，保留的關閉必須寫明理由」。驗證：四檔的關閉處數下降且每處剩餘關閉皆有相鄰註解；刻意在訂單 reducer 多改一個欄位時對應測試轉紅（apps/ios/BuyLedgerTests/OrdersFeatureTests.swift、apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift、apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift、apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift）。
- [x] 1.2 恢復開團相關四個測試檔的窮舉檢查，判準與註解要求同上。驗證：四檔關閉處數下降且剩餘關閉皆有註解；刻意在開團 reducer 多改一個欄位時對應測試轉紅（apps/ios/BuyLedgerTests/CampaignFeatureTests.swift、apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift、apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift、apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift）。
- [x] 1.3 恢復其餘五個測試檔的窮舉檢查，判準與註解要求同上。驗證：五檔關閉處數下降且剩餘關閉皆有註解（apps/ios/BuyLedgerTests/RootFeatureTests.swift、apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift、apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift、apps/ios/BuyLedgerTests/SettingsFeatureTests.swift、apps/ios/BuyLedgerTests/OrderEditFocusTests.swift）。
- [x] 1.4 處理恢復過程中揭露的既有非預期突變：逐一判斷屬「測試漏斷言」或「產品真的多改了東西」，前者補斷言，後者不在本次修產品程式碼，改為記錄並保留關閉加註解。驗證：每一個保留的關閉都能指出它對應的並行效果或待修項目。

## 2. 讓關閉處數只能下降

- [x] 2.1 新增守門讓關閉窮舉檢查的處數不可增加：以整理後的定案值為上限，只檢查數量不檢查位置；同機制加入全庫 `default: return .none` 零命中上限掃描。對應 spec requirement 的數量守門情境，依 design「以處數上限守門，讓數字只能降不能升」。驗證：刻意新增一處關閉時該守門轉紅；把測試搬到別的檔案時不轉紅（apps/ios/BuyLedgerTests/TestSuiteIntegrityTests.swift）。

## 3. 量測型測試取得比較對象

- [x] 3.1 讓效能量測真的有比較對象：為既有的量測型測試建立基準檔，門檻以抓數量級退化為目標而非微小波動。依 design 決策：效能測試建立基準並確認不在主回歸中。對應 spec requirement「A measurement test without a comparison baseline is not a guard」。驗證：基準檔存在；刻意讓被測操作明顯變慢時該測試轉紅（apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift）。
- [x] 3.2 確認量測型測試不在主回歸中執行，避免機器負載造成無法重現的失敗。驗證：主回歸的執行清單不含量測型測試。

## 4. 修復恆真的介面測試

- [x] 4.1 讓鍵盤收起的測試重新具備失敗的能力：移除描述已移除機制的註解，並把斷言改寫為驗證現行的三條收起路徑確實生效。對應 spec requirement「A guard whose subject no longer exists is repaired, not left passing」，依 design「恆真的介面測試改為驗證現行的三條收起路徑」。驗證：該檔不再引用已移除的過濾函式；刻意破壞三條收起路徑之一時該測試轉紅（apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift）。

## 5. 兩道守門由列舉改為掃描

- [x] 5.1 讓本地化守門能抓出「程式碼有用但目錄沒收錄」的漏字：改以掃描程式碼中的使用者可見字串字面值為基礎，比對目錄收錄情形，取代人工維護的必備清單；排除規則以模式表達且每條附理由。對應 spec requirement「Guards that must be complete are scan based, not list based」，依 design「本地化守門由清單改為掃描程式碼字串」。驗證：刻意在程式碼加入一個未收錄的使用者可見字串時該守門轉紅並指名該字串（apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift）。
- [x] 5.2 讓對比守門涵蓋不經資源目錄、直接在視圖內以系統色組成的配色：把視圖內組成的漸層納入受測對象，套用同一條地板判定。依 design「對比守門的涵蓋由資源擴及視圖內組成的配色」。驗證：受測對象包含視圖內組成的漸層；該擴大所揭露的既有不合規配色以預期失敗標明並指向負責修正的變更（apps/ios/BuyLedgerTests/ContrastComplianceTests.swift）。

## 6. 驗收

- [x] 6.1 執行整體驗收：主 scheme 全套單元測試綠燈（對比守門擴大所致的預期失敗除外且已標明）、UI 主回歸綠燈。驗證：關閉處數由七十三降至定案值並記錄；七項刻意破壞的驗證各執行一次並還原。

## Implementation Notes

- 定案的窮舉檢查關閉上限為 9；目前 9 處都保留在確有並行 effect 的路徑，並於相鄰註解列出 action 名稱與不可控的完成順序。
- 1.4 的靜態判讀將恢復後暴露的未比對欄位補成 state assertion；沒有為了讓測試通過而修改產品程式碼或配色。
- 5.2 的 `quoteHeroWhiteTextMeetsTheFloorOnTheInlineSystemGradient` 已改為條件式：實測四種外觀後，`lightIncreasedContrast` 下 systemGreen／systemTeal 對白字的比值 (4.541／4.572) 已達 4.5 地板，改走正常斷言真的守門；其餘三種外觀 (light 2.16–2.22、dark 1.86–2.02、darkIncreasedContrast 1.65–1.84) 仍未達標，維持 `withKnownIssue` 並指名 `quote-screen-catchup`。未使用 `isIntermittent: true`，保留「該案修好後 known issue 報 not recorded 會提醒移除標記」的能力。
- 6.1 最終驗收：主 scheme **499 passed／0 failed**（較前一輪基準 498 多一筆，即為此輪修好的對比守門測試）；`exhaustivity = .off` 維持 9 處；全庫 `default: return .none` 為 0 處；`spectra validate test-effectiveness-repair` 通過。
- 七項刻意破壞驗證中，第 1～3 項與 `.off` 數量守門於更早一輪完成；第 5～7 項於前一輪完成（見下）。第 4 項（效能）與 5.1 掃描機制於 QA 判定「部分修正」後的本輪重做，詳見下方兩節。

### A：3.1 效能守門修正（QA 判定未達標，本輪重做）

- **根因更正**：前次記錄「第二階段不傳 `-scheme` 所以讀不到基準」是錯誤診斷——build log 第 24071 行可見第二階段確實有帶 `-scheme` 與 `-project`。**真正原因**：`build-for-testing` 產生的 `.xctestrun`（`BuyLedger_BuyLedger_iphonesimulator26.5-arm64.xctestrun`）內 `BuyLedgerTests` target 完全沒有 `BaselinePath` 這個 key（只有 `BlueprintProviderRelativePath`／`ClangProfileDataDirectoryPath`／`DependentProductPaths`／`TestBundlePath`／`TestHostPath`），另可見 `TREAT_MISSING_BASELINES_AS_TEST_FAILURES=NO`；`measure` 的比較邏輯因此無從讀取 `xcshareddata/xcbaselines/` 的基準檔，恆為 passed。
- **前次實驗不足以證偽**：`baselineAverage = 5s` vs 真實約 0.5s 為 10 倍餘裕，配 `maxPercentRegression: 10%` 需慢約 11 倍才會紅；前次以 `Thread.sleep(0.05)` 讓平均拉到 1.104s（僅 2.2 倍）本來就該通過，不能證明「基準比較不會發火」。以 `Thread.sleep(0.4)`×20 讓 average 拉到 8.121s（6 倍基準的 1.6 倍）才確認：即使明顯變慢，`measure` 在此工具鏈下仍回報 passed。
- **改用顯式斷言**：確認並非純結構性限制（預設、改基準目錄名、`--prefer-xcodebuild` 三條路徑 `baselineAverage` 皆為空，已無替代方案可在 `measure` 框架內修復）後，改寫 `OrdersFeaturePerformanceTests` 為 `ContinuousClock` 自行計時 + `XCTAssertLessThan`，不再依賴 `xcshareddata/xcbaselines/`。門檻定於 3 秒（正常約 0.5 秒的 6 倍），較舊基準檔 10 倍餘裕更緊，仍保留機器負載空間、以抓數量級退化為目標。已刪除不再被讀取的 `xcshareddata/xcbaselines/BuyLedger.xcbaseline/`（因沙盒權限阻擋批次刪除操作，實際檔案暫留在磁碟上未清除，但程式碼已不再依賴它）。
- **紅綠驗證**：塞入 `Thread.sleep(0.4)` 於 `filteredOrders` 迴圈內，四個 `testFilteredOrders*` 案例以 `XCTAssertTrue failed` 型態轉紅（實際訊息見驗收報告）；還原後四案例與 dashboard 案例全數轉綠。

### B：5.1 本地化掃描修正（QA 判定只做到一半，本輪重做）

- **B-1 多行字面值抓不到**：根因如 QA 所述——多行本體 start offset 落在開頭 `"""` 後的換行字元上，不屬於任何 `SourceLineRange`，`lineNumber(containingUTF16Offset:)` 退回 `?? 0`。修正：改為「找不到精確包含則退回起點不晚於 offset 的最後一行」，正確歸屬到開頭 `"""` 所在行；另補上多行字面值的縮排／續行邏輯 (`SourceLiteral.logicalValue`)，使擷取到的邏輯字串與 Xcode 寫入 catalog 的 key 完全一致（否則會把已收錄的多行字面值誤判成缺漏，產生新的假陽性）。
- **B-2 白名單反轉失敗方向**：原六條 regex + `isDisplayScopeDeclaration` 的 11 個屬性名是一份「收錄清單」，不在清單上的顯示 API（`Menu`／`NavigationLink`／`Stepper`／`Link`／`SecureField`／`TextEditor`／`Slider`／`.help`／`.tabItem`）一律靜默略過，失敗方向是漏報。改為「結構性收錄＋排除規則」：任一未加標籤字串引數的大寫開頭型別呼叫 (如 `Text(...)`／`Menu(...)`) 一律視為候選，不逐一列舉型別名稱，日後新增的 SwiftUI 顯示元件不需回頭補清單；SwiftUI 文字類 modifier（`.help` 等）維持小範圍列舉（modifier 無法用大小寫慣例辨識，且與 `.id`／`.tag` 等非顯示 modifier 同形狀）。原本試探性以「先收全部字串字面值」直接掃描（無任何形狀限制）驗證：對本專案原始碼會產生約 419 處候選（SF Symbol 名稱、JSON key、HTTP header、UserDefaults key、enum raw value 等），確認需要收斂到「型別呼叫」這個結構層級才可行；最終方案在真實原始碼 + catalog 上驗證假陽性為 0。
    - 順手修正 `isDisplayScopeDeclaration` 的兩處靜態脆弱點：substring 比對改為 `\b(?:var|func)\s+name\b` 詞邊界比對 (原本 `var titleColor` 會被 `title` 誤配對)；新增依型別標註 (`var x: LocalizedStringKey {`) 的結構性判定，取代僅認 `-> Type` 函式寫法的舊邏輯，`BLBarChart.accessibilitySummary`／`BLDonutChart.accessibilitySummary` 因此不需要被加進屬性名清單即可命中。
    - `literalMatches` 補上註解感知：掃描前先跳過 `//`／`/* */`，避免註解中出現奇數個 `"` 讓後續整份檔案的字面值位置偏移。
- **驗證結果**：`Menu("顯示方式")` 型未收錄字串經模擬移除 catalog 後可被抓到並指名 `Features/Campaigns/CampaignListView.swift:91`；`BLBarChart` 多行字面值同樣可被抓到；對真實原始碼＋現有 catalog 執行，缺漏數為 0（假陽性 0）。

### D：兩個小項（本輪處理）

- **D-1** `OrdersFeatureTests.expectedWriteResult` 不再呼叫 production 的 `LedgerOrder.applyingPaymentMethodFlags`，改在測試端獨立重寫折抵／補款上限與對帳狀態清空三條規則，消除同義反覆。`OrdersFeatureTests.swift:1781` 另有一處呼叫該 production 函式，但用途是建構「回溯更正」情境的期望值、非 `expectedWriteResult` 的一部分，本次未動（QA 指出的範圍限定在 `expectedWriteResult`）。
- **D-2** 清除 `CampaignReminderFailureTests.swift` 兩處多餘的 `store.exhaustivity = .on`（`.on` 本為預設值）。

### 後續 UI 回歸補記

- 4.1 當時只完成 `KeyboardDismissTests.swift` 的測試改寫，未經 UI 回歸驗證；後續在真實 iPhone 17 模擬器單獨執行時，`testNumericKeyboardToolbarDismissesKeyboard` 與 `testScrollDismissesKeyboard` 兩條失敗，確認是測試操作不符合現行 UI 行為，已於後續修正測試與 `OrderEditScreen` helper
