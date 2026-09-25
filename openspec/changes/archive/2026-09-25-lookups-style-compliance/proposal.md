## Summary

把 `apps/ios/BuyLedger/Features/Lookups/` 的 6 個 production 檔與 2 個對應單元測試檔對齊 `/ios-dev-kit`，套用第 3 步定型的 TCA 範本 (Action 分組、父子只經 delegate 溝通、`Reduce(core)`)，並依使用者 2026-09-24 裁決修掉四個會影響使用者的缺陷。這是 ios-dev-kit 修正順序十步計劃的第 4 步，前三步 (`core-codegen-style-compliance`、`shared-designsystem-style-compliance`、`small-features-style-compliance`) 已結案。

## Motivation

2026-09-14 全庫審查在這 8 個檔記錄 **302 筆待修項** (實測值，由報告資料集依檔名篩出，已排除 commit `291d841` 修掉的 247 筆尾隨空白)：production 6 檔 191 筆、單元測試 2 檔 111 筆；合計必擋 119、違規 169、建議 8、已登記例外 6。修正順序表寫的「0／28」只計審查員判讀項，不含腳本掃描項。

排在第 4 位的理由是主檔目錄 (`LookupCatalog`) 被 Orders 與 Campaigns 讀取，要在第 5、6 步動它們之前先穩定。

四類問題必須現在處理：

1. **寫入先改畫面、失敗不回滾** (實際缺陷)：新增與改名先改共享目錄再寫資料庫，寫入失敗時目錄不還原，訂單編輯的選單會出現沒存進資料庫的項目，重開 App 後消失，但已選用它的訂單留著該名稱。改名時 `RootFeature` 也在寫入前就改寫記憶體內的訂單。這違反 `.claude/rules/ios-navigation.md` 的「寫入先落盤、成功才改畫面狀態」。
2. **寫入失敗訊息常駐不清** (實際缺陷)：新增、刪除、改名失敗都寫進載入錯誤用的 `errorMessage`，顯示成清單上方的紅字；它只在重新載入成功時清除，而首次載入後不再重新載入，所以紅字會留到付款方式編輯成功或 App 重啟。違反 `ios-navigation.md` 的「一次性操作失敗與持續性載入失敗不共用狀態欄位」。
3. **付款方式同名會讓畫面崩潰** (潛在缺陷)：`LookupManagementFeature.State` 用 `Dictionary(uniqueKeysWithValues:)` 建三張旗標對應表，資料表沒有唯一性約束 (CloudKit 限制)，同名付款方式會直接 trap。
4. **結構偏離規範**：`LookupManagementFeature.swift` 546 行 (2026-09-24 實測，不含檔頭與空行；上限 300)，`body` 內單一 `switch` 約 360 行；Action 全部平放、四個子表單只有平放的 `saveButtonTapped` 由父層直接攔截；一個畫面有四個 `@Presents`；`RootFeature` 直接攔截子層的 `renameRequested` 與 `paymentMethodEditSucceeded`；`LookupManagementFeatureTests.swift` 1,030 行；另有 30 筆非規範 MARK、29 筆缺 doc comment、33 個測試缺 Given／When／Then。

## Proposed Solution

依使用者 2026-09-24 兩項裁決執行。

**拆分 (裁決一：子 Feature ＋ 同域輔助型別)**

- `LookupManagementFeature` 只留畫面協調：Action 依 `view` → `delegate` → 子層與 `destination` → 內部回應分組，`body` 寫 `Reduce(core)`，同一次請求的成功與失敗合併成單一 `...Response(Result<..., PersistenceError>)`。
- 付款方式更正流程 (取樣受影響訂單 → 確認 → 主檔與訂單原子寫入) 抽成子 Feature `PaymentMethodCorrectionFeature`，比照第 3 步的 `QuoteRateFeature`：沒有自己的 View、不設 `view` 分組、由父層轉送。
- 四種主檔的讀取、新增、刪除、改名分派收進同域輔助型別 `LookupItemOperations`，消除目前四段重複的 `switch kind`。
- 三個子表單改為各自一檔的頂層 Feature (`LookupAddFormFeature`、`LookupRenameFormFeature`、`PaymentMethodEditFormFeature`)，以 `view` 收使用者送出、以 `delegate` 把結果交給父層；`Destination` 移到 `LookupManagementFeature+Destination.swift`，四個 `@Presents` 併成一個 (三種 alert 成為 `Destination` 的 `alert` case)。
- `apps/ios/CLAUDE.md`「大型 reducer 以同域輔助型別拆分，不拆成子 reducer」改寫成與 `tca-architecture.md` 拆分順序一致 (第 3 步抽 `QuoteRateFeature` 時已與該條文矛盾)。

**行為修正 (裁決二：四項全納入)**

- 新增、改名、刪除一律**寫入成功才更新目錄**；改名成功後由 delegate 通知 `RootFeature` 改寫記憶體內的訂單。
- 寫入失敗改以**關掉即消失的 alert** 呈現，沿用既有文案；清單上方的紅字只留給首次載入失敗。
- 付款方式旗標改由 `LookupCatalog` 的單一查詢方法提供 (同名取第一筆)，移除三張對應表。
- `LookupCatalogTests` 的合併旗標測試：審查報告 (2026-09-14) 記的「付款方式合併旗標測試沒走到合併分支」已在第 0 步 commit `4263e45` 修好 (現況先放入「匯款」與已存在的「銀行匯款」兩筆再改名)，task 0.1 抽驗時發現；本步只以變異驗證確認它真的守得住，不改寫它。

**畫面與排版**

- `LookupManagementView` 的 `body` 只放大框架，新增鍵、三種表單與 alert 各自以 `$store.scope(state: \.$destination, action: \.destination).<case>` 綁定；清單列抽成獨立 View 型別，檔案不超過 300 行。
- `LookupNameEditorSheet`、`LookupKind`、`LookupCatalog` 依樣板修正分區、屬性順序與 doc comment；`LookupKind` 補 `CaseIterable`，`addAlert*` 改名 `addForm*` (它們早已不是 alert)。

**守門與驗證**

- `ActionGroupingScanTests` 納入 Lookups 的 View，並讓掃描涵蓋子層 store (`renameStore.send(...)` 這類寫法目前掃不到)。
- 改動任何 production code 之前，先新增主檔管理畫面與名稱表單的 snapshot 測試並錄製基準圖，完工後必須維持綠燈。
- 同樣在改動前新增主檔管理的 UI 測試 (新增、改名、刪除、寫入失敗、首次載入失敗)，為此補五個 `BLAccessibilityID` 與一個模擬主檔寫入失敗的 UI 測試啟動參數；「寫入失敗」那條在改動前轉紅、改動後轉綠，作為行為修正的實測證據。

**測試跟著改**：兩個測試檔依規範補齊 doc comment、Given／When／Then、case key path `receive` 與參數化，1,030 行的 `LookupManagementFeatureTests` 依職責拆檔；`RootFeatureTests` 只改受 delegate 改動影響的主檔測試。測試方法名稱維持單段 lowerCamel (既有裁決)。

## Non-Goals

見 design.md 的 Goals / Non-Goals。

## Alternatives Considered

- **只抽子 Feature (再抽一個「主檔讀寫」子 Feature)**：父層只剩畫面路由，但父子轉送最多；使用者未採用。
- **只用同域輔助型別**：守 `apps/ios/CLAUDE.md` 現行條文不抽子 Feature，估計父層仍可能略超 300 行；使用者未採用。
- **付款方式更正流程整個搬進編輯表單子 Feature**：共用的 `PaymentMethodEditorSheet` 送出後立即關閉，子 Feature 的 Effect 會隨表單關閉被取消，更正流程會中斷；不可行。

## Impact

- Affected specs: lookup-management
- Affected code:
  - Modified:
    - apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift
    - apps/ios/BuyLedger/Features/Lookups/LookupKind.swift
    - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
    - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
    - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
    - apps/ios/BuyLedger/Features/App/RootFeature.swift (兩處主檔攔截改為 delegate；iPad 側邊欄切分頁與智慧分組先清「更多」路徑，使用者 2026-09-24 裁決)
    - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift (側邊欄選取改送 `sidebarTabSelected`)
    - apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift (改名單一交易，使用者 2026-09-25 裁決)
    - apps/ios/BuyLedger/Core/Persistence/NameLookupPersistence.swift (主檔改名規則抽成共用 helper)
    - apps/ios/BuyLedger/Core/Persistence/PaymentMethodPersistence.swift (付款方式改名合併規則抽成共用 helper)
    - apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift (改名交易 closure 取代只改訂單的改名 closure)
    - apps/ios/BuyLedger/Core/Persistence/LookupRecordRenamer.swift (主檔改名共用 helper)
    - apps/ios/BuyLedgerTests/OrderPersistence+LookupTesting.swift (改名交易測試用的讀取 helper)
    - apps/ios/BuyLedgerTests/OrderPersistenceTests.swift 或其 `+<Domain>.swift` 拆分檔 (改名交易測試)
    - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
    - apps/ios/BuyLedgerTests/LookupCatalogTests.swift
    - apps/ios/BuyLedgerTests/RootFeatureTests.swift (主檔相關測試，另補三條 iPad 側邊欄切分頁測試)
    - apps/ios/BuyLedgerTests/ActionGroupingScanTests.swift
    - apps/ios/BuyLedgerTests/ActionGroupingScanTests+Scanner.swift
    - apps/ios/BuyLedgerTests/ActionGroupingScanTests+Scenarios.swift
    - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift (只同步 `LookupKind` 改名後的可見文案屬性名稱)
    - apps/ios/BuyLedgerTests/BLUITestConfigurationTests.swift (只加寫入失敗旗標的解析測試)
    - apps/ios/BuyLedger/App/Testing/BLUITestConfiguration.swift (只加寫入失敗旗標)
    - apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift (只加寫入失敗替身)
    - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift (只加寫入失敗旗標)
    - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID.swift (只加主檔管理的五個 identifier)
    - apps/ios/CLAUDE.md
    - apps/ios/README.md
    - .claude/rules/ios-data-layer.md
    - .claude/rules/ios-navigation.md
    - .claude/rules/ios-unit-tests.md
  - New:
    - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature+Destination.swift (由 LookupManagementDestination.swift 改名並重寫)
    - apps/ios/BuyLedger/Features/Lookups/LookupAddFormFeature.swift
    - apps/ios/BuyLedger/Features/Lookups/LookupRenameFormFeature.swift
    - apps/ios/BuyLedger/Features/Lookups/PaymentMethodEditFormFeature.swift
    - apps/ios/BuyLedger/Features/Lookups/PaymentMethodCorrectionFeature.swift
    - apps/ios/BuyLedger/Features/Lookups/PaymentMethodEditPlan.swift
    - apps/ios/BuyLedger/Features/Lookups/LookupItemAddition.swift
    - apps/ios/BuyLedger/Features/Lookups/LookupItemRename.swift
    - apps/ios/BuyLedger/Features/Lookups/LookupItemOperations.swift
    - apps/ios/BuyLedger/Features/Lookups/SharedKey+LookupCatalog.swift
    - apps/ios/BuyLedger/Features/Lookups/Components/LookupItemRow.swift
    - apps/ios/BuyLedger/Features/Lookups/Components/LookupItemList.swift
    - apps/ios/BuyLedgerTests/LookupManagementFeatureTests+Forms.swift
    - apps/ios/BuyLedgerTests/PaymentMethodCorrectionFeatureTests.swift
    - apps/ios/BuyLedgerTests/LookupCatalog+TestIsolation.swift
    - apps/ios/BuyLedgerTests/SnapshotTests+Lookups.swift
    - apps/ios/BuyLedgerUITests/Screens/LookupManagementScreen.swift
    - apps/ios/BuyLedgerUITests/Tests/More/LookupManagementTests.swift
    - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Lookups/ 下的主檔管理基準圖 (task 0.3 在改動前錄製)
  - Removed:
    - apps/ios/BuyLedger/Features/Lookups/LookupManagementDestination.swift
