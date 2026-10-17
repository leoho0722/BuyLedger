//
//  BLUITestSeedData.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/24.
//

import Foundation
import SwiftData

#if DEBUG

/// 依 ``BLUITestSeedProfile`` 寫入確定性的 UI 測試資料，由 ``BLUITestHarness`` 建立測試 container 時呼叫
enum BLUITestSeedData {

    // MARK: - Properties

    /// 訂單來源主檔名稱 (4 筆)
    static let orderSourceNames = ["蝦皮", "Instagram", "官方網站", "代購社團"]

    /// 商品類別主檔名稱 (4 筆)
    static let categoryNames = ["美妝", "服飾", "精品", "生活雜貨"]

    /// 對帳狀態主檔名稱 (3 筆)
    private static let reconciliationStatusNames = ["待對帳", "對帳成功", "對帳失敗"]

    /// 1×1 灰階 JPEG 的 base64 (141 bytes)，作為 `photos` profile 的照片基底
    static let minimalJPEGBase64 = """
            /9j/2wBDAFA3PEY8MlBGQUZaVVBfeMiCeG5uePWvuZHI////////////////////\
            ////////////////////////////////wAALCAABAAEBAREA/8QAFAABAAAAAAAA\
            AAAAAAAAAAAAA//EABQQAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQEAAD8Ad//Z
            """

    /// 種子資料使用的 Gregorian／UTC 行事曆
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt

        return calendar
    }()
}

// MARK: - Internal Method

extension BLUITestSeedData {

    /// 把指定 `profile` 的種子資料同步寫入 `container`
    ///
    /// - Parameters:
    ///   - profile: 要寫入的資料組合
    ///   - container: UI 測試用的 container (記憶體或磁碟)
    ///   - referenceDate: 推導所有日期的基準時間點
    static func seed(
        _ profile: BLUITestSeedProfile,
        into container: ModelContainer,
        referenceDate: Date
    ) {
        let context = ModelContext(container)
        populate(profile, in: context, referenceDate: referenceDate)

        do {
            try context.save()
        } catch {
            // 種子寫不進測試 container 時每條 UI 測試的前提都不成立，直接中止讓失敗立即浮現
            fatalError("[BuyLedger][UITest] 種子資料寫入失敗：\(error)")
        }
    }
}

// MARK: - Private Method

private extension BLUITestSeedData {

    /// 依 `profile` 分派到各自的建構函式並逐筆寫入 `context`
    ///
    /// - Parameters:
    ///   - profile: 要寫入的資料組合
    ///   - context: 寫入用的 context
    ///   - referenceDate: 推導所有日期的基準時間點
    static func populate(
        _ profile: BLUITestSeedProfile,
        in context: ModelContext,
        referenceDate: Date
    ) {
        switch profile {
        case .empty:
            break

        case .lookupsOnly:
            insertLookups(into: context)

        case .minimalOrders:
            insertLookups(into: context)
            insertOrders(makeMinimalOrders(referenceDate: referenceDate), into: context)

        case .fullOrders:
            insertLookups(into: context)
            insertOrders(makeFullOrders(referenceDate: referenceDate), into: context)

        case .paymentMethodCorrection:
            insertLookups(into: context)
            insertOrders(
                makePaymentMethodCorrectionOrders(referenceDate: referenceDate),
                into: context
            )

        case .revenueAttribution:
            insertLookups(into: context)
            let campaigns = makeRevenueAttributionCampaigns(referenceDate: referenceDate)
            for campaign in campaigns {
                context.insert(CampaignRecord(campaign: campaign))
            }
            insertOrders(
                makeRevenueAttributionOrders(referenceDate: referenceDate, campaigns: campaigns),
                into: context
            )

        case .campaignsWithOrders:
            insertLookups(into: context)
            let campaigns = makeCampaigns(referenceDate: referenceDate)
            for campaign in campaigns {
                context.insert(CampaignRecord(campaign: campaign))
            }
            insertOrders(
                makeCampaignOrders(referenceDate: referenceDate, campaigns: campaigns),
                into: context
            )

        case .mergeCandidates:
            insertLookups(into: context)
            insertOrders(makeMergeCandidateOrders(referenceDate: referenceDate), into: context)

        case .photos:
            insertLookups(into: context)
            insertOrders(makePhotoOrders(referenceDate: referenceDate), into: context)

        case .customerRanking:
            insertLookups(into: context)
            insertOrders(makeCustomerRankingOrders(referenceDate: referenceDate), into: context)

        case .insightsRange:
            insertLookups(into: context)
            insertOrders(makeInsightsRangeOrders(referenceDate: referenceDate), into: context)
        }
    }

    /// 寫入四種主檔共 17 筆
    ///
    /// - Parameter context: 寫入用的 context
    static func insertLookups(into context: ModelContext) {
        for name in orderSourceNames {
            context.insert(OrderSourceRecord(name: name))
        }

        for name in categoryNames {
            context.insert(CategoryRecord(name: name))
        }

        let paymentMethods: [(
            name: String,
            isCardless: Bool,
            isBankTransfer: Bool,
            isCashOnDelivery: Bool
        )] = [
            (name: "信用卡", isCardless: false, isBankTransfer: false, isCashOnDelivery: false),
            (name: "銀行轉帳", isCardless: false, isBankTransfer: true, isCashOnDelivery: false),
            (name: "無卡", isCardless: true, isBankTransfer: false, isCashOnDelivery: false),
            (name: "貨到付款", isCardless: false, isBankTransfer: false, isCashOnDelivery: true),
            (name: "LINE Pay", isCardless: false, isBankTransfer: false, isCashOnDelivery: false),
            (name: "Apple Pay", isCardless: false, isBankTransfer: false, isCashOnDelivery: false),
        ]
        for method in paymentMethods {
            context.insert(
                PaymentMethodRecord(
                    name: method.name,
                    isCardless: method.isCardless,
                    isBankTransfer: method.isBankTransfer,
                    isCashOnDelivery: method.isCashOnDelivery
                )
            )
        }

        for name in reconciliationStatusNames {
            context.insert(ReconciliationStatusRecord(name: name))
        }
    }

    /// 把領域訂單逐筆轉成持久化記錄寫入
    ///
    /// - Parameters:
    ///   - orders: 要寫入的訂單
    ///   - context: 寫入用的 context
    static func insertOrders(_ orders: [LedgerOrder], into context: ModelContext) {
        for order in orders {
            context.insert(OrderRecord(order: order))
        }
    }
}

#endif
