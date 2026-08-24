//
//  LaunchOptions.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import Foundation

/// 描述一次 App 啟動的前置條件，並序列化成 App 端 harness 認得的啟動參數
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

    /// App 鎖定是否於啟動時已開啟，開啟時鎖定相關測試不必先走一遍設定頁
    var appLockEnabled: Bool = false

    /// 本機驗證替身的情境
    var biometricScenario: BiometricScenario = .success

    /// UI 測試資料庫的儲存方式
    var persistenceMode: PersistenceMode = .inMemory

    /// 是否在啟動時清除 persistent UI test store；僅對 persistent 有效
    var resetPersistentStore = false

    // MARK: - Static Properties

    /// 空資料庫 + 預設語言的最小啟動條件
    static let `default` = LaunchOptions()

    // MARK: - Computed Properties

    /// 序列化成 `XCUIApplication.launchArguments`
    /// - Returns: 傳給受測 App 的啟動參數
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
        if appLockEnabled {
            arguments.append("-BLUITestAppLockEnabled")
        }
        arguments += ["-BLUITestBiometricScenario", biometricScenario.rawValue]
        if persistenceMode != .inMemory {
            arguments += ["-BLUITestPersistence", persistenceMode.rawValue]
        }
        if resetPersistentStore {
            arguments.append("-BLUITestResetPersistentStore")
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

        /// 一筆使用信用卡且尚未標記貨到付款的訂單，供回溯重算驗收
        case paymentMethodCorrection

        /// 2 筆來源訂單與 1 筆合併結果，供營收歸屬跨畫面一致性驗收
        case revenueAttribution

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

    /// 本機驗證替身的情境，rawValue 對齊 App 端 `BLUITestBiometricScenario`
    enum BiometricScenario: String {

        /// 驗證一律成功
        case success

        /// 驗證一律失敗
        case failure
    }

    /// UI 測試資料庫的儲存方式
    enum PersistenceMode: String {

        /// 每次啟動建立新的記憶體資料庫
        case inMemory

        /// 使用可跨 App 重啟讀取的本機資料庫
        case persistent
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
    /// - Parameter date: 要序列化的日期
    /// - Returns: ISO8601 格式的 UTC 字串
    static func iso8601String(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return formatter.string(from: date)
    }
}
