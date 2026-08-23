//
//  AppLogger.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/8/23.
//

import Foundation
import OSLog

/// BuyLedger 共用的 OSLog factory
enum AppLogger {

    // MARK: - Nested Types

    /// App 目前使用的日誌分類
    enum Category: String {

        /// SwiftData 持久化層
        case persistence = "Persistence"

        /// AI 商品明細總結功能
        case aiSummary = "AISummary"
    }

    // MARK: - Static Properties

    /// App bundle identifier 作為統一 subsystem；無法取得時使用模組名稱
    private static var subsystem: String {
        Bundle.main.bundleIdentifier ?? "BuyLedger"
    }

    /// 持久化層日誌
    static var persistence: Logger {
        Logger(subsystem: subsystem, category: Category.persistence.rawValue)
    }

    /// AI 商品明細總結日誌
    static var aiSummary: Logger {
        Logger(subsystem: subsystem, category: Category.aiSummary.rawValue)
    }
}
