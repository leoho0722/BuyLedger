## Context

BuyLedger 的訂單編輯表單 (`OrderEditFeature` / `OrderEditView`) 已支援付款方式主檔，且付款方式帶有「無卡」(`isCardless`) 分類旗標——選到無卡付款方式時會展開「無卡折抵金額／補款金額」欄位。訂單來源、商品類別、付款方式三種主檔已抽象成共用的 `LookupKind` + `LookupManagementFeature`，並由 `RootFeature` 攔截更名／新增／刪除做 cascade。

「無卡」與「銀行匯款」類付款方式的款項不會即時入帳，店主需要事後人工對帳。目前缺乏結構化欄位記錄對帳結果。本變更沿用既有主檔與訂單持久化架構，加入「對帳狀態」。

約束：
- Swift 6 strict concurrency，專案層級 `SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated`。
- TCA reducer body 用顯式 `some Reducer<State, Action>`。
- SwiftData 採版本化 `VersionedSchema`，舊版本須凍結成影子型別保住 attribute 指紋；多個 repository 共用 `PersistenceContainer.shared`。
- `LedgerOrder` 為 immutable struct，改任一欄位需 memberwise init 重建。
- liveValue 不自動 seed 假資料；UI 寧顯示空狀態也不顯示假資料。
- 時間／隨機數走 `@Dependency` 注入。

## Goals / Non-Goals

**Goals:**

- 在訂單編輯表單，當選到的付款方式屬於無卡或銀行匯款時，於「付款方式」row 底下顯示可選的「對帳狀態」row，操作行為比照「新增付款方式」並以 medium sheet 新增。
- 讓「對帳狀態」成為第 4 種可自訂主檔，可在「更多」頁管理，並能在訂單編輯時即時新增。
- 把對帳狀態持久化在訂單上，且只在「對帳語意有效」(付款方式為無卡／銀行匯款) 時保留。
- 付款方式新增「銀行匯款」分類旗標，與「無卡」平行。

**Non-Goals:**

- 不做自動對帳、不串接銀行 API、不做金額比對；對帳狀態純為人工標記。
- 不在儀表板／洞察頁新增對帳相關統計或篩選 (本變更僅止於訂單編輯與主檔管理)。
- 不自動 seed 預設詞彙；待對帳／對帳成功／對帳失敗由使用者自行新增 (符合空狀態原則)。
- 不把「無卡」與「銀行匯款」設為互斥；兩個旗標獨立，任一為真即觸發對帳狀態 row。
- 不修改無卡折抵／補款的既有計算邏輯。

## Decisions

### 決策一：「銀行匯款」採付款方式分類旗標 isBankTransfer（與 isCardless 平行）

於 `PaymentMethodRecord` / `PaymentMethodInfo` 新增 `isBankTransfer: Bool`（default `false`），並在新增付款方式的 `PaymentMethodEditorSheet` 加第二個 Toggle「標記為「銀行匯款」付款方式」。觸發對帳狀態 row 的條件為 `isCardless || isBankTransfer`。

替代方案：(a) 以付款方式「名稱字串等於『銀行匯款』」判定——已否決，字串硬比對脆弱且無法支援多種銀行匯款命名；(b) 以單一「需對帳」旗標取代兩者——已否決，使用者明確要求保留「無卡」與「銀行匯款」兩個獨立語意。

### 決策二：「對帳狀態」採可自訂主檔（第 4 個 LookupKind）而非固定 enum

新增 `LookupKind.reconciliationStatus`，搭配新的 `ReconciliationStatusRecord`（@Model，僅 `name`，比照 `OrderSourceRecord`）、`ReconciliationStatusPersistence`（@ModelActor）、`ReconciliationStatusRepository`（liveValue 走 `PersistenceContainer.shared`）。`LookupManagementFeature` 依 kind 分流到此 repository。

替代方案：固定 `enum ReconciliationStatus`——已否決，使用者明確選擇「可自訂主檔」。

### 決策三：對帳狀態以 String 持久化於訂單，並在付款方式非無卡／銀行匯款時於儲存清空

`LedgerOrder` 新增 `let reconciliationStatus: String`、`OrderRecord` 新增 `var reconciliationStatus: String = ""`。`OrdersFeature.applyEditDraft` 讀 `draftReconciliationStatus`；若該訂單付款方式非無卡／銀行匯款，存回 `""`（比照無卡金額在切換付款方式後歸零的既有 normalize 作法）。

替代方案：把對帳狀態存成另一張關聯表——已否決，過度設計；訂單與狀態為單純一對一字串欄位，與既有 `paymentMethod`／`category` 一致。

### 決策四：新增名稱-only medium sheet 共用元件 LookupItemEditorSheet

「對帳狀態」的新增比照「新增付款方式」使用 medium sheet，但只需名稱欄位 (無旗標)。新增 `LookupItemEditorSheet`（單一 TextField + `.presentationDetents([.medium])`，macOS 給固定 frame），供 `OrderEditView` 的對帳狀態 picker 與 `LookupManagementView` 的對帳狀態管理頁共用。`OptionPickerSheet` 新增一個可選的「name-only medium sheet 新增 handler」入口，未提供時行為完全不變。

替代方案：(a) 把對帳狀態新增改用 alert（與訂單來源／類別相同）——已否決，使用者明確要求 medium sheet；(b) 重用 `PaymentMethodEditorSheet` 並隱藏 Toggle——已否決，該元件語意專屬付款方式，泛化會讓參數爆炸。

### 決策五：SwiftData 升版 BuyLedgerSchemaV7 lightweight migration 與舊版影子型別凍結

新增 `BuyLedgerSchemaV7`，`models` 含既有四表加新表 `ReconciliationStatusRecord`，並引用 top-level（已含新欄位）。把目前仍引用 top-level 的 `BuyLedgerSchemaV6.OrderRecord` 凍結成 V6 影子型別（含 `notes`，不含 `reconciliationStatus`）；`PaymentMethodRecord` 自 V4 起被 top-level 引用，於 V6（最後引用它的版本）凍結成影子型別（含 `isCardless`，不含 `isBankTransfer`）以保住其 V4–V6 指紋。`MigrationPlan.schemas`／`stages` append V7，V6 → V7 走 `.lightweight`（兩個帶 default 的新欄位 + 一張全新表，皆符合 lightweight）。`PersistenceContainer.make` 的 `Schema(versionedSchema:)` 指向 V7。

替代方案：`.custom` dump-and-restore——已否決，新增帶 default 欄位與新表是 lightweight 的標準情境，不需 custom。

### 決策六：主檔 cascade 沿用 RootFeature 機制擴充第 4 個 kind

`RootFeature` 既有 `cascadeRename` / `addToOrdersMaster` / `removeFromOrdersMaster` 與 `rebuildOrder` 已涵蓋三種 kind；新增 `.reconciliationStatus` 分支：更名時同步 `OrdersFeature.State` 的 `reconciliationStatusMaster` 與訂單表中 `reconciliationStatus` 等於舊名的訂單。`rebuildOrder` 新增 `reconciliationStatus` 覆寫參數。

## Implementation Contract

**行為（使用者可觀察）：**

- 在訂單編輯表單選到 `isCardless` 或 `isBankTransfer` 為真的付款方式時，「付款方式」row 底下出現「對帳狀態」row；選到其他付款方式時該 row 不顯示。
- 點「對帳狀態」row 開啟 picker，列出目前對帳狀態主檔；點「新增對帳狀態」開啟 medium sheet（半屏，僅名稱欄位），確認後即時套用到此訂單並加入主檔。
- 新增付款方式的 sheet 出現「無卡」與「銀行匯款」兩個 Toggle；勾選任一者，使用該付款方式的訂單在編輯時都會顯示對帳狀態 row。
- 「更多」頁新增「對帳狀態」管理入口，可新增／更名／刪除；更名會同步更新引用該狀態的訂單。
- 儲存訂單後，若付款方式為無卡／銀行匯款則保留所選對帳狀態，否則對帳狀態存為空字串。
- 付款方式管理頁的列在 `isBankTransfer` 為真時顯示「銀行匯款」徽章（比照「無卡」徽章）。

**介面 / 資料形狀：**

- `PaymentMethodInfo`：新增 `isBankTransfer: Bool`。
- `PaymentMethodRepository.addPaymentMethod` 簽章：`@Sendable (String, Bool, Bool) async throws -> Void`（name, isCardless, isBankTransfer）；新增 `setPaymentMethodIsBankTransfer` 比照 `setPaymentMethodIsCardless`（或合併處理）。
- `PaymentMethodEditorSheet.onSubmit`：`(_ name: String, _ isCardless: Bool, _ isBankTransfer: Bool) -> Void`。
- `OptionPickerSheet`：新增可選 `onAddViaNameSheet: ((String) -> Void)?`（提供時新增控制項改開 `LookupItemEditorSheet`）。
- `LookupKind`：新增 `case reconciliationStatus`，補齊所有顯示字串屬性。
- `LookupManagementFeature`：注入 `ReconciliationStatusRepository`，`addConfirmed` / `deleteRequested` / `renameRequested` / 載入動作在 `kind == .reconciliationStatus` 時分流到它；付款方式新增改帶 `isBankTransfer`。
- `ReconciliationStatusRepository`：`fetchReconciliationStatuses` / `addReconciliationStatus` / `removeReconciliationStatus` / `renameReconciliationStatus`（比照 `OrderSourceRepository`）。
- `LedgerOrder`：新增 `let reconciliationStatus: String`（memberwise init 多一個參數）。
- `OrderRecord`：新增 `var reconciliationStatus: String = ""`，`init(order:)` / `toDomain()` / `apply(_:)` 同步。
- `OrderEditFeature.State`：新增 `var draftReconciliationStatus: String`、`var availableReconciliationStatuses: [String]`；computed `isSelectedPaymentMethodBankTransfer`、`showsReconciliationStatusRow`（= 無卡或銀行匯款）；Action 新增 `addReconciliationStatusTapped(String)` 與 `availableReconciliationStatusesLoaded([String])`。
- `OrdersFeature.State`：新增 `reconciliationStatusMaster: [String]` 與 computed `availableReconciliationStatuses`；Action 新增 `reconciliationStatusMasterLoaded([String])`；`.task` 平行載入；兩處 `OrderEditFeature.State(...)` 建構補 `availableReconciliationStatuses`。
- `BuyLedgerSchemaV7` 為最新 schema；`PersistenceContainer` 指向 V7。

**失敗模式：**

- 對帳狀態主檔為空時，picker 顯示既有空狀態文案（不顯示假資料）；對帳狀態 row 顯示「選擇對帳狀態」placeholder。
- repo 讀取失敗時 `try?` 靜默略過（比照既有 lookup 載入），不阻斷表單。
- migration 失敗時沿用 `PersistenceContainer.makeForApp()` 既有開發期 fallback（本變更不依賴砍檔，lightweight 應可成功）。

**驗收標準：**

- 新增單元測試：對帳狀態 row 顯示條件（無卡 / 銀行匯款 / 其他）、`addReconciliationStatusTapped` 套用、`applyEditDraft` 在非無卡／銀行匯款時清空 `reconciliationStatus`、`OrderPersistence` round-trip 帶 `reconciliationStatus`、`LookupManagementFeature` `.reconciliationStatus` 分流、付款方式 `isBankTransfer` round-trip 與更名保留。
- 既有所有 `LedgerOrder(...)` 測試與 sample 補上新參數後，全測試通過。
- macOS 與 iOS Simulator build 皆成功（序列化執行避免 build.db lock）；最後 build-and-run 到實體 iPhone 由使用者確認 UI。

**範圍邊界：**

- 範圍內：付款方式 `isBankTransfer` 旗標、對帳狀態主檔與其管理頁、訂單編輯的條件式對帳狀態 row 與 medium sheet 新增、訂單持久化欄位與 V7 migration、RootFeature cascade。
- 範圍外：對帳相關的統計／圖表／篩選、銀行 API 整合、CloudKit container/entitlements 變更、訂單列表或詳情頁顯示對帳狀態（本次不動列表與詳情 UI）。

## Risks / Trade-offs

- [付款方式新增 API 簽章由二參數改三參數，連動多個 caller] → 以編譯器為守門員，盤點所有 caller（OptionPickerSheet、OrderEditView、OrderEditFeature、LookupManagementView、LookupManagementFeature）一次到位；測試 testValue 同步。
- [所有 LedgerOrder memberwise init 呼叫點都要補參數，易漏] → design 已列出全部呼叫點（applyEditDraft 兩路徑、statusChanged、rebuildOrder、toDomain、samples、6 個測試檔），以 build 失敗清單逐一補齊。
- [schema 影子型別凍結若漏凍結，會破壞舊版指紋導致 migration 失敗] → 嚴格遵循「只有最新版引用 top-level，其餘凍結」原則：V6.OrderRecord 與 PaymentMethodRecord 凍結為 V6 影子；新增 V7 引用 top-level。
- [對帳狀態主檔不 seed，首次使用 picker 為空] → 符合既有空狀態原則與其他主檔行為；使用者可即時新增；驗證時於裝置以管理頁建立待對帳／對帳成功／對帳失敗示範。
- [更名 cascade 漏接新 kind] → RootFeature cascade switch 為 exhaustive，新增 case 後編譯器會強制覆蓋。

## Migration Plan

1. 先改資料層（`PaymentMethodRecord` / `PaymentMethodInfo` / `OrderRecord` / `LedgerOrder` 新欄位），讓編譯失敗清單浮現所有 init 呼叫點，逐一補齊。
2. 加 `BuyLedgerSchemaV7` 與 V6 影子型別凍結、append migration stage、`PersistenceContainer` 指向 V7。
3. 加對帳狀態主檔三件套（Record / Persistence / Repository）與 `LookupKind` case。
4. 接 `LookupManagementFeature` 分流、`RootFeature` cascade、`MoreView` 入口。
5. 接訂單編輯 UI（`OrderEditFeature` / `OrderEditView` / `OrdersFeature`）與 `LookupItemEditorSheet`、`OptionPickerSheet` 入口。
6. 補測試與 sample 參數，跑單元測試。
7. macOS + iOS Simulator build（序列化）、最後 build-and-run 到實體 iPhone。

回滾：本變更為 lightweight migration 且新欄位皆帶 default；若需回滾程式碼，已寫入 `reconciliationStatus` / `isBankTransfer` 的資料在舊版會被忽略（欄位仍存在於 store，但舊版 schema 不引用），不影響舊版讀取既有欄位。

## Open Questions

- 對帳狀態主檔是否需要在 fresh install 預先寫入待對帳／對帳成功／對帳失敗？目前依空狀態原則決定「不 seed」，由使用者新增；若日後希望 fresh install 即有預設詞彙，可另開變更加入一次性 bootstrap（不在本變更範圍）。
