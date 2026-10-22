## Summary

第 6 步拆出的 6c：每個 Service 搬到擁有它資料的 Feature，跨 Feature 的需求改由 Root 轉送，不再直接注入別的 Feature 的 Service。改到的檔一律依 `/ios-dev-kit` 整檔對齊 (2026-10-09 裁決 1)。

- `OrderService` 搬到 `Features/Orders/Data/`；四個主檔 Service 依 kit「一個 Feature 一個 Service」合併成 `Features/Lookups/Data/` 的 `LookupService`；開團的提醒連結 Service 併入 `CampaignService`。
- 主檔改名、開團改名與付款方式更正都由擁有者的 Service 在同一筆交易內一併更新訂單，`OrderService` 刪除改名入口。
- 訂單端只讀主檔目錄；主檔目錄的載入與訂單表單新增選項，改由主檔端的無 View 子 Feature 處理，經 Root 轉送；所有訂單載入請求都先經主檔目錄。
- Root 送進訂單容器的請求收成一個 `OrdersRootRequest`；`OrderPersistenceError` 改為 `OrderError`。
- 本 change 在 worktree `/Users/leoho/Develop/BuyLedger-6c` (分支 `features/6c-service-ownership`) 實作，與 `palette-analytics-style-compliance` 平行。

範圍演變：

- 2026-10-04 第 6 步 discuss 裁決 6c 的內容 (Service 搬到擁有者、改名在同一交易、新增選項經 Root、付款方式更正讀投影、`<Feature>Error`)。
- 2026-10-15 使用者同意 6c 提前到 6d 之前，與色盤插單平行。
- 2026-10-16 propose 時發現 kit 3.8.0 `project-structure.md` 規定「一個 Feature 一個 Service，命名 `<Feature>Service`」；使用者裁決四個主檔 Service 合併成 `LookupService`，取代 10/04「四個原樣搬」。同日也裁決 `CampaignReminderService` 併入 `CampaignService`。
- 2026-10-16 第一輪三方唯讀審查後，使用者裁決：
    - 付款方式更正改由 `LookupService` 在交易內讀資料庫選取並重算訂單，取代 10/04「改讀 Root 訂單投影」。投影只在訂單已載入時完整，要另外加載入狀態與拒絕規則；交易內選取則不受載入時機影響，也不會以較早讀到的值覆寫訂單。
    - Root 送進訂單容器的請求收成一個列舉，讓 `OrdersFeature` 維持在 359 行內。
- Lookups 不新增 `LookupError`：改由 Service 自己選訂單後不再有「找不到訂單」這種語意失敗，沿用 `PersistenceError` (同 `CampaignService`)。

## Motivation

- **跨 Feature 注入 Service** (2026-10-16 實測，`@Dependency` 引用處)：
    - `CampaignWritesFeature` 注入 `orderService`，在開團存檔後另開一筆交易改訂單裡的開團名稱。
    - `LookupManagementFeature` 注入 `orderService`，以它的四個 `apply…Rename` 入口改主檔與訂單。
    - `PaymentMethodCorrectionFeature` 注入 `orderService` 讀全部訂單，以建立更正計畫。
    - `OrdersLoadFeature` 注入四個主檔 Service 讀主檔目錄，`OrderWritesFeature` 注入它們寫入表單新增的選項。
    - kit `project-structure.md` 規定 Service 屬單一 Feature，跨 Feature 只引用對方 Domain 的 Model 與 Error；`apps/ios/CLAUDE.md` 把上述情況登記為 6c 前的過渡例外。
- **Service 與錯誤型別放在 Core**：`OrderService` (6 檔) 與四個主檔 Service (各 3 檔) 在 `Core/Dependencies/`；`OrderPersistenceError`、`PaymentMethodPersistenceError` 在 `Core/Persistence/`。
- **開團改名分兩筆交易**：開團存檔成功後才改訂單，改訂單失敗時開團已是新名稱、訂單仍是舊名稱，畫面要另外提示「開團已儲存，但歸屬訂單的開團名稱更新失敗」。
- **付款方式更正以先前讀到的訂單覆寫**：計畫取自請求時的整批讀取，寫入時以計畫內的整筆訂單覆寫資料列；兩者之間若有訂單寫入，較新的欄位會被蓋掉。
- **訂單端可寫主檔目錄**：`OrdersFeature`、`OrderListFeature`、`OrdersLoadFeature`、`OrderWritesFeature` 都以可寫的 `@Shared(.lookupCatalog)` 宣告；`OrderEditPickersFeature` 把選項逐欄攤平複製進 State (kit 規定直接持有 Model)。
- **Campaigns 有兩個讀寫儲存資料的 Service**：`CampaignService` 與 `CampaignReminderService` (提醒連結的讀取、儲存、刪除，只有 `CampaignReminderFeature` 使用)，同樣違反 kit「一個 Feature 一個 Service」。
- **規模** (2026-10-16 以 6a＋6b 的 `style_checks.py` 量測，根目錄指向 worktree)：逐檔清單在 `reference/file-list.txt`，修改 111、搬移 13、新增 15、刪除 22；現有 123 檔的基準 133 筆 (計失敗 92 筆) 分布在 38 檔，`PaymentMethodCorrectionFeatureTests` 已有 466 行。
- **行數例外**：`OrdersFeature` 以 359 行為上限 (登記在 `apps/ios/CLAUDE.md`)，條件是 6c 移走新增主檔選項的轉送後回到 300 行內；本 change 估計約 356 行，仍需例外 (見 design)。

## Proposed Solution

- **Service 歸屬**：
    - `OrderService` (含 `+Dependency`、`+Preview`、`+Reads`、`+Writes`) 以 `git mv` 搬到 `Features/Orders/Data/`，刪除四個主檔改名入口與 `renameOrderCampaign`；`OrderPersistenceError` 改名 `OrderError` 放在同一目錄。
    - 新增 `Features/Lookups/Data/LookupService`，以 `LookupKind` 分派主檔的讀取、新增、刪除與改名 (改名在同一次 `database.write` 內更新主檔與引用訂單)，並提供付款方式更正的筆數讀取與交易內重算；刪除四個主檔 Service 與 `PaymentMethodPersistenceError`。
    - `CampaignService` 新增 `renameCampaign`，在同一次寫入內存開團並改寫訂單的開團名稱；`CampaignWritesFeature` 不再注入 `orderService`，「開團已儲存但訂單改名失敗」這種失敗消失。
    - `CampaignReminderService` 的三個操作併入 `CampaignService`，`CampaignReminderFeature` 改用 `campaignService`，刪除 `CampaignReminderService`。
- **主檔目錄的單一寫入端**：
    - 新增主檔端的無 View 子 Feature `LookupCatalogFeature`，負責主檔目錄的讀取，以及訂單表單新增選項的寫入；先落盤、成功才更新 `@Shared(.lookupCatalog)`。
    - 它由 `MoreFeature` 組合 (主檔管理畫面也在「更多」之下)。所有訂單載入請求 (啟動、首頁、分析頁、客戶頁與訂單分頁的重試) 都由 Root 先送主檔目錄讀取，完成後才送訂單載入；新增選項的請求與結果也由 Root 在訂單容器與它之間轉送。放在「更多」而非 Root，是因為 `RootFeature.swift` 已接近 300 行上限 (見 design)。
    - 訂單端 (`OrdersFeature`、`OrderListFeature` 等) 改以 `@SharedReader(.lookupCatalog)` 唯讀；`OrdersLoadFeature` 只載入訂單；`OrderWritesFeature` 不再寫主檔。
- **付款方式更正**：`PaymentMethodCorrectionFeature` 改用 `LookupService`：旗標有變時先讀使用該付款方式的訂單筆數供確認，確認後由 `LookupService` 在同一筆交易內更新主檔、選取並重算資料庫當下使用該付款方式的訂單，再把寫入的訂單交給 Root 更新記憶體。
- **整理**：
    - Root 送進訂單容器的四個請求 action 收成一個 `rootRequest(OrdersRootRequest)`。
    - `OrderEditPickersFeature` 直接持有表單選項，不逐欄攤平。
    - Root 為控制行數，把 `refreshDateContexts` 移到 `RootNavigationOperations`，並合併相同的導覽轉送 case。
    - 新增掃描守門，鎖住「Feature 專屬的 Service 只被該 Feature 引用」與「每個 Feature 至多一個以資料庫為下層的 Service」。
- **文件**：改寫 `.claude/rules/ios-data-layer.md` 的改名、付款方式編輯與主檔目錄規則，`ios-integrations.md` 的提醒連結、`ios-navigation.md` 的載入順序；刪除 `apps/ios/CLAUDE.md` 的 6c 過渡例外，`OrdersFeature` 行數例外依實測處理。

## Non-Goals (optional)

詳見 design.md。

## Alternatives Considered (optional)

- **四個主檔 Service 原樣搬進 Lookups，登記 kit 差異**：改動較小，但與 kit「一個 Feature 一個 Service」不一致；使用者 2026-10-16 選擇合併。
- **主檔目錄子 Feature 由 Root 組合**：路徑最短，但 `RootFeature.swift` 會超過 300 行 (design 有估算)，需要登記行數例外。
- **付款方式更正改讀 Root 的訂單投影 (10/04 原裁決)**：要給「更多」加訂單載入狀態，訂單未載入時只能拒絕更正，且仍以先前讀到的訂單覆寫；使用者 2026-10-16 改採交易內選取。
- **只有啟動與 Root 轉送的重試先讀主檔，訂單分頁自己的重試照舊**：`OrdersFeature` 少改兩行，但訂單分頁先出現時 (例如啟動後立刻切到訂單分頁) 訂單可能在主檔讀完前就載入，首次開啟的表單拿不到已存的主檔；不採用。
- **`OrdersFeature` 另拆容器以回到 300 行內**：再拆只會產生沒有內聚性的轉手層 (`apps/ios/CLAUDE.md` 的例外理由)；使用者 2026-10-16 選擇收成一個請求列舉。

## Impact

- Affected specs：
    - 修改 `lookup-management` 的「Payment method editing via the editor sheet」與「Lookup data has a single source shared by every consumer」
    - 修改 `order-campaign-assignment` 的「Renaming a campaign cascades to its orders」
    - 修改 `persistence-error-contract` 的「Domain persistence errors preserve semantic failures」
    - 修改 `order-write-integrity` 的「An option added from the order editor is stored before it appears」
    - 在 `app-layer-boundaries` 新增「A feature-owned service is used only by its feature」
- Affected code (逐檔清單與負責 task 見 openspec/changes/service-ownership-alignment/reference/file-list.txt)：
    - Modified：
        - apps/ios/BuyLedger/Features/Orders/ 的容器、載入、寫入、呈現、清單、篩選操作與編輯選項相關 Feature 與操作型別
        - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift、LookupItemOperations.swift、PaymentMethodCorrectionFeature.swift、PaymentMethodEditPlan.swift
        - apps/ios/BuyLedger/Features/Campaigns/CampaignWritesFeature.swift、CampaignReminderFeature.swift、CampaignPresentationFeature+Destination.swift、Data/CampaignService.swift、Data/CampaignService+Dependency.swift、Data/CampaignService+Preview.swift
        - apps/ios/BuyLedger/Features/More/MoreFeature.swift、apps/ios/BuyLedger/Features/App/RootFeature.swift、RootNavigationOperations.swift
        - apps/ios/BuyLedger/App/Testing/DependencyValues+BLUITestOverrides.swift、apps/ios/BuyLedger/Resources/Localizable.xcstrings
        - apps/ios/BuyLedgerTests/ 中 OrderService、開團 Service 與提醒、主檔管理、付款方式更正、訂單容器、載入與寫入、開團寫入與整合、Root、更多與守門相關的測試
        - apps/ios/CLAUDE.md、apps/ios/README.md、.claude/rules/ios-data-layer.md、.claude/rules/ios-integrations.md、.claude/rules/ios-navigation.md
    - New：
        - apps/ios/BuyLedger/Features/Lookups/Data/ 的 LookupService.swift、LookupService+Dependency.swift、LookupService+Preview.swift、LookupService+Renames.swift、LookupService+PaymentMethods.swift
        - apps/ios/BuyLedger/Features/Lookups/LookupCatalogFeature.swift
        - apps/ios/BuyLedger/Features/Orders/OrdersRootRequest.swift
        - apps/ios/BuyLedger/App/Testing/DependencyValues+BLUITestLookupOverrides.swift (UI 測試替身的主檔部分，原檔已有 280 行)
        - apps/ios/BuyLedger/Features/Campaigns/Data/CampaignService+Reminders.swift
        - apps/ios/BuyLedgerTests/ 的 LookupServiceTests、LookupServiceTests+PaymentMethods、LookupCatalogFeatureTests、RootFeatureTests+LookupCatalog、PaymentMethodCorrectionFeatureTests+Confirmation、ServiceOwnershipScanTests
        - openspec/changes/service-ownership-alignment/reference/ 的 style_checks.py、baseline.txt
    - Moved (git mv)：
        - apps/ios/BuyLedger/Core/Dependencies/OrderService*.swift → apps/ios/BuyLedger/Features/Orders/Data/ (其中 OrderService+Renames.swift 在收尾時刪除)
        - apps/ios/BuyLedger/Core/Persistence/OrderPersistenceError.swift → apps/ios/BuyLedger/Features/Orders/Data/OrderError.swift
        - apps/ios/BuyLedger/Features/Orders/OrderOptionWritePlan.swift → apps/ios/BuyLedger/Features/Lookups/LookupAdditionRequest.swift
        - apps/ios/BuyLedgerTests/OrderServiceTests+Rename*.swift → apps/ios/BuyLedgerTests/LookupServiceTests+Rename*.swift；CampaignReminderServiceTests.swift → CampaignServiceTests+Reminders.swift
    - Removed：
        - apps/ios/BuyLedger/Core/Dependencies/ 的 CategoryService、OrderSourceService、PaymentMethodService、ReconciliationStatusService 及其 `+Dependency`、`+Preview` (12 檔)
        - apps/ios/BuyLedger/Core/Persistence/PaymentMethodPersistenceError.swift
        - apps/ios/BuyLedger/Features/Campaigns/Data/CampaignReminderService.swift、CampaignReminderService+Dependency.swift、CampaignReminderService+Preview.swift
        - apps/ios/BuyLedgerTests/ 的四個主檔 Service 測試 (CategoryServiceTests、OrderSourceServiceTests、PaymentMethodServiceTests、PaymentMethodServiceTests+ApplyEdit、ReconciliationStatusServiceTests) 與 OrderWritesFeatureTests+Options (情境移到 LookupServiceTests、LookupCatalogFeatureTests 與 RootFeatureTests+LookupCatalog)
