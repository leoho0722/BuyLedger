//
//  DependencyValues+BLUITestOverrides.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/24.
//

import Dependencies
import Foundation
import SwiftData

#if DEBUG

// MARK: - Internal Method

extension DependencyValues {

    /// 依 UI 測試設定一次覆寫全部依賴
    ///
    /// - Parameters:
    ///   - configuration: 由啟動參數解析出的 UI 測試設定
    ///   - container: 已注入種子的 UI 測試 ``ModelContainer``
    ///   - storeLocation: UI 測試 store 的隔離位置
    mutating func applyUITestOverrides(
        _ configuration: BLUITestConfiguration,
        container: ModelContainer,
        storeLocation: BuyLedgerDatabase.StoreLocation
    ) {
        // 沒有測試參數時不替換正式依賴
        guard configuration.isEnabled else {
            return
        }

        applyEnvironmentOverrides(configuration)
        let database = BuyLedgerDatabase(modelContainer: container, storeLocation: storeLocation)
        self.buyLedgerDatabase = database
        self.orderService = makeOrderService(configuration, database: database)
        applyCampaignOverrides(configuration, database: database)
        applyLookupOverrides(configuration, database: database)
        applySystemAccessOverrides(configuration)
        applyNetworkOverrides(configuration)
        applySettingsServiceOverride(configuration)
    }
}

// MARK: - Private Method

private extension DependencyValues {

    /// 固定時間、曆法、時區與 UUID，讓畫面內容與截圖跨機器一致
    ///
    /// - Parameter configuration: UI 測試設定
    mutating func applyEnvironmentOverrides(_ configuration: BLUITestConfiguration) {
        let utc = TimeZone.gmt
        // 固定 Gregorian／UTC，避免日期分組受執行環境影響
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utc

        self.date = .constant(configuration.referenceDate)
        self.calendar = calendar
        self.timeZone = utc
        self.uuid = .incrementing
    }

    /// 讓訂單 Service 指向 UI 測試資料庫，並依設定包裝讀取失敗
    ///
    /// - Parameters:
    ///   - configuration: UI 測試設定
    ///   - database: UI 測試使用的交易資料庫
    /// - Returns: 已套用載入失敗設定的訂單 Service
    func makeOrderService(
        _ configuration: BLUITestConfiguration,
        database: BuyLedgerDatabase
    ) -> OrderService {
        var orderService = withDependencies {
            $0.buyLedgerDatabase = database
        } operation: {
            OrderService.liveValue
        }
        let baseFetch = orderService.fetchOrders

        switch configuration.loadFailure {
        case .orders:
            orderService.fetchOrders = { () throws(PersistenceError) in
                throw BLUITestErrorFactory.persistenceLoadFailed(source: .orders)
            }

        case .ordersFirstReadOnly:
            let gate = BLUITestFirstReadGate()
            orderService.fetchOrders = { () throws(PersistenceError) in
                if gate.consumeFailure() {
                    throw BLUITestErrorFactory.persistenceLoadFailed(source: .orders)
                }
                return try await baseFetch()
            }

        case .none, .campaigns, .lookups:
            break
        }

        return orderService
    }

    /// 讓開團 Service 與提醒連結指向 UI 測試資料庫，並依設定包裝開團讀寫失敗
    ///
    /// - Parameters:
    ///   - configuration: UI 測試設定
    ///   - database: UI 測試使用的交易資料庫
    mutating func applyCampaignOverrides(
        _ configuration: BLUITestConfiguration,
        database: BuyLedgerDatabase
    ) {
        var campaignService = withDependencies {
            $0.buyLedgerDatabase = database
        } operation: {
            CampaignService.liveValue
        }

        if configuration.loadFailure == .campaigns {
            campaignService.fetchCampaigns = { () throws(PersistenceError) in
                throw BLUITestErrorFactory.persistenceLoadFailed(source: .campaigns)
            }
        }

        if configuration.shouldFailCampaignWrites {
            campaignService.saveCampaign = { _ throws(PersistenceError) in
                throw BLUITestErrorFactory.persistenceSaveFailed()
            }
            campaignService.removeCampaign = { _, _ throws(PersistenceError) in
                throw BLUITestErrorFactory.persistenceSaveFailed()
            }
            campaignService.renameCampaign = { _, _ throws(PersistenceError) in
                throw BLUITestErrorFactory.persistenceSaveFailed()
            }
        }

        // 提醒連結不受 `loadFailure` 影響：失敗情境要驗的是開團清單本身的錯誤畫面，
        // 故 `configuration.loadFailure == .campaigns` 時僅覆寫 `fetchCampaigns`，保留 live 的提醒操作
        self.campaignService = campaignService
    }

    /// 以替身取代照片、行事曆、本機驗證與系統設定
    ///
    /// - Parameter configuration: UI 測試設定
    mutating func applySystemAccessOverrides(_ configuration: BLUITestConfiguration) {
        self.photoService = BLUITestStubs.makePhotoService()
        self.calendarReminderService = BLUITestStubs.makeCalendarReminderService(
            access: configuration.calendarAccess
        )
        self.biometricAuthService = BLUITestStubs.makeBiometricAuthService(
            scenario: configuration.biometricScenario
        )
        self.openSettingsService = OpenSettingsService(
            open: {}
        )
    }

    /// 讓匯率與 AI 改回固定輸出，並封死底層 HTTP，確保測試全程不打網路
    ///
    /// - Parameter configuration: UI 測試設定
    mutating func applyNetworkOverrides(_ configuration: BLUITestConfiguration) {
        self.exchangeRateService = BLUITestStubs.makeExchangeRateService(
            referenceDate: configuration.referenceDate
        )
        self.aiSummaryService = BLUITestStubs.makeAISummaryService()
        // 兜底：上面兩個 Service 已不經過 HTTP，真的走到這裡代表有漏網的網路路徑
        self.httpClient = PreviewHTTPClient()
    }

    /// 將設定改存於記憶體，並依設定覆寫語言、預設幣別、月目標、AI 總結與 App 鎖定
    ///
    /// - Parameter configuration: UI 測試設定
    mutating func applySettingsServiceOverride(_ configuration: BLUITestConfiguration) {
        var snapshot = SettingsSnapshot.default

        // `language` 為 `nil` 代表不覆寫，沿用 `SettingsSnapshot` 的預設語言
        if let language = configuration.language {
            snapshot.language = AppLanguage(storedValue: language.rawValue)
        }

        if let code = configuration.defaultCurrencyCode {
            snapshot.defaultCurrency = CurrencyCode(rawValue: code)
        }

        if let goal = configuration.monthlyProfitGoalTWD {
            snapshot.monthlyProfitGoalTWD = Decimal(goal)
        }

        if configuration.shouldUseAISummary {
            snapshot.isAISummaryEnabled = true
        }

        if configuration.isAppLockEnabled {
            snapshot.isBiometricUnlockEnabled = true
        }

        self.settingsService = BLUITestSettingsStore.makeSettingsService(initial: snapshot)
    }
}

#endif
