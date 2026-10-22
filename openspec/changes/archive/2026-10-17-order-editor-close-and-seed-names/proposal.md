## Problem

- **訂單編輯表單進過選擇器後關不掉**：在訂單編輯表單點任一選擇列 (訂單來源、類別、付款方式等) 推入選擇器，再返回表單，之後工具列的取消與儲存都不會關閉表單；儲存仍會把訂單寫入資料庫，表單卻停在畫面上，使用者只能下滑或重複點擊而不知道是否已存檔。2026-10-17 以 `mobilebuildmcp ui-automation` 在 iPhone 17 (`DDAA3311-B464-4DD3-96B8-360B26AF1929`) 重現：沒進選擇器時取消可關閉表單；推入訂單來源選擇器、按返回、再按取消，表單 5 秒後仍在。
- **UI 測試種子的付款方式名稱變成本地化 key**：`BLUITestSeedData` 寫入的六筆付款方式中，「無卡」與「貨到付款」兩筆的名稱是 `orders.detail.label.cardless`、`orders.list.label.cashDelivery`，以 UI 測試模式啟動時付款方式管理與訂單編輯直接顯示這兩串 key。同型誤值也出現在四處 SwiftUI Preview 假資料。
- 兩者都是 6c `service-ownership-alignment` task 4.2 實測時發現、主 checkout 同樣重現的既有缺陷 (紀錄在 `openspec/changes/archive/2026-10-17-service-ownership-alignment/tasks.md`)，使用者 2026-10-17 指示在 6d 之前插單修正。

## Root Cause

**表單關不掉 (已以實驗確認)**：

- `OrdersFeature` 依 `ios-navigation.md` 的例外，在同一次更新內直接呼叫 `OrdersPresentationFeature.State.present(_:)` 設定 `destination`，這個 action 不經過 `OrdersPresentationFeature` 的 `ifLet(\.$destination, action: \.destination)`。
- TCA 的 `PresentationReducer` 只在自己執行時比對呈現識別；`presentedID` 為 `nil` 時才啟動一個長效 effect，`@Dependency(\.dismiss)` 的實作就是取消這個 effect，讓它接著送出 `.dismiss`。容器直接改 `destination` 時這個 effect 沒有啟動，要等第一個送進呈現 reducer 的 action 才啟動。
- 表單呈現後第一個送進來的 action 是 `OrderEditView` 的 `.task { await store.send(.view(.task)).finish() }`，所以 dismiss effect 成為這次 send 的效果之一，被 `.task` 的生命週期綁住。
- 推入選擇器時表單根畫面消失，SwiftUI 取消 `.task`，`finish()` 的取消連帶取消 dismiss effect，且不送 `.dismiss`；`presentedID` 仍是同一個表單，之後不會重新啟動。從此 `dismiss()` 取消不到任何 effect，取消與儲存都關不掉表單。
- 實驗：只把該行改成 `store.send(.view(.task))` (不等完成)，同樣操作下取消與「選取後儲存」都能關閉表單；還原後重現。
- 守門缺口：`OrderCreateTests.testCreateOrder_填寫並儲存訂單_清單出現新訂單` 本來就經過兩個選擇器再儲存，但它只等訂單清單根元素出現，而清單一直在 sheet 底下存在，所以表單沒關也通過。

**種子名稱 (已比對提交)**：`f03a82c` (本地化全面遷移為結構化英文 key) 批次把中文字面值換成 key 時，連同屬於使用者資料的付款方式名稱一起換掉；`git show f03a82c` 可見 `"無卡"`、`"貨到付款"`、`"銀行匯款"` 三個資料值在種子與 Preview 假資料中被替換。

## Proposed Solution

- `OrderEditView` 的 `.task` 改為只送出 `.view(.task)`、不等待完成：這個 action 只在新訂單時設定初始焦點，沒有需要隨畫面取消的長效 effect，與 `ios-navigation.md` 對清單 `.task` 的規則一致；dismiss effect 因此留在 store 內，不受推入與返回影響。
- 先補守門再修：在 `OrderEditDirtyTests` 新增 UI 測試「進過選擇器返回後未修改，取消會關閉表單」，並讓 `testCreateOrder_填寫並儲存訂單_清單出現新訂單` 先確認表單消失再查清單；兩條在修正前失敗、修正後通過，再以還原 `.finish()` 的變異確認守得住。
- 新增單元測試，確認每個種子 profile 寫入的主檔名稱與訂單引用的主檔欄位都不是本地化 key 的形狀；種子兩筆與三處 Preview 假資料還原為 `f03a82c` 之前的中文資料值。
- `.claude/rules/ios-navigation.md` 補上這條 gotcha：容器直接設定 `destination` 時，sheet 內畫面的 `.task` 不可等待 send 完成。

## Success Criteria

- iPhone 17 上，新增的取消 UI 測試與加強後的建立訂單 UI 測試在修正前失敗、修正後通過；把 `.task` 暫時改回 `await … .finish()` 時兩條都再次失敗，還原後通過。
- 種子單元測試在修正後通過；把任一筆付款方式名稱暫時改回 key 時失敗。
- 以 UI 測試模式與 `lookupsOnly` 種子啟動 App，付款方式管理列出「無卡」與「貨到付款」，沒有任何 key 字串 (以 `mobilebuildmcp ui-automation` 讀取確認)。
- 完整單元回歸與 iPhone 17 UI 主回歸通過；iPad 執行 `OrderCreateTests` 與 `OrderEditDirtyTests` 通過。

## Impact

- Affected specs：修改 `sheet-nested-presentation`、`ui-test-launch-harness`
- Affected code:
  - Modified:
    - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
    - apps/ios/BuyLedger/App/Testing/BLUITestSeedData.swift
    - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
    - apps/ios/BuyLedger/Features/Lookups/Components/LookupItemList.swift
    - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterPreviewFixtures.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/PaymentMethodEditorSheet.swift (預覽的 `initialName`，review 補抓)
    - apps/ios/BuyLedgerUITests/Tests/Orders/OrderCreateTests.swift
    - apps/ios/BuyLedgerUITests/Tests/Orders/OrderEditDirtyTests.swift
    - apps/ios/BuyLedgerUITests/Screens/OptionPickerScreen.swift
    - apps/ios/BuyLedger.xcodeproj/project.pbxproj (build number)
    - .claude/rules/ios-navigation.md
  - New:
    - apps/ios/BuyLedgerTests/BLUITestSeedDataTests.swift
    - apps/ios/BuyLedger/App/Testing/BLUITestSeedData+Orders.swift、BLUITestSeedData+Campaigns.swift、BLUITestSeedData+Analytics.swift、BLUITestSeedData+Builders.swift (種子檔整檔對齊時拆出)
  - Removed: 無
