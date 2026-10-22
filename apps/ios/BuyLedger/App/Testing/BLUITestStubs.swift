//
//  BLUITestStubs.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

#if DEBUG

import UIKit

/// UI 測試替身共用的固定資料與工廠
enum BLUITestStubs {

    // MARK: - Properties

    /// 僅供替身通過 API key 檢查，不會送出請求
    static let stubAPIKey = "ui-test-stub-key"

    /// 以 TWD 為基準的固定測試匯率 (非真實匯率，僅供畫面對照)
    private static let twdBasedRates: [CurrencyCode: Decimal] = [
        .twd: 1,
        .krw: Decimal(sign: .plus, exponent: -2, significand: 4386),
        .jpy: Decimal(sign: .plus, exponent: -2, significand: 475),
        .usd: Decimal(sign: .plus, exponent: -4, significand: 308),
        .cny: Decimal(sign: .plus, exponent: -3, significand: 224),
        CurrencyCode(rawValue: "EUR"): Decimal(sign: .plus, exponent: -4, significand: 285),
    ]

    /// 由固定匯率表排序推導 UI 測試可用的幣別代碼
    static let stubSupportedCodes = twdBasedRates.keys.map(\.rawValue).sorted()

    /// 行事曆替身建立事件後回傳的固定識別碼
    private static let stubEventIdentifier = "ui-test-event-identifier"

    /// UI 測試用本機驗證回覆延遲，讓重試中間狀態可被 XCUITest 觀察
    private static let biometricResponseDelay = Duration.seconds(3)

    /// AI 總結替身的固定輸出，建立串流時一次全部 yield 完 (不模擬串流節奏)
    private static let aiSummaryChunks = [
        "## 商品明細總結\n\n",
        "本批訂單以 3C 配件為主，重點如下：\n\n",
        "- **熱門品項**：藍牙耳機 x3、保溫瓶 x2\n",
        "- **金額區間**：單價集中在 NT$300–1,200\n",
    ]

    /// 假影像的色盤：相鄰兩張顏色不同，縮圖可肉眼區分
    private static let photoPalette: [UIColor] = [
        .systemBlue, .systemPink, .systemGreen, .systemOrange,
    ]

    /// 假影像的邊長 (點)
    private static let photoSide: CGFloat = 240
}

// MARK: - Internal Method

extension BLUITestStubs {

    /// 建立不開系統選擇器的照片 Service
    ///
    /// - Returns: 依選取數量回傳純色 JPEG 的 ``PhotoService``
    static func makePhotoService() -> PhotoService {
        let cache = BLUITestPhotoCache()

        return PhotoService(
            importPhotos: { items in
                guard !items.isEmpty else {
                    return PhotoImportResult(photos: [], failedCount: 0)
                }
                let photos = cache.resolvedPhotos {
                    makePalettePhotos()
                }
                guard !photos.isEmpty else {
                    return PhotoImportResult(photos: [], failedCount: 0)
                }
                return PhotoImportResult(
                    photos: items.indices.map {
                        photos[$0 % photos.count]
                    },
                    failedCount: 0
                )
            }
        )
    }

    /// 建立不碰 EventKit 的行事曆 Service
    ///
    /// - Parameter access: 要模擬的授權結果
    /// - Returns: 回傳固定結果的行事曆 Service
    static func makeCalendarReminderService(
        access: BLUITestCalendarAccess
    ) -> CalendarReminderService {
        // UI 測試只需模擬 granted 與 denied
        let resolvedAccess: CalendarReminderService.AccessResult
        if access == .granted {
            resolvedAccess = .granted
        } else {
            resolvedAccess = .denied
        }

        return CalendarReminderService(
            requestAccess: { resolvedAccess },
            addReminder: { _, _, _ in stubEventIdentifier },
            removeReminder: { _ in }
        )
    }

    /// 建立不彈出系統生物辨識提示的本機驗證 Service
    ///
    /// - Parameter scenario: 要模擬的驗證情境
    /// - Returns: 固定回傳測試用的生物辨識 Service
    static func makeBiometricAuthService(
        scenario: BLUITestBiometricScenario
    ) -> BiometricAuthService {
        let result: BiometricAuthService.AuthenticationResult
        if scenario == .success {
            result = .success
        } else {
            result = .failure
        }
        return BiometricAuthService(
            isAvailable: { true },
            authenticate: { _ in
                if scenario == .failure {
                    try? await Task.sleep(for: biometricResponseDelay) // 失敗可忽略，因為延遲被取消時仍回傳固定的失敗結果
                }
                return result
            },
            biometryType: { .faceID }
        )
    }

    /// 建立不打網路的匯率 Service
    ///
    /// - Parameter referenceDate: 快照時間戳，沿用 UI 測試的固定「現在」
    /// - Returns: 回傳固定匯率的 Service
    static func makeExchangeRateService(referenceDate: Date) -> ExchangeRateService {
        ExchangeRateService(
            fetchLatest: { base throws(APIError) in
                // 固定表以 TWD 為基準，改用其他基準時整表除以該幣別的 TWD 匯率
                guard let baseRate = twdBasedRates[base], baseRate > 0 else {
                    throw BLUITestErrorFactory.unsupportedBase(base.rawValue)
                }
                return FxRateSnapshot(
                    date: referenceDate,
                    base: base,
                    rates: twdBasedRates.mapValues {
                        $0 / baseRate
                    }
                )
            }
        )
    }

    /// 建立回傳固定文字與測試金鑰的 AI 摘要 Service
    ///
    /// - Returns: 固定段落一次吐完即結束的 AI 摘要 Service
    static func makeAISummaryService() -> AISummaryService {
        AISummaryService(
            streamSummary: { _, _, _ in
                AsyncThrowingStream<String, any Error> { continuation in
                    for chunk in aiSummaryChunks {
                        continuation.yield(chunk)
                    }
                    continuation.finish()
                }
            },
            apiKey: { stubAPIKey }
        )
    }
}

// MARK: - Private Method

private extension BLUITestStubs {

    /// 依色盤繪出各一張純色 JPEG
    ///
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

#endif
