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

        /// 持久層開啟失敗畫面的根 accessibility identifier
        static let root = "persistenceFailure.root"

        /// 持久層復原操作按鈕
        static let recoveryButton = "persistenceFailure.recoveryButton"
    }

    /// 帳本鎖定時的阻斷畫面
    enum AppLock {

        /// 帳本鎖定畫面的根 accessibility identifier
        static let root = "appLock.root"

        /// 帳本解鎖重試按鈕
        static let retryButton = "appLock.retryButton"
    }

    /// 根導覽 (iPhone 分頁列與 iPad 側邊欄)
    enum Root {

        /// 根導覽側邊欄
        static let sidebar = "root.sidebar"

        /// 分頁項目，目前只有 iPad 側邊欄的分頁列吃得到
        /// - Parameter tab: 主導覽分頁
        /// - Returns: 對應分頁的 accessibility identifier
        static func tab(_ tab: Tab) -> String {
            option("root.tab", key: tab.rawValue)
        }

        /// 側邊欄智慧分組列
        /// - Parameter group: 側邊欄智慧分組
        /// - Returns: 對應智慧分組列的 accessibility identifier
        static func smartGroup(_ group: SmartGroup) -> String {
            option("root.sidebar.smartGroup", key: group.rawValue)
        }

        /// 主導覽分頁的 key
        enum Tab: String {

            /// 總覽分頁
            case dashboard

            /// 訂單分頁
            case orders

            /// 開團分頁
            case campaigns

            /// 分析分頁
            case insights

            /// 更多分頁
            case more
        }

        /// 側邊欄智慧分組的 key
        enum SmartGroup: String {

            /// 報價中的訂單
            case quoting

            /// 已確認的訂單
            case confirmed

            /// 已購買的訂單
            case purchased

            /// 配送中的訂單
            case shipping

            /// 部分到貨的訂單
            case partiallyArrived

            /// 已到貨的訂單
            case arrived

            /// 已交付的訂單
            case delivered

            /// 已取貨的訂單
            case pickedUp
        }
    }

    /// 總覽頁
    enum Dashboard {

        /// 總覽頁的根 accessibility identifier
        static let root = "dashboard.root"

        /// 總覽頁載入中容器
        static let loading = Common.loading("dashboard")

        /// 總覽頁載入失敗容器
        static let loadFailure = Common.loadFailure("dashboard")

        /// 總覽頁載入失敗重試按鈕
        static let loadFailureRetryButton = Common.loadFailureRetryButton("dashboard")

        /// 總覽頁無資料狀態容器
        static let emptyState = "dashboard.emptyState"

        /// 總覽頁無資料狀態操作按鈕
        static let emptyStateActionButton = "dashboard.emptyState.actionButton"

        /// KPI 卡容器
        /// - Parameter kpi: KPI 指標
        /// - Returns: 對應 KPI 卡的 accessibility identifier
        static func kpiTile(_ kpi: KPI) -> String {
            option("dashboard.kpiTile", key: kpi.rawValue)
        }

        /// 近期訂單區塊的查看全部按鈕
        static let recentOrdersSeeAllButton = "dashboard.recentOrders.seeAllButton"

        /// 近期訂單列，以訂單編號識別
        /// - Parameter orderID: 訂單編號
        /// - Returns: 對應近期訂單列的 accessibility identifier
        static func recentOrderRow(orderID: String) -> String {
            row("dashboard.recentOrders.row", key: orderID)
        }

        /// KPI 指標的 key
        enum KPI: String {

            /// 營收
            case revenue

            /// 成本
            case cost

            /// 毛利率
            case grossMargin

            /// 進行中的訂單數
            case activeOrders

            /// 淨利
            case netProfit
        }
    }

    /// 訂單清單、篩選與詳情
    enum Orders {

        /// 訂單清單的根 accessibility identifier
        static let listRoot = "orders.list.root"

        /// 訂單清單無資料狀態容器
        static let listEmptyState = "orders.list.emptyState"

        /// 新增訂單按鈕
        static let addButton = "orders.list.addButton"

        /// 批次操作選單按鈕
        static let batchMenuButton = "orders.list.batchMenuButton"

        /// 訂單篩選按鈕
        static let filterButton = "orders.list.filterButton"

        /// AI 摘要按鈕
        static let aiSummaryButton = "orders.list.aiSummaryButton"

        /// 狀態瀏覽膠囊，key 取 ``OrderStatusFilter`` 的 id (all 或狀態 rawValue)
        /// - Parameter filterID: 訂單狀態篩選識別值
        /// - Returns: 對應狀態膠囊的 accessibility identifier
        static func statusChip(_ filterID: String) -> String {
            option("orders.list.statusChip", key: filterID)
        }

        /// 訂單列，key 取訂單編號這個業務鍵
        /// - Parameter orderID: 訂單編號
        /// - Returns: 對應訂單列的 accessibility identifier
        static func row(orderID: String) -> String {
            BLAccessibilityID.row("orders.list.row", key: orderID)
        }

        /// 訂單篩選 sheet
        static let filterSheet = "orders.filterSheet"

        /// 篩選 sheet 的日期期間膠囊，key 取 ``OrderDatePeriod`` 的 id
        /// - Parameter periodID: 日期期間識別值
        /// - Returns: 對應日期期間膠囊的 accessibility identifier
        static func filterDatePeriod(_ periodID: String) -> String {
            option("orders.filterSheet.datePeriod", key: periodID)
        }

        /// 套用篩選按鈕
        static let filterApplyButton = "orders.filterSheet.applyButton"

        /// 取消篩選按鈕
        static let filterCancelButton = "orders.filterSheet.cancelButton"

        /// 訂單詳情頁的根 accessibility identifier
        static let detailRoot = "orders.detail.root"

        /// 訂單詳情更多操作按鈕
        static let detailMoreButton = "orders.detail.moreButton"

        /// 訂單詳情狀態選單按鈕
        static let detailStatusMenuButton = "orders.detail.statusMenuButton"

        /// 訂單詳情編輯按鈕
        static let detailEditButton = "orders.detail.editButton"

        /// 訂單詳情合併按鈕
        static let detailMergeButton = "orders.detail.mergeButton"

        /// 訂單詳情刪除按鈕
        static let detailDeleteButton = "orders.detail.deleteButton"

        /// 詳情獲利摘要卡，主要數值放各卡的 accessibility value
        /// - Parameter kind: 財務摘要卡種類
        /// - Returns: 對應摘要卡的 accessibility identifier
        static func detailSummaryTile(_ kind: SummaryTile) -> String {
            option("orders.detail.summaryTile", key: kind.rawValue)
        }

        /// 詳情財務摘要卡的種類
        enum SummaryTile: String {

            /// 營收摘要
            case revenue

            /// 成本摘要
            case cost

            /// 獲利摘要
            case profit
        }
    }

    /// 訂單編輯表單
    enum OrderEdit {

        /// 訂單編輯表單的根 accessibility identifier
        static let root = "orderEdit.root"

        /// 客戶欄位
        static let customerField = "orderEdit.customerField"

        /// 訂單來源選擇列
        static let sourceRow = "orderEdit.sourceRow"

        /// 商品類別選擇列
        static let categoryRow = "orderEdit.categoryRow"

        /// 幣別選擇列
        static let currencyRow = "orderEdit.currencyRow"

        /// 付款方式選擇列
        static let paymentRow = "orderEdit.paymentRow"

        /// 對帳狀態選擇列
        static let reconciliationRow = "orderEdit.reconciliationRow"

        /// 開團選擇列
        static let campaignRow = "orderEdit.campaignRow"

        /// 收款金額欄位
        static let chargedAmountField = "orderEdit.chargedAmountField"

        /// 儲存訂單按鈕
        static let saveButton = "orderEdit.saveButton"

        /// 取消編輯按鈕
        static let cancelButton = "orderEdit.cancelButton"

        /// 照片縮圖，key 取序位 (0 起算)
        /// - Parameter index: 照片序位
        /// - Returns: 對應照片縮圖的 accessibility identifier
        static func photoThumbnail(index: Int) -> String {
            indexed("orderEdit.photoThumbnail", index: index)
        }
    }

    /// 訂單合併流程
    enum OrderMerge {

        /// 合併候選訂單清單的根 accessibility identifier
        static let candidateListRoot = "orderMerge.candidateList.root"

        /// 合併候選訂單清單無資料狀態容器
        static let candidateListEmptyState = "orderMerge.candidateList.emptyState"

        /// 候選訂單列，key 取訂單編號這個業務鍵
        /// - Parameter orderID: 訂單編號
        /// - Returns: 對應候選訂單列的 accessibility identifier
        static func candidateRow(orderID: String) -> String {
            BLAccessibilityID.row("orderMerge.candidateList.row", key: orderID)
        }

        /// 取消合併按鈕
        static let cancelButton = "orderMerge.cancelButton"

        /// 照片挑選步驟的繼續按鈕
        static let photoContinueButton = "orderMerge.photoStep.continueButton"

        /// 照片挑選步驟的單格縮圖，key 取序位 (0 起算)
        /// - Parameter index: 照片格序位
        /// - Returns: 對應照片格的 accessibility identifier
        static func photoCell(index: Int) -> String {
            indexed("orderMerge.photoStep.cell", index: index)
        }
    }

    /// 照片檢視器 (BLPhotoViewer)
    enum PhotoViewer {

        /// 照片檢視器的根 accessibility identifier
        static let root = "photoViewer.root"

        /// 照片檢視器中的圖片
        static let image = "photoViewer.image"
    }

    /// AI 商品明細總結 sheet
    enum AISummary {

        /// AI 摘要 sheet 的根 accessibility identifier
        static let root = "aiSummary.root"

        /// 關閉 AI 摘要按鈕
        static let closeButton = "aiSummary.closeButton"

        /// AI 摘要重新載入按鈕
        static let retryButton = "aiSummary.retryButton"

        /// 資料傳輸揭露區塊
        static let dataTransferDisclosure = "aiSummary.dataTransferDisclosure"
    }

    /// 開團列表與詳情
    enum Campaigns {

        /// 開團清單的根 accessibility identifier
        static let listRoot = "campaigns.list.root"

        /// 開團清單無資料狀態容器
        static let listEmptyState = "campaigns.list.emptyState"

        /// 開團清單載入失敗容器
        static let listLoadFailure = Common.loadFailure("campaigns.list")

        /// 開團清單載入失敗重試按鈕
        static let listLoadFailureRetryButton = Common.loadFailureRetryButton("campaigns.list")

        /// 新增開團按鈕
        static let addButton = "campaigns.list.addButton"

        /// 開團篩選選單按鈕
        static let filterMenuButton = "campaigns.list.filterMenuButton"

        /// 開團卡片列，key 取開團 id 這個業務鍵
        /// - Parameter campaignID: 開團識別值
        /// - Returns: 對應開團卡片列的 accessibility identifier
        static func row(campaignID: String) -> String {
            BLAccessibilityID.row("campaigns.list.row", key: campaignID)
        }

        /// 開團詳情頁的根 accessibility identifier
        static let detailRoot = "campaigns.detail.root"

        /// 開團詳情更多操作按鈕
        static let detailMoreButton = "campaigns.detail.moreButton"

        /// 開團詳情編輯按鈕
        static let detailEditButton = "campaigns.detail.editButton"

        /// 開團詳情結團結算按鈕
        static let detailSettleButton = "campaigns.detail.settleButton"

        /// 開團詳情刪除按鈕
        static let detailDeleteButton = "campaigns.detail.deleteButton"

        /// 開團詳情未付款篩選切換鈕
        static let detailUnpaidToggle = "campaigns.detail.unpaidToggle"

        /// 結團結算的數值列，主要數值放各列的 accessibility value
        /// - Parameter kind: 結團結算摘要種類
        /// - Returns: 對應結算摘要列的 accessibility identifier
        static func detailSummary(_ kind: DetailSummary) -> String {
            option("campaigns.detail.summary", key: kind.rawValue)
        }

        /// 結團結算的數值列種類
        enum DetailSummary: String {

            /// 應收金額
            case receivables

            /// 已收金額
            case received
        }
    }

    /// 開團新增與編輯表單
    enum CampaignEdit {

        /// 開團編輯表單的根 accessibility identifier
        static let root = "campaignEdit.root"

        /// 開團名稱欄位
        static let nameField = "campaignEdit.nameField"

        /// 開團提醒切換鈕
        static let reminderToggle = "campaignEdit.reminderToggle"

        /// 儲存開團按鈕
        static let saveButton = "campaignEdit.saveButton"

        /// 取消編輯按鈕
        static let cancelButton = "campaignEdit.cancelButton"
    }

    /// 客戶名單
    enum Customers {

        /// 客戶清單的根 accessibility identifier
        static let listRoot = "customers.list.root"

        /// 客戶清單無資料狀態容器
        static let listEmptyState = "customers.list.emptyState"

        /// Top 3 卡片，key 取客戶名這個業務鍵
        /// - Parameter customerName: 客戶名稱
        /// - Returns: 對應 Top 卡片的 accessibility identifier
        static func topCard(customerName: String) -> String {
            BLAccessibilityID.row("customers.topCard", key: customerName)
        }

        /// 全部客戶列，key 取客戶名這個業務鍵
        /// - Parameter customerName: 客戶名稱
        /// - Returns: 對應客戶列的 accessibility identifier
        static func row(customerName: String) -> String {
            BLAccessibilityID.row("customers.list.row", key: customerName)
        }
    }

    /// 分析頁
    enum Insights {

        /// 分析頁的根 accessibility identifier
        static let root = "insights.root"

        /// 分析頁無資料狀態容器
        static let emptyState = "insights.emptyState"

        /// 分析頁期間選擇器
        static let rangePicker = "insights.rangePicker"

        /// 期間選項，key 取 ``InsightsDateRange`` 的 rawValue
        /// - Parameter rangeID: 分析期間識別值
        /// - Returns: 對應期間選項的 accessibility identifier
        static func rangeSegment(_ rangeID: String) -> String {
            option("insights.rangeSegment", key: rangeID)
        }

        /// 趨勢圖表
        static let trendChart = "insights.chart.trend"

        /// 趨勢卡總獲利數值
        static let trendTotalProfit = "insights.trend.totalProfit"

        /// 成本圓餅圖
        static let costDonut = "insights.chart.costDonut"

        /// 類別排行列，key 取類別名這個業務鍵 (點擊深連結到訂單)
        /// - Parameter category: 類別名稱
        /// - Returns: 對應類別排行列的 accessibility identifier
        static func categoryRankRow(category: String) -> String {
            BLAccessibilityID.row("insights.categoryRank.row", key: category)
        }

        /// 每團毛利排行列，key 取開團 id 這個業務鍵 (點擊深連結到開團詳情)
        /// - Parameter campaignID: 開團識別值
        /// - Returns: 對應開團排行列的 accessibility identifier
        static func campaignRankRow(campaignID: String) -> String {
            BLAccessibilityID.row("insights.campaignRank.row", key: campaignID)
        }
    }

    /// 匯率工具
    enum Fx {

        /// 匯率工具的根 accessibility identifier
        static let root = "fx.root"

        /// 匯率查詢狀態橫幅
        static let statusBanner = "fx.statusBanner"

        /// 幣別選擇按鈕
        static let currencyPickerButton = "fx.currencyPickerButton"

        /// 金額輸入欄位
        static let amountField = "fx.amountField"

        /// 換算後金額
        static let convertedValue = "fx.convertedValue"
    }

    /// 報價試算
    enum Quote {

        /// 報價試算頁的根 accessibility identifier
        static let root = "quote.root"

        /// 幣別選擇按鈕
        static let currencyPickerButton = "quote.currencyPickerButton"

        /// 本金輸入欄位
        static let principalField = "quote.principalField"

        /// 建議售價
        static let suggestedPriceValue = "quote.suggestedPriceValue"

        /// 報價試算狀態橫幅
        static let statusBanner = "quote.statusBanner"

        /// 報價試算重新載入按鈕
        static let retryButton = "quote.retryButton"
    }

    /// 設定頁
    enum Settings {

        /// 設定頁的根 accessibility identifier
        static let root = "settings.root"

        /// 語言選擇器
        static let languagePicker = "settings.languagePicker"

        /// 語言選項
        /// - Parameter key: 語言選項識別值
        /// - Returns: 對應語言選項的 accessibility identifier
        static func languageOption(_ key: String) -> String {
            option("settings.languageOption", key: key)
        }

        /// 預設幣別選擇列
        static let defaultCurrencyRow = "settings.defaultCurrencyRow"

        /// 每月目標金額欄位
        static let monthlyGoalField = "settings.monthlyGoalField"

        /// AI 摘要功能切換鈕
        static let aiSummaryToggle = "settings.aiSummaryToggle"

        /// AI 摘要模型選擇列
        static let aiSummaryModelRow = "settings.aiSummaryModelRow"

        /// 帳本鎖定功能切換鈕
        static let appLockToggle = "settings.appLockToggle"

        /// App 版本列
        static let versionRow = "settings.versionRow"
    }

    /// 更多分頁
    enum More {

        /// 更多分頁的根 accessibility identifier
        static let root = "more.root"

        /// 導向各工具與設定的列 (以目的地 key 指定)
        /// - Parameter row: 更多分頁目的地
        /// - Returns: 對應目的地列的 accessibility identifier
        static func row(_ row: Row) -> String {
            option("more.row", key: row.rawValue)
        }

        /// 更多分頁各列的目的地 key
        enum Row: String {

            /// 匯率工具
            case fx

            /// 客戶名單
            case customers

            /// 報價試算
            case quote

            /// 訂單來源主檔
            case orderSources

            /// 商品類別主檔
            case categories

            /// 付款方式主檔
            case paymentMethods

            /// 對帳狀態主檔
            case reconciliationStatuses

            /// 設定頁
            case settings
        }
    }

    /// 主檔管理頁面與付款方式編輯表單
    enum LookupManagement {

        /// 主檔管理頁面的根 accessibility identifier
        static let root = "lookupManagement.root"

        /// 主檔項目列，以名稱這個業務鍵識別
        /// - Parameter name: 主檔項目名稱
        /// - Returns: 主檔項目列的 accessibility identifier
        static func row(_ name: String) -> String {
            BLAccessibilityID.row("lookupManagement.row", key: name)
        }

        /// 編輯或重新命名操作按鈕，以項目名稱識別
        /// - Parameter name: 主檔項目名稱
        /// - Returns: 編輯操作按鈕的 accessibility identifier
        static func editButton(_ name: String) -> String {
            BLAccessibilityID.row("lookupManagement.editButton", key: name)
        }

        /// 其他主檔的重新命名操作按鈕，以項目名稱識別
        /// - Parameter name: 主檔項目名稱
        /// - Returns: 重新命名操作按鈕的 accessibility identifier
        static func renameButton(_ name: String) -> String {
            BLAccessibilityID.row("lookupManagement.renameButton", key: name)
        }

        /// 付款方式名稱輸入欄位
        static let paymentMethodNameField = "lookupManagement.paymentMethodEditor.nameField"

        /// 付款方式編輯表單的捲動容器
        static let paymentMethodEditorRoot = "lookupManagement.paymentMethodEditor.root"

        /// 付款方式貨到付款旗標
        static let paymentMethodCashOnDeliveryToggle = "lookupManagement.paymentMethodEditor.cashOnDeliveryToggle"

        /// 付款方式編輯表單儲存按鈕
        static let paymentMethodSaveButton = "lookupManagement.paymentMethodEditor.saveButton"
    }

    /// 單選／多選選項選擇器 (設定、訂單編輯、匯率、報價共用同一個元件)
    enum OptionPicker {

        /// 選項選擇器的根 accessibility identifier
        static let root = "optionPicker.root"

        /// 新增選項按鈕
        static let addButton = "optionPicker.addButton"

        /// 新增選項提示框的名稱輸入欄位
        static let addAlertNameField = "optionPicker.addAlert.nameField"

        /// 新增選項提示框的確認按鈕
        static let addAlertConfirmButton = "optionPicker.addAlert.confirmButton"

        /// 新增選項提示框的取消按鈕
        static let addAlertCancelButton = "optionPicker.addAlert.cancelButton"

        /// 完成選項選擇按鈕
        static let doneButton = "optionPicker.doneButton"

        /// 選項列，以原始字串識別
        /// - Parameter option: 選項原始字串
        /// - Returns: 對應選項列的 accessibility identifier
        static func optionRow(_ option: String) -> String {
            row("optionPicker.optionRow", key: option)
        }
    }

    /// 跨畫面共用的元件
    enum Common {

        /// 鍵盤工具列的完成按鈕
        static let keyboardDoneButton = "common.keyboard.doneButton"

        /// 系統導覽返回按鈕
        static let backButton = "BackButton"

        /// 載入中容器
        /// - Parameter feature: 功能名稱
        /// - Returns: 載入中容器的 accessibility identifier
        static func loading(_ feature: String) -> String {
            option(feature, key: "loading")
        }

        /// 載入失敗容器
        /// - Parameter feature: 功能名稱
        /// - Returns: 載入失敗容器的 accessibility identifier
        static func loadFailure(_ feature: String) -> String {
            option(feature, key: "loadFailure")
        }

        /// 載入失敗容器的重試
        /// - Parameter feature: 功能名稱
        /// - Returns: 載入失敗重試按鈕的 accessibility identifier
        static func loadFailureRetryButton(_ feature: String) -> String {
            option(feature, key: "loadFailure") + ".retryButton"
        }
    }
}

// MARK: - Internal Method

extension BLAccessibilityID {

    /// 組出列舉型集合的 identifier
    /// - Parameters:
    ///   - prefix: identifier 前綴
    ///   - key: 集合項目的識別值
    /// - Returns: 組合後的 accessibility identifier
    static func option(_ prefix: String, key: String) -> String {
        "\(prefix).\(key)"
    }

    /// 組出使用者資料列的 identifier
    /// - Parameters:
    ///   - prefix: identifier 前綴
    ///   - key: 資料列的識別值
    /// - Returns: 組合後的 accessibility identifier
    static func row(_ prefix: String, key: String) -> String {
        "\(prefix):\(key)"
    }

    /// 組出純序位集合的 identifier
    /// - Parameters:
    ///   - prefix: identifier 前綴
    ///   - index: 集合項目的序位
    /// - Returns: 組合後的 accessibility identifier
    static func indexed(_ prefix: String, index: Int) -> String {
        "\(prefix).index.\(index)"
    }
}
