## Summary

把 App 內所有以 `String` 攜帶的本地化 key 改成 `LocalizedStringResource`，並把 `AppLanguage` 的四種解析寫法收斂成一個入口，讓 Xcode 能追蹤每個 key 的使用、參數型別錯誤不再拖到執行期才發現。範圍含 `string-catalog-warning-cleanup` 交下來的 53 筆，以及更早就以 `String` 攜帶、標成 manual 的既有寫法。

## Motivation

`string-catalog-warning-cleanup` 為了讓警告歸零，把第一、二類共 53 筆 key 暫時標成 manual：這些 key 經非抽取路徑引用，Xcode 不會在它們沒人用時提醒。使用者 2026-11-07 決定另開本 change 處理，並指出 `AppLanguage` 的寫法需要收斂。現況 (2026-11-07 實測)：

- 同一件事有四種寫法：`localized(_: String.LocalizationValue)` (正式程式碼 25 處)、`localizedString(forKey:_:)`／`(forKey:arguments:)` (12 處)、`static format(_:_:locale:)` (34 處)、`rootNavigationTitle(_:language:)` (7 處)。
- `localized(_:)` 以 `Mirror` 反射 `String.LocalizationValue` 的內部欄位拆出 key 與參數 (`extractKeyAndArgs`)，依賴標準庫的非公開表示。
- `localizedString(forKey:)`／`format` 以 `CVarArg` 傳參數，參數數量或型別與 catalog 不符時編譯器不會發現。
- 錯誤訊息、導覽標題等 key 以 `String` 存在 TCA State、`@Shared` 與回傳值中，和一般文字無法區分。

2026-11-08 apply 期間盤點發現範圍缺口：catalog 共 167 筆 manual，其中 105 筆在 `string-catalog-warning-cleanup` 之前就存在；扣除已被手寫程式碼抽取的 24 筆，約 81 筆分散在原計畫沒列到的約 40 個檔，同樣以 `String` 攜帶 key (列舉的 `title`、共用元件的 `String` 參數、`LocalizedStringKey(變數)`)。其中 `BLStatusPill`、`BLProgressView` 同時接收 key 與使用者資料，使用者資料會被當成 key 查表。使用者 2026-11-08 決定併入本 change。

## Proposed Solution

1. `AppLanguage` 新增單一解析入口：複製 `LocalizedStringResource`、把 `locale` 設為所選 App 語言後以 `String(localized:)` 解析；畫面上的一般文字直接 `Text(resource)` (已實測會跟隨 App 語言)，只有必須是 `String` 的地方 (無障礙圖表描述、根分頁標題、元件需要的字串) 經此入口。
2. 第一類 32 筆帶參數的格式字串改用「明確 key＋defaultValue」建構 (`LocalizedStringResource("orders.detail.label.quantity", defaultValue: "\(quantity)")`，使用者決策)，key 維持四段點記號並由編譯器抽取。
3. 第二類 21 筆，以及同樣以 `String` 攜帶 key 的 State、`@Shared`、回傳值與 `LookupKind` 屬性，改為 `LocalizedStringResource` 並以字面值建構。
4. 既有以 `String` 攜帶的 key 一併遷移：列舉的 `title` 改為 `LocalizedStringResource`；混用 key 與使用者資料的共用元件分成 resource 與 `verbatim:` 兩種輸入；混用的格式化結果拆開 key 與 verbatim 文字。
5. 依功能分批遷移，每批結束時建置與測試都通過；全部遷移後移除舊 API、`Mirror` 反射與共用元件的過渡 `String` init，新增掃描守門。
6. 收尾時清理 manual 標記：Debug 與 Release 都被手寫程式碼抽取的 key 一律移除 manual，剩下的 manual 每筆都要有抽不到的理由 (使用者決策)。

本 change 必須在 `string-catalog-warning-cleanup` 完成並 archive 後才開始。

## Non-Goals

- 不改 catalog 的 key 名稱與翻譯文案，不新增 catalog key。
- 不重新設計 Design System 圖表元件 (`BLBarChart`、`BLDonutChart`、`BLSparkline`) 的介面：對外參數只做「不以 `String` 攜帶 key」所需的型別調整 (見 design「Design System 元件內部改用單一入口」)，其餘改動在元件內部的解析方式。
- 不改用 Xcode 為 manual 條目產生的符號：它要求條目維持 manual，與「讓 Xcode 追蹤使用」的目標衝突 (使用者決策)。
- 以字面值建構、編譯器抽得到的 `LocalizedStringKey` 參數與回傳值 (例如 `OrderEditSelectionRow.title`、`AppLockFormatters`) 不改型別。

## Alternatives Considered

- 產生的符號 (`.ordersDetailLabelQuantity(quantity)`)：參數型別由 catalog 決定、寫錯會編譯失敗，但這些 key 必須一直標 manual，Xcode 無法在它們沒人用時提醒；使用者選擇明確 key＋defaultValue。
- 全面改用 `LocalizedStringKey`：SwiftUI 型別，不能放進只 import Foundation 的模型，也沒有解析成 `String` 的公開 API。
- 既有約 81 筆另開 change：使用者 2026-11-08 選擇併入本 change，讓 spec 的要求在本 change 結束時成立。

## Impact

- Affected specs: `app-localization` (新增 requirement：本地化 key 以 `LocalizedStringResource` 攜帶並經單一入口解析；修改 requirement「String Catalog extraction state matches source references」：manual 只留給 Debug 或 Release 抽不到的 key，原本「以 `String` 攜帶的 key 標 manual」的路徑與範例改寫)
- Affected code (2026-11-08 4.6 依 `git diff` 實際改動更新):
  - Modified:
    - .claude/rules/ios-accessibility-localization.md
    - apps/ios/BuyLedger/Core/Domain/CampaignStatus.swift
    - apps/ios/BuyLedger/Core/Domain/CustomerTier.swift
    - apps/ios/BuyLedger/Core/Domain/OrderStatus.swift
    - apps/ios/BuyLedger/Core/Domain/PaymentReceiptStatus.swift
    - apps/ios/BuyLedger/Features/App/Domain/RootTab.swift
    - apps/ios/BuyLedger/Features/App/Presentation/AppLock/AppLockFeature.swift
    - apps/ios/BuyLedger/Features/App/Presentation/Root/RootNavigationLayout.swift
    - apps/ios/BuyLedger/Features/App/Presentation/Root/SidebarBadgeCounts.swift
    - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignDetail/CampaignDetailDistributionSection.swift
    - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignDetail/CampaignDetailView.swift
    - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignEdit/CampaignEditFeature.swift
    - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignEdit/CampaignEditView.swift
    - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignList/CampaignListFeature.swift
    - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignList/Queries/CampaignGrouping.swift
    - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignList/Views/CampaignListView.swift
    - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignList/Views/CampaignRow.swift
    - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignList/Views/CampaignSectionList.swift
    - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignLoad/CampaignLoadFeature.swift
    - apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignPresentation/CampaignPresentationFeature.swift
    - apps/ios/BuyLedger/Features/Customers/Presentation/Formatting/CustomerFormatters.swift
    - apps/ios/BuyLedger/Features/Customers/Presentation/Root/CustomerListRow.swift
    - apps/ios/BuyLedger/Features/Customers/Presentation/Root/CustomersView.swift
    - apps/ios/BuyLedger/Features/Customers/Presentation/Root/CustomerTopCard.swift
    - apps/ios/BuyLedger/Features/Dashboard/Presentation/Formatting/DashboardFormatters.swift
    - apps/ios/BuyLedger/Features/Dashboard/Presentation/Root/DashboardFeature.swift
    - apps/ios/BuyLedger/Features/Dashboard/Presentation/Root/Views/DashboardHeroCard.swift
    - apps/ios/BuyLedger/Features/Dashboard/Presentation/Root/Views/DashboardKPITile.swift
    - apps/ios/BuyLedger/Features/Dashboard/Presentation/Root/Views/DashboardKPITiles.swift
    - apps/ios/BuyLedger/Features/Dashboard/Presentation/Root/Views/DashboardOngoingCampaignsSection.swift
    - apps/ios/BuyLedger/Features/Dashboard/Presentation/Root/Views/DashboardSummarySection.swift
    - apps/ios/BuyLedger/Features/Dashboard/Presentation/Root/Views/DashboardView.swift
    - apps/ios/BuyLedger/Features/FX/Presentation/Formatting/FxFormatters.swift
    - apps/ios/BuyLedger/Features/FX/Presentation/Root/FxStatusBanner.swift
    - apps/ios/BuyLedger/Features/Insights/Domain/InsightsDateRange.swift
    - apps/ios/BuyLedger/Features/Insights/Presentation/Formatting/InsightsFormatters.swift
    - apps/ios/BuyLedger/Features/Insights/Presentation/Root/InsightsFeature.swift
    - apps/ios/BuyLedger/Features/Insights/Presentation/Root/Views/InsightsCampaignProfitCard.swift
    - apps/ios/BuyLedger/Features/Insights/Presentation/Root/Views/InsightsCategoryCard.swift
    - apps/ios/BuyLedger/Features/Insights/Presentation/Root/Views/InsightsCostStructureCard.swift
    - apps/ios/BuyLedger/Features/Insights/Presentation/Root/Views/InsightsHeatmapCard.swift
    - apps/ios/BuyLedger/Features/Insights/Presentation/Root/Views/InsightsTrendCard.swift
    - apps/ios/BuyLedger/Features/Insights/Presentation/Root/Views/InsightsView.swift
    - apps/ios/BuyLedger/Features/Lookups/Domain/LookupKind.swift
    - apps/ios/BuyLedger/Features/Lookups/Presentation/Root/Views/LookupItemList.swift
    - apps/ios/BuyLedger/Features/Lookups/Presentation/Root/Views/LookupManagementPresentations.swift
    - apps/ios/BuyLedger/Features/Lookups/Presentation/Root/Views/LookupManagementView.swift
    - apps/ios/BuyLedger/Features/Lookups/Presentation/Root/Views/LookupNameEditorSheet.swift
    - apps/ios/BuyLedger/Features/More/Presentation/Root/MoreView.swift
    - apps/ios/BuyLedger/Features/Orders/Domain/OrderDatePeriod.swift
    - apps/ios/BuyLedger/Features/Orders/Domain/OrdersLoadState.swift
    - apps/ios/BuyLedger/Features/Orders/Domain/OrderStatusFilter.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/Components/OrderCategoryGrid.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/Components/OrdersFilterControlsView.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/Formatting/OrderFormatters.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrderDetail/OrderCostBreakdown.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrderDetail/Views/OrderDetailCostView.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrderDetail/Views/OrderDetailItemsView.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrderDetail/Views/OrderDetailMenu.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/OrderEditFeature.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/OrderEditView.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditCampaignSection.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditFeesSection.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditItemsSection.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditStatusSection.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEditPhotos/OrderEditPhotosSection.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrderFilter/Views/OrderFilterDateSection.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrderList/OrderListFeature.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrderList/Queries/OrdersListQuery.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrderList/Views/OrdersCompactListView.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrderMerge/MergePhotoPickerSheet.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrderMerge/OrderMergeCandidateSheet.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrderMerge/OrderMergeFeature.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrdersLoad/OrdersLoadFeature.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrdersPresentation/OrdersPresentationFeature.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrderWrites/OrderWriteOperations.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Plans/OrdersContainerPlan+Writes.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Views/OrdersRegularListColumn.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Views/OrdersToolbarContent.swift
    - apps/ios/BuyLedger/Features/Quote/Presentation/Formatting/QuoteFormatters.swift
    - apps/ios/BuyLedger/Features/Quote/Presentation/Root/QuoteBreakdownCard.swift
    - apps/ios/BuyLedger/Features/Quote/Presentation/Root/QuoteInputsCard.swift
    - apps/ios/BuyLedger/Features/Quote/Presentation/Root/QuoteStatusBanner.swift
    - apps/ios/BuyLedger/Features/Quote/Presentation/Root/QuoteView.swift
    - apps/ios/BuyLedger/Features/Settings/Presentation/Root/SettingsFeature.swift
    - apps/ios/BuyLedger/Resources/Localizable.xcstrings
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChipLabel.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/BLNumberField.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/OptionPickerSheet.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressView.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/States/BLLoadFailureView.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Tags/BLTagPill.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLFormatters.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTone.swift
    - apps/ios/BuyLedger/Shared/Localization/AppLanguage.swift
    - apps/ios/README.md
    - apps/ios/BuyLedgerTests 內 37 個既有測試檔：以 key 字串斷言、呼叫舊 API 或建構已改介面的測試，含 `LocalizationCatalogAppLanguageTests`、`LocalizationCatalogSourceGuardsTests`、`LocalizationCatalogTests`、`OrderStatusTests`、`InsightsFormattersTests`、`OrderCostBreakdownTests`、`OrderEditFeatureDisplayTextTests`、`CustomerFormattersTests` 與各 snapshot 測試
  - New:
    - apps/ios/BuyLedgerTests/Core/Domain/CustomerTierTests.swift
    - apps/ios/BuyLedgerTests/Features/Orders/OrderWriteOperationsFailureTests.swift
    - apps/ios/BuyLedgerTests/Shared/DesignSystem/BLBarChartTests.swift
    - apps/ios/BuyLedgerTests/Shared/DesignSystem/BLDonutChartTests.swift
    - apps/ios/BuyLedgerTests/Shared/DesignSystem/BLSparklineTests.swift
    - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotSharedTests/blTagPill_英文且類別名稱等於本地化鍵_顯示原文.1.png
  - Removed:
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift (零呼叫點)
