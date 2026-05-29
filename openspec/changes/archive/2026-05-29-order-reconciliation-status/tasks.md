## 1. 資料層欄位與型別（決策一、決策三）

- [x] 1.1 [P] 為付款方式加入「Payment method bank-transfer classification」所需欄位：`PaymentMethodRecord` 新增 `var isBankTransfer: Bool = false`、`PaymentMethodInfo` 新增 `let isBankTransfer: Bool`（決策一：「銀行匯款」採付款方式分類旗標 isBankTransfer（與 isCardless 平行））。驗證：專案編譯通過，型別含新欄位。
- [x] 1.2 [P] `LedgerOrder` 新增 `let reconciliationStatus: String`（決策三：對帳狀態以 String 持久化於訂單，並在付款方式非無卡／銀行匯款時於儲存清空）。驗證：型別含新欄位，後續呼叫點補齊後編譯通過。
- [x] 1.3 `OrderRecord` 新增 `var reconciliationStatus: String = ""`，並在 `init(order:)`／`toDomain()`／`apply(_:)` 三處雙向映射此欄位。驗證：`OrderPersistenceTests` round-trip 測試保留值。
- [x] 1.4 補齊所有 `LedgerOrder(...)` memberwise init 呼叫點的新參數（`applyEditDraft` 編輯與新增兩路徑、`statusChanged`、`RootFeature.rebuildOrder`、`OrderRecord.toDomain`、`LedgerOrder+Samples` 全部 sample、各測試檔）。驗證：`xcodebuildmcp build`（macOS 與 iOS）無 missing-argument 錯誤。

## 2. SwiftData schema 升版 V7（決策五）

- [x] 2.1 把仍引用 top-level 的 `BuyLedgerSchemaV6.OrderRecord` 與 `PaymentMethodRecord` 凍結成 V6 影子型別（含 `notes`／`isCardless`，不含新欄位），保住 V6 與 V4–V6 attribute 指紋（決策五：SwiftData 升版 BuyLedgerSchemaV7 lightweight migration 與舊版影子型別凍結）。驗證：V6 影子型別欄位集合與凍結前一致。
- [x] 2.2 新增 `BuyLedgerSchemaV7`，`models` 含既有四表加新表 `ReconciliationStatusRecord`，引用 top-level（已含 `reconciliationStatus`／`isBankTransfer`）。驗證：`BuyLedgerSchemaV7.models` 列出六個 model 型別。
- [x] 2.3 `BuyLedgerMigrationPlan.schemas`／`stages` append V7 並加入 V6→V7 `.lightweight` 階段，`PersistenceContainer.make` 的 `Schema(versionedSchema:)` 指向 V7。驗證：App 以既有 V6 store 啟動可成功 lightweight 遷移（裝置／模擬器啟動不崩潰、既有訂單仍在）。

## 3. 對帳狀態主檔三件套與 LookupKind（決策二）

- [x] 3.1 新增 `ReconciliationStatusRecord`（@Model，僅 `name`，比照 `OrderSourceRecord`），作為對帳狀態主檔持久化型別（決策二：「對帳狀態」採可自訂主檔（第 4 個 LookupKind）而非固定 enum）。驗證：型別可被 V7 `models` 納入並編譯通過。
- [x] 3.2 新增 `ReconciliationStatusPersistence`（@ModelActor：`fetchAll`／`upsert`／`delete`／`rename`，比照 lookup persistence）。驗證：以 in-memory container 做 add→fetch→rename→delete 的單元測試通過。
- [x] 3.3 新增 `ReconciliationStatusRepository`（dependency，`fetchReconciliationStatuses`／`addReconciliationStatus`／`removeReconciliationStatus`／`renameReconciliationStatus`；liveValue 走 `PersistenceContainer.shared`、previewValue 走 in-memory、testValue 空）。驗證：以 `@Dependency` 注入可編譯，testValue 回空陣列。
- [x] 3.4 [P] `LookupKind` 新增 `case reconciliationStatus` 並補齊全部顯示字串（title／entryTitle／entrySubtitle／systemImage／addButtonTitle／emptyTitle／emptyDescription／addAlertTitle／addFieldPlaceholder／addAlertMessage）。驗證：switch 對所有 case exhaustive、編譯通過。

## 4. 付款方式 isBankTransfer 寫入路徑（決策一）

- [x] 4.1 `PaymentMethodPersistence` 的 `fetchAllInfos` 帶出 `isBankTransfer`、`upsert`／`rename`／setter 帶 `isBankTransfer`（rename 合併保留任一邊為 true，比照 isCardless）。驗證：in-memory round-trip 與更名保留 `isBankTransfer` 的單元測試通過。
- [x] 4.2 `PaymentMethodRepository.addPaymentMethod` 簽章改為 `(String, Bool, Bool)`（name, isCardless, isBankTransfer），並新增設定 `isBankTransfer` 的能力；liveValue／previewValue／testValue 同步（達成「Payment method bank-transfer classification」的寫入端）。驗證：所有 caller 編譯通過、testValue 簽章一致。
- [x] 4.3 `PaymentMethodEditorSheet` 加第二個 Toggle「標記為「銀行匯款」付款方式」，`onSubmit` 改為 `(name, isCardless, isBankTransfer)`。驗證：sheet `#Preview` 顯示兩個 Toggle；新增付款方式可帶出第二旗標。

## 5. 共用 medium sheet 與 picker 新增入口（決策四、option-picker）

- [x] 5.1 [P] 新增 `LookupItemEditorSheet`（單一名稱 TextField + `.presentationDetents([.medium])`，macOS 給固定 frame，含 `#Preview`），作為 name-only medium 新增 sheet 共用元件（決策四：新增名稱-only medium sheet 共用元件 LookupItemEditorSheet）。驗證：`#Preview` 呈現半屏名稱表單。
- [x] 5.2 `OptionPickerSheet` 新增可選 `onAddViaNameSheet` 入口（提供時新增控制項改開 `LookupItemEditorSheet`），並把付款方式 editor 新增流程更新為帶 `isBankTransfer`，未提供任何 handler 時維持既有 alert 行為（達成「Add-option flows are preserved across platforms」）。驗證：對應三條新增路徑（alert／payment editor／name sheet）的 handler precedence 正確，既有 caller 行為不變。

## 6. 主檔管理整合與 cascade（決策二、決策六）

- [x] 6.1 `LookupManagementFeature` 注入 `ReconciliationStatusRepository`，於 `addConfirmed`／`deleteRequested`／`renameRequested`／載入動作在 `kind == .reconciliationStatus` 時分流到它；付款方式 `addConfirmed` 帶 `isBankTransfer`（達成「Reconciliation status is a managed lookup kind」的 reducer 端）。驗證：`LookupManagementFeature` TestStore 對 `.reconciliationStatus` 的 add/rename/delete 走對應 repository。
- [x] 6.2 `LookupManagementView` 的 reconciliationStatus 新增改用 `LookupItemEditorSheet`（medium sheet），且付款方式管理列在 `isBankTransfer` 為真時顯示「銀行匯款」徽章（與「無卡」徽章並存，達成「Payment method bank-transfer indicator」）。驗證：付款方式列同時可見「無卡」與「銀行匯款」徽章；對帳狀態新增為半屏 sheet。
- [x] 6.3 `MoreView` 的 `ToolItem` 新增 `reconciliationStatuses` 並在 `destination(for:)` scope 到 `reconciliationStatusManagement`，作為「更多」頁的對帳狀態管理入口。驗證：更多頁出現「對帳狀態」入口並可進入管理頁。
- [x] 6.4 `RootFeature` 新增 `reconciliationStatusManagement = LookupManagementFeature.State(kind: .reconciliationStatus)`、Action case、`Scope`，並擴充 cascade（`cascadeRename`／`addToOrdersMaster`／`removeFromOrdersMaster` switch）涵蓋新 kind，`rebuildOrder` 新增 `reconciliationStatus` 覆寫參數（決策六：主檔 cascade 沿用 RootFeature 機制擴充第 4 個 kind）。驗證：`RootFeatureTests` 驗證更名對帳狀態會 cascade 到 `reconciliationStatusMaster` 與引用該值的訂單。

## 7. 訂單編輯 UI 與 OrdersFeature（決策三）

- [x] 7.1 `OrderEditFeature.State` 新增 `draftReconciliationStatus`、`availableReconciliationStatuses`、computed `isSelectedPaymentMethodBankTransfer` 與 `showsReconciliationStatusRow`（= 無卡或銀行匯款），init 比照 `availablePaymentMethods` merge（含補上 `original.reconciliationStatus`），Action 新增 `addReconciliationStatusTapped(String)` 與 `availableReconciliationStatusesLoaded([String])`、`.task` 一併載入（達成「Conditional reconciliation status row in order editing」的狀態端）。驗證：`OrderEditFeatureTests` 驗證三種付款方式下 `showsReconciliationStatusRow` 的真假與 `addReconciliationStatusTapped` 套用。
- [x] 7.2 `OrderEditView` 在 `paymentMethodPickerRow` 底下，`store.showsReconciliationStatusRow` 為真時顯示 `reconciliationStatusPickerRow`，點擊開 `OptionPickerSheet` 列對帳狀態並以 `onAddViaNameSheet` 走 medium sheet 新增（達成「Selecting and adding a reconciliation status during order editing」）。驗證：實機／模擬器手動確認 row 條件顯示、選擇與新增（medium sheet）行為。
- [x] 7.3 `OrdersFeature.State` 新增 `reconciliationStatusMaster` 與 computed `availableReconciliationStatuses`、Action `reconciliationStatusMasterLoaded`、`.task` 平行載入；兩處 `OrderEditFeature.State(...)` 建構補 `availableReconciliationStatuses`；`applyEditDraft` 讀 `draftReconciliationStatus` 並在付款方式非無卡／銀行匯款時清成 `""`（達成「Reconciliation status persistence and clearing rule」）。驗證：`OrdersFeatureTests` 驗證儲存時依付款方式分類保留或清空 `reconciliationStatus`。

## 8. 測試（TDD）

- [x] 8.1 新增／更新 `OrderEditFeatureTests`：涵蓋「Conditional reconciliation status row in order editing」（無卡／銀行匯款／其他三情境）與 `addReconciliationStatusTapped`。驗證：測試通過。
- [x] 8.2 新增 `OrdersFeatureTests` 對「Reconciliation status persistence and clearing rule」的儲存清空／保留測試（含 design 範例表三列情境）。驗證：測試通過。
- [x] 8.3 更新 `OrderPersistenceTests` 加入 `reconciliationStatus` round-trip，並新增付款方式 `isBankTransfer` round-trip 與更名保留測試。驗證：測試通過。
- [x] 8.4 新增 `LookupManagementFeature` 對 `.reconciliationStatus` 分流的 TestStore 測試（add/rename/delete 呼叫 `ReconciliationStatusRepository`）。驗證：測試通過。
- [x] 8.5 既有所有 `LedgerOrder(...)` 測試與 `SnapshotTests`／`OrdersFeaturePerformanceTests`／`OrderCalculationTests` 補新參數，必要時更新 snapshot baseline。驗證：`xcodebuildmcp test`（iOS）全綠。

## 9. 建置與裝置驗證

- [x] 9.1 macOS 與 iOS Simulator build 序列化執行皆成功（`cmd1 && cmd2` 避免 build.db lock），file system synchronized groups 正確拾取新增檔案。驗證：兩平台 `BUILD SUCCEEDED`。
- [x] 9.2 build-and-run 到實體 iPhone，手動驗證：選無卡／銀行匯款付款方式時出現「對帳狀態」row、可從 medium sheet 新增狀態、儲存後再開保留狀態、非無卡／銀行匯款不顯示該 row。驗證：使用者於裝置確認 UI 與行為。

## 10. 付款方式編輯流程（follow-up）

- [x] 10.1 達成「Payment method editing via the editor sheet」：付款方式管理列操作改為「編輯」，開 `PaymentMethodEditorSheet` 帶入原名稱與旗標；`editConfirmed` 先 rename 再權威覆寫旗標 (可取消勾選)，`RootFeature` cascade 改名與旗標到 in-memory 訂單／master；其餘 kind 維持「重新命名」。驗證：`LookupManagementFeatureTests` 的 editConfirmed 清除旗標測試與 `RootFeatureTests` 的 cascade 測試通過。
