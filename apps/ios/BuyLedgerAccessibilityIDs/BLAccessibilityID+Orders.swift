//
//  BLAccessibilityID+Orders.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/3.
//

// MARK: - Nested Types

extension BLAccessibilityID {

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

        /// 寬版付款方式篩選選單的觸發鈕
        static let paymentMethodMenuButton = "orders.list.paymentMethodMenu"

        /// 寬版付款方式篩選選單的全部選項
        static let paymentMethodMenuAllOption = "orders.list.paymentMethodMenu.all"

        /// 寬版類別選擇器的觸發鈕
        static let categoryFilterButton = "orders.list.categoryFilterButton"

        /// 寬版清單立即清除篩選的按鈕
        static let clearFiltersButton = "orders.list.clearFiltersButton"

        /// 寬版類別選擇器 sheet
        static let categoryPickerSheet = "orders.categoryPicker"

        /// 類別選擇器的完成按鈕
        static let categoryPickerDoneButton = "orders.categoryPicker.doneButton"

        /// 類別選擇器的取消按鈕
        static let categoryPickerCancelButton = "orders.categoryPicker.cancelButton"

        /// 類別選擇器的搜尋欄
        static let categoryPickerSearchField = "orders.categoryPicker.searchField"

        /// 類別選擇器的清除搜尋按鈕
        static let categoryPickerSearchClearButton = "orders.categoryPicker.clearSearchButton"

        /// 類別選擇器的全部類別選項
        static let categoryPickerAllOption = "orders.categoryPicker.all"

        /// AI 摘要按鈕
        static let aiSummaryButton = "orders.list.aiSummaryButton"

        /// 訂單篩選 sheet
        static let filterSheet = "orders.filterSheet"

        /// 套用篩選按鈕
        static let filterApplyButton = "orders.filterSheet.applyButton"

        /// 取消篩選按鈕
        static let filterCancelButton = "orders.filterSheet.cancelButton"

        /// 篩選 sheet 的清除篩選按鈕
        static let filterClearButton = "orders.filterSheet.clearButton"

        /// 篩選 sheet 的日期選單觸發鈕
        static let filterDateMenuButton = "orders.filterSheet.dateMenu"

        /// 篩選 sheet 的付款方式選單觸發鈕
        static let filterPaymentMethodMenuButton = "orders.filterSheet.paymentMethodMenu"

        /// 篩選 sheet 的付款方式全部選項
        static let filterPaymentMethodAllOption = "orders.filterSheet.paymentMethodMenu.all"

        /// 篩選 sheet 的類別搜尋欄
        static let filterSearchField = "orders.filterSheet.searchField"

        /// 篩選 sheet 的清除搜尋按鈕
        static let filterSearchClearButton = "orders.filterSheet.clearSearchButton"

        /// 篩選 sheet 的全部類別選項
        static let filterCategoryAllOption = "orders.filterSheet.categoryAll"

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

        /// 詳情財務摘要卡的種類
        enum SummaryTile: String {

            /// 營收摘要
            case revenue

            /// 成本摘要
            case cost

            /// 獲利摘要
            case profit
        }

        /// 狀態瀏覽膠囊，key 取 ``OrderStatusFilter`` 的 `id` (`all` 或狀態 `rawValue`)
        ///
        /// - Parameter filterID: 訂單狀態篩選識別值
        /// - Returns: 對應狀態膠囊的 accessibility identifier
        static func statusChip(_ filterID: String) -> String {
            option("orders.list.statusChip", key: filterID)
        }

        /// 日期瀏覽膠囊，key 取 ``OrderDatePeriod`` 的 `id`
        ///
        /// - Parameter periodID: 日期期間識別值
        /// - Returns: 對應日期膠囊的 accessibility identifier
        static func dateChip(_ periodID: String) -> String {
            option("orders.list.dateChip", key: periodID)
        }

        /// 訂單列，key 取訂單編號
        ///
        /// - Parameter orderID: 訂單編號
        /// - Returns: 對應訂單列的 accessibility identifier
        static func row(orderID: String) -> String {
            BLAccessibilityID.row("orders.list.row", key: orderID)
        }

        /// 篩選 sheet 的日期選單選項，key 取 ``OrderDatePeriod`` 的 `id`
        ///
        /// - Parameter periodID: 日期期間識別值
        /// - Returns: 對應日期選單選項的 accessibility identifier
        static func filterDatePeriod(_ periodID: String) -> String {
            option("orders.filterSheet.datePeriod", key: periodID)
        }

        /// 寬版付款方式篩選選單的選項，key 取付款方式名稱
        ///
        /// - Parameter name: 付款方式名稱
        /// - Returns: 對應付款方式選項的 accessibility identifier
        static func paymentMethodMenuOption(_ name: String) -> String {
            option("orders.list.paymentMethodMenu.option", key: name)
        }

        /// 篩選 sheet 的付款方式選項，key 取付款方式名稱
        ///
        /// - Parameter name: 付款方式名稱
        /// - Returns: 對應付款方式選項的 accessibility identifier
        static func filterPaymentMethodOption(_ name: String) -> String {
            option("orders.filterSheet.paymentMethodMenu.option", key: name)
        }

        /// 類別分組的組標題，key 取組別種類的識別值
        ///
        /// - Parameter kindID: 組別種類的識別值
        /// - Returns: 對應組標題的 accessibility identifier
        static func categoryGroupHeader(_ kindID: String) -> String {
            option("orders.filter.categoryGroup", key: kindID)
        }

        /// 類別格，key 取類別名稱
        ///
        /// - Parameter name: 類別名稱
        /// - Returns: 對應類別格的 accessibility identifier
        static func categoryCell(_ name: String) -> String {
            option("orders.filter.category", key: name)
        }

        /// 詳情獲利摘要卡，主要數值放各卡的 accessibility value
        ///
        /// - Parameter kind: 財務摘要卡種類
        /// - Returns: 對應摘要卡的 accessibility identifier
        static func detailSummaryTile(_ kind: SummaryTile) -> String {
            option("orders.detail.summaryTile", key: kind.rawValue)
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

        /// 訂購日期選擇器
        static let orderDatePicker = "orderEdit.orderDatePicker"

        /// 基本資料區段頁尾的訂購時間戳
        static let orderDateTimestamp = "orderEdit.orderDateTimestamp"

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
        ///
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

        /// 取消合併按鈕
        static let cancelButton = "orderMerge.cancelButton"

        /// 照片挑選步驟的繼續按鈕
        static let photoContinueButton = "orderMerge.photoStep.continueButton"

        /// 候選訂單列，key 取訂單編號
        ///
        /// - Parameter orderID: 訂單編號
        /// - Returns: 對應候選訂單列的 accessibility identifier
        static func candidateRow(orderID: String) -> String {
            BLAccessibilityID.row("orderMerge.candidateList.row", key: orderID)
        }

        /// 照片挑選步驟的單格縮圖，key 取序位 (0 起算)
        ///
        /// - Parameter index: 照片格序位
        /// - Returns: 對應照片格的 accessibility identifier
        static func photoCell(index: Int) -> String {
            indexed("orderMerge.photoStep.cell", index: index)
        }
    }

    /// 照片檢視器 (`BLPhotoViewer`)
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
}
