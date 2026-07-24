//
//  BLAccessibilityID.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/24.
//

import Foundation

/// UI 測試定位元素用的 accessibility identifier 常數
///
/// 這份常數同時編入 App target 與 `BuyLedgerUITests` target，是 identifier 字串的唯一宣告處；
/// 兩端一律引用常數、不寫字面值，改一次兩邊同時生效
///
/// 命名格式為 `feature.screen.element`，必要時再加第四段補述。片段一律 ASCII lowerCamelCase，
/// 不隨語言變動，也不編入「停用」「已選取」這類測試可直接從元素讀到的狀態
///
/// - Important: UI 測試 bundle 不連結 App binary，因此本檔不得引用任何 App 型別；
///   需要對應 App 的列舉時，於本檔另宣告同形狀的 key 列舉，並由 App 端以窮舉 switch 對應
///
/// - Warning: identifier 只能掛在「本身就是一個無障礙元素」的東西上 (按鈕、輸入欄、捲動容器、
///   `accessibilityElement(children:)` 合併後的列)。掛在單純的 `VStack` 這類版面容器上，
///   SwiftUI 會把它往下傳並蓋掉所有子元素自己的 identifier，實測會讓整個區塊只剩一個字串
enum BLAccessibilityID {}

// MARK: - Nested Types

extension BLAccessibilityID {

    /// 根導覽 (iPhone 分頁列與 iPad 側邊欄)
    enum Root {

        /// iPad 側邊欄容器
        static let sidebar = "root.sidebar"

        /// 分頁項目，目前只有 iPad 側邊欄的分頁列吃得到
        ///
        /// iPhone 底部分頁列是 SwiftUI `Tab` 建立的 UIKit tab bar，identifier 不論掛在 `Tab` 或其 label 上
        /// 都不會傳到分頁按鈕 (實測)。compact 版面的分頁切換由測試端的導覽分流器依 ``Tab`` 的宣告順序取按鈕，
        /// 再等該分頁的畫面根 identifier 確認切換成功
        ///
        /// 側邊欄分頁列的進行中筆數併入該列朗讀，由該列的 accessibility value 讀取
        /// - Parameter tab: 目標分頁
        /// - Returns: 該分頁列的 identifier
        static func tab(_ tab: Tab) -> String {
            option("root.tab", key: tab.rawValue)
        }

        /// 側邊欄智慧分組列
        ///
        /// 整列合併為單一朗讀單位，訂單筆數由該列的 accessibility value 讀取
        /// - Parameter group: 目標智慧群組
        /// - Returns: 該智慧群組列的 identifier
        static func smartGroup(_ group: SmartGroup) -> String {
            option("root.sidebar.smartGroup", key: group.rawValue)
        }

        /// 主導覽分頁的 key
        ///
        /// 對應 App 的 `RootTab`，由 App 端以窮舉 switch 轉換；`RootTab` 新增 case 時該 switch 會編不過，
        /// 藉此逼出這裡的同步更新
        enum Tab: String {

            /// 總覽頁
            case dashboard

            /// 訂單頁
            case orders

            /// 開團頁
            case campaigns

            /// 分析頁
            case insights

            /// 更多與設定頁
            case more
        }

        /// 側邊欄智慧分組的 key
        ///
        /// 對應 App 側邊欄的智慧分組項目，由 App 端以窮舉 switch 轉換；新增分組時該 switch 會編不過，
        /// 藉此逼出這裡的同步更新
        enum SmartGroup: String {

            /// 報價中
            case quoting

            /// 已確認
            case confirmed

            /// 已下單
            case purchased

            /// 集運中
            case shipping

            /// 部分到貨
            case partiallyArrived

            /// 已到貨
            case arrived

            /// 已交付
            case delivered

            /// 已取貨
            case pickedUp
        }
    }

    /// 總覽頁
    enum Dashboard {

        /// 畫面根容器
        static let root = "dashboard.root"

        /// 載入中容器
        static let loading = Common.loading("dashboard")

        /// 載入失敗容器
        static let loadFailure = Common.loadFailure("dashboard")

        /// 載入失敗容器的重試
        static let loadFailureRetryButton = Common.loadFailureRetryButton("dashboard")

        /// 尚無資料時的引導空狀態
        static let emptyState = "dashboard.emptyState"

        /// 引導空狀態的行動按鈕 (建立第一筆訂單)
        static let emptyStateActionButton = "dashboard.emptyState.actionButton"

        /// KPI 卡容器
        ///
        /// 卡片是合併朗讀的單一元素，主要數值由該元素的 accessibility value 承載、不另立子 identifier
        /// - Parameter kpi: 目標 KPI
        /// - Returns: 該 KPI 卡的 identifier
        static func kpiTile(_ kpi: KPI) -> String {
            option("dashboard.kpiTile", key: kpi.rawValue)
        }

        /// 近期訂單的「查看全部」
        static let recentOrdersSeeAllButton = "dashboard.recentOrders.seeAllButton"

        /// 近期訂單的單列，key 取訂單編號這個業務鍵，排序或語言變動都不影響定位
        /// - Parameter orderID: 訂單編號 (業務鍵)
        /// - Returns: 該近期訂單列的 identifier
        static func recentOrderRow(orderID: String) -> String {
            row("dashboard.recentOrders.row", key: orderID)
        }

        /// KPI 指標的 key
        ///
        /// 涵蓋 hero 卡的淨獲利與 KPI 格的四張卡；compact 與 regular 版面共用同一組 key
        enum KPI: String {

            /// 營業額
            case revenue

            /// 成本
            case cost

            /// 毛利率
            case grossMargin

            /// 進行中訂單
            case activeOrders

            /// 本月淨獲利 (hero 卡)
            case netProfit
        }
    }

    /// 訂單清單、篩選與詳情
    enum Orders {

        /// 清單捲動容器，判定訂單頁就緒
        static let listRoot = "orders.list.root"

        /// 沒有符合條件訂單的空狀態
        static let listEmptyState = "orders.list.emptyState"

        /// 新增訂單 (工具列 icon-only)
        static let addButton = "orders.list.addButton"

        /// 批次操作選單 (工具列 icon-only)
        static let batchMenuButton = "orders.list.batchMenuButton"

        /// compact 開啟整合篩選 sheet
        static let filterButton = "orders.list.filterButton"

        /// AI 商品明細總結 (在「更多操作」選單內，label「AI 總結」)
        static let aiSummaryButton = "orders.list.aiSummaryButton"

        /// 狀態瀏覽膠囊，key 取 ``OrderStatusFilter`` 的 id (all 或狀態 rawValue)
        /// - Parameter filterID: ``OrderStatusFilter`` 的 id
        /// - Returns: 該狀態瀏覽膠囊的 identifier
        static func statusChip(_ filterID: String) -> String {
            option("orders.list.statusChip", key: filterID)
        }

        /// 訂單列，key 取訂單編號這個業務鍵
        /// - Parameter orderID: 訂單編號 (業務鍵)
        /// - Returns: 該訂單列的 identifier
        static func row(orderID: String) -> String {
            BLAccessibilityID.row("orders.list.row", key: orderID)
        }

        /// 整合篩選 sheet 根容器
        static let filterSheet = "orders.filterSheet"

        /// 篩選 sheet 的日期期間膠囊，key 取 ``OrderDatePeriod`` 的 id
        /// - Parameter periodID: ``OrderDatePeriod`` 的 id
        /// - Returns: 該日期期間膠囊的 identifier
        static func filterDatePeriod(_ periodID: String) -> String {
            option("orders.filterSheet.datePeriod", key: periodID)
        }

        /// 篩選 sheet 的套用
        static let filterApplyButton = "orders.filterSheet.applyButton"

        /// 篩選 sheet 的取消
        static let filterCancelButton = "orders.filterSheet.cancelButton"

        /// 訂單詳情捲動容器
        static let detailRoot = "orders.detail.root"

        /// 詳情的更多操作選單 (編輯/合併/刪除)
        static let detailMoreButton = "orders.detail.moreButton"

        /// 詳情的狀態更新選單
        static let detailStatusMenuButton = "orders.detail.statusMenuButton"

        /// 更多選單的編輯
        static let detailEditButton = "orders.detail.editButton"

        /// 更多選單的合併
        static let detailMergeButton = "orders.detail.mergeButton"

        /// 更多選單的刪除 (破壞性)
        static let detailDeleteButton = "orders.detail.deleteButton"

        /// 詳情獲利摘要卡，主要數值放各卡的 accessibility value
        /// - Parameter kind: 摘要卡種類
        /// - Returns: 該獲利摘要卡的 identifier
        static func detailSummaryTile(_ kind: SummaryTile) -> String {
            option("orders.detail.summaryTile", key: kind.rawValue)
        }

        /// 詳情財務摘要卡的種類
        enum SummaryTile: String {

            /// 總收款
            case revenue

            /// 總成本
            case cost

            /// 獲利
            case profit
        }
    }

    /// 訂單編輯表單
    enum OrderEdit {

        /// 表單捲動容器，判定編輯表單就緒
        static let root = "orderEdit.root"

        /// 客戶名稱輸入欄
        static let customerField = "orderEdit.customerField"

        /// 訂單來源選擇列 (push 選擇器)
        static let sourceRow = "orderEdit.sourceRow"

        /// 商品類別選擇列 (push 選擇器)
        static let categoryRow = "orderEdit.categoryRow"

        /// 幣別選擇列 (push 選擇器)
        static let currencyRow = "orderEdit.currencyRow"

        /// 付款方式選擇列 (push 選擇器)
        static let paymentRow = "orderEdit.paymentRow"

        /// 對帳狀態選擇列 (push 選擇器)
        static let reconciliationRow = "orderEdit.reconciliationRow"

        /// 開團選擇列 (合併情境的多選 push 選擇器)
        static let campaignRow = "orderEdit.campaignRow"

        /// 客戶實付金額輸入欄 (數字鍵盤)
        static let chargedAmountField = "orderEdit.chargedAmountField"

        /// 儲存 (工具列 icon-only)
        static let saveButton = "orderEdit.saveButton"

        /// 取消 (工具列 icon-only)
        static let cancelButton = "orderEdit.cancelButton"

        /// 照片縮圖，key 取序位 (0 起算)
        /// - Parameter index: 縮圖序位 (0 起算)
        /// - Returns: 該照片縮圖的 identifier
        static func photoThumbnail(index: Int) -> String {
            indexed("orderEdit.photoThumbnail", index: index)
        }
    }

    /// 訂單合併流程
    enum OrderMerge {

        /// 候選清單捲動容器，判定合併候選 sheet 就緒
        static let candidateListRoot = "orderMerge.candidateList.root"

        /// 無可合併訂單的空狀態
        static let candidateListEmptyState = "orderMerge.candidateList.emptyState"

        /// 候選訂單列，key 取訂單編號這個業務鍵
        /// - Parameter orderID: 訂單編號 (業務鍵)
        /// - Returns: 該候選訂單列的 identifier
        static func candidateRow(orderID: String) -> String {
            BLAccessibilityID.row("orderMerge.candidateList.row", key: orderID)
        }

        /// 取消合併 (工具列)
        static let cancelButton = "orderMerge.cancelButton"

        /// 照片挑選步驟的繼續 (工具列)
        static let photoContinueButton = "orderMerge.photoStep.continueButton"

        /// 照片挑選步驟的單格縮圖，key 取序位 (0 起算)
        /// - Parameter index: 縮圖序位 (0 起算)
        /// - Returns: 該照片格的 identifier
        static func photoCell(index: Int) -> String {
            indexed("orderMerge.photoStep.cell", index: index)
        }
    }

    /// 照片檢視器 (BLPhotoViewer)
    enum PhotoViewer {

        /// 檢視器容器，判定已推進呈現
        static let root = "photoViewer.root"

        /// 目前顯示的照片
        static let image = "photoViewer.image"
    }

    /// AI 商品明細總結 sheet
    enum AISummary {

        /// sheet 內容容器
        static let root = "aiSummary.root"

        /// 關閉
        static let closeButton = "aiSummary.closeButton"

        /// 錯誤態的重試
        static let retryButton = "aiSummary.retryButton"
    }

    /// 開團列表與詳情
    enum Campaigns {

        /// 列表捲動容器，判定開團頁就緒
        static let listRoot = "campaigns.list.root"

        /// 尚無開團的空狀態
        static let listEmptyState = "campaigns.list.emptyState"

        /// 新增開團 (工具列 icon-only)
        static let addButton = "campaigns.list.addButton"

        /// 篩選與分組選單 (工具列)
        static let filterMenuButton = "campaigns.list.filterMenuButton"

        /// 開團卡片列，key 取開團 id 這個業務鍵
        /// - Parameter campaignID: 開團 id (業務鍵)
        /// - Returns: 該開團卡片列的 identifier
        static func row(campaignID: String) -> String {
            BLAccessibilityID.row("campaigns.list.row", key: campaignID)
        }

        /// 詳情捲動容器
        static let detailRoot = "campaigns.detail.root"

        /// 詳情的更多選單 (編輯/結團/刪除)
        static let detailMoreButton = "campaigns.detail.moreButton"

        /// 更多選單的編輯開團
        static let detailEditButton = "campaigns.detail.editButton"

        /// 更多選單的結團結算 (不可逆)
        static let detailSettleButton = "campaigns.detail.settleButton"

        /// 更多選單的刪除開團 (破壞性)
        static let detailDeleteButton = "campaigns.detail.deleteButton"

        /// 只看未收款切換
        static let detailUnpaidToggle = "campaigns.detail.unpaidToggle"

        /// 結團結算的數值列，主要數值放各列的 accessibility value
        /// - Parameter kind: 結算數值列種類
        /// - Returns: 該結算數值列的 identifier
        static func detailSummary(_ kind: DetailSummary) -> String {
            option("campaigns.detail.summary", key: kind.rawValue)
        }

        /// 結團結算的數值列種類
        enum DetailSummary: String {

            /// 應收
            case receivables

            /// 已收
            case received
        }
    }

    /// 開團新增與編輯表單
    enum CampaignEdit {

        /// 表單捲動容器，判定編輯表單就緒
        static let root = "campaignEdit.root"

        /// 開團名稱輸入欄
        static let nameField = "campaignEdit.nameField"

        /// 訂購提醒開關
        static let reminderToggle = "campaignEdit.reminderToggle"

        /// 儲存 (工具列 icon-only)
        static let saveButton = "campaignEdit.saveButton"

        /// 取消 (工具列 icon-only)
        static let cancelButton = "campaignEdit.cancelButton"
    }

    /// 客戶名單
    enum Customers {

        /// 名單捲動容器，判定客戶頁就緒
        static let listRoot = "customers.list.root"

        /// 尚無客戶的空狀態
        static let listEmptyState = "customers.list.emptyState"

        /// Top 3 卡片，key 取客戶名這個業務鍵
        /// - Parameter customerName: 客戶名 (業務鍵)
        /// - Returns: 該 Top 3 卡片的 identifier
        static func topCard(customerName: String) -> String {
            BLAccessibilityID.row("customers.topCard", key: customerName)
        }

        /// 全部客戶列，key 取客戶名這個業務鍵
        /// - Parameter customerName: 客戶名 (業務鍵)
        /// - Returns: 該全部客戶列的 identifier
        static func row(customerName: String) -> String {
            BLAccessibilityID.row("customers.list.row", key: customerName)
        }
    }

    /// 分析頁
    enum Insights {

        /// 捲動容器，判定分析頁就緒
        static let root = "insights.root"

        /// 尚無足夠資料的空狀態
        static let emptyState = "insights.emptyState"

        /// 期間選擇器
        static let rangePicker = "insights.rangePicker"

        /// 期間選項，key 取 ``InsightsDateRange`` 的 rawValue
        /// - Parameter rangeID: ``InsightsDateRange`` 的 rawValue
        /// - Returns: 該期間選項的 identifier
        static func rangeSegment(_ rangeID: String) -> String {
            option("insights.rangeSegment", key: rangeID)
        }

        /// 走勢圖容器，摘要留在其 accessibilityLabel
        static let trendChart = "insights.chart.trend"

        /// 成本結構 donut 容器
        static let costDonut = "insights.chart.costDonut"

        /// 類別排行列，key 取類別名這個業務鍵 (點擊深連結到訂單)
        /// - Parameter category: 類別名 (業務鍵)
        /// - Returns: 該類別排行列的 identifier
        static func categoryRankRow(category: String) -> String {
            BLAccessibilityID.row("insights.categoryRank.row", key: category)
        }

        /// 每團毛利排行列，key 取開團 id 這個業務鍵 (點擊深連結到開團詳情)
        /// - Parameter campaignID: 開團 id (業務鍵)
        /// - Returns: 該每團毛利排行列的 identifier
        static func campaignRankRow(campaignID: String) -> String {
            BLAccessibilityID.row("insights.campaignRank.row", key: campaignID)
        }
    }

    /// 匯率工具
    enum Fx {

        /// 捲動容器，判定匯率頁就緒
        static let root = "fx.root"

        /// 載入或錯誤狀態橫幅
        static let statusBanner = "fx.statusBanner"

        /// 來源幣別選擇 (開幣別選擇器)
        static let currencyPickerButton = "fx.currencyPickerButton"

        /// 金額輸入欄 (數字鍵盤)
        static let amountField = "fx.amountField"

        /// 換算後 TWD 結果，數值放該元素的 accessibility value
        static let convertedValue = "fx.convertedValue"
    }

    /// 報價試算
    enum Quote {

        /// 捲動容器，判定報價頁就緒
        static let root = "quote.root"

        /// 來源幣別選擇 (開幣別選擇器)
        static let currencyPickerButton = "quote.currencyPickerButton"

        /// 商品本金輸入欄 (數字鍵盤，7 個輸入欄的第一個)
        static let principalField = "quote.principalField"

        /// 建議售價 hero 卡，數值放該元素的 accessibility value
        static let suggestedPriceValue = "quote.suggestedPriceValue"
    }

    /// 設定頁
    enum Settings {

        /// 畫面根容器
        static let root = "settings.root"

        /// 語言選擇
        static let languagePicker = "settings.languagePicker"

        /// 語言選項
        /// - Parameter key: 語言選項的 key
        /// - Returns: 該語言選項的 identifier
        static func languageOption(_ key: String) -> String {
            option("settings.languageOption", key: key)
        }

        /// 預設幣別列 (推進到選擇器)
        static let defaultCurrencyRow = "settings.defaultCurrencyRow"

        /// 每月目標金額輸入欄
        static let monthlyGoalField = "settings.monthlyGoalField"

        /// AI 總結開關
        static let aiSummaryToggle = "settings.aiSummaryToggle"

        /// AI 總結模型列 (推進到選擇器)，僅 DEBUG 建置出現
        static let aiSummaryModelRow = "settings.aiSummaryModelRow"

        /// 版本資訊列
        static let versionRow = "settings.versionRow"
    }

    /// 更多分頁
    enum More {

        /// 畫面根容器
        static let root = "more.root"

        /// 導向各工具與設定的列 (以目的地 key 指定)
        /// - Parameter row: 目的地列
        /// - Returns: 該導向列的 identifier
        static func row(_ row: Row) -> String {
            option("more.row", key: row.rawValue)
        }

        /// 更多分頁各列的目的地 key
        ///
        /// 對應 App 的 `RootFeature.MoreRoute`，由 App 端以窮舉 switch 轉換；`MoreRoute` 新增 case 時該 switch 會編不過，
        /// 藉此逼出這裡的同步更新
        enum Row: String {

            /// 匯率工具
            case fx

            /// 客戶名單
            case customers

            /// 報價試算
            case quote

            /// 訂單來源主檔管理
            case orderSources

            /// 商品類別主檔管理
            case categories

            /// 付款方式主檔管理
            case paymentMethods

            /// 對帳狀態主檔管理
            case reconciliationStatuses

            /// 設定
            case settings
        }
    }

    /// 單選／多選選項選擇器 (設定、訂單編輯、匯率、報價共用同一個元件)
    ///
    /// 同一時刻只會有一個選擇器在畫面上，故不分呼叫來源、全部共用這組 identifier
    enum OptionPicker {

        /// 畫面根容器 (選項清單)
        static let root = "optionPicker.root"

        /// 開啟新增流程的按鈕
        static let addButton = "optionPicker.addButton"

        /// 新增 alert 的名稱輸入欄
        static let addAlertNameField = "optionPicker.addAlert.nameField"

        /// 新增 alert 的確認
        static let addAlertConfirmButton = "optionPicker.addAlert.confirmButton"

        /// 新增 alert 的取消
        static let addAlertCancelButton = "optionPicker.addAlert.cancelButton"

        /// 多選模式的完成
        static let doneButton = "optionPicker.doneButton"

        /// 選項列，key 取選項的原始字串這個業務鍵，顯示名稱與排序變動都不影響定位
        /// - Parameter option: 選項的原始字串 (業務鍵)
        /// - Returns: 該選項列的 identifier
        static func optionRow(_ option: String) -> String {
            row("optionPicker.optionRow", key: option)
        }
    }

    /// 跨畫面共用的元件
    enum Common {

        /// 數字鍵盤工具列的「完成」
        static let keyboardDoneButton = "common.keyboard.doneButton"

        /// 導覽堆疊返回鍵
        ///
        /// 此為 SwiftUI 系統返回鍵預設帶的 identifier (非 App 自設)，穩定且與語言無關，可用來定位 push 目的地的返回鍵
        static let backButton = "BackButton"

        /// 載入中容器
        /// - Parameter feature: 功能前綴
        /// - Returns: 該功能載入中容器的 identifier
        static func loading(_ feature: String) -> String {
            option(feature, key: "loading")
        }

        /// 載入失敗容器
        /// - Parameter feature: 功能前綴
        /// - Returns: 該功能載入失敗容器的 identifier
        static func loadFailure(_ feature: String) -> String {
            option(feature, key: "loadFailure")
        }

        /// 載入失敗容器的重試
        /// - Parameter feature: 功能前綴
        /// - Returns: 該功能載入失敗容器重試鍵的 identifier
        static func loadFailureRetryButton(_ feature: String) -> String {
            option(feature, key: "loadFailure") + ".retryButton"
        }
    }
}

// MARK: - Internal Method

extension BLAccessibilityID {

    /// 組出列舉型集合的 identifier
    ///
    /// 用於狀態、期間、分頁這類由列舉驅動的集合，key 取列舉的 rawValue
    /// - Parameters:
    ///   - prefix: 集合的固定前綴
    ///   - key: 列舉的 rawValue
    /// - Returns: 以 `.` 串接的 identifier
    static func option(_ prefix: String, key: String) -> String {
        "\(prefix).\(key)"
    }

    /// 組出使用者資料列的 identifier
    ///
    /// 業務鍵維持原始字串、不翻譯，切換語言後 identifier 不變
    /// - Parameters:
    ///   - prefix: 清單的固定前綴
    ///   - key: 該筆資料的業務鍵 (訂單編號、客戶名等)
    /// - Returns: 以 `:` 分隔前綴與業務鍵的 identifier
    static func row(_ prefix: String, key: String) -> String {
        "\(prefix):\(key)"
    }

    /// 組出純序位集合的 identifier
    ///
    /// 用於照片、商品明細這類沒有穩定業務鍵、只能靠位置區分的集合
    /// - Parameters:
    ///   - prefix: 集合的固定前綴
    ///   - index: 從 0 起算的位置
    /// - Returns: 以 `.index.` 串接位置的 identifier
    static func indexed(_ prefix: String, index: Int) -> String {
        "\(prefix).index.\(index)"
    }
}
