//
//  BLAccessibilityID+App.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/3.
//

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

        /// 生物辨識失敗提示文字
        static let failedMessage = "appLock.failedMessage"
    }

    /// 根導覽 (iPhone 分頁列與 iPad 側邊欄)
    enum Root {

        /// 根導覽側邊欄
        static let sidebar = "root.sidebar"

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

        /// 分頁項目，目前只有 iPad 側邊欄的分頁列吃得到
        ///
        /// - Parameter tab: 主導覽分頁
        /// - Returns: 對應分頁的 accessibility identifier
        static func tab(_ tab: Tab) -> String {
            option("root.tab", key: tab.rawValue)
        }

        /// 側邊欄智慧分組列
        ///
        /// - Parameter group: 側邊欄智慧分組
        /// - Returns: 對應智慧分組列的 accessibility identifier
        static func smartGroup(_ group: SmartGroup) -> String {
            option("root.sidebar.smartGroup", key: group.rawValue)
        }
    }
}
