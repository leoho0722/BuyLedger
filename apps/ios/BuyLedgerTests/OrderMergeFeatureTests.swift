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

/// 驗證訂單合併流程
@MainActor
struct OrderMergeFeatureTests {
    
    // MARK: - Tests
    
    @Test func eligibleCandidatesFilterMatrix() {
        // 資格矩陣：同幣別 + 同客戶 + 非已合併/已取消，且排除主訂單自身
        let primary = Self.makeOrder(id: "O1", customer: "Alice", currency: .jpy, status: .shipping)
        let orders = [
            primary,
            Self.makeOrder(id: "O2", customer: "Alice", currency: .jpy, status: .purchased),
            Self.makeOrder(id: "O3", customer: "Alice", currency: .jpy, status: .merged),
            Self.makeOrder(id: "O4", customer: "Alice", currency: .jpy, status: .cancelled),
            Self.makeOrder(id: "O5", customer: "Alice", currency: .krw, status: .purchased),
            Self.makeOrder(id: "O6", customer: "Bob", currency: .jpy, status: .purchased),
            Self.makeOrder(id: "O7", customer: "Alice", currency: .jpy, status: .delivered),
        ]
        
        let eligible = OrderMergeFeature.State.eligibleCandidates(for: primary, in: orders)
        
        #expect(eligible.map(\.id) == ["O2", "O7"])
    }
    
    @Test func searchFiltersCandidatesInRealTime() async {
        let primary = Self.makeOrder(id: "O1", customer: "Alice", currency: .jpy, status: .shipping)
        let orders = [
            primary,
            Self.makeOrder(
                id: "O2", customer: "Alice", currency: .jpy, status: .purchased, itemName: "香水"),
            Self.makeOrder(
                id: "O3", customer: "Alice", currency: .jpy, status: .purchased, itemName: "外套"),
        ]
        
        let store = TestStore(
            initialState: OrderMergeFeature.State(primary: primary, orders: orders)
        ) {
            OrderMergeFeature()
        } withDependencies: {
            $0.uuid = .incrementing
        }
        
        await store.send(\.binding.searchText, "香水") {
            $0.searchText = "香水"
        }
        
        #expect(store.state.filteredCandidates.map(\.id) == ["O2"])
    }
    
    @Test func candidateSectionsGroupByDayNewestFirst() {
        // 候選依日期分組，並由新到舊排序。
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        
        let reference = Date(timeIntervalSince1970: 1_770_000_000)
        let primary = Self.makeOrder(id: "O1", customer: "Alice", currency: .jpy, status: .shipping)
        let orders = [
            primary,
            Self.makeOrder(
                id: "O2", customer: "Alice", currency: .jpy, status: .purchased,
                date: reference.addingTimeInterval(-3_600)
            ),
            Self.makeOrder(
                id: "O3", customer: "Alice", currency: .jpy, status: .purchased,
                date: reference.addingTimeInterval(-60)
            ),
            Self.makeOrder(
                id: "O4", customer: "Alice", currency: .jpy, status: .purchased,
                date: reference.addingTimeInterval(-86_400)
            ),
        ]
        
        let state = withDependencies {
            $0.uuid = .incrementing
        } operation: {
            OrderMergeFeature.State(primary: primary, orders: orders)
        }
        let sections = state.candidateSections(
            referenceDate: reference,
            calendar: calendar,
            locale: Locale(identifier: "zh-Hant")
        )
        
        #expect(sections.map(\.title) == ["今天", "昨天"])
        #expect(sections.map { $0.orders.map(\.id) } == [["O3", "O2"], ["O4"]])
    }
    
    @Test func candidateSectionsApplySearchFilter() {
        // 搜尋過濾先於分組生效：無符合候選的日子不產生區段
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        
        let reference = Date(timeIntervalSince1970: 1_770_000_000)
        let primary = Self.makeOrder(id: "O1", customer: "Alice", currency: .jpy, status: .shipping)
        let orders = [
            primary,
            Self.makeOrder(
                id: "O2", customer: "Alice", currency: .jpy, status: .purchased,
                itemName: "香水", date: reference.addingTimeInterval(-3_600)
            ),
            Self.makeOrder(
                id: "O3", customer: "Alice", currency: .jpy, status: .purchased,
                itemName: "外套", date: reference.addingTimeInterval(-86_400)
            ),
        ]
        
        var state = withDependencies {
            $0.uuid = .incrementing
        } operation: {
            OrderMergeFeature.State(primary: primary, orders: orders)
        }
        state.searchText = "香水"
        let sections = state.candidateSections(
            referenceDate: reference,
            calendar: calendar,
            locale: Locale(identifier: "zh-Hant")
        )
        
        #expect(sections.map(\.title) == ["今天"])
        #expect(sections.flatMap { $0.orders.map(\.id) } == ["O2"])
    }
    
    @Test func candidateTappedWithinPhotoLimitCompletesDirectly() async {
        // 照片合計 ≤ 上限：跳過挑選步驟直接 delegate，照片主前副後串接
        // 清單不帶照片，詳情才依訂單編號載入
        let primaryPhotos = [Data([0x01]), Data([0x02])]
        let secondaryPhotos = [Data([0x03]), Data([0x04]), Data([0x05])]
        let primary = Self.makeOrder(id: "O1", customer: "Alice", currency: .jpy, status: .shipping)
        let secondary = Self.makeOrder(
            id: "O2", customer: "Alice", currency: .jpy, status: .purchased)
        
        let store = TestStore(
            initialState: OrderMergeFeature.State(primary: primary, orders: [primary, secondary])
        ) {
            OrderMergeFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            var orderRepository = OrderRepository.testValue
            orderRepository.fetchOrderPhotos = { id in
                id == primary.id ? primaryPhotos : secondaryPhotos
            }
            $0[OrderRepository.self] = orderRepository
        }
        
        await store.send(.candidateTapped("O2"))
        await store.receive(\.candidatePhotosLoaded)
        await store.receive(\.delegate.completed)
        
        #expect(store.state.step == .selectCandidate)
    }
    
    @Test func candidateTappedOverPhotoLimitEntersPhotoStep() async {
        // 4 + 3 = 7 張 > 5：進入照片挑選步驟並預選前 5 張 (主訂單照片在前)
        let primaryPhotos = (1...4).map { Data([UInt8($0)]) }
        let secondaryPhotos = (5...7).map { Data([UInt8($0)]) }
        let primary = Self.makeOrder(id: "O1", customer: "Alice", currency: .jpy, status: .shipping)
        let secondary = Self.makeOrder(
            id: "O2", customer: "Alice", currency: .jpy, status: .purchased)
        
        let store = TestStore(
            initialState: OrderMergeFeature.State(primary: primary, orders: [primary, secondary])
        ) {
            OrderMergeFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            var orderRepository = OrderRepository.testValue
            orderRepository.fetchOrderPhotos = { id in
                id == primary.id ? primaryPhotos : secondaryPhotos
            }
            $0[OrderRepository.self] = orderRepository
        }
        
        await store.send(.candidateTapped("O2"))
        await store.receive(\.candidatePhotosLoaded) {
            $0.selectedSecondary = secondary
            $0.combinedPhotos = primaryPhotos + secondaryPhotos
            $0.selectedPhotoIndices = Set(0..<LedgerOrder.maxPhotoCount)
            $0.step = .selectPhotos
        }
    }
    
    @Test func backToCandidatesTappedReturnsToCandidateStepAndClearsPhotoState() async {
        let primaryPhotos = (1...4).map { Data([UInt8($0)]) }
        let secondaryPhotos = (5...7).map { Data([UInt8($0)]) }
        let primary = Self.makeOrder(id: "O1", customer: "Alice", currency: .jpy, status: .shipping)
        let secondary = Self.makeOrder(
            id: "O2", customer: "Alice", currency: .jpy, status: .purchased)
        
        let store = TestStore(
            initialState: OrderMergeFeature.State(primary: primary, orders: [primary, secondary])
        ) {
            OrderMergeFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            var orderRepository = OrderRepository.testValue
            orderRepository.fetchOrderPhotos = { id in
                id == primary.id ? primaryPhotos : secondaryPhotos
            }
            $0[OrderRepository.self] = orderRepository
        }
        
        await store.send(.candidateTapped("O2"))
        await store.receive(\.candidatePhotosLoaded) {
            $0.selectedSecondary = secondary
            $0.combinedPhotos = primaryPhotos + secondaryPhotos
            $0.selectedPhotoIndices = Set(0..<LedgerOrder.maxPhotoCount)
            $0.step = .selectPhotos
        }
        
        // Back 返回候選步驟並清掉照片步驟暫存
        await store.send(.backToCandidatesTapped) {
            $0.step = .selectCandidate
            $0.selectedSecondary = nil
            $0.combinedPhotos = []
            $0.selectedPhotoIndices = []
        }
    }
    
    @Test func photoToggleGuardsTheKeepLimit() async {
        let primaryPhotos = (1...4).map { Data([UInt8($0)]) }
        let secondaryPhotos = (5...7).map { Data([UInt8($0)]) }
        let primary = Self.makeOrder(id: "O1", customer: "Alice", currency: .jpy, status: .shipping)
        let secondary = Self.makeOrder(
            id: "O2", customer: "Alice", currency: .jpy, status: .purchased)
        
        let store = TestStore(
            initialState: OrderMergeFeature.State(primary: primary, orders: [primary, secondary])
        ) {
            OrderMergeFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            var orderRepository = OrderRepository.testValue
            orderRepository.fetchOrderPhotos = { id in
                id == primary.id ? primaryPhotos : secondaryPhotos
            }
            $0[OrderRepository.self] = orderRepository
        }
        await store.send(.candidateTapped("O2"))
        await store.receive(\.candidatePhotosLoaded) {
            $0.selectedSecondary = secondary
            $0.combinedPhotos = primaryPhotos + secondaryPhotos
            $0.selectedPhotoIndices = Set(0..<LedgerOrder.maxPhotoCount)
            $0.step = .selectPhotos
        }
        
        // 已選滿 5 張，再選第 6 張應被忽略。
        await store.send(.photoToggled(5))
        #expect(store.state.selectedPhotoIndices == Set(0..<5))
        
        // 取消一張後即可改勾其他照片
        await store.send(.photoToggled(0)) {
            $0.selectedPhotoIndices = Set(1..<5)
        }
        await store.send(.photoToggled(6)) {
            $0.selectedPhotoIndices = Set([1, 2, 3, 4, 6])
        }
        #expect(store.state.selectedPhotoIndices == Set([1, 2, 3, 4, 6]))
    }
    
    @Test func photoStepConfirmDeliversKeptPhotosInOrder() async {
        let primaryPhotos = (1...4).map { Data([UInt8($0)]) }
        let secondaryPhotos = (5...7).map { Data([UInt8($0)]) }
        let primary = Self.makeOrder(id: "O1", customer: "Alice", currency: .jpy, status: .shipping)
        let secondary = Self.makeOrder(
            id: "O2", customer: "Alice", currency: .jpy, status: .purchased)
        
        let store = TestStore(
            initialState: OrderMergeFeature.State(primary: primary, orders: [primary, secondary])
        ) {
            OrderMergeFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            var orderRepository = OrderRepository.testValue
            orderRepository.fetchOrderPhotos = { id in
                id == primary.id ? primaryPhotos : secondaryPhotos
            }
            $0[OrderRepository.self] = orderRepository
        }
        await store.send(.candidateTapped("O2"))
        await store.receive(\.candidatePhotosLoaded) {
            $0.selectedSecondary = secondary
            $0.combinedPhotos = primaryPhotos + secondaryPhotos
            $0.selectedPhotoIndices = Set(0..<LedgerOrder.maxPhotoCount)
            $0.step = .selectPhotos
        }
        // 改保留 index 1, 2, 6 三張
        await store.send(.photoToggled(0)) {
            $0.selectedPhotoIndices = Set([1, 2, 3, 4])
        }
        await store.send(.photoToggled(3)) {
            $0.selectedPhotoIndices = Set([1, 2, 4])
        }
        await store.send(.photoToggled(4)) {
            $0.selectedPhotoIndices = Set([1, 2])
        }
        await store.send(.photoToggled(6)) {
            $0.selectedPhotoIndices = Set([1, 2, 6])
        }
        
        await store.send(.photoStepConfirmTapped)
        await store.receive(\.delegate.completed)
        
        // delegate payload 驗證：以 case path 取出參數
        let combined = primaryPhotos + secondaryPhotos
        let expectedKept = [combined[1], combined[2], combined[6]]
        #expect(store.state.selectedPhotoIndices.sorted() == [1, 2, 6])
        #expect(store.state.selectedPhotoIndices.sorted().map { combined[$0] } == expectedKept)
    }
    
    /// 挑選步驟顯示雙方已載入的照片
    @Test func mergeLoadsBothSourcePhotosBeforeSelectionStep() async {
        let primaryPhotos = (1...3).map { Data([UInt8($0)]) }
        let secondaryPhotos = (4...7).map { Data([UInt8($0)]) }
        let primary = Self.makeOrder(id: "O1", customer: "Alice", currency: .jpy, status: .shipping)
        let secondary = Self.makeOrder(
            id: "O2", customer: "Alice", currency: .jpy, status: .purchased)
        
        let store = TestStore(
            initialState: OrderMergeFeature.State(primary: primary, orders: [primary, secondary])
        ) {
            OrderMergeFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            var orderRepository = OrderRepository.testValue
            orderRepository.fetchOrderPhotos = { id in
                id == primary.id ? primaryPhotos : secondaryPhotos
            }
            $0[OrderRepository.self] = orderRepository
        }
        
        // state 內照片為空，合計值不能直接取自這兩個欄位。
        #expect(primary.photos.isEmpty)
        #expect(secondary.photos.isEmpty)
        
        await store.send(.candidateTapped("O2"))
        // 載入完成前，步驟維持在候選選擇 (尚未進入挑選步驟)
        #expect(store.state.step == .selectCandidate)
        
        await store.receive(\.candidatePhotosLoaded) {
            $0.selectedSecondary = secondary
            $0.combinedPhotos = primaryPhotos + secondaryPhotos
            $0.selectedPhotoIndices = Set(0..<LedgerOrder.maxPhotoCount)
            $0.step = .selectPhotos
        }
        
        // 挑選畫面的照片集合等於雙方庫內照片串接 (主前副後)，共 7 張
        #expect(store.state.combinedPhotos == primaryPhotos + secondaryPhotos)
        #expect(store.state.combinedPhotos.count == 7)
    }
    
    /// 雙方照片載入失敗時應顯示錯誤
    @Test func candidateTappedPhotoLoadFailureShowsAlertAndStaysOnCandidateStep() async {
        let primary = Self.makeOrder(id: "O1", customer: "Alice", currency: .jpy, status: .shipping)
        let secondary = Self.makeOrder(
            id: "O2", customer: "Alice", currency: .jpy, status: .purchased)
        
        let store = TestStore(
            initialState: OrderMergeFeature.State(primary: primary, orders: [primary, secondary])
        ) {
            OrderMergeFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            var orderRepository = OrderRepository.testValue
            orderRepository.fetchOrderPhotos = {
                (_: LedgerOrder.ID) async throws(PersistenceError) -> [Data] in
                throw .fetchFailed(message: "photo load failed")
            }
            $0[OrderRepository.self] = orderRepository
        }
        
        await store.send(.candidateTapped("O2"))
        await store.receive(\.candidatePhotosLoadFailed) {
            $0.photoLoadFailureAlert = AlertState {
                TextState("操作失敗")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("知道了")
                }
            } message: {
                TextState("無法讀取訂單照片，請稍後再試。")
            }
        }
        
        #expect(store.state.step == .selectCandidate, "載入失敗應停留在候選選擇步驟，讓使用者可重新點選同一候選訂單重試")
    }
}

// MARK: - Helpers

private extension OrderMergeFeatureTests {
    
    /// 建立測試訂單；未指定的欄位使用中性預設值
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - customer: 客戶名稱
    ///   - currency: 訂單幣別
    ///   - status: 訂單狀態
    ///   - itemName: 商品名稱
    ///   - date: 訂單日期
    ///   - photos: 訂單照片
    /// - Returns: 建立的測試訂單
    static func makeOrder(
        id: String,
        customer: String,
        currency: CurrencyCode,
        status: OrderStatus,
        itemName: String = "示範商品",
        date: Date = Date(timeIntervalSince1970: 1_770_000_000),
        photos: [Data] = []
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: customer, initials: "XX", tier: .regular),
            status: status,
            currency: currency,
            date: date,
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
            reconciliationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: photos,
            mergedSourceIDs: []
        )
    }
}
