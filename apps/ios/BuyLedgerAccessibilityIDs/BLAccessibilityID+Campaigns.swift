//
//  BLAccessibilityID+Campaigns.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/3.
//

// MARK: - Nested Types

extension BLAccessibilityID {

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

        /// 開團詳情已結團狀態標籤
        static let detailSettledBadge = "campaigns.detail.settledBadge"

        /// 開團詳情未付款篩選切換鈕
        static let detailUnpaidToggle = "campaigns.detail.unpaidToggle"

        /// 結團結算的數值列種類
        enum DetailSummary: String {

            /// 應收金額
            case receivables

            /// 已收金額
            case received
        }

        /// 開團卡片列，key 取開團識別值
        ///
        /// - Parameter campaignID: 開團識別值
        /// - Returns: 對應開團卡片列的 accessibility identifier
        static func row(campaignID: String) -> String {
            BLAccessibilityID.row("campaigns.list.row", key: campaignID)
        }

        /// 客戶分貨列，key 取客戶名稱
        ///
        /// - Parameter customerName: 客戶名稱
        /// - Returns: 對應客戶分貨列的 accessibility identifier
        static func detailDistributionRow(customerName: String) -> String {
            BLAccessibilityID.row("campaigns.detail.distributionRow", key: customerName)
        }

        /// 訂單收款切換鍵，key 取訂單識別值
        ///
        /// - Parameter orderID: 訂單識別值
        /// - Returns: 對應訂單收款切換鍵的 accessibility identifier
        static func detailReceiptToggle(orderID: String) -> String {
            BLAccessibilityID.row("campaigns.detail.receiptToggle", key: orderID)
        }

        /// 結團結算的數值列，主要數值放各列的 accessibility value
        ///
        /// - Parameter kind: 結團結算摘要種類
        /// - Returns: 對應結算摘要列的 accessibility identifier
        static func detailSummary(_ kind: DetailSummary) -> String {
            option("campaigns.detail.summary", key: kind.rawValue)
        }
    }

    /// 開團新增與編輯表單
    enum CampaignEdit {

        /// 開團編輯表單的根 accessibility identifier
        static let root = "campaignEdit.root"

        /// 開團名稱欄位
        static let nameField = "campaignEdit.nameField"

        /// 開團日期選擇器
        static let openDatePicker = "campaignEdit.openDatePicker"

        /// 結單日期選擇器
        static let closeDatePicker = "campaignEdit.closeDatePicker"

        /// 開團提醒切換鈕
        static let reminderToggle = "campaignEdit.reminderToggle"

        /// 訂購提醒時間選擇器，提醒開啟時才出現
        static let reminderDatePicker = "campaignEdit.reminderDatePicker"

        /// 儲存開團按鈕
        static let saveButton = "campaignEdit.saveButton"

        /// 取消編輯按鈕
        static let cancelButton = "campaignEdit.cancelButton"
    }
}
