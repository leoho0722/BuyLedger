//
//  OrderMergeFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/6/6.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import BuyLedger

@MainActor
struct OrderMergeFeatureTests {

    // MARK: - Tests

    @Test func eligibleCandidatesFilterMatrix() {
        // 資格矩陣：同幣別 + 同客戶 + 非已合併/已取消，且排除主訂單自身。
        let primary = Self.makeOrder(id: "O1", customer: "Alice", currency: .jpy, status: .shipping)
        let orders = [
            primary,
            Self.makeOrder(id: "O2", customer: "Alice", currency: .jpy, status: .purchased),
            Self.makeOrder(id: "O3", customer: "Alice", currency: .jpy, status: .merged),
            Self.makeOrder(id: "O4", customer: "Alice", currency: .jpy, status: .cancelled),
            Self.makeOrder(id: "O5", customer: "Alice", currency: .krw, status: .purchased),
            Self.makeOrder(id: "O6", customer: "Bob", currency: .jpy, status: .purchased),
        ]

        let eligible = OrderMergeFeature.State.eligibleCandidates(for: primary, in: orders)

        #expect(eligible.map(\.id) == ["O2"])
    }

    @Test func searchFiltersCandidatesInRealTime() async {
        let primary = Self.makeOrder(id: "O1", customer: "Alice", currency: .jpy, status: .shipping)
        let orders = [
            primary,
            Self.makeOrder(id: "O2", customer: "Alice", currency: .jpy, status: .purchased, itemName: "香水"),
            Self.makeOrder(id: "O3", customer: "Alice", currency: .jpy, status: .purchased, itemName: "外套"),
        ]

        let store = TestStore(
            initialState: OrderMergeFeature.State(primary: primary, orders: orders)
        ) {
            OrderMergeFeature()
        }

        await store.send(\.binding.searchText, "香水") {
            $0.searchText = "香水"
        }

        #expect(store.state.filteredCandidates.map(\.id) == ["O2"])
    }

    @Test func candidateTappedWithinPhotoLimitCompletesDirectly() async {
        // 照片合計 ≤ 上限：跳過挑選步驟直接 delegate，照片主前副後串接。
        let primaryPhotos = [Data([0x01]), Data([0x02])]
        let secondaryPhotos = [Data([0x03]), Data([0x04]), Data([0x05])]
        let primary = Self.makeOrder(id: "O1", customer: "Alice", currency: .jpy, status: .shipping, photos: primaryPhotos)
        let secondary = Self.makeOrder(id: "O2", customer: "Alice", currency: .jpy, status: .purchased, photos: secondaryPhotos)

        let store = TestStore(
            initialState: OrderMergeFeature.State(primary: primary, orders: [primary, secondary])
        ) {
            OrderMergeFeature()
        }

        await store.send(.candidateTapped("O2"))
        await store.receive(\.delegate.completed)

        #expect(store.state.step == .selectCandidate)
    }

    @Test func candidateTappedOverPhotoLimitEntersPhotoStep() async {
        // 4 + 3 = 7 張 > 5：進入照片挑選步驟並預選前 5 張 (主訂單照片在前)。
        let primaryPhotos = (1...4).map { Data([UInt8($0)]) }
        let secondaryPhotos = (5...7).map { Data([UInt8($0)]) }
        let primary = Self.makeOrder(id: "O1", customer: "Alice", currency: .jpy, status: .shipping, photos: primaryPhotos)
        let secondary = Self.makeOrder(id: "O2", customer: "Alice", currency: .jpy, status: .purchased, photos: secondaryPhotos)

        let store = TestStore(
            initialState: OrderMergeFeature.State(primary: primary, orders: [primary, secondary])
        ) {
            OrderMergeFeature()
        }

        await store.send(.candidateTapped("O2")) {
            $0.selectedSecondary = secondary
            $0.combinedPhotos = primaryPhotos + secondaryPhotos
            $0.selectedPhotoIndices = Set(0..<LedgerOrder.maxPhotoCount)
            $0.step = .selectPhotos
        }
    }

    @Test func photoToggleGuardsTheKeepLimit() async {
        let primaryPhotos = (1...4).map { Data([UInt8($0)]) }
        let secondaryPhotos = (5...7).map { Data([UInt8($0)]) }
        let primary = Self.makeOrder(id: "O1", customer: "Alice", currency: .jpy, status: .shipping, photos: primaryPhotos)
        let secondary = Self.makeOrder(id: "O2", customer: "Alice", currency: .jpy, status: .purchased, photos: secondaryPhotos)

        let store = TestStore(
            initialState: OrderMergeFeature.State(primary: primary, orders: [primary, secondary])
        ) {
            OrderMergeFeature()
        }
        store.exhaustivity = .off

        await store.send(.candidateTapped("O2"))

        // 已選滿 5 張：再勾第 6 張會被守門忽略。
        await store.send(.photoToggled(5))
        #expect(store.state.selectedPhotoIndices == Set(0..<5))

        // 取消一張後即可改勾其他照片。
        await store.send(.photoToggled(0))
        await store.send(.photoToggled(6))
        #expect(store.state.selectedPhotoIndices == Set([1, 2, 3, 4, 6]))
    }

    @Test func photoStepConfirmDeliversKeptPhotosInOrder() async {
        let primaryPhotos = (1...4).map { Data([UInt8($0)]) }
        let secondaryPhotos = (5...7).map { Data([UInt8($0)]) }
        let primary = Self.makeOrder(id: "O1", customer: "Alice", currency: .jpy, status: .shipping, photos: primaryPhotos)
        let secondary = Self.makeOrder(id: "O2", customer: "Alice", currency: .jpy, status: .purchased, photos: secondaryPhotos)

        let store = TestStore(
            initialState: OrderMergeFeature.State(primary: primary, orders: [primary, secondary])
        ) {
            OrderMergeFeature()
        }
        store.exhaustivity = .off

        await store.send(.candidateTapped("O2"))
        // 改保留 index 1, 2, 6 三張。
        await store.send(.photoToggled(0))
        await store.send(.photoToggled(3))
        await store.send(.photoToggled(4))
        await store.send(.photoToggled(6))

        await store.send(.photoStepConfirmTapped)
        await store.receive(\.delegate.completed)

        // delegate payload 驗證：以 case path 取出參數。
        let combined = primaryPhotos + secondaryPhotos
        let expectedKept = [combined[1], combined[2], combined[6]]
        #expect(store.state.selectedPhotoIndices.sorted() == [1, 2, 6])
        #expect(store.state.selectedPhotoIndices.sorted().map { combined[$0] } == expectedKept)
    }
}

// MARK: - Helpers

private extension OrderMergeFeatureTests {

    /// 建立測試訂單；未指定的欄位使用中性預設值。
    static func makeOrder(
        id: String,
        customer: String,
        currency: CurrencyCode,
        status: OrderStatus,
        itemName: String = "示範商品",
        photos: [Data] = []
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: customer, initials: "XX", tier: .regular),
            status: status,
            currency: currency,
            date: Date(timeIntervalSince1970: 1_770_000_000),
            items: [LedgerOrderItem(name: itemName, quantity: 1, unitPrice: 100)],
            itemCost: 100,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 1_000,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "蝦皮",
            categories: ["美妝"],
            paymentMethod: "信用卡",
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
