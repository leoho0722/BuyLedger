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
    ///
    /// 由 ``BLUITestHarness/prepareIfNeeded()`` 在 `prepareDependencies` 內呼叫，因此全程同步、不可 await
    ///
    /// 覆寫後行事曆、系統設定與網路都走替身，畫面所見一律來自 in-memory 種子與固定值；
    /// 相簿選取器 (`PhotosPicker`) 仍是 view 直接呈現的系統 UI，替身只接管選取後的匯入解碼
    /// - Parameters:
    ///   - configuration: 由啟動參數解析出的 UI 測試設定
    ///   - container: 已注入種子的 in-memory ``ModelContainer``
    mutating func applyUITestOverrides(_ configuration: BLUITestConfiguration, container: ModelContainer) {
        // 未帶 -BLUITest 時直接不動任何依賴：誤呼叫不該把正式 App 的資料來源整組換掉
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
        // 曆法與時區都釘 UTC：種子資料以 UTC 推導日期，日期界線與月份分組不隨執行機器時區漂移
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
    mutating func applyOrderOverrides(_ configuration: BLUITestConfiguration, container: ModelContainer) {
        var repository = OrderRepository.live(container: container)
        let baseFetch = repository.fetchOrders

        switch configuration.loadFailure {
        case .orders:
            repository.fetchOrders = {
                throw BLUITestErrorFactory.loadFailed(source: "orders")
            }

        case .ordersFirstReadOnly:
            let gate = BLUITestFirstReadGate()
            repository.fetchOrders = {
                if gate.consumeFailure() {
                    throw BLUITestErrorFactory.loadFailed(source: "orders")
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
    mutating func applyCampaignOverrides(_ configuration: BLUITestConfiguration, container: ModelContainer) {
        var repository = CampaignRepository.live(container: container)

        if configuration.loadFailure == .campaigns {
            repository.fetchCampaigns = {
                throw BLUITestErrorFactory.loadFailed(source: "campaigns")
            }
        }

        self[CampaignRepository.self] = repository
        // 提醒連結不受 loadFailure 影響：失敗情境要驗的是開團清單本身的錯誤畫面
        self[CampaignReminderRepository.self] = CampaignReminderRepository.live(container: container)
    }

    /// 各主檔 (來源／類別／付款方式／對帳狀態／幣別) 指向 in-memory container，並依設定包裝讀取失敗
    /// - Parameters:
    ///   - configuration: UI 測試設定
    ///   - container: in-memory ``ModelContainer``
    mutating func applyLookupOverrides(_ configuration: BLUITestConfiguration, container: ModelContainer) {
        let shouldFail = configuration.loadFailure == .lookups

        var orderSourceRepository = OrderSourceRepository.live(container: container)
        var categoryRepository = CategoryRepository.live(container: container)
        var paymentMethodRepository = PaymentMethodRepository.live(container: container)
        var reconciliationStatusRepository = ReconciliationStatusRepository.live(container: container)
        var currencyMetadataRepository = CurrencyMetadataRepository.live(
            container: container,
            client: BLUITestStubs.makeExchangeRateClient(referenceDate: configuration.referenceDate),
            now: { configuration.referenceDate }
        )

        if shouldFail {
            orderSourceRepository.fetchOrderSources = {
                throw BLUITestErrorFactory.loadFailed(source: "orderSources")
            }
            categoryRepository.fetchCategories = {
                throw BLUITestErrorFactory.loadFailed(source: "categories")
            }
            paymentMethodRepository.fetchPaymentMethods = {
                throw BLUITestErrorFactory.loadFailed(source: "paymentMethods")
            }
            paymentMethodRepository.fetchPaymentMethodInfos = {
                throw BLUITestErrorFactory.loadFailed(source: "paymentMethodInfos")
            }
            reconciliationStatusRepository.fetchReconciliationStatuses = {
                throw BLUITestErrorFactory.loadFailed(source: "reconciliationStatuses")
            }
            currencyMetadataRepository.fetchCodes = {
                throw BLUITestErrorFactory.loadFailed(source: "currencyCodes")
            }
            // 刷新也要一起失敗：否則啟動時的 TTL 刷新會寫入代碼，資料庫狀態與「主檔載入失敗」的畫面語意相反
            currencyMetadataRepository.refreshIfStale = { _ in
                throw BLUITestErrorFactory.loadFailed(source: "currencyCodes")
            }
            currencyMetadataRepository.forceRefresh = {
                throw BLUITestErrorFactory.loadFailed(source: "currencyCodes")
            }
        }

        self[OrderSourceRepository.self] = orderSourceRepository
        self[CategoryRepository.self] = categoryRepository
        self[PaymentMethodRepository.self] = paymentMethodRepository
        self[ReconciliationStatusRepository.self] = reconciliationStatusRepository
        self[CurrencyMetadataRepository.self] = currencyMetadataRepository
    }

    // MARK: 系統存取

    /// 照片匯入、行事曆與系統設定改走不觸碰系統的替身，避免測試被系統彈窗攔截
    /// - Parameter configuration: UI 測試設定
    mutating func applySystemAccessOverrides(_ configuration: BLUITestConfiguration) {
        self[PhotoClient.self] = BLUITestStubs.makePhotoClient()
        self[CalendarReminderClient.self] = BLUITestStubs.makeCalendarReminderClient(
            access: configuration.calendarAccess
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
            data: { _ in
                throw APIError.transport(message: "UI 測試模式禁止發出網路請求")
            },
            stream: { _ in
                throw APIError.transport(message: "UI 測試模式禁止發出網路請求")
            }
        )
    }

    // MARK: 設定

    /// 設定改存記憶體，初始值套用啟動參數指定的語言、預設幣別與月獲利目標
    ///
    /// 記憶體儲存代表設定不跨啟動保留，「改設定後重啟仍在」這類持久化行為無法用 UI 測試驗證
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

    /// 替身用的假 API key：只為讓「未設定 key」的擋門不誤擋，實際不會送出任何請求
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
    nonisolated static let photoPalette: [UIColor] = [.systemBlue, .systemPink, .systemGreen, .systemOrange]

    /// 假影像的邊長 (點)
    nonisolated static let photoSide: CGFloat = 240
}

// MARK: - Private Method

private extension BLUITestStubs {

    // MARK: 工廠

    /// 建立不打網路的匯率 client
    /// - Parameter referenceDate: 快照時間戳，沿用 UI 測試的固定「現在」
    /// - Returns: 依基準幣別換算固定匯率、並回固定幣別清單的 ``ExchangeRateClient``
    static func makeExchangeRateClient(referenceDate: Date) -> ExchangeRateClient {
        ExchangeRateClient(
            fetchLatest: { base in
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
                AsyncThrowingStream { continuation in
                    for chunk in aiSummaryChunks {
                        continuation.yield(chunk)
                    }
                    continuation.finish()
                }
            }
        )
    }

    /// 建立不開系統選擇器的照片 client
    ///
    /// 假影像延後到首次匯入才繪並快取，啟動路徑不付主執行緒繪圖成本
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

    /// 建立不碰 EventKit 的行事曆 client
    /// - Parameter access: 要模擬的授權結果
    /// - Returns: 授權依設定、建立回固定識別碼、查詢一律存在的 ``CalendarReminderClient``
    static func makeCalendarReminderClient(access: BLUITestCalendarAccess) -> CalendarReminderClient {
        let isGranted = access == .granted

        return CalendarReminderClient(
            requestAccess: { isGranted },
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
///
/// 覆寫依賴時不繪圖，首次匯入才付繪圖成本；`Mutex` 不可被 escaping closure 捕捉，故包一層 class 持有
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

/// UI 測試注入用的錯誤工廠
///
/// 本身不是 `Error` 型別、也沒有任何 case，只是產生 `NSError` 的命名空間，不能拿來 `catch`
private enum BLUITestErrorFactory {

    // MARK: - Static Properties

    /// 錯誤網域，方便在 log 中辨識來源
    nonisolated static let domain = "com.buyledger.uitest"

    /// 載入失敗的錯誤碼
    nonisolated static let loadFailedCode = 1

    /// 匯率替身不支援該基準幣別的錯誤碼
    nonisolated static let unsupportedBaseCode = 2
}

// MARK: - Private Method

private extension BLUITestErrorFactory {

    /// 產生指定資料來源的載入失敗錯誤
    ///
    /// 資料層無共用錯誤型別，改用 `NSError` 帶可讀訊息
    /// - Parameter source: 失敗的資料來源名稱，寫進訊息供除錯辨識
    /// - Returns: 帶描述文字的 `NSError`
    static func loadFailed(source: String) -> NSError {
        NSError(
            domain: domain,
            code: loadFailedCode,
            userInfo: [NSLocalizedDescriptionKey: "UI 測試注入的載入失敗 (\(source))"]
        )
    }

    /// 產生「匯率替身沒有這個基準幣別」的錯誤
    /// - Parameter base: 被要求的基準幣別代碼
    /// - Returns: 帶描述文字的 `NSError`
    static func unsupportedBase(_ base: String) -> NSError {
        NSError(
            domain: domain,
            code: unsupportedBaseCode,
            userInfo: [
                NSLocalizedDescriptionKey: "UI 測試的匯率替身沒有基準幣別 \(base)，請加進固定匯率表",
            ]
        )
    }
}

/// 只讓第一次讀取失敗的閘門
///
/// Swift 6 下不可用可變全域變數，故以 `Mutex` 保護旗標
private final class BLUITestFirstReadGate: Sendable {

    // MARK: - Data Properties

    /// 尚未用掉那一次失敗額度時為 `true`
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
///
/// ``SettingsStorage/load`` 是同步介面，actor 不適用，故以 `Mutex` 保護
private final class BLUITestSettingsStore: Sendable {

    // MARK: - Data Properties

    /// 目前的設定快照
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
