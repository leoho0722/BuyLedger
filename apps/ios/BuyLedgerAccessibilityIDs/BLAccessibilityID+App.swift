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

        /// 分頁項目，目前只有 iPad 側邊欄的分頁列吃得到
        ///
        /// - Parameter tab: 主導覽分頁
        /// - Returns: 對應分頁的 accessibility identifier
        static func tab(_ tab: Tab) -> String {
            option("root.tab", key: tab.rawValue)
        }
    }
}
