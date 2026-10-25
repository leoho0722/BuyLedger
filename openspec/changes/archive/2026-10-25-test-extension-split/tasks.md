<!--
變更紀錄 (2026-10-23，apply 中，主對話依 claude-impl 2.10 回報修正)：`DependencyConventionScanTests+TestValueRules` 沒有測試，原分類是把 `func testValue…` 誤判為 XCTest 測試函式；file-list 改為 guard-type `DependencyConventionTestValueRules`，檢查腳本的 XCTest 計數改為只計 import XCTest 的檔案，基準由 10 更正為 8；design 與 2.10 移除 ServiceOwnership 並未使用的 `SourceTree`、`ScanRule`。
平行開發 (主對話分派，決策來源見 design 各決策的「決策來源」)：
- 熱點：拆分前測試型別之間的 440 處跨族群引用集中在第 1 節處理；1.2 → 1.3 單線 (呼叫端檔案重疊)。
- 第 2 節每個任務只改「自己族群的檔案＋自己族群的 TestSupport＋該族群主檔」，族群歸屬見 reference/file-list.tsv 的 `task` 欄；各任務的 [after:] 只取決於第 1 節是否改到它的檔案。
    - 不依賴第 1 節 (只等 1.1 基準)：2.5、2.10、2.12、2.13
    - 等 1.2：2.4、2.7
    - 等 1.3：2.1、2.2、2.3、2.6、2.8、2.9、2.11
- 實作與審查 (主對話分派；審查不交給實作者本人，主對話同時審架構、正確性、測試與風格)：
    - 第 1 波 (1.1 後)：1.2 codex-impl、2.10 claude-impl、2.12 gemini-impl
    - 第 2 波：1.3 codex-impl (1.2 後)、2.13 claude-impl、2.5 gemini-impl
    - 第 3 波 (1.3 後)：2.2 codex-impl、2.1 claude-impl、2.3 gemini-impl
    - 第 4 波：2.4 codex-impl、2.6 claude-impl、2.7 gemini-impl
    - 第 5 波：2.11 codex-impl、2.8 claude-impl、2.9 gemini-impl
    - 3.1 claude-impl；4.1 由未參與實作的 haiku-max-implementer 子代理執行
    - 審查分工：codex-impl 的任務由 claude-impl 審，claude-impl 的由 gemini-impl 審，gemini-impl 的由 codex-impl 審
    - 派工前後比對 `git status --short` 確認改動歸屬；gemini-impl 唯讀審查前後另比對檔案雜湊
- agent 只改檔案：不 build、不跑測試、不做 git 寫入 (快照目錄以一般搬移改名，不用 `git mv`)；codex-impl 交回前跑 `swiftc -parse`。建置、測試與勾選由主對話依序執行，同一時間只跑一組測試。
- 驗證分層：每個任務只跑改到的測試類別；完整單元測試與 UI 回歸只在 1.1 (基準) 與 4.2 跑，UI 測試另在 2.13 跑受影響類別。測試模擬器：iPhone 17 (iOS 26.5，`1FB73457-BA2B-4D45-9233-1C53F1DB2362`)、iPad Air 11-inch (M4) (iOS 26.5，`E30658D5-A19C-40CE-AA6E-C11BEAE95A1A`)；跑快照前外觀鎖淺色；驗證用建置不遞增 build 號。
變更紀錄 (2026-10-24，ingest，主對話依使用者回覆更新)：4.2 完成後使用者決定把 style 閘門的範圍外項目在本 change 一次改完 (design「測試寫法這輪一併修正」)，新增第 5 至 8 節；第 1 至 4 節已完成的紀錄不變。
第 5 至 8 節的平行開發 (主對話分派)：
- 熱點：唯一同檔 test extension `OrdersDetailNavigationFeatureTests.swift` 在 5.1 先改，6.1 等它。共用層 (`Support/`、`Fixtures/`、`Mocks/`) 只由 6.10 改，其他任務不改共用層與別組資料夾的 TestSupport，需要時寫進回報由主對話排入 6.10 或後續任務。
- 第 6 節 11 組依資料夾切開、檔案不重疊，彼此可平行；第 7 節每組只等同組的第 6 節任務 (改同一批檔) 與 kit 回覆 (design「測試說明統一動詞開頭並改白話」)。
- 實作與審查：
    - 第 6 節開工前，11 組各由一個未參與實作的 haiku-max-implementer 子代理唯讀、逐檔逐條列出 T1 至 T13 違規清單 (可同時進行)
    - 第 6 節實作 (2026-10-24 主對話調整：審查清單到齊的順序與縮短時程)：claude-impl 依序做 5.1、6.6、6.1、6.4、6.11；codex-impl 依序做 6.8、6.2、6.3、6.10；6.5、6.7、6.9 各由一個 haiku-max-implementer 子代理實作 (同時進行，檔案互不重疊)
    - 審查：claude-impl 的任務由 codex-impl 審，codex-impl 的由 claude-impl 審，haiku 實作的任務由另一個未參與該任務的 haiku-max-implementer 子代理審；主對話同時審查並跑測試
    - 第 7 節實作：haiku-max-implementer 子代理每組一個，可同時進行；審查由 claude-impl 與 codex-impl 輪流，主對話同時審查
    - gemini-impl 重開機後每個讀檔與指令都要人工核准，本輪不派工；使用者以略過核准模式重開後可加入
    - 8.2 style 閘門由未參與實作的 haiku-max-implementer 子代理執行
-->

## 1. 基準與共用 helper

- [x] 1.1 主對話在任何改動前建立回歸基準：在 repo 根目錄執行 `python3 -I openspec/changes/test-extension-split/reference/check_test_extensions.py`，確認輸出的數量為 unit `@Test` 1744、unit XCTest 測試函式 8、UI 測試函式 108、快照基準圖 74 (失敗清單此時預期不為空)；以 `mobilebuildmcp` 在 iPhone 17 跑完整單元測試 (略過 `OrdersFeaturePerformanceTests`)，在 iPhone 17 與 iPad Air 11-inch 跑完整 UI 回歸 (略過 `LaunchPerformanceTests`)。驗證：通過數、失敗清單與 result bundle 路徑記在本任務下，作為 4.2 的比對基準；本任務不改任何檔案 (`git status --short` 前後相同)。
    - 檢查腳本數量 (`19ef9ccc`)：unit `@Test` 1744、unit XCTest 測試函式 8 (腳本更正後只計 import XCTest 的檔案)、UI 測試函式 108、快照基準圖 74。
    - 單元測試 (iPhone 17 `1FB73457`，略過 `OrdersFeaturePerformanceTests`)：1740 條通過、0 失敗；`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-23T11-17-10-257Z_pid87974_04b3ae5f.xcresult`
    - UI 回歸 iPhone 17 (`--scheme BuyLedgerUITests`，略過 `LaunchPerformanceTests`)：83 條通過、0 失敗、24 條略過 (只在 iPad 跑的測試)；`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-23T11-21-18-158Z_pid94014_d91e3b67.xcresult`
    - UI 回歸 iPad Air 11-inch (M4) `E30658D5`：模擬器資料夾已不在磁碟上，以 `simulator-management erase` 重建後開機 (Device Hub 未執行、未接硬體鍵盤)，`KeyboardDismissTests` 2 條先通過；重用 iPhone 那次改動前的建置產物 (`--profile products --test-products-path`) 跑完整回歸，97 條通過、0 失敗、10 條略過；`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-23T12-11-26-069Z_pid62301_ffc8bdb5.xcresult`

- [x] 1.2 讓資料層的跨族群 helper 不再掛在測試型別上 [after: 1.1：基準要在任何改動前量完]：依 design「先抽共用 helper 再平行拆分」與「共用 helper 依使用範圍分三層」，把 `BuyLedgerDatabaseTests` 的 `makeInMemoryDatabase`／`makeDatabase`／`removeTemporaryDirectory`、`OrderServiceTests` 的 `seed`／`makeOrder`／`makeService`／`fetchOrder`／`makeSaveFailingService`、`OrderServiceResidueTests` 的 `requireRelationshipSaveFailure`／`fetchPersistedOrders`、`CurrencyMetadataServiceTests` 的 `makeHTTPResponse`／`makeConfigurationStore` 移到 `BuyLedgerTests/Support/` 的同名 `<Base>TestSupport`，把 `CampaignServiceTests.makeService` 移到 `Features/Campaigns/CampaignServiceTestSupport`、`LookupServiceTests` 的 `makeService`／`makePaymentOrder`／`fetchOrder` 移到 `Features/Lookups/LookupServiceTestSupport`，原型別上的成員刪除，所有呼叫端 (含原族群內以 `Self.` 或未限定名稱呼叫者) 改成呼叫 TestSupport；`TestDependencies+Calendar.swift` 併回 `TestDependencies.swift`；新增與改到的檔案整檔對齊 ios-dev-kit。驗證：`python3 -I openspec/changes/test-extension-split/reference/check_test_extensions.py --phase1` 的失敗清單不再出現這 6 個型別 (其餘型別留給 1.3)；主對話建置成功並跑這 6 個族群與所有呼叫端所屬的測試類別全數通過；`check_test_extensions.py` 輸出的四個數量不變。
    - 實作 codex-impl；審查 claude-impl。應修 1 (`CampaignServiceTestSupport` 因第 2 節新增跨資料夾使用者而搬到 `Support/`) 與建議 1 由 gemini-impl 修正。
    - 主對話建置成功 (四次建置：前三次共補回 5 檔在 `MemberImportVisibility` 下缺的 import，各檔歸屬見各任務說明)，完整單元測試 1740 條通過、0 失敗，與 1.1 基準相同；`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-23T13-38-09-795Z_pid88857_40d67b3f.xcresult`。`check_test_extensions.py` 輸出「[全部] 通過」；測試本體比對 (HEAD 與現在各 1828 個測試函式) 只有型別限定、名稱替換、Page Object 建立與 trailing closure 差異。

- [x] 1.3 讓 Feature 狀態類的跨族群 helper 不再掛在測試型別上 [after: 1.2：呼叫端檔案與 1.2 大量重疊，例如同一個 `OrdersFeatureTests+*.swift` 同時用兩邊的 helper]：依 design「共用 helper 依使用範圍分三層」，把 `OrdersFeatureTests` 的 `makeOrder`／`expectedDiscardAlert`／`SearchCase`／`failureNotice`、`OrderListFeatureTests` 的 `makeState`／`makeClearFiltersState`、`CampaignFeatureTests.detailPath`、`CampaignIntegrationTests` 的 `makeRootState`／`loadCampaigns`、`RootFeatureTests.makeIsolatedRootState` 移到 `BuyLedgerTests/Support/` 的 `<Base>TestSupport`，把 `OrderFilterFeatureTests` 的 `makeState`／`makeGroupedState`、`OrderCategoryPickerFeatureTests` 的 `makeState`／`expectedDiscardAlert`、`PaymentMethodCorrectionFeatureTests.PaymentMethodEditArguments`、`DashboardStatsTests` 的 `makeOrder`／`utcDate`、`InsightsStatsTests.makeOrder` 移到各自資料夾的 `<Base>TestSupport`，原成員刪除並改完所有呼叫端；新增與改到的檔案整檔對齊 ios-dev-kit。驗證：`python3 -I openspec/changes/test-extension-split/reference/check_test_extensions.py --phase1` 輸出「[共用 helper 階段] 通過」；主對話建置成功並跑改到的測試類別全數通過；四個數量不變。
    - 實作 codex-impl；審查 claude-impl。應修 1 (`SearchCase` 只有 `OrderListFeatureFiltersTests` 使用，搬回該型別；派工表指定位置有誤，屬主對話派工問題) 與建議 1 (移除失效的 `- Note:`) 由 gemini-impl 修正。`LocalizationCatalogTests+AppLanguage.swift` 的一處呼叫端由主對話指示 codex-impl 一併更新。
    - 主對話建置成功 (四次建置：前三次共補回 5 檔在 `MemberImportVisibility` 下缺的 import，各檔歸屬見各任務說明)，完整單元測試 1740 條通過、0 失敗，與 1.1 基準相同；`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-23T13-38-09-795Z_pid88857_40d67b3f.xcresult`。`check_test_extensions.py` 輸出「[全部] 通過」；測試本體比對 (HEAD 與現在各 1828 個測試函式) 只有型別限定、名稱替換、Page Object 建立與 trailing closure 差異。

## 2. 依族群拆成獨立型別

本節每個任務的共同完成條件：
- 該任務族群在 `reference/file-list.tsv` 的每一列都依 `action` 落地，並刪除來源 `+` 檔：
  - split-test：依 design「拆出的測試型別命名」改成獨立測試型別
  - guard-type：依 design「Guards 的 helper 分檔改成職責型別」改成職責型別
  - support：依 design「共用 helper 依使用範圍分三層」放 private 或 TestSupport
  - page-object、merge：依 design「UI 測試分檔的拆法」
- 測試函式名稱與內容不變；拆出的型別依 design Implementation Contract 判斷 `@MainActor`／`.serialized`。
- 主型別沒有測試時依 design「主型別沒有測試時刪除主檔」刪除。
- 新增與改到的檔案整檔對齊 ios-dev-kit。
- 主對話建置成功，跑該族群全部測試類別 (含新型別) 全數通過，執行數等於該族群拆分前的測試數；`check_test_extensions.py` 的數量不變，失敗清單中不再出現該族群的檔案。

- [x] 2.1 App 族群 `RootFeatureTests` (28 檔) 與 `AppLockFeatureTests` (1 檔) 拆成獨立型別，並符合本節共同完成條件 [after: 1.3：1.3 改到 `RootFeatureTests` 族群並建立 `RootFeatureTestSupport`]。驗證：`find apps/ios/BuyLedgerTests/Features/App -name 'RootFeatureTests+*' -o -name 'AppLockFeatureTests+*'` 無結果，`RootFeature*Tests` 與 `AppLockFeature*Tests` 全數通過。
    - 實作 claude-impl；審查 gemini-impl。無阻擋與應修；行寬建議皆屬 kit 允許的既有 closure 簽章，維持原樣。
    - 主對話建置成功 (四次建置：前三次共補回 5 檔在 `MemberImportVisibility` 下缺的 import，各檔歸屬見各任務說明)，完整單元測試 1740 條通過、0 失敗，與 1.1 基準相同；`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-23T13-38-09-795Z_pid88857_40d67b3f.xcresult`。`check_test_extensions.py` 輸出「[全部] 通過」；測試本體比對 (HEAD 與現在各 1828 個測試函式) 只有型別限定、名稱替換、Page Object 建立與 trailing closure 差異。

- [x] 2.2 Orders 第 1 組 `OrdersFeatureTests` (26 檔) 與 `OrdersFeaturePerformanceTests+FilterSheet` 拆成獨立型別，並符合本節共同完成條件 [after: 1.3：1.3 改到 `OrdersFeatureTests` 族群並建立 `OrdersFeatureTestSupport`]：主檔 `OrdersFeatureTests.swift` 沒有測試，helper 移走後刪除；效能測試改名 `OrdersFeatureFilterSheetPerformanceTests` (XCTest)，CI 與 test plan 的略過清單留到 3.1。驗證：拆出的 `OrdersFeature*Tests` 全數通過；`OrdersFeatureFilterSheetPerformanceTests` 以 `-only-testing` 單獨執行時測試數為 2 並通過。
    - 實作 codex-impl；審查 claude-impl。無阻擋與應修；建議的效能測試型別 `///` 補上類別分組 (gemini-impl 修正)。`OrdersFeatureFilterSheetPerformanceTests` 以 `-only-testing` 單獨執行 2 條通過：`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-23T13-43-39-670Z_pid95909_31314221.xcresult`。
    - 主對話建置成功 (四次建置：前三次共補回 5 檔在 `MemberImportVisibility` 下缺的 import，各檔歸屬見各任務說明)，完整單元測試 1740 條通過、0 失敗，與 1.1 基準相同；`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-23T13-38-09-795Z_pid88857_40d67b3f.xcresult`。`check_test_extensions.py` 輸出「[全部] 通過」；測試本體比對 (HEAD 與現在各 1828 個測試函式) 只有型別限定、名稱替換、Page Object 建立與 trailing closure 差異。

- [x] 2.3 Orders 第 2 組 `OrderListFeatureTests` (18 檔)、`OrderFilterFeatureTests` (4 檔)、`OrderCategoryPickerFeatureTests` (4 檔)、`OrdersFilterOperationsTests` (4 檔) 拆成獨立型別，並符合本節共同完成條件 [after: 1.3：1.3 改到這四個族群並建立其中三個的 TestSupport]。驗證：這四個族群拆出的測試類別全數通過，`OrdersSearchCancellationTests` 與 `OrdersBatchOperationsTests` (呼叫端) 仍通過。
    - 實作 gemini-impl；審查 codex-impl。應修 F3-1 (`@MainActor` 縮到用 `TestStore` 的方法、移除失效的 `nonisolated`) 與 F3-2 (未達斷行條件的參數合併) 由 gemini-impl 修正。建置時補回 `OrdersFilterOperationsTestSupport` 的 `import ComposableArchitecture`。
    - 主對話建置成功 (四次建置：前三次共補回 5 檔在 `MemberImportVisibility` 下缺的 import，各檔歸屬見各任務說明)，完整單元測試 1740 條通過、0 失敗，與 1.1 基準相同；`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-23T13-38-09-795Z_pid88857_40d67b3f.xcresult`。`check_test_extensions.py` 輸出「[全部] 通過」；測試本體比對 (HEAD 與現在各 1828 個測試函式) 只有型別限定、名稱替換、Page Object 建立與 trailing closure 差異。

- [x] 2.4 Orders 第 3 組 `OrderEditFeatureTests` (14 檔)、`OrderServiceTests` (9 檔)、`OrderWritesFeatureTests` (8 檔)、`OrderServiceResidueTests` (1 檔) 拆成獨立型別，並符合本節共同完成條件 [after: 1.2：1.2 改到 `OrderServiceTests` 與 `OrderServiceResidueTests` 族群]：主檔 `OrderEditFeatureTests.swift` 沒有測試，依 design「主型別沒有測試時刪除主檔」處理。驗證：四個族群拆出的測試類別全數通過。
    - 實作 claude-impl；審查 gemini-impl。無阻擋與應修。主對話裁定：`OrderWritesFeature` 的 `original`／`other` 在各型別以 `private static let` 取自 TestSupport。
    - 主對話建置成功 (四次建置：前三次共補回 5 檔在 `MemberImportVisibility` 下缺的 import，各檔歸屬見各任務說明)，完整單元測試 1740 條通過、0 失敗，與 1.1 基準相同；`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-23T13-38-09-795Z_pid88857_40d67b3f.xcresult`。`check_test_extensions.py` 輸出「[全部] 通過」；測試本體比對 (HEAD 與現在各 1828 個測試函式) 只有型別限定、名稱替換、Page Object 建立與 trailing closure 差異。

- [x] 2.5 Orders 第 4 組 `OrdersContainerPlanTests`、`OrderCategoryGroupsTests`、`OrdersPresentationFeatureTests`、`OrderMergeFeatureTests`、`OrdersQueryTests`、`OrderDetailFeatureTests`、`OrderDraftTests`、`OrdersLoadFeatureTests` (共 19 檔) 拆成獨立型別，並符合本節共同完成條件 [after: 1.1：第 1 節不改這 8 個族群，只需等基準]。驗證：8 個族群拆出的測試類別全數通過。
    - 實作 codex-impl；審查 claude-impl。無阻擋、應修與建議。主對話裁定純語法的 kit 對齊 (trailing closure 等) 屬整檔對齊範圍。建置時補回 `OrderDraftTestSupport` 的 `import Foundation`。
    - 主對話建置成功 (四次建置：前三次共補回 5 檔在 `MemberImportVisibility` 下缺的 import，各檔歸屬見各任務說明)，完整單元測試 1740 條通過、0 失敗，與 1.1 基準相同；`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-23T13-38-09-795Z_pid88857_40d67b3f.xcresult`。`check_test_extensions.py` 輸出「[全部] 通過」；測試本體比對 (HEAD 與現在各 1828 個測試函式) 只有型別限定、名稱替換、Page Object 建立與 trailing closure 差異。

- [x] 2.6 Campaigns 第 1 組 `CampaignFeatureTests` (19 檔) 與 `CampaignIntegrationTests` (5 檔) 拆成獨立型別，並符合本節共同完成條件 [after: 1.3：1.3 建立兩者的 TestSupport，1.2 改到 `CampaignFeatureTests` 的呼叫端]。驗證：兩個族群拆出的測試類別全數通過，`RootFeature*Tests` 中使用 `CampaignFeatureTestSupport`／`CampaignIntegrationTestSupport` 的類別仍通過。
    - 實作 claude-impl；審查 gemini-impl。無阻擋與應修。主對話裁定 `titledAlert` 因多型別共用改為 internal。
    - 主對話建置成功 (四次建置：前三次共補回 5 檔在 `MemberImportVisibility` 下缺的 import，各檔歸屬見各任務說明)，完整單元測試 1740 條通過、0 失敗，與 1.1 基準相同；`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-23T13-38-09-795Z_pid88857_40d67b3f.xcresult`。`check_test_extensions.py` 輸出「[全部] 通過」；測試本體比對 (HEAD 與現在各 1828 個測試函式) 只有型別限定、名稱替換、Page Object 建立與 trailing closure 差異。

- [x] 2.7 Campaigns 第 2 組 `CampaignReminderFeatureTests`、`CampaignServiceTests`、`CampaignListFeatureTests`、`CampaignLoadFeatureTests`、`CampaignWritesFeatureTests`、`CampaignDateSectionBuilderTests`、`CampaignEditFeatureTests`、`CampaignSavePlanTests` (共 30 檔) 拆成獨立型別，並符合本節共同完成條件 [after: 1.2：1.2 改到 `CampaignServiceTests` 族群並建立 `CampaignServiceTestSupport`]。驗證：8 個族群拆出的測試類別全數通過。
    - 實作 gemini-impl；審查 codex-impl。應修 F7-1 (TestSupport 分區)、F7-2 (`@MainActor` 範圍)、F7-3 (23 行超過 100)、F7-4 (未達斷行條件的參數合併) 由 gemini-impl 修正。建置時補回 `CampaignEditFeatureTestSupport` 的 `import ComposableArchitecture`。
    - 主對話建置成功 (四次建置：前三次共補回 5 檔在 `MemberImportVisibility` 下缺的 import，各檔歸屬見各任務說明)，完整單元測試 1740 條通過、0 失敗，與 1.1 基準相同；`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-23T13-38-09-795Z_pid88857_40d67b3f.xcresult`。`check_test_extensions.py` 輸出「[全部] 通過」；測試本體比對 (HEAD 與現在各 1828 個測試函式) 只有型別限定、名稱替換、Page Object 建立與 trailing closure 差異。

- [x] 2.8 Lookups 族群 `LookupServiceTests` (11 檔)、`LookupManagementFeatureTests` (6 檔)、`PaymentMethodCorrectionFeatureTests`、`LookupCatalogFeatureTests` 拆成獨立型別，並符合本節共同完成條件 [after: 1.3：1.2 與 1.3 分別建立 `LookupServiceTestSupport` 與 `PaymentMethodCorrectionFeatureTestSupport`]。驗證：4 個族群拆出的測試類別全數通過。
    - 實作 claude-impl；審查 gemini-impl。無阻擋與應修。主對話裁定 `PaymentMethodCorrectionFeatureTests` 的型別 `///` 依現況改寫。
    - 主對話建置成功 (四次建置：前三次共補回 5 檔在 `MemberImportVisibility` 下缺的 import，各檔歸屬見各任務說明)，完整單元測試 1740 條通過、0 失敗，與 1.1 基準相同；`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-23T13-38-09-795Z_pid88857_40d67b3f.xcresult`。`check_test_extensions.py` 輸出「[全部] 通過」；測試本體比對 (HEAD 與現在各 1828 個測試函式) 只有型別限定、名稱替換、Page Object 建立與 trailing closure 差異。

- [x] 2.9 其餘 Feature、Core 與 App/Testing 族群 (Dashboard 3 族、Insights 2 族、`MoreFeatureTests`、`SettingsFeatureTests`、`QuoteFeatureTests`、`FxFeatureTests`、`AISummaryServiceTests`、`CurrencyMetadataServiceTests`、`CampaignSummaryTests`、`BuyLedgerDatabaseTests`、`BLUITestSeedDataTests`、`BLUITestConfigurationTests`，共 24 檔) 拆成獨立型別，並符合本節共同完成條件 [after: 1.3：1.2 與 1.3 改到 `BuyLedgerDatabaseTests`、`CurrencyMetadataServiceTests`、`DashboardStatsTests`、`InsightsStatsTests` 族群]。驗證：15 個族群拆出的測試類別全數通過。
    - 實作 claude-impl；審查 gemini-impl。無阻擋與應修。另處理對照表未列的 `InsightsHeatmapTests.swift` (檔名不含 `+` 的 `extension InsightsStatsTests`)，改成同名獨立型別，主對話接受；HEAD 只有這一個此類檔案 (主對話以 grep 確認)。
    - 主對話建置成功 (四次建置：前三次共補回 5 檔在 `MemberImportVisibility` 下缺的 import，各檔歸屬見各任務說明)，完整單元測試 1740 條通過、0 失敗，與 1.1 基準相同；`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-23T13-38-09-795Z_pid88857_40d67b3f.xcresult`。`check_test_extensions.py` 輸出「[全部] 通過」；測試本體比對 (HEAD 與現在各 1828 個測試函式) 只有型別限定、名稱替換、Page Object 建立與 trailing closure 差異。

- [x] 2.10 Guards 第 1 組 `DependencyConventionScanTests`、`DependencyConventionScanScenario`、`ServiceOwnershipScanTests`、`ActionGroupingScanTests` (共 22 檔) 拆成獨立型別，並符合本節共同完成條件 [after: 1.1：第 1 節不改 Guards 的提供者，只需等基準]：依 design「Guards 的 helper 分檔改成職責型別」，`ServiceOwnership` 使用的 `declaresDependencyKey`、`matches`、`matchingDelimiter`、`blankedCommentsAndStrings` 所在的型別放 `Guards/Scanning/`。驗證：4 個族群拆出的測試類別全數通過，且刻意違規的情境資料仍讓對應的守門測試判定違規 (情境測試的預期結果不變)。
    - 實作 claude-impl；審查 gemini-impl。無阻擋與應修。主對話依 claude-impl 回報更正 file-list (`+TestValueRules` 實為 guard-type) 與 design (ServiceOwnership 並未使用 `SourceTree`／`ScanRule`)。守門的違規情境測試仍判定違規 (含在上述 1740 條通過內)。
    - 主對話建置成功 (四次建置：前三次共補回 5 檔在 `MemberImportVisibility` 下缺的 import，各檔歸屬見各任務說明)，完整單元測試 1740 條通過、0 失敗，與 1.1 基準相同；`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-23T13-38-09-795Z_pid88857_40d67b3f.xcresult`。`check_test_extensions.py` 輸出「[全部] 通過」；測試本體比對 (HEAD 與現在各 1828 個測試函式) 只有型別限定、名稱替換、Page Object 建立與 trailing closure 差異。

- [x] 2.11 Guards 第 2 組 `ProjectionWriteBoundaryTests`、`DesignSystemSourceScanTests`、`LayerBoundaryTests`、`LocalizationCatalogTests` (共 20 檔) 拆成獨立型別，並符合本節共同完成條件 [after: 1.3：1.3 改到 `LocalizationCatalogTests+AppLanguage.swift` 的呼叫端]：依 design「Guards 的 helper 分檔改成職責型別」，`StripMode` 與 `stripCommentsAndStrings` 所在的型別放 `Guards/Scanning/`，呼叫端 `OrderListSnapshotSourceScanTests` 同步改；主檔 `ProjectionWriteBoundaryTests.swift` 沒有測試，依 design「主型別沒有測試時刪除主檔」處理。驗證：4 個族群拆出的測試類別與 `OrderListSnapshotSourceScanTests` 全數通過。
    - 實作 codex-impl；審查 claude-impl。阻擋 1 (移除 `import Foundation` 後 `URL.path` 在 `MemberImportVisibility` 下編譯失敗，第一次建置重現) 由 gemini-impl 補回；應修 1 至 8 與建議 1 至 4 (含抽出頂層 `ProjectionWriteBoundaryScenario`、`DesignSystemSourceLexer` 只留共用成員) 由 codex-impl 修正。
    - 主對話建置成功 (四次建置：前三次共補回 5 檔在 `MemberImportVisibility` 下缺的 import，各檔歸屬見各任務說明)，完整單元測試 1740 條通過、0 失敗，與 1.1 基準相同；`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-23T13-38-09-795Z_pid88857_40d67b3f.xcresult`。`check_test_extensions.py` 輸出「[全部] 通過」；測試本體比對 (HEAD 與現在各 1828 個測試函式) 只有型別限定、名稱替換、Page Object 建立與 trailing closure 差異。

- [x] 2.12 快照測試 `SnapshotTests+<X>` (18 檔) 改成 `Snapshot<X>Tests`，16 個基準圖目錄依 design「快照基準圖只搬不重錄」改名為 `Snapshot<X>Tests/`，`SnapshotTests+CampaignFixtures` 依 design「共用 helper 依使用範圍分三層」處理，空殼主檔 `SnapshotTests.swift` 刪除，並符合本節共同完成條件 [after: 1.1：第 1 節不改快照測試，只需等基準]；CI 略過清單留到 3.1。驗證：外觀鎖淺色後跑全部 `Snapshot*Tests`，76 條全數通過且不重錄；執行後 `find apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__ -name '*.png' | wc -l` 仍為 74，`git status --short` 沒有新增的 png，只有目錄改名。
    - 實作 gemini-impl；審查 codex-impl。阻擋 B12-1 (照片 helper 被改成自訂錯誤，已還原為 `try #require(image.pngData())`) 與應修 F12-1 (5 處 `assertSnapshot` 合併成一行) 由 gemini-impl 修正。74 張基準圖全部為 `R100` 改名，跑完快照後沒有新增 png。
    - 主對話建置成功 (四次建置：前三次共補回 5 檔在 `MemberImportVisibility` 下缺的 import，各檔歸屬見各任務說明)，完整單元測試 1740 條通過、0 失敗，與 1.1 基準相同；`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-23T13-38-09-795Z_pid88857_40d67b3f.xcresult`。`check_test_extensions.py` 輸出「[全部] 通過」；測試本體比對 (HEAD 與現在各 1828 個測試函式) 只有型別限定、名稱替換、Page Object 建立與 trailing closure 差異。

- [x] 2.13 UI 測試的 8 個分檔依 design「UI 測試分檔的拆法」處理 [after: 1.1：單元測試的任務都不改 UI 測試 target，只需等基準]：
    - 新增遵循 `Screen` 協定的 `OrderFilterSheetScreen` 與 `OrderCategoryPickerScreen`，各有自己的根 identifier，呼叫端改成建立對應的 Page Object
    - `OrdersScreen`、`CampaignDetailScreen`、`InsightsScreen` 的同畫面片段併回主檔
    - 兩個 `+Assertions` 併回測試類別檔
    - 不改操作順序與斷言；新增與改到的檔案整檔對齊 ios-dev-kit
    - 驗證：`find apps/ios/BuyLedgerUITests -name '*+*.swift'` 無結果；主對話建置 UI 測試 target 成功，在 iPhone 17 與 iPad Air 11-inch 以 `-only-testing` 逐一跑用到這五個 Page Object 或兩個測試類別的 UI 測試類別，全數通過且執行數大於 0
    - 實作 claude-impl；審查 gemini-impl (無阻擋與應修)。主對話裁定：兩個 sheet 共用的 helper 留在 `OrdersScreen`、`filterSheet.filterSheet` 名稱依「只改接收者」不改、規則檔引用留到 3.1。
    - 受影響的 31 個 UI 測試類別 (`OrdersScreen`、`OrderFilterSheetScreen`、`OrderCategoryPickerScreen`、`CampaignDetailScreen`、`InsightsScreen` 與兩個併入 `+Assertions` 的測試類別的使用者) 以 `--scheme BuyLedgerUITests` 逐一 `-only-testing` 執行：
        - iPhone 17：68 條通過、0 失敗、24 條略過 (只在 iPad 跑)；第一次因模擬器服務 `Mach error -308` 無法啟動 runner，重用同一份建置產物重跑；`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-24T02-30-14-832Z_pid20086_5dd2e399.xcresult`
        - iPad Air 11-inch：81 條通過、1 條失敗、10 條略過；失敗的 `OrdersListTests/testSearch_沒有符合的訂單_顯示空狀態` 停在 Given 的「切到訂單分頁後畫面未就緒」，同類其他測試走同一路徑皆通過，單獨重跑 `OrdersListTests` 3 條全過，判定為偶發；`…/test_sim_2026-10-24T03-11-04-648Z_pid73078_475a86eb.xcresult`、`…/test_sim_2026-10-24T04-06-10-346Z_pid27531_34a7784b.xcresult`
    - 這兩次重用 4.1 style 修正前的建置產物；style 修正後的 UI 程式由 4.2 完整回歸驗證。

## 3. CI 與文件同步

- [x] 3.1 讓 CI、test plan 與文件只引用拆分後的實際名稱 [after: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9, 2.10, 2.11, 2.12, 2.13：要引用全部任務定案後的型別名與檔名]：
    - `.github/workflows/ci.yml` 的快照略過改成每個 `Snapshot<X>Tests` 一條 `-skip-testing`，並加上 `OrdersFeatureFilterSheetPerformanceTests` (design「CI 逐一列名略過快照」)
    - `apps/ios/BuyLedger.xctestplan` 的 `skippedTests` 加上 `OrdersFeatureFilterSheetPerformanceTests`
    - 刪除 `apps/ios/CLAUDE.md` 過渡例外中的「測試拆檔」一項
    - `.claude/rules/ios-unit-tests.md` 補上 design「共用 helper 依使用範圍分三層」的共用 helper 三層放置規則，並更新快照目錄範例與舊檔名
    - `.claude/rules/ios-ui-tests.md`、`.claude/rules/ios-accessibility-localization.md` 與 `apps/ios/README.md` (專案結構註解、快照 baseline 路徑) 中的舊檔名與已刪除的主型別名改成新名稱
    - 驗證：`grep -rnE '[A-Za-z]+(Tests|Screen|Scenario)\+[A-Za-z]+|SnapshotTests\b|BuyLedgerTests/SnapshotTests|ProjectionWriteBoundaryTests|OrdersFeatureTests|OrderEditFeatureTests' .github/workflows/ci.yml apps/ios/BuyLedger.xctestplan apps/ios/CLAUDE.md apps/ios/README.md .claude/rules` 無結果，或剩下的每一筆都指向仍存在的型別 (逐筆記錄在本任務下)
    - 驗證：ci.yml 的 `Snapshot*Tests` 略過條目數等於 `apps/ios/BuyLedgerTests/SnapshotTests` 內 `Snapshot*Tests.swift` 的檔案數
    - 驗證：`python3 -I openspec/changes/test-extension-split/reference/check_test_extensions.py` 輸出「[全部] 通過」
    - 實作 claude-impl；主對話審閱 9 檔 diff (`.github/workflows/ci.yml`、`apps/ios/BuyLedger.xctestplan`、`apps/ios/CLAUDE.md`、`apps/ios/README.md`、`.claude/rules/ios-unit-tests.md`、`ios-ui-tests.md`、`ios-accessibility-localization.md`、`ios-design-system.md` 等)，文件風格另由 4.1 逐檔審查。
    - 舊名稱 grep：無結果 (`SnapshotTests/` 目錄名與保留檔 `String+SourceLiteralScan.swift` 不計)；ci.yml 的 `Snapshot*Tests` 略過 17 條，等於 `SnapshotTests/` 內 17 個 `Snapshot*Tests.swift`；`skippedTests` 為 `OrdersFeatureFilterSheetPerformanceTests`、`OrdersFeaturePerformanceTests`；`check_test_extensions.py` 輸出「[全部] 通過」。
    - `openspec/specs/` 仍有舊檔名，全部在 `<!-- @trace -->` 區塊內，依 root `CLAUDE.md` 不手改。
    - 待使用者決定：`.claude/rules/ios-unit-tests.md`「只含 `@Test` 的 test extension 不設 MARK」在拆分後已無對象，候選為刪除整條，或改寫成「helper、fixture、nested type 所在的 extension 照 kit 的區名設 MARK」；使用者裁定刪除前者、保留後者，由 5.1 執行。

## 4. 驗收

- [x] 4.1 style 閘門 [after: 3.1：要審全部程式與文件的最終版本]：
    - 由未參與實作的 haiku-max-implementer 子代理依 `/ios-dev-kit` 逐檔逐條審查本 change 全部新增與改到的檔案，不抽查，回報每檔的檢查清單
    - 違規交回原實作者修正後重審，直到沒有違規
    - 驗證：最後一輪審查回報零違規，檢查清單涵蓋 `git status --short` 列出的每一個檔案
    - 第一輪：11 個 haiku-max-implementer 子代理逐檔審查 393 檔 (清單、檢查項與裁定見 scratchpad `gate-brief.md`)。審查前後檔案雜湊相同，確認未改檔。
    - 主對話裁定：
        - 修正：註解用詞「拋出」改「丟出」，共數百處；斷行與對齊；字面值括號貼合；closure 簽章；方法順序；`- Note:` 拆分；反引號；函式本體 `do throws(E)` 改 `do`；Bool 命名；helper 放置；`switch default` 改 `if case`
        - 範圍外 (不改測試內容與結構)：預期值字面化、Given 直設、等待位置、Then 內多動作、`@Test(arguments:)` tuple、`throws(any Error)`、UI 測試類別層 `@MainActor`、`search(_:)` 行為、SourceStripping 去重
        - 維持：TestSupport 檔頭沿用來源日期、`enum X {}`、鏈式在 `.` 前斷行
        - 修正由 codex-impl (Guards) 與 claude-impl (其餘) 執行；gemini-impl 重開機後每步都要人工核准，改派他人
    - import 試移除：47 處疑似多餘的 import 先移除，再以建置判定 (`MemberImportVisibility`)，編譯需要的逐一補回，最終保留的都是編譯需要的。
    - 確認輪：4 個子代理逐檔再審修正輪改過的 110 檔，提出的應修 (`do throws`、貼合、方法順序、反引號、`@MainActor` 範圍等) 再修一輪；最後一輪改到的 20 檔由主對話檢視 diff 並跑機械檢查，無新問題。
    - 收斂說明：確認輪另提出兩類新判準，主對話未擴大本輪範圍，列為後續由使用者決定：
        - 測試摘要須動詞開頭 (前一輪 11 組皆未採用此判準，套用需重掃全部檔案)
        - 只用一次的短 private helper 內聯 (已排定與 Core 一起另開一輪)
    - 完整單元測試 1740 條通過：`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-24T04-49-46-056Z_pid85546_c616d31d.xcresult`；`check_test_extensions.py` 輸出「[全部] 通過」；測試本體比對 1828 個函式，只有型別限定、名稱替換、Page Object 建立與已核准的語法調整差異。

- [x] 4.2 主對話完整回歸 [after: 4.1：style 修正可能改到測試，回歸要跑最終版本]：
    - 全量建置沒有新增編譯警告
    - 在 iPhone 17 跑完整單元測試，在 iPhone 17 與 iPad Air 11-inch 跑完整 UI 回歸，結果與 1.1 基準一致：基準中通過的測試全部通過，已知失敗不增加，測試總數相同
    - `check_test_extensions.py` 輸出「[全部] 通過」；`git status --short` 沒有未預期的新增 png 或 App target 檔案
    - 依文件同步鐵則對照 diff，結論為「有影響，已同步」
    - 驗證：上述結果、result bundle 路徑與同步結論記在本任務下
    - 編譯警告：單元與 UI 兩次建置的 `warning:` 行去重後與 1.1 基準逐行比對，沒有新增。
    - 單元測試 (iPhone 17 `1FB73457`，略過兩個效能測試類別)：1740 條通過、0 失敗，與基準相同；`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-24T04-49-46-056Z_pid85546_c616d31d.xcresult`
    - UI 回歸 iPhone 17：83 條通過、0 失敗、24 條略過，與基準相同；`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-24T04-53-20-753Z_pid89230_de6fcb72.xcresult`
    - UI 回歸 iPad Air 11-inch (M4) `E30658D5` (重用 iPhone 這次的建置產物 `test_sim_2026-10-24T04-53-20-753Z_pid89230_1621beae.xctestproducts`)：
        - `KeyboardDismissTests` 2 條先通過；完整回歸 88 條通過、9 條失敗、10 條略過 (`test_sim_2026-10-24T05-38-48-217Z_pid29492_400a03c3.xcresult`)
        - 9 條失敗全在需要橫向的 5 個類別 (`OrientationLayoutTests`、`OrderRegularAccessibilitySizeTests`、`OrderRegularColumnScopeTests`、`OrderRegularColumnWidthTests`、`OrderRegularSearchBarTests`)，訊息都是 `Orientation.swift` 的「轉向後 App 視窗寬仍未大於高」；單獨重跑仍失敗，改用 1.1 改動前的建置產物跑 `OrientationLayoutTests` 也失敗 (`test_sim_2026-10-24T06-42-44-617Z_pid80324_f5d36607.xcresult`)，判定為模擬器轉向失效，不是本次改動造成
        - `erase --shutdown-first` 後開機、鎖淺色，同一批產物重跑 5 個類別全數通過：`OrientationLayoutTests` 2 條 (`test_sim_2026-10-24T06-44-20-015Z_pid82095_f386e7aa.xcresult`)、其餘 4 類 14 條 (`test_sim_2026-10-24T06-49-50-689Z_pid86428_e7984b9d.xcresult`)
        - 合計 97 條通過、0 失敗、10 條略過，與基準相同
    - `check_test_extensions.py`：數量為 unit `@Test` 1744、unit XCTest 測試函式 8、UI 測試函式 108、快照基準圖 74，輸出「[全部] 通過」。
    - `git status --short` (不含使用者另外進行的 `.archify/`)：74 張 png 全是改名 (`R`)，沒有新增；App target (`apps/ios/BuyLedger/`) 沒有任何變更；測試 target 以外只有 3.1 的文件與設定檔和本 change 的 openspec 檔。
    - 文件同步：有影響，已同步。命中「目錄結構、build / test 指令變動」與「讓既有描述失效的行為改變」，3.1 已同步 `.github/workflows/ci.yml`、`apps/ios/BuyLedger.xctestplan`、`apps/ios/README.md`、`apps/ios/CLAUDE.md` (刪除測試拆檔過渡例外) 與 `.claude/rules/` 五份規則檔的測試識別碼；新的共用 helper 三層放置規則寫進 `.claude/rules/ios-unit-tests.md`。
    - 另修正本檔開頭測試模擬器一行被先前替換弄壞的 iPad UDID。

## 5. 規則條文與同檔 test extension

- [x] 5.1 讓 test extension 的 MARK 規則只剩適用的條文，測試一律寫在測試型別本體 [after: 4.2：以回歸過的版本為起點]：依 design「test extension 的 MARK 規則改寫」，`.claude/rules/ios-unit-tests.md` 刪除「只含 `@Test` 的 test extension 不設 MARK」，該條改寫為「helper、fixture、nested type 所在的 extension 照 kit 的區名設 MARK」；`OrdersDetailNavigationFeatureTests` 的測試從同檔 `extension` 搬進型別本體，接在 Properties 之後，內容不變。驗證：規則檔不再出現「只含 `@Test`」；掃描兩個測試 target，內含 `@Test` 或 `func test` 的 `extension` 為 0 個；主對話建置成功並跑 `OrdersDetailNavigationFeatureTests` 全數通過，執行數不變。
    - 實作 claude-impl；審查 codex-impl，無阻擋、應修與建議。規則檔該條改為「helper、fixture、nested type 所在的 extension 照 kit 的區名設 MARK」；測試檔只刪掉空本體結尾與 extension 開頭 4 行，17 個 `@Test` 直接成為型別本體成員。
    - 掃描兩個測試 target：內含 `@Test` 的 `extension` 0 個 (腳本另命中 `DependencyConventionTestValueRules` 的 `func testValueViolations`，是 helper 方法名、不是 XCTest 測試)。
    - `OrdersDetailNavigationFeatureTests` 17 條通過，與改動前相同；`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-24T07-33-38-921Z_pid31170_08d8eed6.xcresult`

## 6. 測試寫法逐檔修正

本節每個任務的共同完成條件：
- 範圍內每個檔案都對過 design「測試寫法逐檔修正的規則」T1 至 T13 (不適用的代號略過)，先由 haiku-max-implementer 子代理列出違規清單，實作者逐項修正並補上自己發現的同類項；判定不改的項目寫明理由 (例如要改 App target 才能修)。
- 不改 App target；不改 `Support/`、`Fixtures/`、`Mocks/` 與其他組資料夾的檔案 (6.10 除外)。
- 拆開多組 When／Then (T4)、tuple 參數改 struct (T6)、Bool 參數改名 (T8) 造成的測試識別碼變更，逐一記在任務下；T1、T10 改過的斷言，回報寫出它會在什麼錯誤實作下失敗。
- 改到的檔案整檔對齊 ios-dev-kit 與專案規則 (註解規則同 4.1)。
- 主對話建置成功，跑該組全部測試類別全數通過；執行數等於改動前的執行數加上記錄的拆分新增數。

- [x] 6.1 Orders 複數組 (`Features/Orders/Orders*.swift`，56 檔約 1 萬行，含 `OrdersFeature*`、`OrdersContainer*`、`OrdersLoad*`、`OrdersPresentation*`、`OrdersQuery*`、`OrdersFilter*`、`OrdersSearch*`、`OrdersShared*`、`OrdersBatch*`、`OrdersDetail*`) 的測試寫法符合 T1 至 T10，並符合本節共同完成條件 [after: 5.1：5.1 改到同組的 `OrdersDetailNavigationFeatureTests.swift`]。驗證：違規清單逐項處理完畢；該組測試類別全數通過。
    - 實作 claude-impl；審查清單 haiku-max-implementer (兩份)；交叉審查 codex-impl：阻擋 1 項 (MergeTiming 改寫後 499ms 斷言抓不到提早排入的確認，`store.state` 在 `receive` 前不更新) 已修，改以記錄型 clock 替身斷言延遲正好 500ms；應修 4 項已修。主對話審查：MergeTiming 拆分合理。
    - 變異驗證：正式碼延遲暫改 499ms 時 `formSheetDismissed_合併轉場中關閉回呼先到_到期後先開啟確認表單()` 與 `presentation_合併候選完成且關閉回呼未到_到期時暫存確認表單()` 失敗，還原後通過 (正式碼 diff 為空)。
    - 該組執行數 297 → 313 (+16，拆分與參數化 15、StatusWrites 首輪失敗新測試 1)，與回報一致；識別碼變更由 8.1 彙整。
    - 驗證 (主對話)：完整單元測試建置成功，1777 條中 1776 條通過，唯一失敗屬 6.4 未完成的 `CampaignFeatureLoadingTests`；`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-24T08-52-18-201Z_pid68730_2bfd6c0f.xcresult`。各組執行數以結果檔對照 4.2 基準逐類別比對。
- [x] 6.2 Orders 編輯、清單與篩選組 (`Features/Orders/` 的 `OrderEdit*`、`OrderList*`、`OrderFilter*`，45 檔約 8,600 行) 的測試寫法符合 T1 至 T10，並符合本節共同完成條件 [after: 4.2：以回歸過的版本為起點，檔案與其他任務不重疊]。驗證：違規清單逐項處理完畢；該組測試類別全數通過。
    - 實作 codex-impl；交叉審查 claude-impl：無阻擋，應修 2 處斷行已還原；審查總裁定 39 列「T10 冗餘」不改。
    - 驗證 (主對話)：完整單元測試 1777 條全數通過，`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-24T12-45-33-295Z_pid95284_b11c8213.xcresult`；該組執行數 331 → 331，與回報一致 (沒有新增或拆分)。
- [x] 6.3 Orders 其餘組 (`Features/Orders/` 中 6.1、6.2 以外的檔案，含 `OrderCategory*`、`OrderService*`、`OrderWrites*`、`OrderMerge*`、`OrderDraft*`、`OrderDetail*` 與單檔類別，52 檔約 8,400 行) 的測試寫法符合 T1 至 T10，並符合本節共同完成條件 [after: 4.2：以回歸過的版本為起點，檔案與其他任務不重疊]。驗證：違規清單逐項處理完畢；該組測試類別全數通過。
    - 實作 codex-impl；交叉審查 claude-impl：無阻擋，應修 2 項 (Nested Types 併成單一 extension、`guard else` 不放計數) 已修；codex 把 `SpecFixture` 標成 `private` 後編譯失敗 (被 `private extension` 內方法的回傳型別引用)，主對話依 kit 4.2.0 規則改回 internal。
    - 驗證 (主對話)：完整單元測試 1777 條全數通過，`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-24T12-45-33-295Z_pid95284_b11c8213.xcresult`；該組執行數 331 → 331 (`toggle_切換單一組別兩次…` 改成單次展開的新測試，淨增 0)，與回報一致。
- [x] 6.4 Campaigns 第 1 組 (`Features/Campaigns/` 的 `CampaignFeature*`、`CampaignIntegration*`、`CampaignReminder*`、`CampaignWrites*`、`CalendarReminderTests`，37 檔約 6,400 行) 的測試寫法符合 T1 至 T10，並符合本節共同完成條件 [after: 4.2：以回歸過的版本為起點，檔案與其他任務不重疊]。驗證：違規清單逐項處理完畢；該組測試類別全數通過。
    - 實作 claude-impl；交叉審查 codex-impl：阻擋 1 項 (深連結測試直設時漏設 `selectedTab = .campaigns`，測試變弱) 已修；實跑發現 `CampaignFeatureLoadingTests` 的直設寫法拿掉了讀取閘門，斷言位置錯開，恢復閘門後通過；依實作者回報補 `load_表單開啟中收到同名開團_維持表單且不提前顯示重名()`。
    - 驗證 (主對話)：完整單元測試 1777 條全數通過，`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-24T12-45-33-295Z_pid95284_b11c8213.xcresult`；該組執行數 128 → 134 (+6)，與回報一致。
- [x] 6.5 Campaigns 第 2 組 (`Features/Campaigns/` 中 6.4 以外的檔案，36 檔約 5,500 行) 的測試寫法符合 T1 至 T10，並符合本節共同完成條件 [after: 4.2：以回歸過的版本為起點，檔案與其他任務不重疊]。驗證：違規清單逐項處理完畢；該組測試類別全數通過。
    - 實作 haiku-max-implementer；審查清單與交叉審查各由另一個 haiku-max-implementer 子代理；交叉審查無阻擋，應修中「首次失敗前置改直設」採納 (推翻先前保留的裁定)、computed 斷言 3 處依「與 Given 相同的 `#expect` 不改」裁定不改，建議 3 項採納。
    - 該組執行數 192 → 196 (+4)，與回報一致。
    - 驗證 (主對話)：完整單元測試建置成功，1777 條中 1776 條通過，唯一失敗屬 6.4 未完成的 `CampaignFeatureLoadingTests`；`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-24T08-52-18-201Z_pid68730_2bfd6c0f.xcresult`。各組執行數以結果檔對照 4.2 基準逐類別比對。
- [x] 6.6 App、More 與 Customers 組 (`Features/App/`、`Features/More/`、`Features/Customers/`，38 檔約 7,300 行) 的測試寫法符合 T1 至 T10，並符合本節共同完成條件 [after: 4.2：以回歸過的版本為起點，檔案與其他任務不重疊]。驗證：違規清單逐項處理完畢；該組測試類別全數通過。
    - 實作 claude-impl；交叉審查 codex-impl：無阻擋，應修 2 項 (計數替身、多餘斷行) 已修。主對話審查：`MoreFeatureTests` 兩條「返回後再進入」改成空堆疊會失去返回這一步，要求還原 (屬只能經 reducer 建立的前置)，已還原。
    - `CustomerRowTests` 2 個舊式名稱由 6.9 的實作者改名 (主對話指派)。
    - 該組執行數 165 → 167 (+2)，與回報一致。
    - 驗證 (主對話)：完整單元測試建置成功，1777 條中 1776 條通過，唯一失敗屬 6.4 未完成的 `CampaignFeatureLoadingTests`；`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-24T08-52-18-201Z_pid68730_2bfd6c0f.xcresult`。各組執行數以結果檔對照 4.2 基準逐類別比對。
- [x] 6.7 其餘 Feature 組 (`Features/` 的 `Lookups`、`Dashboard`、`Insights`、`AISummary`、`FX`、`Quote`、`Settings`，55 檔約 1.07 萬行) 的測試寫法符合 T1 至 T10，並符合本節共同完成條件 [after: 4.2：以回歸過的版本為起點，檔案與其他任務不重疊]。驗證：違規清單逐項處理完畢；該組測試類別全數通過。
    - 實作 haiku-max-implementer；交叉審查另一個 haiku-max-implementer：無阻擋，應修 (斷行、`LookupCatalogTests` 12 個舊式名稱改名、裸 GWT 標記、`- Throws:` 更正、Given 前置確認) 已修。審查建議刪除的 `import Foundation` 有 3 檔 (`DashboardStatsTests`、`PaymentMethodCorrectionFeatureConfirmationTests`、`SettingsFeatureTests`) 與 1 檔 (`LookupManagementFeaturePaymentMethodStoredOrdersTests`) 在建置時證明需要 (`MemberImportVisibility` 下 Decimal 字面值)，主對話補回。
    - 該組執行數 361 → 367 (+6)，與回報一致。
    - 驗證 (主對話)：完整單元測試建置成功，1777 條中 1776 條通過，唯一失敗屬 6.4 未完成的 `CampaignFeatureLoadingTests`；`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-24T08-52-18-201Z_pid68730_2bfd6c0f.xcresult`。各組執行數以結果檔對照 4.2 基準逐類別比對。
- [x] 6.8 Guards 組 (`Guards/`，69 檔約 1.18 萬行) 的測試寫法符合 T1 至 T10 與 T13：`LayerBoundarySourceStripping` 與 `ProjectionWriteBoundarySourceStripping` 合併成 `Guards/Scanning/` 的單一型別，兩邊呼叫端改用它，刻意違規的情境資料仍讓守門測試判定違規；並符合本節共同完成條件 [after: 4.2：以回歸過的版本為起點，檔案與其他任務不重疊]。驗證：違規清單逐項處理完畢；`find apps/ios/BuyLedgerTests/Guards -name '*SourceStripping.swift'` 只剩 `Guards/Scanning/` 的一個檔；Guards 全部測試類別通過。
    - 實作 codex-impl；交叉審查 claude-impl：無阻擋，應修 8 項 (排版、空 allowlist 的恆真斷言) 已修；Guards 8 個舊式名稱改名。`LayerBoundarySourceStripping` 與 `ProjectionWriteBoundarySourceStripping` 合併為 `Guards/Scanning/SwiftSourceStripping.swift`，`find apps/ios/BuyLedgerTests/Guards -name '*SourceStripping.swift'` 只剩這一檔。
    - 該組執行數 377 → 390 (+13)，與回報一致；Guards 全部通過，刻意違規的情境資料仍判定違規。
    - 驗證 (主對話)：完整單元測試建置成功，1777 條中 1776 條通過，唯一失敗屬 6.4 未完成的 `CampaignFeatureLoadingTests`；`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-24T08-52-18-201Z_pid68730_2bfd6c0f.xcresult`。各組執行數以結果檔對照 4.2 基準逐類別比對。
- [x] 6.9 Core、Shared、App 與 AccessibilityIDs 組 (`BuyLedgerTests/` 的 `Core/`、`Shared/`、`App/`、`AccessibilityIDs/`，44 檔約 7,700 行) 的測試寫法符合 T1 至 T10，並符合本節共同完成條件 [after: 4.2：以回歸過的版本為起點，檔案與其他任務不重疊]：`CurrencyMetadataServiceRefreshTests` 的 tuple 參數改 struct 後，`.claude/rules/ios-unit-tests.md` 以它為例的 `-only-testing` 參數標籤範例同步改成新標籤。驗證：違規清單逐項處理完畢；該組測試類別全數通過，規則檔範例的 `-only-testing` 實際執行數大於 0。
    - 實作 haiku-max-implementer；交叉審查另一個 haiku-max-implementer：無阻擋，應修已修；舊式名稱共改 79 個 (含 `AppLanguageTests` 等本輪原本未改的檔)。審查建議刪除的 `CampaignSummaryMembershipTests` 的 `import Foundation` 建置證明需要，主對話補回。
    - `.claude/rules/ios-unit-tests.md` 的 `-only-testing` 參數標籤範例改為 `refreshIfStale_快取年齡在七天門檻前後_依門檻決定是否刷新(scenario:)`。
    - 該組執行數 389 → 403 (+14)，與回報一致。
    - 驗證 (主對話)：完整單元測試建置成功，1777 條中 1776 條通過，唯一失敗屬 6.4 未完成的 `CampaignFeatureLoadingTests`；`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-24T08-52-18-201Z_pid68730_2bfd6c0f.xcresult`。各組執行數以結果檔對照 4.2 基準逐類別比對。
- [x] 6.10 共用層與快照組 (`BuyLedgerTests/` 的 `Support/`、`Fixtures/`、`Mocks/`、`SnapshotTests/`，42 檔約 6,700 行) 的寫法符合 T1 至 T10，並符合本節共同完成條件 [after: 4.2：以回歸過的版本為起點，檔案與其他任務不重疊]：共用 helper 的簽章若要改，同時改完所有呼叫端，且只在其他組的第 6 節任務都勾選後進行；其他組回報要改共用層的項目在本任務處理。驗證：違規清單與其他組轉來的項目逐項處理完畢；外觀鎖淺色後跑全部 `Snapshot*Tests` 通過且不重錄，`__Snapshots__` 仍為 74 張；共用層的呼叫端所在測試類別全數通過。
    - 實作 codex；審查清單 haiku-max-implementer、交叉審查另一個 haiku-max-implementer：無阻擋。應修 2 項：`MockUserDefaultsStore.StoredValue` 由主對話改回 Nested Types 單一 extension 內的 `private enum` (kit：同一區不拆兩個 extension)，`CampaignIntegrationTestSupport` 型別摘要由 7.10 改寫。
    - 刪除 0 呼叫端的 `CampaignIntegrationTestSupport.loadCampaigns` 與 `MockUserDefaultsStore.boolResult` (主對話授權)；`SnapshotLookupsTests` 改名時以 `testName` 明設原快照名稱，`__Snapshots__` 仍為 74 張、無新增或改動。
    - 「與 Given 相同的 `#expect`」2 處依 impl-brief 裁定不改 (send 不帶 closure，TestStore 已保證 State 不變)；`SnapshotOrderEditTests` 的 `shouldRepeatTask` 兩案例在 `.loaded` 起始下等價屬既有問題，列入最終回報。
    - 該組執行數不變 (0)。
    - 驗證 (主對話)：完整單元測試 1777 條全數通過 (含全部 `Snapshot*Tests`，外觀鎖淺色)；`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-24T12-45-33-295Z_pid95284_b11c8213.xcresult`。`StoredValue` 改回後的建置由 8.3 回歸驗證 (改回的寫法即 HEAD 版本)。
- [x] 6.11 UI 測試組 (`BuyLedgerUITests/`，78 檔約 1.17 萬行) 的寫法符合 T1 至 T12，並符合本節共同完成條件 [after: 4.2：以回歸過的版本為起點，UI 測試 target 與其他任務不重疊]：40 個測試類別的 `@MainActor` 改標在類別上並移除逐方法標註 (T11)；`OrdersScreen.search(_:)` 改用 `hittableSearchField()` 取得搜尋欄，呼叫端隨簽章調整 (T12)；`OptionPickerScreen.search(_:)` 若同樣取 searchable 搜尋欄也一併改。驗證：違規清單逐項處理完畢；iPhone 17 完整 UI 回歸與 1.1 基準一致 (83 條通過、24 條略過)。
    - 實作 claude-impl；審查清單兩份由 haiku-max-implementer，交叉審查 codex：應修 5 項已修。40 個測試類別改為類別層 `@MainActor`，`OrdersScreen.search` 與 `OptionPickerScreen.search` 改走 `hittableSearchField()`，`dismissNumericKeyboard` 刪除硬體鍵盤分支 (只點完成鍵)。
    - UI 測試的拆分依使用者裁定「只拆獨立行為」：前置移到 Given，驗證獨立結果才拆，同一流程的步驟保留並以情境流程 `- Note` 說明；UI 測試函式 108 → 119 (+11)。
    - `SettingsScreen` 兩個 extension 補 `@MainActor` (修正既有與新增的隔離警告)；`assertNavigationTitle` 後續改名時確認 0 呼叫端，主對話刪除。
    - 驗證 (主對話)：iPhone 17 完整 UI 回歸 90 條通過、0 失敗、28 條略過 (基準 83／0／24 加 11 條拆分)，`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-24T08-59-13-825Z_pid80969_87f26fd0.xcresult`；iPad Air 11-inch 先單獨跑 `KeyboardDismissTests` 2 條通過，再跑完整 UI 回歸 107 條通過、0 失敗、11 條略過 (基準 97／0／10 加 11 條拆分)，`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-24T12-54-20-967Z_pid6514_4a376419.xcresult`。iPad 回歸前先結束 Device Hub、erase 後以 `simulator-management boot` 開機 (不連接硬體鍵盤)。

## 7. 測試說明文字

本節每個任務的共同完成條件：
- kit 已回覆 `@Test` 摘要的定案寫法 (記在 design「Open Questions」)，本節依 kit 新版原文執行。
- 範圍內每個 `///` 摘要依 kit 新版寫法動詞開頭；`//` 與 `///` 說明依 kit `coding-style.md` 註解一節改白話、精簡，註解規則同 4.1。
- 只改註解：該組 diff 的每一個改動行都是註解行 (以腳本比對 `git diff` 驗證)，測試名稱與程式碼不變。
- 審查清單逐檔列出，判定不改的項目寫明理由。

- [x] 7.1 6.1 範圍的說明文字符合本節共同完成條件 [after: 6.1：改同一批檔]。驗證：diff 只有註解行；審查清單涵蓋該組每個檔案。
    - 實作 haiku-max-implementer 兩名 (7.1a 27 檔、7.1b 28 檔，摘要共 317 則)；審查 A 由 claude-impl 唯讀審查：阻擋 7 項 (摘要宣稱斷言以外的效果，如「等表單關好才呈現」) 與應修、建議全數依本體改寫。
    - 名稱與本體不符 2 項 (`OrdersFeaturePaymentMethodParityTests`、`OrdersFeaturePerformanceTests`) 由 claude-impl 改名 (6.1 後續)；型別名 `OrdersFeaturePaymentMethodParityTests` 依 design 的 `<Base><Suffix>Tests` 命名規則保留 (主對話裁定)。
    - 驗證 (主對話)：對照第 7 節前快照，非註解差異只有上述改名 (含效能測試同名 label 字串)。
- [x] 7.2 6.2 範圍的說明文字符合本節共同完成條件 [after: 6.2：改同一批檔]。驗證：diff 只有註解行；審查清單涵蓋該組每個檔案。
    - 實作 haiku-max-implementer 兩名 (7.2a 23 檔、摘要 149 則；7.2b 21 檔、摘要 150 則)；審查 F 由 codex 唯讀審查：阻擋 6 項 (未斷言的折抵夾限與欄位、把接收子層套用結果寫成不通知清單、未檢查的啟用外觀) 與應修、建議全數依本體改寫。
    - 名稱與本體不符 4 項列入改名 (`OrderFilterFeatureSearchTests` 兩條、`OrderListFeatureDatesTests` 一條、`OrderEditFeatureBindingTests` 一條)；測試名稱含「委派／子層／容器」的 22 個屬識別碼，本輪不改 (列入最終回報)。
    - 驗證 (主對話)：對照第 7 節前快照，非註解差異為 0。
- [x] 7.3 6.3 範圍的說明文字符合本節共同完成條件 [after: 6.3：改同一批檔]。驗證：diff 只有註解行；審查清單涵蓋該組每個檔案。
    - 實作 haiku-max-implementer 兩名 (7.3a 24 檔、摘要 186 則；7.3b 26 檔、摘要 121 則，`- Throws` 刪去測試內 do/catch 捕捉的錯誤)；審查 D 由 claude-impl 唯讀審查：阻擋 (宣稱下游處理與畫面效果) 改為只寫本體斷言、畫面用途以括號說明，應修與建議全數處理，`- Throws` 刪減逐條核對正確。
    - 名稱與本體不符 2 項列入改名 (`rate_範例百分比_精確儲存並顯示捨入值`、`rows_無障礙單欄_每個類別獨立一列`)；`initialExpansion_開團中組為空_展開已收單組` 與 `groups_未排序類別輸入_各組內依語言排序` 主對話裁定不改。
    - 驗證 (主對話)：對照第 7 節前快照，非註解差異為 0。
- [x] 7.4 6.4 範圍的說明文字符合本節共同完成條件 [after: 6.4：改同一批檔]。驗證：diff 只有註解行；審查清單涵蓋該組每個檔案。
    - 實作 haiku-max-implementer (37 檔、摘要 150 則)；審查 C 由 codex 唯讀審查 (與 7.11 合併)：阻擋 3 項 (未驗證的深連結比較、把交給提醒流程寫成提醒已移除、未驗證的延後呈現) 與應修 2 項依本體改寫。
    - 名稱與本體不符 1 項列入改名 (`list_點選開團_推入與深連結相同的詳情堆疊`)。
    - 驗證 (主對話)：對照第 7 節前快照，非註解差異為 0。
- [x] 7.5 6.5 範圍的說明文字符合本節共同完成條件 [after: 6.5：改同一批檔]。驗證：diff 只有註解行；審查清單涵蓋該組每個檔案。
    - 實作 haiku-max-implementer (35 檔、摘要 196 則)；審查 A 由 claude-impl 唯讀審查，阻擋、應修與建議全數處理。
    - 名稱與本體不符 1 項 (`CampaignListFeatureDateContextTests` 的「不重複載入」) 列入改名；型別名 `CampaignDateSectionBuilderSectionTitleTests` 依 design 命名規則保留 (主對話裁定)。
    - 驗證 (主對話)：非註解差異只有警告修正的 `var` 改 `let` 4 行 (編譯器 `VariableNeverMutated` 指出)。
- [x] 7.6 6.6 範圍的說明文字符合本節共同完成條件 [after: 6.6：改同一批檔]。驗證：diff 只有註解行；審查清單涵蓋該組每個檔案。
    - 實作 haiku-max-implementer (38 檔、摘要 188 則)；審查 A 由 claude-impl 唯讀審查，阻擋、建議全數處理；`AppScenePhaseTests` 的「殼層階段」由主對話統一改為「自訂場景階段」。
    - 名稱與本體不符 2 項由 claude-impl 改名 (6.6 後續)。
    - 驗證 (主對話)：非註解差異只有上述改名與警告修正 (`var` 改 `let`、`Void?` 型別標註)。
- [x] 7.7 6.7 範圍的說明文字符合本節共同完成條件 [after: 6.7：改同一批檔]。驗證：diff 只有註解行；審查清單涵蓋該組每個檔案。
    - 實作 haiku-max-implementer 兩名 (7.7a 28 檔、7.7b 26 檔，摘要共 378 則)；審查 B 由 codex 唯讀審查 (與 7.8、7.9 合併)，阻擋與應修全數處理。
    - 名稱與本體不符 2 項由 6.7 實作者改名，`InsightsStatsTests` 合計斷言補上。
    - 驗證 (主對話)：非註解差異只有上述改名、補斷言與警告修正。
- [x] 7.8 6.8 範圍的說明文字符合本節共同完成條件 [after: 6.8：改同一批檔]。驗證：diff 只有註解行；審查清單涵蓋該組每個檔案。
    - 實作 haiku-max-implementer 兩名 (7.8a 26 檔、7.8b 30 檔)；審查 B 由 codex 唯讀審查，阻擋與應修全數處理。
    - 驗證 (主對話)：非註解差異只有警告修正 (`flatMap({ $0 })`)。
- [x] 7.9 6.9 範圍的說明文字符合本節共同完成條件 [after: 6.9：改同一批檔]。驗證：diff 只有註解行；審查清單涵蓋該組每個檔案。
    - 實作 haiku-max-implementer (43 檔)；審查 B 由 codex 唯讀審查，阻擋與應修全數處理。
    - 驗證 (主對話)：對照第 7 節前快照，非註解差異為 0。
- [x] 7.10 6.10 範圍的說明文字符合本節共同完成條件 [after: 6.10：改同一批檔]。驗證：diff 只有註解行；審查清單涵蓋該組每個檔案。
    - 實作 haiku-max-implementer (37 檔、摘要 164 則；`RootFeatureTestSupport`、`CampaignFeatureTestSupport` 由其子代理改寫後複核)；審查 E 由另一個 haiku-max-implementer 唯讀審查：阻擋 6 則 (快照摘要宣稱靜態圖看不出的捲動、點按、比較，以及把「新增」鈕寫成儲存鈕) 與應修 8 項全數處理，建議 18 項中 17 項採納，空的 `// Given` 依 kit 樣板保留 (主對話裁定)。
    - `orderCategoryGrid_欄數減一_符合基準圖` 名稱綁定基準圖檔名、語意為比預設三欄少一欄，不改名 (主對話裁定)，摘要改寫。
    - 驗證 (主對話)：對照第 7 節前快照，非註解差異只有主對話改回 `StoredValue` 結構的 4 行。
- [x] 7.11 6.11 範圍的說明文字符合本節共同完成條件 [after: 6.11：改同一批檔]。驗證：diff 只有註解行；審查清單涵蓋該組每個檔案。
    - 實作 haiku-max-implementer 兩名 (7.11a 40 檔以 helper 與 Page Object 為主、7.11b 38 檔測試摘要 175 則，帶說明的 GWT 標記改裸標記)；審查 C 由 codex 唯讀審查：阻擋 11 項 (摘要宣稱搜尋只留目標、切到該客戶訂單等斷言以外的結果) 依本體與共用 helper 實際檢查的內容改寫，應修補上 `BLUITestCase` 生命週期方法的 `///`；`SheetInteraction` 的「dirty」由主對話統一為「有變更／沒有變更」。
    - 名稱與本體不符 4 項列入改名 (類別選擇器與篩選 sheet 的搜尋測試各兩條)。
    - 驗證 (主對話)：對照第 7 節前快照，非註解差異只有警告修正在 `SettingsScreen` 加的兩行 `@MainActor`。

## 8. 第 5 至 7 節驗收

- [x] 8.1 文件與檢查基準跟上改名後的測試 [after: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 7.8, 7.9, 7.10, 7.11：要等全部測試識別碼定案]：依第 6 節各任務記錄的識別碼變更，以 grep 檢查 `.github/workflows/ci.yml`、`apps/ios/BuyLedger.xctestplan`、`apps/ios/CLAUDE.md`、`apps/ios/README.md` 與 `.claude/rules/` 中的舊識別碼並改成新的；`check_test_extensions.py` 的 `BASELINE` 依各任務記錄的拆分新增數更新。驗證：grep 舊識別碼 0 筆；`check_test_extensions.py` 輸出「[全部] 通過」；文件中引用的 `-only-testing` 識別碼抽跑時執行數大於 0。
    - 第 7 節回報的名稱與本體不符共 14 項，由原實作者處理 (主對話指派)：改名 10 項，補字面值斷言並保留名稱 3 項 (codex 選擇：`LocalizationCatalogAppLanguageTests` 圈狀圖摘要的金額、`OrderFilterFeatureSearchTests` 跨結單界線的展開組別、`OrderListFeatureDatesTests` 跨午夜的起點標題，最後一項的起點斷言由主對話移到 Then)，`CampaignFeatureDeletionReminderTests` 的連結與刪除結果改用相異事件識別值 (EVT-link／EVT-deleted)；UI helper `assertNavigationTitle` 確認 0 呼叫端後刪除。主對話裁定不改名 4 項：`initialExpansion_開團中組為空_展開已收單組`、`groups_未排序類別輸入_各組內依語言排序`、`orderCategoryGrid_欄數減一_符合基準圖` 與兩個型別名 (見 7.3、7.5、7.10)。
    - 文件與檢查基準：以腳本比對 `.github/workflows/ci.yml`、三份 `.xctestplan`、`apps/ios/CLAUDE.md`、`apps/ios/README.md`、根 `README.md` 與 `.claude/rules/` 引用的測試型別與方法，全部存在於測試程式碼 (唯一命中 `RunSomeTests` 是 Xcode MCP 工具名)。`check_test_extensions.py` 的 `BASELINE` 改為 unit 1781 (+37：6.1 +9、6.4 +6、6.5 +5、6.6 +1、6.7 +3、6.8 +5、6.9 +8，以 4.2 基準 result bundle 與 6.x 完成後的 bundle 逐類別比對) 與 UI 119 (+11，6.11)；`file-list.tsv` 兩列 `<Guard>SourceStripping` 的目標改為 6.8 合併後的 `Guards/Scanning/SwiftSourceStripping.swift`。
    - 驗證 (主對話)：`check_test_extensions.py` 輸出「[全部] 通過」；`.claude/rules/ios-unit-tests.md` 引用的兩個 `-only-testing` 識別碼抽跑 2 條通過、執行 3 次 (參數化案例)，`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-24T13-53-49-738Z_pid82266_61279018.xcresult`；該次建置的測試檔警告只剩未改動的 `ColorContrast.swift` 既有 2 條。
- [x] 8.2 style 閘門 [after: 8.1：要審全部程式與文件的最終版本]：由未參與所審範圍實作的獨立 Codex 代理依 `/ios-dev-kit`、專案規則、design「測試寫法逐檔修正的規則」與 kit 新版註解寫法，逐檔逐條審查第 5 至 8 節改到的全部檔案，不抽查；違規交回實作者修正後重審。驗證：最後一輪審查回報零違規，檢查清單涵蓋第 5 至 8 節改到的每一個檔案。
    - 執行方式裁定 (使用者，2026-10-24；見 design「第 8.2 節接手與獨立重審」)：接手主對話後，允許以獨立 Codex 代理取代原指定的 haiku-max-implementer 做最後逐檔重審；原審查紀錄保留，零違規與完整檔案覆蓋的驗收條件不變。
    - 接手修正 (主對話 Codex，獨立重審完成)：恢復原始審查報告，補查 S09 中斷部分；首輪三組分別修正 34、23、64 個 Swift 檔。獨立重審後再修 Orders 41 檔與畫面 binding 2 檔、Features 22 檔、Guards 11 檔、Core 23 檔、UI 21 檔與效能計畫舊識別碼；各輪有重疊，不把檔數相加。逐檔 `swiftc -parse` 通過，型別摘要與快照 modifier 縮排依 kit 對齊，沒有改基準圖。完整 diff、識別碼、hash 與獨立審查證據寫在本次 scratch 的 `tes2/s82/takeover/`；完整覆蓋清單與逐檔結論另見該目錄的 `review-*-final.md` 與 `review-common-docs-final.md`；此處不把語法解析視為型別或執行期驗證。
    - 數量基準：本輪宣告數實測為 unit `@Test` 1804、unit XCTest 函式 8、UI XCTest 函式 140、快照圖 74；相較 8.1，單元測試淨增 23 (百分比換算拆分 +1、空清單恆真測試刪除 -1、格式化器拆分 +1、畫面 binding +1、LayerBoundary 掃描拆分 +1、Features getter 拆分 +12、Core getter 與明暗案例拆分 +8)，UI 獨立行為拆分 +21。KPI、schema models 與雙語案例另改參數化，宣告數與展開後案例數分開記錄。檢查腳本同步更新並輸出「[全部] 通過」；完整回歸的執行結果待 8.3 記錄。
    - 效能計畫識別碼驗證：`BuyLedgerUITests-Performance.xctestplan` 選取名稱同步為 `LaunchPerformanceTests/testLaunch_冷啟動_量測啟動時間()` 後，在 iPhone 17 / iOS 26.5 實際執行 1 條通過、0 失敗、0 略過；`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-24T17-00-09-868Z_pid59980_8dca8a04.xcresult`，不是只靠 CLI 退出碼判定。
- [x] 8.3 主對話完整回歸 [after: 8.2：style 修正可能改到測試，回歸要跑最終版本]：全量建置沒有新增編譯警告；iPhone 17 完整單元測試、iPhone 17 與 iPad Air 11-inch 完整 UI 回歸與 1.1 基準一致 (基準中通過的全部通過，單元測試總數等於基準加上記錄的拆分新增數)；`check_test_extensions.py` 輸出「[全部] 通過」；`git status --short` 沒有未預期的新增 png 或 App target 檔案；依文件同步鐵則對照 diff 寫出結論。驗證：上述結果、result bundle 路徑與同步結論記在本任務下。
    - 最終單元測試 (iPhone 17 / iOS 26.5)：1800 條通過、0 失敗、0 略過，另有原本的 3 個 expected failures (logical total 1803)。通過數為 1.1 基準 1740 加第 6 節新增 37 與本輪新增 23；`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-24T17-25-43-807Z_pid80745_2bb52ff6.xcresult`。
    - 單元測試首輪 1799 通過、1 失敗：Python 38 位 HALF_EVEN 求出的非終止 Decimal 字串與 Foundation 對 Given 常數 4300 / 10300 的表示差在末位。只改 `OrderCalculationTests` 的預期字串最後 5 → 4；參考運算僅載入 Foundation、不讀 BuyLedger 輸出，保留精確 `==` 及所有財務輸入。該檔逐檔 parse、獨立全文補審通過後，再跑上述最終完整單元測試；證據在 scratch 的 `decimal-regression-fix.md` 與 `review-core-final.md` 末節。
    - iPhone 17 完整 UI：108 條通過、0 失敗、31 條版面限定略過，normal 範圍共 139 條；`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-24T17-33-17-430Z_pid86446_cb6502b2.xcresult`。相較 6.11 的 90 / 0 / 28，本輪獨立行為拆分增加 18 個通過與 3 個 regular 版面略過。
    - iPad Air 11-inch (M4) / iOS 26.5：先單獨跑 `KeyboardDismissTests` 2 條通過才啟動完整 UI。完整批次為 116 通過、12 失敗、11 條 compact 版面限定略過；12 個失敗全在 `Orientation.swift:23`「轉向後 App 視窗寬仍未大於高」，沒有其他失敗類型。完整結果保留於 `~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-24T18-31-14-220Z_pid34404_e35d499c.xcresult`，不將此原始批次改稱全綠。
    - iPad 環境排除：依 `ios-ui-tests.md` 既有流程開啟再結束 Device Hub，確認兩台模擬器皆 Shutdown，僅重新 boot iPad 並鎖淺色；重開後再跑鍵盤 2 條通過。重跑 5 個受影響類別的全部 25 條，25 通過、0 失敗、0 略過；`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-24T19-44-29-606Z_pid87318_b4675464.xcresult`。逐識別碼核對原 12 個失敗全在重測通過集合，與原始通過集合取聯集為 128 通過、11 版面略過，完整覆蓋原 139 個情境；`ipad-recovery-coverage.json` 留存集合明細。此期間測試來源與 App 均未改，不放寬轉向斷言；重測證實為已記錄的模擬器狀態問題。
    - 建置與靜態檢查：沒有新增專案 Swift 編譯警告；完整首輪單元建置的 `ColorContrast.swift` 兩條為原有，UI 效能計畫建置的 50 條原有隔離警告已按路徑與訊息對照接手前完整 UI log。最終 unit / iPhone UI / iPad UI / 轉向重測均無新增來源編譯警告；SwiftUI 的 `Invalid frame dimension` 執行期訊息不當成編譯警告，App target 未因而修改。`check_test_extensions.py` 實測 1804 / 8 / 140 / 74，輸出「[全部] 通過」。74 張 png 對 HEAD 皆 R100，與接手時路徑及內容 SHA256 相同，未重錄；App target 變更 0，既有未追蹤 `.archify/` 保留。
    - 文件同步結論：有影響，已同步。CI 19 個略過型別、unit plan 兩個效能型別及 UI 效能計畫方法皆存在；README、CLAUDE、rules 的目錄與型別引用已與程式碼對照，過渡例外已刪除；技術棧與環境設定確認無文件影響。逐列結論在 scratch 的 `document-sync-8.3.md`；最終驗收與完整命令、結果檔、內容識別證據在 `tes2/s82/takeover/acceptance-8.3.md`。沒有 git 寫入或提交。
- [x] 8.4 `BLUITestCase` 對齊 ios-dev-kit 4.2.1 的 UITests 樣板 [after: 8.3：kit 4.2.1 在 8.3 完成後才發布]：不存 `XCUIApplication` 的 stored property 與只清參考的 `tearDownWithError`，型別標 `@MainActor`，`setUpWithError` 移到 `// MARK: - XCTestCase` extension，轉回直向移進 `launch(_:)`。驗證：UI 測試 target 編譯沒有警告，`LaunchSmokeTests` 與 `HarnessSelfCheckTests` 通過。
    - 起因：8.2 審查指出 kit UITests 樣板的 `XCUIApplication!` 與鐵則 3 衝突；使用者指示 kit session 修正並發布 4.2.1 (commit `d296b5a`)，`BLUITestCase` 依新版樣板對齊 (主對話實作)。沒有測試讀 `self.app`，39 個測試類別不需改動。
    - 驗證範圍由使用者裁定不跑完整 UI 回歸：執行期唯一的差異是轉回直向從 `setUpWithError` 移到 `launch(_:)`，每個測試的 Given 第一步就是 `launch`，時點相同；其餘改動只影響編譯期。
    - 驗證 (主對話)：iPhone 17 跑 `LaunchSmokeTests` 與 `HarnessSelfCheckTests` 5 條通過 (含同一測試內重新啟動)；UI 測試 target 重新編譯 (含 `BLUITestCase` 與子類別) 的來源警告 0；`~/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-25T04-05-43-368Z_pid37547_88c6d421.xcresult`。
    - 同批依使用者裁定的文件調整：`.claude/rules/ios-unit-tests.md` 刪除與 kit 4.2.0 重複的「共用 helper 依使用範圍放置」(本專案獨有的 `Guards/Scanning/` 一條獨立保留)；本檔 44 處 `[after: X — 理由]` 的破折號改為全形冒號。
