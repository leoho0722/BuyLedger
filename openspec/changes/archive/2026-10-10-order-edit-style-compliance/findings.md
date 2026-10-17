# 整檔基準 (2026-10-06 實測)

以 `reference/style_checks.py` (複製自第 6e 步封存版，含 raw string 剝除修正；`EXISTING_OVER_LIMIT` 移除本步要拆的 `OrdersFeature.swift`、`OrderEditFeature.swift`、`OrdersFeatureTests.swift`、`OrderEditFeatureTests.swift`) 對 15 個檔以明確清單執行，共 **201 筆** (含腳本明列不計失敗的 `WSTR`、`WCL` 各 1 筆)。逐筆輸出在 `reference/baseline.txt`。腳本只涵蓋機械規則；Action 分組、`Reduce(core)`、`body` 只放大框架、State 位置等結構問題由 style agent 逐檔審查，不在此表。

| 檔案 | 總行 | 不含檔頭與空行 | 腳本筆數 |
| --- | ---: | ---: | ---: |
| `apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift` | 1086 | 893 | 3 |
| `apps/ios/BuyLedger/Features/Orders/OrderEditView.swift` | 1035 | 927 | 55 |
| `apps/ios/BuyLedger/Features/Orders/OrderDraft.swift` | 380 | 325 | 16 |
| `apps/ios/BuyLedger/Features/Orders/OrdersMergeFlowOperations.swift` | 145 | 126 | 7 |
| `apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift` | 1405 | 1182 | 1 |
| `apps/ios/BuyLedger/Features/Orders/OrdersFeature+StateQuery.swift` | 265 | 221 | 13 |
| `apps/ios/BuyLedger/Features/App/RootFeature.swift` | 380 | 298 | 0 |
| `apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift` | 1862 | 1604 | 1 |
| `apps/ios/BuyLedgerTests/OrderEditFocusTests.swift` | 180 | 149 | 1 |
| `apps/ios/BuyLedgerTests/OrderDraftTests.swift` | 339 | 286 | 103 |
| `apps/ios/BuyLedgerTests/OrdersFeatureTests.swift` | 3244 | 2910 | 1 |
| `apps/ios/BuyLedgerTests/OrdersFeatureTests+AIDisabledAlert.swift` | 47 | 35 | 0 |
| `apps/ios/BuyLedgerTests/SnapshotTests+OrderEdit.swift` | 138 | 117 | 0 |
| `apps/ios/BuyLedgerTests/RootFeatureTests+DeepLinks.swift` | 295 | 250 | 0 |
| `apps/ios/BuyLedgerTests/RootFeatureTests+LookupSync.swift` | 224 | 202 | 0 |

超過 300 行 (不含檔頭與空行) 須拆檔的有 6 個：`OrderEditFeature`、`OrderEditView`、`OrderDraft`、`OrdersFeature`、`OrderEditFeatureTests`、`OrdersFeatureTests`；`RootFeature` 298 行，本步加入幣別清單載入後預估會超過 (估計，以實作後 `wc` 實測確認)。

## 擴大範圍的基準 (2026-10-07 實測，task 0.1)

6b 併入後本 change 會改到的其餘 production 與測試檔，以同一支 `reference/style_checks.py` 用明確清單 (57 檔) 執行，共 **488 筆**；逐筆輸出在 `reference/baseline-extra.txt`。

| 檔案 | 總行 | 不含檔頭與空行 | 腳本筆數 |
| --- | ---: | ---: | ---: |
| `apps/ios/BuyLedger/Features/Orders/OrderDateSection.swift` | 61 | 46 | 2 |
| `apps/ios/BuyLedger/Features/Orders/OrderDetailPath.swift` | 36 | 21 | 1 |
| `apps/ios/BuyLedger/Features/Orders/OrderMergeFeature.swift` | 355 | 289 | 2 |
| `apps/ios/BuyLedger/Features/Orders/OrdersBatchOperations.swift` | 102 | 83 | 7 |
| `apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift` | 393 | 351 | 29 |
| `apps/ios/BuyLedger/Features/Orders/OrdersFilterOperations.swift` | 248 | 220 | 18 |
| `apps/ios/BuyLedger/Features/Orders/OrdersRegularDetailColumn.swift` | 185 | 151 | 0 |
| `apps/ios/BuyLedger/Features/Orders/OrdersRegularListColumn.swift` | 240 | 202 | 0 |
| `apps/ios/BuyLedger/Features/Orders/OrdersView.swift` | 181 | 149 | 0 |
| `apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift` | 115 | 96 | 10 |
| `apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift` | 894 | 770 | 53 |
| `apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift` | 398 | 349 | 23 |
| `apps/ios/BuyLedger/Features/Orders/Components/OrderFormatters.swift` | 127 | 107 | 9 |
| `apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift` | 171 | 145 | 6 |
| `apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift` | 200 | 152 | 13 |
| `apps/ios/BuyLedger/Features/Orders/Components/OrderSelectableRow.swift` | 68 | 49 | 3 |
| `apps/ios/BuyLedger/Features/Orders/Components/OrdersToolbarContent.swift` | 98 | 78 | 4 |
| `apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift` | 376 | 300 | 0 |
| `apps/ios/BuyLedger/Features/Campaigns/CampaignListFeature.swift` | 326 | 256 | 0 |
| `apps/ios/BuyLedger/Features/Campaigns/CampaignFormatters.swift` | 90 | 72 | 0 |
| `apps/ios/BuyLedger/Features/App/RootCascadeOperations.swift` | 102 | 85 | 0 |
| `apps/ios/BuyLedger/Features/App/RootNavigationOperations.swift` | 80 | 63 | 0 |
| `apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift` | 317 | 261 | 0 |
| `apps/ios/BuyLedger/Features/Dashboard/DashboardFeature.swift` | 81 | 54 | 3 |
| `apps/ios/BuyLedger/Features/Insights/InsightsFeature.swift` | 86 | 57 | 5 |
| `apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift` | 517 | 460 | 1 |
| `apps/ios/BuyLedgerTests/OrdersBatchOperationsTests.swift` | 162 | 126 | 65 |
| `apps/ios/BuyLedgerTests/OrdersFeaturePerformanceTests.swift` | 213 | 178 | 18 |
| `apps/ios/BuyLedgerTests/OrdersFilterOperationsTests.swift` | 433 | 363 | 151 |
| `apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift` | 180 | 150 | 1 |
| `apps/ios/BuyLedgerTests/OrdersSearchCancellationTests.swift` | 132 | 113 | 16 |
| `apps/ios/BuyLedgerTests/SnapshotTests+Orders.swift` | 185 | 160 | 0 |
| `apps/ios/BuyLedgerTests/SnapshotTests+OrderDetail.swift` | 66 | 54 | 0 |
| `apps/ios/BuyLedgerTests/RootFeatureTests.swift` | 163 | 129 | 0 |
| `apps/ios/BuyLedgerTests/RootFeatureTests+AppShell.swift` | 326 | 296 | 0 |
| `apps/ios/BuyLedgerTests/RootFeatureTests+Campaigns.swift` | 247 | 229 | 0 |
| `apps/ios/BuyLedgerTests/RootFeatureTests+Fixtures.swift` | 206 | 190 | 0 |
| `apps/ios/BuyLedgerTests/RootFeatureTests+LookupRename.swift` | 297 | 276 | 0 |
| `apps/ios/BuyLedgerTests/RootFeatureTests+OrderFilters.swift` | 194 | 165 | 0 |
| `apps/ios/BuyLedgerTests/RootFeatureTests+PaymentMethodCorrection.swift` | 282 | 257 | 0 |
| `apps/ios/BuyLedgerTests/CampaignListFeatureTests.swift` | 270 | 243 | 0 |
| `apps/ios/BuyLedgerTests/CampaignListFeatureTests+AutoClose.swift` | 206 | 183 | 0 |
| `apps/ios/BuyLedgerTests/CampaignListFeatureTests+DateContext.swift` | 202 | 178 | 0 |
| `apps/ios/BuyLedgerTests/CampaignListFeatureTests+Loading.swift` | 210 | 188 | 0 |
| `apps/ios/BuyLedgerTests/CampaignFeatureTests+Reload.swift` | 201 | 180 | 0 |
| `apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift` | 129 | 111 | 0 |
| `apps/ios/BuyLedgerTests/CampaignIntegrationTests+Filters.swift` | 100 | 84 | 0 |
| `apps/ios/BuyLedgerTests/CampaignIntegrationTests+Receipt.swift` | 166 | 137 | 0 |
| `apps/ios/BuyLedgerTests/CampaignDateSectionBuilderTests+SectionTitle.swift` | 154 | 129 | 0 |
| `apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests.swift` | 286 | 250 | 0 |
| `apps/ios/BuyLedgerTests/ProjectionWriteBoundaryTests+Patterns.swift` | 225 | 201 | 0 |
| `apps/ios/BuyLedgerTests/ActionGroupingScanTests.swift` | 195 | 163 | 0 |
| `apps/ios/BuyLedgerTests/ActionGroupingScanTests+Scenarios.swift` | 116 | 102 | 0 |
| `apps/ios/BuyLedgerTests/LocalizationCatalogTests+SourceGuards.swift` | 155 | 128 | 0 |
| `apps/ios/BuyLedgerTests/String+SourceLiteralScan.swift` | 330 | 288 | 1 |
| `apps/ios/BuyLedgerTests/DashboardFeatureTests.swift` | 63 | 45 | 26 |
| `apps/ios/BuyLedgerTests/InsightsFeatureTests.swift` | 57 | 40 | 21 |

超過 300 行 (不含檔頭與空行) 的有 5 個：`OrdersCompactView`、`OrderDetailView`、`OrderFilterSheet`、`OrderMergeFeatureTests`、`OrdersFilterOperationsTests`。

`TOTAL` 行：`{'DOLLAR2': 1, 'NESTSL': 3, 'MK1': 31, 'WSIG': 1, 'MKNX': 1, 'DOCBL': 70, 'D6': 17, 'LEN': 5, 'W': 2, 'CASELET': 1, 'MOD': 13, 'RPAR': 19, 'PARTW': 13, 'NAMED1': 8, 'GUARDX': 1, 'D1': 27, 'MKN': 6, 'BRACE': 1, 'CALL1': 23, 'SWC': 2, 'MKIN': 1, 'D9': 6, 'TIMP': 6, 'GWT': 117, 'TD': 25, 'TNAMEL': 39, 'TSTL': 39, 'ARG4': 2, 'MKC': 2, 'D2': 1, 'TRAILC': 1, 'FUNWRAP': 1, 'WCL': 1, 'CT': 1, 'WSTR': 1} files 57 FAIL`

## 行數例外 (使用者 2026-10-09 裁決)

| 檔案 | 實測 | 上限 | 原因 | 撤銷條件 |
|---|---:|---:|---|---|
| `Features/Orders/OrdersFeature.swift` | 359 | 359 | 7.16 抽出呈現與詳情導覽兩個子 Feature 後，剩下的 Root 介面方法與投影依寫入邊界規則只能留主檔，`core` 依 Action 次序逐 case 轉送 (第二輪裁決 1)；再拆只會產生沒有內聚性的轉手層 | 6c 把新增主檔選項改經 Root 轉主檔端後重量，回到 300 行內即撤銷；超過 359 行要重新評估 |

`reference/style_checks.py` 的 `BOUNDED_LENGTH_LIMITS` 登記本表上限：未超過記不計失敗的 `LENB`，超過仍為 `LEN`；撤銷例外時一併移除該列。

