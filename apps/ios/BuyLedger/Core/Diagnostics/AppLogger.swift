//
//  AppLogger.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/8/23.
//

import Foundation
import OSLog

/// 建立 BuyLedger 共用的 OSLog 日誌分類
enum AppLogger {

    // MARK: - Nested Types

    /// App 目前使用的日誌分類
    enum Category: String {

        /// SwiftData 持久化層
        case persistence = "Persistence"

        /// AI 推論功能
        case inference = "Inference"
    }

    // MARK: - Computed Properties

    /// App bundle identifier 作為統一 subsystem；無法取得時使用模組名稱
    private static var subsystem: String {
        Bundle.main.bundleIdentifier ?? "BuyLedger"
    }

    /// 持久化層日誌
    static var persistence: Logger {
        Logger(subsystem: subsystem, category: Category.persistence.rawValue)
    }

    /// AI 推論日誌
    static var inference: Logger {
        Logger(subsystem: subsystem, category: Category.inference.rawValue)
    }
}
