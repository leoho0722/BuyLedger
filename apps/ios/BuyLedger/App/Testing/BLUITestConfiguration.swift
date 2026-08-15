//
//  BLUITestConfiguration.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/24.
//

import Foundation

#if DEBUG

/// UI 測試模式的啟動設定，由 App 的啟動參數解析而來
struct BLUITestConfiguration: Equatable, Sendable {
    
    // MARK: - Data Properties
    
    /// 啟動參數是否帶 `-BLUITest`；為 `false` 時整套 UI 測試掛鉤都不生效
    let isEnabled: Bool
    
    /// 要注入資料庫的種子情境 (`-BLUITestSeed`)，預設 `.empty`
    let seedProfile: BLUITestSeedProfile
    
    /// 覆寫「現在」的參考時間 (`-BLUITestNow`)，預設 ``defaultReferenceDate``
    let referenceDate: Date
    
    /// 覆寫 App 內語言 (`-BLUITestLanguage`)；`nil` 代表不覆寫，沿用預設語言
    let language: BLUITestLanguage?
    
    /// 行事曆權限的模擬結果 (`-BLUITestCalendarAccess`)，預設 `.granted`
    let calendarAccess: BLUITestCalendarAccess
    
    /// 要模擬的載入失敗情境 (`-BLUITestLoadFailure`)，預設 `.none`
    let loadFailure: BLUITestLoadFailure
    
    /// 覆寫預設幣別的三碼代號 (`-BLUITestDefaultCurrency`)；`nil` 代表不覆寫
    let defaultCurrencyCode: String?
    
    /// 覆寫每月利潤目標 (`-BLUITestMonthlyGoal`，單位 TWD)；`nil` 代表不覆寫
    let monthlyProfitGoalTwd: Int?
    
    /// 是否使用 AI 商品明細替身
    let useAiSummary: Bool
    
    /// 是否在啟動時開啟帳本保護 (`-BLUITestAppLockEnabled`)
    let appLockEnabled: Bool
    
    /// UI 測試用的生物辨識結果；預設成功
    let biometricOutcome: BLUITestBiometricOutcome
    
    // MARK: - Static Properties
    
    /// 由啟動參數建立的設定
    static let current = BLUITestConfiguration(arguments: ProcessInfo.processInfo.arguments)
    
    /// 未指定 `-BLUITestNow` 時的參考時間：2026-04-30T00:00:00Z
    static let defaultReferenceDate: Date = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let components = DateComponents(
            year: 2026, month: 4, day: 30, hour: 0, minute: 0, second: 0)
        guard let date = calendar.date(from: components) else {
            // 固定日期無法建立表示程式前提已失效。
            preconditionFailure("無法建構預設參考時間 2026-04-30T00:00:00Z")
        }
        return date
    }()
    
    // MARK: - Init
    
    /// 從啟動參數陣列解析設定
    /// - Parameter arguments: App 啟動參數
    init(arguments: [String]) {
        isEnabled = arguments.contains("-BLUITest")
        seedProfile = Self.option(for: "-BLUITestSeed", in: arguments) ?? .empty
        referenceDate = Self.referenceDate(in: arguments)
        language = Self.option(for: "-BLUITestLanguage", in: arguments)
        calendarAccess = Self.option(for: "-BLUITestCalendarAccess", in: arguments) ?? .granted
        loadFailure =
        Self.option(for: "-BLUITestLoadFailure", in: arguments) ?? BLUITestLoadFailure.none
        defaultCurrencyCode = Self.currencyCode(in: arguments)
        monthlyProfitGoalTwd = Self.monthlyProfitGoal(in: arguments)
        useAiSummary = arguments.contains("-BLUITestAiSummary")
        appLockEnabled = arguments.contains("-BLUITestAppLockEnabled")
        biometricOutcome =
        Self.option(for: "-BLUITestBiometricOutcome", in: arguments) ?? .success
    }
}

// MARK: - Private Method

private extension BLUITestConfiguration {
    
    // MARK: 逐欄位解析
    
    /// 解析 String rawValue 列舉旗標；無效時回傳 `nil`
    /// - Parameters:
    ///   - flag: 要解析的旗標名 (如 `-BLUITestSeed`)
    ///   - arguments: App 啟動參數
    /// - Returns: 解析出的列舉值；缺值或對不到 case 時回 `nil`
    static func option<Option: RawRepresentable>(
        for flag: String,
        in arguments: [String]
    ) -> Option? where Option.RawValue == String {
        guard let raw = value(for: flag, in: arguments) else {
            return nil
        }
        guard let option = Option(rawValue: raw) else {
            warn("\(flag) 的值「\(raw)」無法辨識，改用預設值")
            return nil
        }
        return option
    }
    
    /// 解析 `-BLUITestNow`，失敗時退回 ``defaultReferenceDate``
    /// - Parameter arguments: App 啟動參數
    /// - Returns: 解析出的參考時間；缺值或無法解析時回 ``defaultReferenceDate``
    static func referenceDate(in arguments: [String]) -> Date {
        guard let raw = value(for: "-BLUITestNow", in: arguments) else {
            return defaultReferenceDate
        }
        guard let date = iso8601Date(from: raw) else {
            warn("-BLUITestNow 的值「\(raw)」不是可解析的 ISO8601 時間，改用預設參考時間")
            return defaultReferenceDate
        }
        return date
    }
    
    /// 解析 `-BLUITestDefaultCurrency`；非三碼英文字母一律視為無效
    /// - Parameter arguments: App 啟動參數
    /// - Returns: 大寫的三碼幣別代號；缺值或格式不符時回 `nil`
    static func currencyCode(in arguments: [String]) -> String? {
        guard let raw = value(for: "-BLUITestDefaultCurrency", in: arguments) else {
            return nil
        }
        let code = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let isThreeLetters = code.count == 3 && code.allSatisfy { $0.isASCII && $0.isLetter }
        guard isThreeLetters else {
            warn("-BLUITestDefaultCurrency 的值「\(raw)」不是三碼幣別，忽略此旗標")
            return nil
        }
        return code
    }
    
    /// 解析月獲利目標；無效或負數時回傳 `nil`
    /// - Parameter arguments: App 啟動參數
    /// - Returns: 每月利潤目標 (TWD)；缺值、非整數或負數時回 `nil`
    static func monthlyProfitGoal(in arguments: [String]) -> Int? {
        guard let raw = value(for: "-BLUITestMonthlyGoal", in: arguments) else {
            return nil
        }
        guard let goal = Int(raw.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            warn("-BLUITestMonthlyGoal 的值「\(raw)」不是整數，忽略此旗標")
            return nil
        }
        guard goal >= 0 else {
            warn("-BLUITestMonthlyGoal 的值「\(raw)」是負數，忽略此旗標")
            return nil
        }
        return goal
    }
    
    // MARK: 共用工具
    
    /// 取得旗標後的值；重複旗標採最後一次
    /// - Parameters:
    ///   - flag: 要取值的旗標名
    ///   - arguments: App 啟動參數
    /// - Returns: 旗標後面接的值；缺值或後面接的是另一個旗標時回 `nil`
    static func value(for flag: String, in arguments: [String]) -> String? {
        let flagIndices = arguments.indices.filter { arguments[$0] == flag }
        guard let flagIndex = flagIndices.last else {
            return nil
        }
        if flagIndices.count > 1 {
            warn("\(flag) 出現 \(flagIndices.count) 次，採用最後一次的值")
        }
        let valueIndex = arguments.index(after: flagIndex)
        guard valueIndex < arguments.endIndex else {
            warn("\(flag) 後面沒有接值，改用預設值")
            return nil
        }
        let value = arguments[valueIndex]
        guard !isFlagLike(value) else {
            warn("\(flag) 後面接的是另一個旗標「\(value)」，視為缺值、改用預設值")
            return nil
        }
        return value
    }
    
    /// 判斷字串是否為旗標：以 `-` 開頭且不是數值 (負數要當成合法的值放行)
    /// - Parameter value: 待判斷的字串
    /// - Returns: 是旗標回 `true`；負數等可當值的字串回 `false`
    static func isFlagLike(_ value: String) -> Bool {
        guard value.hasPrefix("-") else {
            return false
        }
        return Double(value) == nil
    }
    
    /// 解析 ISO8601 時間或日期
    /// - Parameter raw: 待解析的字串
    /// - Returns: 解析出的 `Date`；三種格式都對不上時回 `nil`
    static func iso8601Date(from raw: String) -> Date? {
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        if let date = plain.date(from: raw) {
            return date
        }
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: raw) {
            return date
        }
        let fullDate = ISO8601DateFormatter()
        fullDate.formatOptions = [.withFullDate]
        fullDate.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return fullDate.date(from: raw)
    }
    
    /// 印出統一前綴的警告，方便從測試 log 撈出參數問題
    /// - Parameter message: 警告內容 (不含前綴)
    static func warn(_ message: String) {
        print("[BuyLedger][UITest] \(message)")
    }
}

/// UI 測試要覆寫的 App 內語言
enum BLUITestLanguage: String, Equatable, Sendable {
    
    // MARK: - Cases
    
    /// 正體中文
    case traditionalChinese
    
    /// 英文
    case english
}

/// UI 測試要模擬的行事曆權限結果
enum BLUITestCalendarAccess: String, Equatable, Sendable {
    
    // MARK: - Cases
    
    /// 授予完整權限，提醒可正常新增與移除
    case granted
    
    /// 拒絕權限，用於驗證權限被拒的提示路徑
    case denied
}

/// UI 測試要模擬的本機驗證結果
enum BLUITestBiometricOutcome: String, Equatable, Sendable {
    
    // MARK: - Cases
    
    /// 驗證一律成功
    case success
    
    /// 驗證一律失敗
    case failure
}

/// UI 測試要模擬的載入失敗情境
enum BLUITestLoadFailure: String, Equatable, Sendable {
    
    // MARK: - Cases
    
    /// 不模擬失敗
    case none
    
    /// 訂單載入每次都失敗
    case orders
    
    /// 訂單只有第一次讀取失敗，重試即成功
    case ordersFirstReadOnly
    
    /// 開團載入失敗
    case campaigns
    
    /// 主檔載入失敗
    case lookups
}

#endif
