//
//  CloudSyncFieldMergeTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/6/22.
//

import Foundation
import Testing

@testable import BuyLedger

/// ``CloudSyncFieldMerge`` 逐欄合併與 ``CloudSyncEngine`` diff 的單元測試
///
/// 驗證「勝出欄位集」疊到 baseline 的語意：
/// 未勝出欄位保留本機 (DIRTY 保護的落地表現)、
/// 勝出欄位採遠端、
/// `customerName`/`customerTier` decomposed 粒度、
/// 新訂單採全部遠端
@MainActor
struct CloudSyncFieldMergeTests {

    // MARK: - Overlay

    @Test
    func disjointFieldsBothSurvive() {
        let baseline = Self.order(id: "BL-1", name: "本機王", charged: 100)
        let remote = Self.order(id: "BL-1", name: "遠端李", charged: 200)

        let merged = CloudSyncFieldMerge.merged(
            baseline: baseline,
            remote: remote,
            winningFields: ["chargedAmount"]
        )

        // 勝出欄位採遠端、未勝出欄位保留本機
        #expect(merged.chargedAmount == 200)
        #expect(merged.customer.name == "本機王")
    }

    @Test
    func newOrderTakesAllRemoteFields() {
        let remote = Self.order(id: "BL-NEW", name: "新單", charged: 50)
        let merged = CloudSyncFieldMerge.merged(baseline: nil, remote: remote, winningFields: [])
        #expect(merged.customer.name == "新單")
        #expect(merged.chargedAmount == 50)
    }

    @Test
    func customerNameAndTierAreDecomposed() {
        let baseline = Self.order(id: "BL-2", name: "本機名", charged: 1, tier: .new)
        let remote = Self.order(id: "BL-2", name: "遠端名", charged: 1, tier: .vip)

        // customerName/customerTier 拆成獨立粒度，可各自勝出
        let merged = CloudSyncFieldMerge.merged(
            baseline: baseline,
            remote: remote,
            winningFields: ["customerTier"]
        )
        #expect(merged.customer.name == "本機名")
        #expect(merged.customer.tier == .vip)
    }

    @Test
    func photosPreservedFromBaselineDuringFieldMerge() {
        let baseline = Self.order(id: "BL-3", name: "n", charged: 1, photos: [Data([0x01])])
        let remote = Self.order(id: "BL-3", name: "n2", charged: 2, photos: [])
        let merged = CloudSyncFieldMerge.merged(
            baseline: baseline,
            remote: remote,
            winningFields: ["chargedAmount"]
        )
        // photos 不參與 field merge，保留 baseline (改由 photoRefs 解析覆寫)
        #expect(merged.photos == [Data([0x01])])
    }

    // MARK: - Engine diff

    @Test
    func diffFieldsReturnsAllForNewOrder() {
        let order = Self.order(id: "BL-D", name: "x", charged: 9)
        let changed = CloudSyncEngine.diffFields(new: order, baseline: nil)
        #expect(changed["customerName"] == .string("x"))
        #expect(changed["chargedAmount"] == .string("9"))
    }

    @Test
    func diffFieldsReturnsOnlyChanged() {
        let baseline = Self.order(id: "BL-D", name: "x", charged: 9)
        let edited = Self.order(id: "BL-D", name: "x", charged: 99)
        let changed = CloudSyncEngine.diffFields(new: edited, baseline: baseline)
        #expect(changed["chargedAmount"] == .string("99"))
        #expect(changed["customerName"] == nil)
    }
}

// MARK: - Helpers

extension CloudSyncFieldMergeTests {

    /// 建立測試訂單 (僅關注本測試會比對的欄位，其餘帶最小預設)
    /// - Parameters:
    ///   - id: 訂單 id
    ///   - name: 客戶名
    ///   - charged: 收款金額
    ///   - tier: 客戶分級 (預設 new)
    ///   - photos: 照片位元組 (預設空)
    /// - Returns: 組好的訂單
    static func order(
        id: String,
        name: String,
        charged: Decimal,
        tier: CustomerTier = .new,
        photos: [Data] = []
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: name, initials: "", tier: tier),
            status: .confirmed,
            currency: CurrencyCode(rawValue: "TWD"),
            date: Date(timeIntervalSince1970: 1_700_000_000),
            items: [],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: charged,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "",
            categories: [],
            paymentMethod: "",
            notes: "",
            verificationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: photos,
            mergedSourceIDs: []
        )
    }
}
