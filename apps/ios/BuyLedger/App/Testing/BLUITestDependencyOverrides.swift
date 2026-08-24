//
//  BLUITestDependencyOverrides.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/24.
//

import Dependencies
import Foundation
import SwiftData
import Synchronization
import UIKit

#if DEBUG

// MARK: - Internal Method

extension DependencyValues {
    
    /// 依 UI 測試設定一次覆寫全部依賴
    /// - Parameters:
    ///   - configuration: 由啟動參數解析出的 UI 測試設定
    ///   - container: 已注入種子的 in-memory ``ModelContainer``
    mutating func applyUITestOverrides(
        _ configuration: BLUITestConfiguration,
        container: ModelContainer
    ) {
        // 沒有測試參數時不替換正式依賴。
        guard configuration.isEnabled else {
            return
        }
        
        applyEnvironmentOverrides(configuration)
        applyOrderOverrides(configuration, container: container)
        applyCampaignOverrides(configuration, container: container)
        applyLookupOverrides(configuration, container: container)
        applySystemAccessOverrides(configuration)
        applyNetworkOverrides(configuration)
        applySettingsStorageOverride(configuration)
    }
}

// MARK: - Private Method

private extension DependencyValues {
    
    // MARK: 環境
    
    /// 固定時間、曆法、時區與 UUID，讓畫面內容與截圖跨機器一致
    /// - Parameter configuration: UI 測試設定
    mutating func applyEnvironmentOverrides(_ configuration: BLUITestConfiguration) {
        let utc = TimeZone(secondsFromGMT: 0) ?? .gmt
        // 固定 Gregorian／UTC，避免日期分組受執行環境影響。
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utc
        
        self.date = .constant(configuration.referenceDate)
        self.calendar = calendar
        self.timeZone = utc
        self.uuid = .incrementing
    }
    
    // MARK: 資料來源
    
    /// 訂單 repository 指向 in-memory container，並依設定包裝讀取失敗
    /// - Parameters:
    ///   - configuration: UI 測試設定
    ///   - container: in-memory ``ModelContainer``
    mutating func applyOrderOverrides(
        _ configuration: BLUITestConfiguration,
        container: ModelContainer
    ) {
        var repository = OrderRepository.live(container: container)
        let baseFetch = repository.fetchOrders
        
        switch configuration.loadFailure {
        case .orders:
            repository.fetchOrders = { () async throws(PersistenceError) -> [LedgerOrder] in
                throw BLUITestErrorFactory.persistenceLoadFailed(source: .orders)
            }
            
        case .ordersFirstReadOnly:
            let gate = BLUITestFirstReadGate()
            repository.fetchOrders = { () async throws(PersistenceError) -> [LedgerOrder] in
                if gate.consumeFailure() {
                    throw BLUITestErrorFactory.persistenceLoadFailed(source: .orders)
                }
                return try await baseFetch()
            }
            
        case .none, .campaigns, .lookups:
            break
        }
        
        self[OrderRepository.self] = repository
    }
    
    /// 開團主檔與提醒連結指向 in-memory container，並依設定包裝讀取失敗
    /// - Parameters:
    ///   - configuration: UI 測試設定
    ///   - container: in-memory ``ModelContainer``
    mutating func applyCampaignOverrides(
        _ configuration: BLUITestConfiguration,
        container: ModelContainer
    ) {
        var repository = CampaignRepository.live(container: container)
        
        if configuration.loadFailure == .campaigns {
            repository.fetchCampaigns = { () async throws(PersistenceError) -> [Campaign] in
                throw BLUITestErrorFactory.persistenceLoadFailed(source: .campaigns)
            }
        }
        
        self[CampaignRepository.self] = repository
        // 提醒連結不受 loadFailure 影響：失敗情境要驗的是開團清單本身的錯誤畫面
        self[CampaignReminderRepository.self] = CampaignReminderRepository.live(container: container)
    }
    
    /// 各主檔使用 in-memory container，並可注入讀取失敗
    /// - Parameters:
    ///   - configuration: UI 測試設定
    ///   - container: in-memory ``ModelContainer``
    mutating func applyLookupOverrides(
        _ configuration: BLUITestConfiguration,
        container: ModelContainer
    ) {
        let shouldFail = configuration.loadFailure == .lookups
        
        var orderSourceRepository = OrderSourceRepository.live(container: container)
        var categoryRepository = CategoryRepository.live(container: container)
        var paymentMethodRepository = PaymentMethodRepository.live(container: container)
        var reconciliationStatusRepository = ReconciliationStatusRepository.live(container: container)
        var currencyMetadataRepository = CurrencyMetadataRepository.live(
            container: container,
            client: BLUITestStubs.makeExchangeRateClient(
                referenceDate: configuration.referenceDate
            ),
            now: { configuration.referenceDate }
        )
        
        if shouldFail {
            orderSourceRepository.fetchOrderSources = { () async throws(PersistenceError) -> [String] in
                throw BLUITestErrorFactory.persistenceLoadFailed(source: .orderSources)
            }
            categoryRepository.fetchCategories = { () async throws(PersistenceError) -> [String] in
                throw BLUITestErrorFactory.persistenceLoadFailed(source: .categories)
            }
            paymentMethodRepository.fetchPaymentMethods = { () async throws(PersistenceError) -> [String] in
                throw BLUITestErrorFactory.persistenceLoadFailed(source: .paymentMethods)
            }
            paymentMethodRepository.fetchPaymentMethodInfos = { () async throws(PersistenceError) -> [PaymentMethodInfo] in
                throw BLUITestErrorFactory.persistenceLoadFailed(source: .paymentMethodInfos)
            }
            reconciliationStatusRepository.fetchReconciliationStatuses = { () async throws(PersistenceError) -> [String] in
                throw BLUITestErrorFactory.persistenceLoadFailed(
                    source: .reconciliationStatuses)
            }
            currencyMetadataRepository.fetchCodes = { () async throws(CurrencyMetadataRepositoryError) -> [CurrencyCode] in
                throw BLUITestErrorFactory.currencyMetadataLoadFailed(source: .currencyCodes)
            }
            // 刷新也失敗，避免載入失敗時寫入資料。
            currencyMetadataRepository.refreshIfStale = { (_: TimeInterval) async throws(CurrencyMetadataRepositoryError) -> Bool in
                throw BLUITestErrorFactory.currencyMetadataLoadFailed(source: .currencyCodes)
            }
            currencyMetadataRepository.forceRefresh = { () async throws(CurrencyMetadataRepositoryError) in
                throw BLUITestErrorFactory.currencyMetadataLoadFailed(source: .currencyCodes)
            }
        }
        
        self[OrderSourceRepository.self] = orderSourceRepository
        self[CategoryRepository.self] = categoryRepository
        self[PaymentMethodRepository.self] = paymentMethodRepository
        self[ReconciliationStatusRepository.self] = reconciliationStatusRepository
        self[CurrencyMetadataRepository.self] = currencyMetadataRepository
    }
    
    // MARK: 系統存取
    
    /// 以替身取代照片、行事曆、本機驗證與系統設定
    /// - Parameter configuration: UI 測試設定
    mutating func applySystemAccessOverrides(_ configuration: BLUITestConfiguration) {
        self[PhotoClient.self] = BLUITestStubs.makePhotoClient()
        self[CalendarReminderClient.self] = BLUITestStubs.makeCalendarReminderClient(
            access: configuration.calendarAccess
        )
        self[BiometricAuthClient.self] = BLUITestStubs.makeBiometricAuthClient(
            scenario: configuration.biometricScenario
        )
        self[OpenSettingsClient.self] = OpenSettingsClient(open: {})
    }
    
    // MARK: 網路
    
    /// 匯率與 AI 改回固定輸出，並封死底層 HTTP，確保測試全程不打網路
    /// - Parameter configuration: UI 測試設定
    mutating func applyNetworkOverrides(_ configuration: BLUITestConfiguration) {
        self[ExchangeRateClient.self] = BLUITestStubs.makeExchangeRateClient(
            referenceDate: configuration.referenceDate
        )
        self[OllamaClient.self] = BLUITestStubs.makeOllamaClient()
        self.appConfiguration = AppConfiguration(
            exchangeRateAPIKey: { BLUITestStubs.stubAPIKey },
            ollamaAPIKey: { BLUITestStubs.stubAPIKey }
        )
        // 兜底：上面兩個 client 已不經過 HTTP，真的走到這裡代表有漏網的網路路徑
        self.httpClient = HTTPClient(
            data: { (_: URLRequest) async throws(APIError) -> (Data, HTTPURLResponse) in
                throw APIError.transport(message: "UI 測試模式禁止發出網路請求")
            },
            stream: { (_: URLRequest) async throws(APIError) -> (URLSession.AsyncBytes, HTTPURLResponse) in
                throw APIError.transport(message: "UI 測試模式禁止發出網路請求")
            }
        )
    }
    
    // MARK: 設定
    
    /// 將設定改存於記憶體
    /// - Parameter configuration: UI 測試設定
    mutating func applySettingsStorageOverride(_ configuration: BLUITestConfiguration) {
        var snapshot = SettingsSnapshot.default
        
        // language 為 nil 代表不覆寫，沿用 SettingsSnapshot 的預設語言
        if let language = configuration.language {
            snapshot.language = AppLanguage(storedValue: language.rawValue)
        }
        
        if let code = configuration.defaultCurrencyCode {
            snapshot.defaultCurrency = CurrencyCode(rawValue: code)
        }
        
        if let goal = configuration.monthlyProfitGoalTwd {
            snapshot.monthlyProfitGoalTwd = Decimal(goal)
        }
        
        if configuration.useAiSummary {
            snapshot.useAiSummary = true
        }
        
        if configuration.appLockEnabled {
            snapshot.isBiometricUnlockEnabled = true
        }
        
        let store = BLUITestSettingsStore(initial: snapshot)
        self[SettingsStorage.self] = SettingsStorage(
            load: { store.load() },
            save: { store.save($0) }
        )
    }
}

/// UI 測試替身共用的固定資料與工廠
private enum BLUITestStubs {
    
    // MARK: - Static Properties
    
    /// 僅供替身通過 API key 檢查，不會送出請求
    nonisolated static let stubAPIKey = "ui-test-stub-key"
    
    /// 以 TWD 為基準的固定測試匯率 (非真實匯率，僅供畫面對照)
    nonisolated static let twdBasedRates: [CurrencyCode: Decimal] = [
        .twd: 1,
        .krw: Decimal(sign: .plus, exponent: -2, significand: 4386),
        .jpy: Decimal(sign: .plus, exponent: -2, significand: 475),
        .usd: Decimal(sign: .plus, exponent: -4, significand: 308),
        .cny: Decimal(sign: .plus, exponent: -3, significand: 224),
        CurrencyCode(rawValue: "EUR"): Decimal(sign: .plus, exponent: -4, significand: 285),
    ]
    
    /// 幣別主檔的固定測試清單，由 ``twdBasedRates`` 推導確保兩者不會錯開
    nonisolated static let stubSupportedCodes = twdBasedRates.keys.map(\.rawValue).sorted()
    
    /// 行事曆替身建立事件後回傳的固定識別碼
    nonisolated static let stubEventIdentifier = "ui-test-event-identifier"
    
    /// AI 總結替身的固定輸出，建立串流時一次全部 yield 完 (不模擬串流節奏)
    nonisolated static let aiSummaryChunks = [
        "## 商品明細總結\n\n",
        "本批訂單以 3C 配件為主，重點如下：\n\n",
        "- **熱門品項**：藍牙耳機 x3、保溫瓶 x2\n",
        "- **金額區間**：單價集中在 NT$300–1,200\n",
    ]
    
    /// 假影像的色盤：相鄰兩張顏色不同，縮圖可肉眼區分
    nonisolated static let photoPalette: [UIColor] = [
        .systemBlue, .systemPink, .systemGreen, .systemOrange,
    ]
    
    /// 假影像的邊長 (點)
    nonisolated static let photoSide: CGFloat = 240
}

// MARK: - Private Method

private extension BLUITestStubs {
    
    // MARK: 工廠
    
    /// 建立不打網路的匯率 client
    /// - Parameter referenceDate: 快照時間戳，沿用 UI 測試的固定「現在」
    /// - Returns: 回傳固定匯率與幣別清單的 client
    static func makeExchangeRateClient(referenceDate: Date) -> ExchangeRateClient {
        ExchangeRateClient(
            fetchLatest: { (base: CurrencyCode) async throws(APIError) -> FxRateSnapshot in
                // 固定表以 TWD 為基準，改用其他基準時整表除以該幣別的 TWD 匯率
                guard let baseRate = twdBasedRates[base], baseRate > 0 else {
                    throw BLUITestErrorFactory.unsupportedBase(base.rawValue)
                }
                return FxRateSnapshot(
                    date: referenceDate,
                    base: base,
                    rates: twdBasedRates.mapValues { $0 / baseRate }
                )
            },
            fetchSupportedCodes: { stubSupportedCodes }
        )
    }
    
    /// 建立回傳固定文字的 AI 總結 client
    /// - Returns: 固定段落一次吐完即結束的 ``OllamaClient``
    static func makeOllamaClient() -> OllamaClient {
        OllamaClient(
            streamSummary: { _, _, _ in
                AsyncThrowingStream<String, any Error> { continuation in
                    for chunk in aiSummaryChunks {
                        continuation.yield(chunk)
                    }
                    continuation.finish()
                }
            }
        )
    }
    
    /// 建立不開系統選擇器的照片 client
    /// - Returns: 依選取數量回傳純色 JPEG、空選取回空陣列的 ``PhotoClient``
    static func makePhotoClient() -> PhotoClient {
        let cache = BLUITestPhotoCache()
        
        return PhotoClient(
            importPhotos: { items in
                guard !items.isEmpty else {
                    return []
                }
                let photos = cache.resolvedPhotos { makePalettePhotos() }
                guard !photos.isEmpty else {
                    return []
                }
                return items.indices.map { photos[$0 % photos.count] }
            }
        )
    }
    
    /// 建立不彈出系統生物辨識提示的本機驗證 client
    /// - Parameter scenario: 要模擬的驗證情境
    /// - Returns: 固定回傳測試用的生物辨識 client
    static func makeBiometricAuthClient(scenario: BLUITestBiometricScenario) -> BiometricAuthClient {
        let result: BiometricAuthClient.AuthenticationResult = scenario == .success ? .success : .failure
        return BiometricAuthClient(
            isAvailable: { true },
            authenticate: { _ in result },
            biometryType: { .faceID }
        )
    }
    
    /// 建立不碰 EventKit 的行事曆 client
    /// - Parameter access: 要模擬的授權結果
    /// - Returns: 回傳固定結果的行事曆 client
    static func makeCalendarReminderClient(access: BLUITestCalendarAccess) -> CalendarReminderClient {
        // UI 測試只需模擬 granted 與 denied
        let resolvedAccess: CalendarReminderClient.AccessResult = access == .granted ? .granted : .denied
        
        return CalendarReminderClient(
            requestAccess: { resolvedAccess },
            addReminder: { _, _, _ in stubEventIdentifier },
            removeReminder: { _ in },
            reminderExists: { _ in true }
        )
    }
    
    // MARK: 假影像
    
    /// 依色盤繪出各一張純色 JPEG
    /// - Returns: 與色盤同長度的 JPEG data 陣列
    static func makePalettePhotos() -> [Data] {
        let size = CGSize(width: photoSide, height: photoSide)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return photoPalette.map { color in
            renderer.jpegData(withCompressionQuality: 0.8) { context in
                color.setFill()
                context.fill(CGRect(origin: .zero, size: size))
            }
        }
    }
}

/// 假影像的延後產生快取
private final class BLUITestPhotoCache: Sendable {
    
    // MARK: - Data Properties
    
    /// 已繪好的假影像；`nil` 代表還沒繪過
    let photos = Mutex<[Data]?>(nil)
}

// MARK: - Private Method

private extension BLUITestPhotoCache {
    
    /// 取出假影像，尚未繪製時先繪再快取
    /// - Parameter make: 實際繪圖的工廠
    /// - Returns: 快取中的假影像
    func resolvedPhotos(make: () -> [Data]) -> [Data] {
        photos.withLock { (stored: inout [Data]?) -> [Data] in
            if let existing = stored {
                return existing
            }
            let made = make()
            stored = made
            return made
        }
    }
}

/// UI 測試載入失敗的資料來源
private enum BLUITestLoadSource: String, Sendable {
    
    // MARK: - Cases
    
    /// 訂單資料
    case orders
    
    /// 開團資料
    case campaigns
    
    /// 訂單來源主檔
    case orderSources
    
    /// 商品類別主檔
    case categories
    
    /// 付款方式主檔
    case paymentMethods
    
    /// 付款方式詳細資料
    case paymentMethodInfos
    
    /// 對帳狀態主檔
    case reconciliationStatuses
    
    /// 支援幣別清單
    case currencyCodes
}

/// UI 測試注入用的錯誤工廠
private enum BLUITestErrorFactory {}

// MARK: - Private Method

private extension BLUITestErrorFactory {
    
    /// 產生指定資料來源的載入失敗訊息
    /// - Parameter source: 失敗的資料來源
    /// - Returns: 帶資料來源名稱的錯誤訊息
    static func loadFailureMessage(source: BLUITestLoadSource) -> String {
        "UI 測試注入的載入失敗 (\(source.rawValue))"
    }
    
    /// 產生持久化讀取失敗
    /// - Parameter source: 失敗的資料來源
    /// - Returns: 帶資料來源訊息的持久化讀取錯誤
    static func persistenceLoadFailed(source: BLUITestLoadSource) -> PersistenceError {
        .fetchFailed(message: loadFailureMessage(source: source))
    }
    
    /// 產生幣別 metadata repository 讀取失敗
    /// - Parameter source: 失敗的資料來源
    /// - Returns: 帶資料來源訊息的幣別 metadata repository 錯誤
    static func currencyMetadataLoadFailed(source: BLUITestLoadSource) -> CurrencyMetadataRepositoryError {
        .persistence(.storage(persistenceLoadFailed(source: source)))
    }
    
    /// 產生「匯率替身沒有這個基準幣別」的錯誤
    /// - Parameter base: 被要求的基準幣別代碼
    /// - Returns: 描述基準幣別不支援的 ``APIError``
    static func unsupportedBase(_ base: String) -> APIError {
        .apiError(code: "unsupported-base-\(base)")
    }
}

/// 只讓第一次讀取失敗的閘門
private final class BLUITestFirstReadGate: Sendable {
    
    // MARK: - Data Properties
    
    /// 是否尚未觸發第一次讀取失敗
    ///
    /// 以 `Mutex` 保護旗標，確保並行讀取只會失敗一次
    let failurePending = Mutex(true)
}

// MARK: - Private Method

private extension BLUITestFirstReadGate {
    
    /// 消耗一次失敗額度
    /// - Returns: 首次呼叫回 `true` (該次應失敗)，之後一律回 `false`
    func consumeFailure() -> Bool {
        failurePending.withLock { pending in
            let shouldFail = pending
            pending = false
            return shouldFail
        }
    }
}

/// 以記憶體保存設定快照的容器
private final class BLUITestSettingsStore: Sendable {
    
    // MARK: - Data Properties
    
    /// 目前的設定快照
    ///
    /// ``SettingsStorage/load`` 是同步介面，因此以 `Mutex` 保護快照
    let snapshot: Mutex<SettingsSnapshot>
    
    // MARK: - Init
    
    /// 以初始快照建立容器
    /// - Parameter initial: 套用啟動參數後的初始設定
    init(initial: SettingsSnapshot) {
        snapshot = Mutex(initial)
    }
}

// MARK: - Private Method

private extension BLUITestSettingsStore {
    
    /// 讀出目前設定
    /// - Returns: 目前的設定快照
    func load() -> SettingsSnapshot {
        snapshot.withLock { $0 }
    }
    
    /// 覆寫目前設定
    /// - Parameter newSnapshot: 要寫入的設定快照
    func save(_ newSnapshot: SettingsSnapshot) {
        snapshot.withLock { $0 = newSnapshot }
    }
}

#endif
