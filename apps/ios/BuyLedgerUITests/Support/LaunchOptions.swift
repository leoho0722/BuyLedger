//
//  LaunchOptions.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import Foundation

/// 描述一次 App 啟動的前置條件，並序列化成 App 端 harness 認得的啟動參數
///
/// 測試只宣告要什麼狀態 (資料、語言、時間、外部相依行為)，序列化細節收在這裡；
/// 參數名稱必須與 App 端 `BLUITestConfiguration` 的解析逐字對齊，改一邊要同步改另一邊
struct LaunchOptions {

    // MARK: - Data Properties

    /// 要注入的種子資料組合
    var seed: SeedProfile = .empty

    /// 覆寫的參考時間，`nil` 代表沿用 App 端預設 (2026-04-30T00:00:00Z)
    var referenceDate: Date?

    /// 覆寫的 App 內語言，`nil` 代表沿用預設語言 (正體中文)
    var language: Language?

    /// 行事曆權限的模擬結果
    var calendarAccess: CalendarAccess = .granted

    /// 要模擬的載入失敗情境
    var loadFailure: LoadFailure = .none

    /// 覆寫的預設幣別三碼代號，`nil` 代表沿用預設
    var defaultCurrencyCode: String?

    /// 覆寫的每月利潤目標 (TWD)，`nil` 代表沿用預設
    var monthlyProfitGoalTwd: Int?

    /// 是否開啟 AI 商品明細總結，開啟後 AI 走固定輸出的替身
    var useAiSummary: Bool = false

    // MARK: - Static Properties

    /// 空資料庫 + 預設語言的最小啟動條件
    static let `default` = LaunchOptions()

    // MARK: - Computed Properties

    /// 序列化成 `XCUIApplication.launchArguments`
    ///
    /// 一律帶 `-BLUITest` 開啟測試模式，其餘旗標只在對應欄位有值時加入
    var launchArguments: [String] {
        var arguments = ["-BLUITest", "-BLUITestSeed", seed.rawValue]

        if let referenceDate {
            arguments += ["-BLUITestNow", Self.iso8601String(from: referenceDate)]
        }
        if let language {
            arguments += ["-BLUITestLanguage", language.rawValue]
        }
        arguments += ["-BLUITestCalendarAccess", calendarAccess.rawValue]
        arguments += ["-BLUITestLoadFailure", loadFailure.rawValue]
        if let defaultCurrencyCode {
            arguments += ["-BLUITestDefaultCurrency", defaultCurrencyCode]
        }
        if let monthlyProfitGoalTwd {
            arguments += ["-BLUITestMonthlyGoal", String(monthlyProfitGoalTwd)]
        }
        if useAiSummary {
            arguments.append("-BLUITestAiSummary")
        }

        return arguments
    }
}

// MARK: - Nested Types

extension LaunchOptions {

    /// 種子資料組合，rawValue 對齊 App 端 `BLUITestSeedProfile`
    enum SeedProfile: String {

        /// 完全空的資料庫
        case empty

        /// 只有主檔 (訂單來源、商品類別、付款方式、對帳狀態)
        case lookupsOnly

        /// 主檔加 3 筆訂單，日期涵蓋今天、昨天、七天前
        case minimalOrders

        /// 主檔加完整訂單集合，涵蓋多種狀態
        case fullOrders

        /// 完整訂單再加已指派開團的訂單
        case campaignsWithOrders

        /// 同客戶同幣別的可合併候選訂單
        case mergeCandidates

        /// 一筆帶滿張照片的訂單
        case photos

        /// 多位客戶且金額落差明顯，供排行斷言
        case customerRanking

        /// 橫跨十二個月、每月至少一筆，供走勢與熱力圖斷言
        case insightsRange
    }

    /// App 內語言，rawValue 對齊 App 端 `BLUITestLanguage`
    enum Language: String {

        /// 正體中文
        case traditionalChinese

        /// 英文
        case english
    }

    /// 行事曆權限的模擬結果，rawValue 對齊 App 端 `BLUITestCalendarAccess`
    enum CalendarAccess: String {

        /// 授予完整權限
        case granted

        /// 拒絕權限
        case denied
    }

    /// 載入失敗情境，rawValue 對齊 App 端 `BLUITestLoadFailure`
    enum LoadFailure: String {

        /// 不模擬失敗
        case none

        /// 訂單載入每次都失敗
        case orders

        /// 訂單只有第一次讀取失敗
        case ordersFirstReadOnly

        /// 開團載入失敗
        case campaigns

        /// 主檔載入失敗
        case lookups
    }
}

// MARK: - Private Method

private extension LaunchOptions {

    /// 把參考時間序列化成 App 端解析採用的 ISO8601 字串
    ///
    /// `ISO8601DateFormatter` 非 `Sendable`，不能當 static 常數共用，故每次呼叫時建立 (成本低)
    /// - Parameter date: 參考時間
    /// - Returns: UTC 的 ISO8601 字串
    static func iso8601String(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return formatter.string(from: date)
    }
}
