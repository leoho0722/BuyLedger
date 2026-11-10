## Why

`BuyLedgerAccessibilityIDs/` 的 identifier 常數有兩種寫法：載入狀態的 11 個常數經 `BLAccessibilityID.Common.loading(_:)`、`loadFailure(_:)`、`loadFailureRetryButton(_:)` 組出，其餘 159 個 `static let` 直接寫字串 (2026-11-10 實測：`static let` 共 170 個減去經 helper 組出的 11 個；`BLAccessibilityID+More.swift` 的 `paymentMethodCashOnDeliveryToggle` 宣告跨兩行，逐行比對 `= "` 會漏算)。同樣跨畫面重複的 `.root`、`.emptyState`、各畫面的 `retryButton` 都是字串，只有載入狀態例外，而且這個例外的理由沒有寫在任何規則或 design 裡。

組出來的值在原始碼裡搜不到定義：UI 測試失敗訊息印出 `orders.list.loadFailure` 時，以這個字串搜尋只會找到 archive 的歷史紀錄，找不到 `BuyLedgerAccessibilityIDs/` 裡的常數。`Common.selectedItem(_:)` 也有同樣問題：它在中段插入功能名稱、再接固定的 `.selectedItem`，`common.navigation.campaigns.selectedItem` 只出現在單元測試的預期值。使用者 2026-11-09 在 PR #6 的審查中問起這處不一致，同意另開小 change 統一寫法；往字串收斂的方向是主對話的建議。提案審查後，使用者 2026-11-10 明確回覆採納三項推薦：`selectedItem` 一併改寫並改用形狀規則、以暫時測試守住 11 個值不變、刪除總覽 3 條字面值測試 (見 design「提案審查」)。

## What Changes

- 載入狀態的 11 個常數改成完整字串字面值，值不變：
  - `BLAccessibilityID.Dashboard`：`loading`、`loadFailure`、`loadFailureRetryButton`
  - `BLAccessibilityID.Insights`：`loading`、`loadFailure`、`loadFailureRetryButton`
  - `BLAccessibilityID.Orders`：`listLoadFailure`、`listLoading`、`listLoadFailureRetryButton`
  - `BLAccessibilityID.Campaigns`：`listLoadFailure`、`listLoadFailureRetryButton`
- 改寫期間在 `BLAccessibilityIDTests` 加一條暫時的參數化測試，逐一比對 11 個新字面值與舊 helper 的輸出；刪 helper 時一併刪除。
- 刪除 `BLAccessibilityID.Common` 的 `loading(_:)`、`loadFailure(_:)`、`loadFailureRetryButton(_:)`，以及 `BLAccessibilityIDTests` 的 5 條測試：
  - 直接呼叫 `loadFailure(_:)`、`loadFailureRetryButton(_:)` 的 `loadFailure_容器識別碼_附加載入失敗區域`、`loadFailureRetryButton_容器識別碼_附加重試按鈕區域`。
  - 改寫後只拿字面值比對同一個字面值的總覽 3 條：`loading_總覽載入中_使用總覽前綴`、`loadFailure_總覽載入失敗_使用總覽前綴`、`loadFailureRetryButton_總覽重試按鈕_接在失敗區域後`。
- `Common.selectedItem(_:)` 改由 `option("common.navigation.selectedItem", key: feature.rawValue)` 組出，3 個值改為 `common.navigation.selectedItem.<feature>`；`BLAccessibilityIDTests` 的 `selectedItem_指定功能範疇_組成符合慣例之ASCII識別碼` 只更新 3 個預期值。
- `.claude/rules/ios-ui-tests.md` 的「定位與 identifier」補一條常數定義處的寫法：固定 identifier 寫完整字串字面值；需要組出的只能由 `option`、`row`、`indexed` 在字面值前綴之後接最後一段變動值。

## Non-Goals

- 除 `selectedItem` 的 3 個值外，不改任何 identifier 的值；不改 App 與 UI 測試的引用處：兩端引用同一個常數或同一個函式。
- 不把 `.root`、`.emptyState`、`retryButton` 等字串改成 helper 組出 (反方向統一，改動多、好處少，主對話建議不採)。
- 不動 `BLAccessibilityID.option`、`row`、`indexed` 與其他 33 個呼叫它們的 `static func` (例如 `Dashboard.kpiTile(_:)`、`Root.tab(_:)`)：它們已是「字面值前綴後接最後一段參數」(2026-11-10 逐一讀過 `BuyLedgerAccessibilityIDs/` 全部 40 個 `static func`)。
- 不處理 `Common.Feature.orders` 目前只有測試使用的情況。
- 不新增掃描 ID 檔的守門測試 (字面值形狀、值不重複、只含 ASCII)，也不做型別化的載入狀態 identifier 組：架構審查建議列為後續，另開 change。

## Impact

- Affected specs: none
- Affected code:
  - New: (none)
  - Modified:
    - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Common.swift
    - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Dashboard.swift
    - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Insights.swift
    - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Orders.swift
    - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Campaigns.swift
    - apps/ios/BuyLedgerTests/AccessibilityIDs/BLAccessibilityIDTests.swift
    - .claude/rules/ios-ui-tests.md
  - Removed: (none)
- Compatibility: no capability-level observable behavior changes；11 個載入狀態 identifier 的值不變；`selectedItem` 的 3 個值改變，但 App 與 UI 測試經同一個函式取值，定位結果不變，identifier 也不顯示給使用者。
- 基準分支：`BLAccessibilityID+Insights.swift` 與 `+Orders.swift` 的載入狀態常數是 PR #6 (`load-failure-reload-loop`) 新增的，PR #6 已於 2026-11-09 合併 (`0510f34`)，本 change 從 `main` 開新分支實作 (主對話代選)。
