//
//  BLUITestSeedData+Orders.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/17.
//

import Foundation

#if DEBUG

// MARK: - Internal Method

extension BLUITestSeedData {

    /// 產生 `minimalOrders` 的訂單：當天／前一天／7 天前各 1 筆，狀態各異 (共 3 筆)
    ///
    /// - Parameter referenceDate: 推導日期的基準時間點
    /// - Returns: 少量訂單種子
    static func makeMinimalOrders(referenceDate: Date) -> [LedgerOrder] {
        [
            makeOrder(
                id: "UITEST-MIN-001",
                customer: makeCustomer("林書宇", "SY", tier: .vip),
                status: .confirmed,
                date: date(daysBefore: 0, from: referenceDate),
                items: [
                    makeItem(
                        seed: 101,
                        name: "香水 Chamo 50ml",
                        quantity: 1,
                        unitPrice: 2_800
                    ),
                ],
                itemCost: 2_800,
                chargedAmount: 4_200
            ),
            makeOrder(
                id: "UITEST-MIN-002",
                customer: makeCustomer("Mika 周", "MZ"),
                status: .shipping,
                date: date(daysBefore: 1, from: referenceDate),
                items: [
                    makeItem(
                        seed: 102,
                        name: "春季針織外套 (M)",
                        quantity: 1,
                        unitPrice: 3_600
                    ),
                ],
                itemCost: 3_600,
                categories: ["服飾"],
                paymentMethod: "LINE Pay",
                chargedAmount: 5_400
            ),
            makeOrder(
                id: "UITEST-MIN-003",
                customer: makeCustomer("Ariel 陳", "AC"),
                status: .delivered,
                date: date(daysBefore: 7, from: referenceDate),
                items: [
                    makeItem(
                        seed: 103,
                        name: "氣墊粉餅 #21",
                        quantity: 2,
                        unitPrice: 1_500
                    ),
                ],
                itemCost: 3_000,
                orderSource: "Instagram",
                chargedAmount: 4_800
            ),
        ]
    }

    /// 以範例訂單產生 `fullOrders` 的 8 筆相對日期訂單
    ///
    /// - Parameter referenceDate: 推導日期的基準時間點
    /// - Returns: 涵蓋各狀態的完整訂單種子
    static func makeFullOrders(referenceDate: Date) -> [LedgerOrder] {
        let dayOffsets = [4, 6, 8, 9, 10, 12, 15, 18]

        return zip(LedgerOrder.sampleOrders, dayOffsets).map { order, offset in
            rebuild(order, date: date(daysBefore: offset, from: referenceDate), campaignNames: [])
        }
    }

    /// 產生 `paymentMethodCorrection` 的訂單：一筆尚未標記貨到付款的信用卡訂單
    ///
    /// - Parameter referenceDate: 推導日期的基準時間點
    /// - Returns: 供回溯重算驗收的單筆訂單
    static func makePaymentMethodCorrectionOrders(referenceDate: Date) -> [LedgerOrder] {
        [
            makeOrder(
                id: "UITEST-PMC-001",
                customer: makeCustomer("回溯驗收", "PM", tier: .regular),
                status: .delivered,
                date: date(daysBefore: 1, from: referenceDate),
                items: [
                    makeItem(
                        seed: 601,
                        name: "貨到付款驗收商品",
                        quantity: 1,
                        unitPrice: 1_000
                    ),
                ],
                itemCost: 1_000,
                paymentMethod: "信用卡",
                chargedAmount: 2_000,
                domesticShipping: 60,
                internationalShipping: 280,
                foreignDomesticShipping: 120
            ),
        ]
    }

    /// 產生 `mergeCandidates` 的 3 筆可合併訂單
    ///
    /// - Parameter referenceDate: 推導日期的基準時間點
    /// - Returns: 可合併候選的訂單種子
    static func makeMergeCandidateOrders(referenceDate: Date) -> [LedgerOrder] {
        let customer = makeCustomer("林書宇", "SY", tier: .vip)
        let currency = CurrencyCode(rawValue: "KRW")

        return [
            makeOrder(
                id: "UITEST-MRG-001",
                customer: customer,
                status: .confirmed,
                currency: currency,
                date: date(daysBefore: 0, from: referenceDate),
                items: [
                    makeItem(
                        seed: 201,
                        name: "絲絨唇釉 #07",
                        quantity: 1,
                        unitPrice: 22_000
                    ),
                ],
                itemCost: 502,
                chargedAmount: 1_200
            ),
            makeOrder(
                id: "UITEST-MRG-002",
                customer: customer,
                status: .purchased,
                currency: currency,
                date: date(daysBefore: 2, from: referenceDate),
                items: [
                    makeItem(
                        seed: 202,
                        name: "標準 Logo Tee 黑",
                        quantity: 2,
                        unitPrice: 89_000
                    ),
                ],
                itemCost: 4_058,
                categories: ["服飾"],
                chargedAmount: 5_680
            ),
            makeOrder(
                id: "UITEST-MRG-003",
                customer: customer,
                status: .shipping,
                currency: currency,
                date: date(daysBefore: 4, from: referenceDate),
                items: [
                    makeItem(
                        seed: 203,
                        name: "寬版牛仔褲 (S)",
                        quantity: 1,
                        unitPrice: 79_000
                    ),
                ],
                itemCost: 1_801,
                categories: ["服飾"],
                chargedAmount: 3_100
            ),
        ]
    }

    /// 產生 `photos` 的訂單：帶 5 張照片 (達張數上限) 的單筆訂單
    ///
    /// - Parameter referenceDate: 推導日期的基準時間點
    /// - Returns: 帶照片的訂單種子
    static func makePhotoOrders(referenceDate: Date) -> [LedgerOrder] {
        let photos = (0..<LedgerOrder.maxPhotoCount).map { makePhotoData(index: $0) }

        return [
            makeOrder(
                id: "UITEST-PHT-001",
                customer: makeCustomer("Joyce 黃", "JH", tier: .vip),
                status: .arrived,
                date: date(daysBefore: 1, from: referenceDate),
                items: [
                    makeItem(
                        seed: 301,
                        name: "手拿包 米色",
                        quantity: 1,
                        unitPrice: 13_700
                    ),
                ],
                itemCost: 13_700,
                categories: ["精品"],
                chargedAmount: 18_500,
                photos: photos
            ),
        ]
    }
}

#endif
