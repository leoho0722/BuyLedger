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
struct OrderMergeFeatureTests {

    // MARK: - Tests

    /// 只有同客戶、同幣別、尚未合併或取消，且不是主訂單本身的訂單會列為合併候選
    @Test
    func eligibleCandidates_各種資格組合_只回傳符合資格訂單() {
        // Given
        let primary = Self.makeOrder(id: "O1", status: .shipping)
        let orders = [
            primary,
            Self.makeOrder(id: "O2", status: .purchased),
            Self.makeOrder(id: "O3", status: .merged),
            Self.makeOrder(id: "O4", status: .cancelled),
            Self.makeOrder(id: "O5", status: .purchased, currency: .krw),
            Self.makeOrder(id: "O6", status: .purchased, customer: "Bob"),
            Self.makeOrder(id: "O7", status: .delivered),
        ]

        // When
        let eligible = OrderMergeFeature.State.eligibleCandidates(for: primary, in: orders)

        // Then
        #expect(eligible.map(\.id) == ["O2", "O7"])
    }

    /// 輸入搜尋文字後，候選清單只留下商品名稱符合的訂單
    @Test
    @MainActor
    func binding_輸入搜尋文字_即時篩選候選訂單() async {
        // Given
        let primary = Self.makeOrder(id: "O1", status: .shipping)
        let orders = [
            primary,
            Self.makeOrder(id: "O2", status: .purchased, itemName: "香水"),
            Self.makeOrder(id: "O3", status: .purchased, itemName: "外套"),
        ]

        let store = TestStore(
            initialState: OrderMergeFeature.State(primary: primary, orders: orders)
        ) {
            OrderMergeFeature()
        } withDependencies: {
            $0.uuid = .incrementing
        }

        // When
        await store.send(\.binding.searchText, "香水") {
            $0.searchText = "香水"
        }

        // Then
        #expect(store.state.filteredCandidates.map(\.id) == ["O2"])
    }

    /// 候選訂單依日期分成今天、昨天等區段，區段之間與區段內都由新到舊排列
    @Test
    func candidateSections_多日期候選訂單_依日期分組並新到舊排序() {
        // Given
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt

        let reference = Date(timeIntervalSince1970: 1_770_000_000)
        let primary = Self.makeOrder(id: "O1", status: .shipping)
        let orders = [
            primary,
            Self.makeOrder(
                id: "O2",
                status: .purchased,
                date: reference.addingTimeInterval(-3_600)
            ),
            Self.makeOrder(id: "O3", status: .purchased, date: reference.addingTimeInterval(-60)),
            Self.makeOrder(
                id: "O4",
                status: .purchased,
                date: reference.addingTimeInterval(-86_400)
            ),
        ]

        let state = withDependencies {
            $0.uuid = .incrementing
        } operation: {
            OrderMergeFeature.State(primary: primary, orders: orders)
        }

        // When
        let sections = state.candidateSections(
            referenceDate: reference,
            calendar: calendar,
            locale: Locale(identifier: "zh-Hant")
        )

        // Then
        #expect(sections.map(\.title) == ["今天", "昨天"])
        #expect(sections.map { $0.orders.map(\.id) } == [["O3", "O2"], ["O4"]])
    }

    /// 先依搜尋文字篩選再分組，沒有符合訂單的日期不會產生區段
    @Test
    func candidateSections_輸入搜尋文字_只分組符合候選項目() {
        // Given
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt

        let reference = Date(timeIntervalSince1970: 1_770_000_000)
        let primary = Self.makeOrder(id: "O1", status: .shipping)
        let orders = [
            primary,
            Self.makeOrder(
                id: "O2",
                status: .purchased,
                itemName: "香水",
                date: reference.addingTimeInterval(-3_600)
            ),
            Self.makeOrder(
                id: "O3",
                status: .purchased,
                itemName: "外套",
                date: reference.addingTimeInterval(-86_400)
            ),
        ]

        var state = withDependencies {
            $0.uuid = .incrementing
        } operation: {
            OrderMergeFeature.State(primary: primary, orders: orders)
        }
        state.searchText = "香水"

        // When
        let sections = state.candidateSections(
            referenceDate: reference,
            calendar: calendar,
            locale: Locale(identifier: "zh-Hant")
        )

        // Then
        #expect(sections.map(\.title) == ["今天"])
        #expect(sections.flatMap { $0.orders.map(\.id) } == ["O2"])
    }

    /// 雙方照片合計不超過上限 5 張時跳過挑選並回報合併完成，主訂單照片在前
    ///
    /// - Note: 清單上的訂單不帶照片，照片依訂單編號另外讀取
    @Test
    @MainActor
    func candidateTapped_合併照片未超過上限_直接送出完成委派() async {
        // Given
        let primaryPhotos = [Data([0x01]), Data([0x02])]
        let secondaryPhotos = [Data([0x03]), Data([0x04]), Data([0x05])]
        let expectedKept = [Data([0x01]), Data([0x02]), Data([0x03]), Data([0x04]), Data([0x05])]
        let primary = Self.makeOrder(id: "O1", status: .shipping)
        let secondary = Self.makeOrder(id: "O2", status: .purchased)
        let store = TestStore(
            initialState: OrderMergeFeature.State(primary: primary, orders: [primary, secondary])
        ) {
            OrderMergeFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.orderService.fetchOrderPhotos = {
                $0 == primary.id ? primaryPhotos : secondaryPhotos
            }
        }

        // When
        await store.send(.candidateTapped("O2"))

        // Then
        await store.receive(\.candidatePhotosLoaded)
        await store.receive { action in
            guard let completed = action[case: \.delegate.completed] else {
                return false
            }
            return completed.primary == primary
                && completed.secondary == secondary
                && completed.keptPhotos == expectedKept
        }
        #expect(store.state.step == .selectCandidate)
    }

    /// 雙方照片合計超過 5 張時進入挑選步驟，並預先勾選最前面 5 張
    @Test
    @MainActor
    func candidateTapped_合併照片超過上限_進入挑選步驟() async {
        // Given
        let primaryPhotos = [Data([1]), Data([2]), Data([3]), Data([4])]
        let secondaryPhotos = [Data([5]), Data([6]), Data([7])]
        let expectedPhotos = [
            Data([1]), Data([2]), Data([3]), Data([4]), Data([5]), Data([6]), Data([7]),
        ]
        let primary = Self.makeOrder(id: "O1", status: .shipping)
        let secondary = Self.makeOrder(id: "O2", status: .purchased)
        let store = TestStore(
            initialState: OrderMergeFeature.State(primary: primary, orders: [primary, secondary])
        ) {
            OrderMergeFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.orderService.fetchOrderPhotos = {
                $0 == primary.id ? primaryPhotos : secondaryPhotos
            }
        }

        // When
        await store.send(.candidateTapped("O2"))

        // Then
        await store.receive(\.candidatePhotosLoaded) {
            $0.selectedSecondary = secondary
            $0.combinedPhotos = expectedPhotos
            $0.selectedPhotoIndices = [0, 1, 2, 3, 4]
            $0.step = .selectPhotos
        }
    }

    /// 選定候選訂單時，依編號分別讀取主訂單與候選訂單的照片
    ///
    /// - Note: 兩筆訂單本身帶有與讀取結果不同的照片，證明合併用的是依編號讀取的照片
    @Test
    @MainActor
    func candidateTapped_選定候選訂單_依編號讀取雙方照片() async {
        // Given
        let requestedIDs = LockIsolated<[LedgerOrder.ID]>([])
        let primaryPhotos = [Data([1]), Data([2]), Data([3])]
        let secondaryPhotos = [Data([4]), Data([5]), Data([6]), Data([7])]
        let expectedPhotos = [
            Data([1]), Data([2]), Data([3]), Data([4]), Data([5]), Data([6]), Data([7]),
        ]
        let primary = Self.makeOrder(id: "O1", status: .shipping, photos: [Data([0xA1])])
        let secondary = Self.makeOrder(id: "O2", status: .purchased, photos: [Data([0xB1])])
        let store = TestStore(
            initialState: OrderMergeFeature.State(primary: primary, orders: [primary, secondary])
        ) {
            OrderMergeFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.orderService.fetchOrderPhotos = { id in
                requestedIDs.withValue {
                    $0.append(id)
                }
                return id == primary.id ? primaryPhotos : secondaryPhotos
            }
        }

        // When
        await store.send(.candidateTapped("O2"))

        // Then
        await store.receive(\.candidatePhotosLoaded) {
            $0.selectedSecondary = secondary
            $0.combinedPhotos = expectedPhotos
            $0.selectedPhotoIndices = [0, 1, 2, 3, 4]
            $0.step = .selectPhotos
        }
        #expect(requestedIDs.value.sorted() == ["O1", "O2"])
    }

    /// 候選訂單的照片讀取失敗時跳出錯誤提示，並停留在候選選擇步驟
    @Test
    @MainActor
    func candidateTapped_載入照片失敗_顯示通知並停留候選步驟() async {
        // Given
        let primary = Self.makeOrder(id: "O1", status: .shipping)
        let secondary = Self.makeOrder(id: "O2", status: .purchased)
        let failingFetchPhotos: OrderService.FetchOrderPhotos = { id in
            guard id != "O2" else {
                throw .fetchFailed(
                    underlying: TestDependencies.makeUnderlyingError(message: "photo load failed")
                )
            }
            return []
        }
        let store = TestStore(
            initialState: OrderMergeFeature.State(primary: primary, orders: [primary, secondary])
        ) {
            OrderMergeFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.orderService.fetchOrderPhotos = failingFetchPhotos
        }

        // When
        await store.send(.candidateTapped("O2"))

        // Then
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
        #expect(store.state.step == .selectCandidate, "載入失敗後仍可重新選取候選訂單重試")
    }

    /// 從照片挑選步驟返回時回到候選選擇，並清掉已選的副訂單與照片
    @Test
    @MainActor
    func backToCandidatesTapped_返回候選步驟_清除照片暫存() async {
        // Given
        let primary = Self.makeOrder(id: "O1", status: .shipping)
        let secondary = Self.makeOrder(id: "O2", status: .purchased)
        let initialState = Self.makePhotoStepState(
            primary: primary,
            secondary: secondary,
            selectedPhotoIndices: [0, 1, 2, 3, 4]
        )
        let store = TestStore(initialState: initialState) { OrderMergeFeature() }

        // When
        await store.send(.backToCandidatesTapped) {
            $0.step = .selectCandidate
            $0.selectedSecondary = nil
            $0.combinedPhotos = []
            $0.selectedPhotoIndices = []
        }

        // Then
        #expect(store.state.step == .selectCandidate)
        #expect(store.state.selectedSecondary == nil)
        #expect(store.state.combinedPhotos.isEmpty)
        #expect(store.state.selectedPhotoIndices.isEmpty)
    }

    /// 已勾滿 5 張時，再勾選其他照片不會生效
    @Test
    @MainActor
    func photoToggled_已達保留照片上限_忽略新增選取() async {
        // Given
        let primary = Self.makeOrder(id: "O1", status: .shipping)
        let secondary = Self.makeOrder(id: "O2", status: .purchased)
        let initialState = Self.makePhotoStepState(
            primary: primary,
            secondary: secondary,
            selectedPhotoIndices: [1, 2, 3, 4, 6]
        )
        let store = TestStore(initialState: initialState) { OrderMergeFeature() }

        // When
        await store.send(.photoToggled(5))

        // Then
        #expect(store.state.selectedPhotoIndices == [1, 2, 3, 4, 6])
    }

    /// 已勾選照片時取消勾選，清單會移除該照片位置
    @Test
    @MainActor
    func photoToggled_已勾選照片_取消勾選() async {
        // Given
        let primary = Self.makeOrder(id: "O1", status: .shipping)
        let secondary = Self.makeOrder(id: "O2", status: .purchased)
        let initialState = Self.makePhotoStepState(
            primary: primary,
            secondary: secondary,
            selectedPhotoIndices: [0, 1, 2, 3, 4]
        )
        let store = TestStore(initialState: initialState) { OrderMergeFeature() }

        // When
        await store.send(.photoToggled(0)) {
            $0.selectedPhotoIndices = [1, 2, 3, 4]
        }

        // Then
        #expect(store.state.selectedPhotoIndices == [1, 2, 3, 4])
    }

    /// 未達照片上限時勾選照片，清單會加入該照片位置
    @Test
    @MainActor
    func photoToggled_未達上限_加入勾選() async {
        // Given
        let primary = Self.makeOrder(id: "O1", status: .shipping)
        let secondary = Self.makeOrder(id: "O2", status: .purchased)
        let initialState = Self.makePhotoStepState(
            primary: primary,
            secondary: secondary,
            selectedPhotoIndices: [1, 2, 3, 4]
        )
        let store = TestStore(initialState: initialState) { OrderMergeFeature() }

        // When
        await store.send(.photoToggled(6)) {
            $0.selectedPhotoIndices = [1, 2, 3, 4, 6]
        }

        // Then
        #expect(store.state.selectedPhotoIndices == [1, 2, 3, 4, 6])
    }

    /// 按下繼續時，把勾選的照片依原本位置順序交給父層完成合併
    @Test
    @MainActor
    func photoStepConfirmTapped_確認保留照片_依索引順序送出委派() async {
        // Given
        let primary = Self.makeOrder(id: "O1", status: .shipping)
        let secondary = Self.makeOrder(id: "O2", status: .purchased)
        let expectedKept = [Data([1]), Data([3]), Data([4]), Data([6]), Data([7])]
        let initialState = Self.makePhotoStepState(
            primary: primary,
            secondary: secondary,
            selectedPhotoIndices: [0, 2, 3, 5, 6]
        )
        let store = TestStore(initialState: initialState) { OrderMergeFeature() }

        // When
        await store.send(.photoStepConfirmTapped)

        // Then
        await store.receive { action in
            guard let completed = action[case: \.delegate.completed] else {
                return false
            }
            return completed.primary == primary
                && completed.secondary == secondary
                && completed.keptPhotos == expectedKept
        }
    }
}

// MARK: - Private Method

private extension OrderMergeFeatureTests {

    /// 建立測試訂單；未指定的欄位使用中性預設值
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - status: 訂單狀態
    ///   - customer: 客戶名稱，預設所有測試訂單屬於同一位客戶
    ///   - currency: 訂單幣別，預設日圓
    ///   - itemName: 商品名稱
    ///   - date: 訂單日期
    ///   - photos: 訂單照片
    /// - Returns: 建立的測試訂單
    static func makeOrder(
        id: String,
        status: OrderStatus,
        customer: String = "Alice",
        currency: CurrencyCode = .jpy,
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

    /// 建立停在照片挑選步驟的合併流程狀態：副訂單已選定，合併照片依序為 `Data([1])` 到 `Data([7])`
    ///
    /// - Parameters:
    ///   - primary: 主訂單
    ///   - secondary: 已選定的副訂單
    ///   - selectedPhotoIndices: 目前勾選的照片位置
    /// - Returns: 照片挑選步驟的狀態
    static func makePhotoStepState(
        primary: LedgerOrder,
        secondary: LedgerOrder,
        selectedPhotoIndices: Set<Int>
    ) -> OrderMergeFeature.State {
        var state = withDependencies {
            $0.uuid = .incrementing
        } operation: {
            OrderMergeFeature.State(primary: primary, orders: [primary, secondary])
        }
        state.step = .selectPhotos
        state.selectedSecondary = secondary
        state.combinedPhotos = (1...7).map {
            Data([UInt8($0)])
        }
        state.selectedPhotoIndices = selectedPhotoIndices
        return state
    }
}
