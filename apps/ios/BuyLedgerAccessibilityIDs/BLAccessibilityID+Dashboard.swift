//
//  BLAccessibilityID+Dashboard.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/3.
//

// MARK: - Nested Types

extension BLAccessibilityID {

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

        /// 總覽頁標題的日期副標
        static let currentDateSubtitle = "dashboard.currentDateSubtitle"

        /// 近期訂單區塊的查看全部按鈕
        static let recentOrdersSeeAllButton = "dashboard.recentOrders.seeAllButton"

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

        /// KPI 卡容器
        ///
        /// - Parameter kpi: KPI 指標
        /// - Returns: 對應 KPI 卡的 accessibility identifier
        static func kpiTile(_ kpi: KPI) -> String {
            option("dashboard.kpiTile", key: kpi.rawValue)
        }

        /// 近期訂單列，以訂單編號識別
        ///
        /// - Parameter orderID: 訂單編號
        /// - Returns: 對應近期訂單列的 accessibility identifier
        static func recentOrderRow(orderID: String) -> String {
            row("dashboard.recentOrders.row", key: orderID)
        }
    }
}
