//
//  BLAccessibilityID.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/24.
//

import Foundation

/// UI 測試定位元素用的 accessibility identifier 常數
enum BLAccessibilityID {}

// MARK: - Nested Types

extension BLAccessibilityID {

    /// 持久層開啟失敗時的全畫面阻斷狀態
    enum PersistenceFailure {

        static let root = "persistenceFailure.root"

        static let recoveryButton = "persistenceFailure.recoveryButton"
    }

    /// 帳本鎖定時的阻斷畫面
    enum AppLock {

        static let root = "appLock.root"

        static let retryButton = "appLock.retryButton"
    }

    /// 根導覽 (iPhone 分頁列與 iPad 側邊欄)
    enum Root {

        static let sidebar = "root.sidebar"

        /// 分頁項目，目前只有 iPad 側邊欄的分頁列吃得到
        static func tab(_ tab: Tab) -> String {
            option("root.tab", key: tab.rawValue)
        }

        /// 側邊欄智慧分組列
        static func smartGroup(_ group: SmartGroup) -> String {
            option("root.sidebar.smartGroup", key: group.rawValue)
        }

        /// 主導覽分頁的 key
        enum Tab: String {

            case dashboard

            case orders

            case campaigns

            case insights

            case more
        }

        /// 側邊欄智慧分組的 key
        enum SmartGroup: String {

            case quoting

            case confirmed

            case purchased

            case shipping

            case partiallyArrived

            case arrived

            case delivered

            case pickedUp
        }
    }

    /// 總覽頁
    enum Dashboard {

        static let root = "dashboard.root"

        static let loading = Common.loading("dashboard")

        static let loadFailure = Common.loadFailure("dashboard")

        static let loadFailureRetryButton = Common.loadFailureRetryButton("dashboard")

        static let emptyState = "dashboard.emptyState"

        static let emptyStateActionButton = "dashboard.emptyState.actionButton"

        /// KPI 卡容器
        static func kpiTile(_ kpi: KPI) -> String {
            option("dashboard.kpiTile", key: kpi.rawValue)
        }

        static let recentOrdersSeeAllButton = "dashboard.recentOrders.seeAllButton"

        /// 近期訂單列，以訂單編號識別
        static func recentOrderRow(orderID: String) -> String {
            row("dashboard.recentOrders.row", key: orderID)
        }

        /// KPI 指標的 key
        enum KPI: String {

            case revenue

            case cost

            case grossMargin

            case activeOrders

            case netProfit
        }
    }

    /// 訂單清單、篩選與詳情
    enum Orders {

        static let listRoot = "orders.list.root"

        static let listEmptyState = "orders.list.emptyState"

        static let addButton = "orders.list.addButton"

        static let batchMenuButton = "orders.list.batchMenuButton"

        static let filterButton = "orders.list.filterButton"

        static let aiSummaryButton = "orders.list.aiSummaryButton"

        /// 狀態瀏覽膠囊，key 取 ``OrderStatusFilter`` 的 id (all 或狀態 rawValue)
        static func statusChip(_ filterID: String) -> String {
            option("orders.list.statusChip", key: filterID)
        }

        /// 訂單列，key 取訂單編號這個業務鍵
        static func row(orderID: String) -> String {
            BLAccessibilityID.row("orders.list.row", key: orderID)
        }

        static let filterSheet = "orders.filterSheet"

        /// 篩選 sheet 的日期期間膠囊，key 取 ``OrderDatePeriod`` 的 id
        static func filterDatePeriod(_ periodID: String) -> String {
            option("orders.filterSheet.datePeriod", key: periodID)
        }

        static let filterApplyButton = "orders.filterSheet.applyButton"

        static let filterCancelButton = "orders.filterSheet.cancelButton"

        static let detailRoot = "orders.detail.root"

        static let detailMoreButton = "orders.detail.moreButton"

        static let detailStatusMenuButton = "orders.detail.statusMenuButton"

        static let detailEditButton = "orders.detail.editButton"

        static let detailMergeButton = "orders.detail.mergeButton"

        static let detailDeleteButton = "orders.detail.deleteButton"

        /// 詳情獲利摘要卡，主要數值放各卡的 accessibility value
        static func detailSummaryTile(_ kind: SummaryTile) -> String {
            option("orders.detail.summaryTile", key: kind.rawValue)
        }

        /// 詳情財務摘要卡的種類
        enum SummaryTile: String {

            case revenue

            case cost

            case profit
        }
    }

    /// 訂單編輯表單
    enum OrderEdit {

        static let root = "orderEdit.root"

        static let customerField = "orderEdit.customerField"

        static let sourceRow = "orderEdit.sourceRow"

        static let categoryRow = "orderEdit.categoryRow"

        static let currencyRow = "orderEdit.currencyRow"

        static let paymentRow = "orderEdit.paymentRow"

        static let reconciliationRow = "orderEdit.reconciliationRow"

        static let campaignRow = "orderEdit.campaignRow"

        static let chargedAmountField = "orderEdit.chargedAmountField"

        static let saveButton = "orderEdit.saveButton"

        static let cancelButton = "orderEdit.cancelButton"

        /// 照片縮圖，key 取序位 (0 起算)
        static func photoThumbnail(index: Int) -> String {
            indexed("orderEdit.photoThumbnail", index: index)
        }
    }

    /// 訂單合併流程
    enum OrderMerge {

        static let candidateListRoot = "orderMerge.candidateList.root"

        static let candidateListEmptyState = "orderMerge.candidateList.emptyState"

        /// 候選訂單列，key 取訂單編號這個業務鍵
        static func candidateRow(orderID: String) -> String {
            BLAccessibilityID.row("orderMerge.candidateList.row", key: orderID)
        }

        static let cancelButton = "orderMerge.cancelButton"

        static let photoContinueButton = "orderMerge.photoStep.continueButton"

        /// 照片挑選步驟的單格縮圖，key 取序位 (0 起算)
        static func photoCell(index: Int) -> String {
            indexed("orderMerge.photoStep.cell", index: index)
        }
    }

    /// 照片檢視器 (BLPhotoViewer)
    enum PhotoViewer {

        static let root = "photoViewer.root"

        static let image = "photoViewer.image"
    }

    /// AI 商品明細總結 sheet
    enum AISummary {

        static let root = "aiSummary.root"

        static let closeButton = "aiSummary.closeButton"

        static let retryButton = "aiSummary.retryButton"

        static let dataTransferDisclosure = "aiSummary.dataTransferDisclosure"
    }

    /// 開團列表與詳情
    enum Campaigns {

        static let listRoot = "campaigns.list.root"

        static let listEmptyState = "campaigns.list.emptyState"

        static let listLoadFailure = Common.loadFailure("campaigns.list")

        static let listLoadFailureRetryButton = Common.loadFailureRetryButton("campaigns.list")

        static let addButton = "campaigns.list.addButton"

        static let filterMenuButton = "campaigns.list.filterMenuButton"

        /// 開團卡片列，key 取開團 id 這個業務鍵
        static func row(campaignID: String) -> String {
            BLAccessibilityID.row("campaigns.list.row", key: campaignID)
        }

        static let detailRoot = "campaigns.detail.root"

        static let detailMoreButton = "campaigns.detail.moreButton"

        static let detailEditButton = "campaigns.detail.editButton"

        static let detailSettleButton = "campaigns.detail.settleButton"

        static let detailDeleteButton = "campaigns.detail.deleteButton"

        static let detailUnpaidToggle = "campaigns.detail.unpaidToggle"

        /// 結團結算的數值列，主要數值放各列的 accessibility value
        static func detailSummary(_ kind: DetailSummary) -> String {
            option("campaigns.detail.summary", key: kind.rawValue)
        }

        /// 結團結算的數值列種類
        enum DetailSummary: String {

            case receivables

            case received
        }
    }

    /// 開團新增與編輯表單
    enum CampaignEdit {

        static let root = "campaignEdit.root"

        static let nameField = "campaignEdit.nameField"

        static let reminderToggle = "campaignEdit.reminderToggle"

        static let saveButton = "campaignEdit.saveButton"

        static let cancelButton = "campaignEdit.cancelButton"
    }

    /// 客戶名單
    enum Customers {

        static let listRoot = "customers.list.root"

        static let listEmptyState = "customers.list.emptyState"

        /// Top 3 卡片，key 取客戶名這個業務鍵
        static func topCard(customerName: String) -> String {
            BLAccessibilityID.row("customers.topCard", key: customerName)
        }

        /// 全部客戶列，key 取客戶名這個業務鍵
        static func row(customerName: String) -> String {
            BLAccessibilityID.row("customers.list.row", key: customerName)
        }
    }

    /// 分析頁
    enum Insights {

        static let root = "insights.root"

        static let emptyState = "insights.emptyState"

        static let rangePicker = "insights.rangePicker"

        /// 期間選項，key 取 ``InsightsDateRange`` 的 rawValue
        static func rangeSegment(_ rangeID: String) -> String {
            option("insights.rangeSegment", key: rangeID)
        }

        static let trendChart = "insights.chart.trend"

        static let costDonut = "insights.chart.costDonut"

        /// 類別排行列，key 取類別名這個業務鍵 (點擊深連結到訂單)
        static func categoryRankRow(category: String) -> String {
            BLAccessibilityID.row("insights.categoryRank.row", key: category)
        }

        /// 每團毛利排行列，key 取開團 id 這個業務鍵 (點擊深連結到開團詳情)
        static func campaignRankRow(campaignID: String) -> String {
            BLAccessibilityID.row("insights.campaignRank.row", key: campaignID)
        }
    }

    /// 匯率工具
    enum Fx {

        static let root = "fx.root"

        static let statusBanner = "fx.statusBanner"

        static let currencyPickerButton = "fx.currencyPickerButton"

        static let amountField = "fx.amountField"

        static let convertedValue = "fx.convertedValue"
    }

    /// 報價試算
    enum Quote {

        static let root = "quote.root"

        static let currencyPickerButton = "quote.currencyPickerButton"

        static let principalField = "quote.principalField"

        static let suggestedPriceValue = "quote.suggestedPriceValue"

        static let statusBanner = "quote.statusBanner"

        static let retryButton = "quote.retryButton"
    }

    /// 設定頁
    enum Settings {

        static let root = "settings.root"

        static let languagePicker = "settings.languagePicker"

        /// 語言選項
        static func languageOption(_ key: String) -> String {
            option("settings.languageOption", key: key)
        }

        static let defaultCurrencyRow = "settings.defaultCurrencyRow"

        static let monthlyGoalField = "settings.monthlyGoalField"

        static let aiSummaryToggle = "settings.aiSummaryToggle"

        static let aiSummaryModelRow = "settings.aiSummaryModelRow"

        static let appLockToggle = "settings.appLockToggle"

        static let versionRow = "settings.versionRow"
    }

    /// 更多分頁
    enum More {

        static let root = "more.root"

        /// 導向各工具與設定的列 (以目的地 key 指定)
        static func row(_ row: Row) -> String {
            option("more.row", key: row.rawValue)
        }

        /// 更多分頁各列的目的地 key
        enum Row: String {

            case fx

            case customers

            case quote

            case orderSources

            case categories

            case paymentMethods

            case reconciliationStatuses

            case settings
        }
    }

    /// 單選／多選選項選擇器 (設定、訂單編輯、匯率、報價共用同一個元件)
    enum OptionPicker {

        static let root = "optionPicker.root"

        static let addButton = "optionPicker.addButton"

        static let addAlertNameField = "optionPicker.addAlert.nameField"

        static let addAlertConfirmButton = "optionPicker.addAlert.confirmButton"

        static let addAlertCancelButton = "optionPicker.addAlert.cancelButton"

        static let doneButton = "optionPicker.doneButton"

        /// 選項列，以原始字串識別
        static func optionRow(_ option: String) -> String {
            row("optionPicker.optionRow", key: option)
        }
    }

    /// 跨畫面共用的元件
    enum Common {

        static let keyboardDoneButton = "common.keyboard.doneButton"

        static let backButton = "BackButton"

        /// 載入中容器
        static func loading(_ feature: String) -> String {
            option(feature, key: "loading")
        }

        /// 載入失敗容器
        static func loadFailure(_ feature: String) -> String {
            option(feature, key: "loadFailure")
        }

        /// 載入失敗容器的重試
        static func loadFailureRetryButton(_ feature: String) -> String {
            option(feature, key: "loadFailure") + ".retryButton"
        }
    }
}

// MARK: - Internal Method

extension BLAccessibilityID {

    /// 組出列舉型集合的 identifier
    static func option(_ prefix: String, key: String) -> String {
        "\(prefix).\(key)"
    }

    /// 組出使用者資料列的 identifier
    static func row(_ prefix: String, key: String) -> String {
        "\(prefix):\(key)"
    }

    /// 組出純序位集合的 identifier
    static func indexed(_ prefix: String, index: Int) -> String {
        "\(prefix).index.\(index)"
    }
}
