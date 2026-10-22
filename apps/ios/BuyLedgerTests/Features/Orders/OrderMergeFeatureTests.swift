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

    /// 只有同客戶、同幣別、尚未合併或取消，且不是主訂單本身的訂單會列為合併候選
    @Test
    func eligible_各種資格組合_只回傳符合資格訂單() {
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
        let eligible = OrderMergeCandidates.eligible(for: primary, in: orders)

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
            initialState: OrderMergeFeature.State(
                primary: primary,
                orders: orders,
                dateContext: Self.fixedDateContext
            )
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
        let sections = store.state.candidateSections(locale: Locale(identifier: "zh-Hant"))
        #expect(sections.flatMap { $0.orders.map(\.id) } == ["O2"])
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
            OrderMergeFeature.State(
                primary: primary,
                orders: orders,
                dateContext: OrderDateContext(now: reference, calendar: calendar)
            )
        }

        // When
        let sections = state.candidateSections(locale: Locale(identifier: "zh-Hant"))

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
            OrderMergeFeature.State(
                primary: primary,
                orders: orders,
                dateContext: OrderDateContext(now: reference, calendar: calendar)
            )
        }
        state.searchText = "香水"

        // When
        let sections = state.candidateSections(locale: Locale(identifier: "zh-Hant"))

        // Then
        #expect(sections.map(\.title) == ["今天"])
        #expect(sections.flatMap { $0.orders.map(\.id) } == ["O2"])
    }

    /// 東十四區午夜前後的候選，依建立合併流程時帶入的時間與時區分組，不讀取依賴中的時間與行事曆
    ///
    /// - Throws: 無法建立測試時區時由 `#require` 丟出
    /// - Note: 台北與 UTC 會把昨天候選併入今天，台北另會把更早候選歸為昨天
    @Test
    func candidateSections_日期脈絡為東十四區午夜_分成今天昨天與更早() throws {
        // Given
        var calendar = TestDependencies.fixedCalendar
        calendar.timeZone = try #require(TimeZone(identifier: "Pacific/Kiritimati"))
        let reference = Date(timeIntervalSince1970: 1_777_458_600)
        let primary = Self.makeOrder(id: "PRIMARY", status: .shipping)
        let orders = [
            primary,
            Self.makeOrder(
                id: "YESTERDAY",
                status: .purchased,
                date: Date(timeIntervalSince1970: 1_777_456_740)
            ),
            Self.makeOrder(
                id: "EARLIER",
                status: .purchased,
                date: Date(timeIntervalSince1970: 1_777_309_200)
            ),
            Self.makeOrder(
                id: "TODAY",
                status: .purchased,
                date: Date(timeIntervalSince1970: 1_777_457_100)
            ),
        ]
        let state = withDependencies {
            $0.uuid = .incrementing
            $0.date = .constant(Date(timeIntervalSince1970: 1_777_593_600))
            $0.calendar = TestDependencies.fixedCalendar
        } operation: {
            OrderMergeFeature.State(
                primary: primary,
                orders: orders,
                dateContext: OrderDateContext(now: reference, calendar: calendar)
            )
        }
        let expectedSectionIDs = [
            Date(timeIntervalSince1970: 1_777_456_800),
            Date(timeIntervalSince1970: 1_777_370_400),
            Date(timeIntervalSince1970: 1_777_284_000),
        ]

        // When
        let sections = state.candidateSections(locale: Locale(identifier: "zh-Hant_TW"))

        // Then
        #expect(sections.prefix(2).map(\.title) == ["今天", "昨天"])
        #expect(sections.map { $0.orders.map(\.id) } == [["TODAY"], ["YESTERDAY"], ["EARLIER"]])
        #expect(sections.map(\.id) == expectedSectionIDs)
    }
}

// MARK: - Computed Properties

extension OrderMergeFeatureTests {

    /// 合併流程測試共用的固定時間與行事曆
    static var fixedDateContext: OrderDateContext {
        OrderDateContext(now: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar)
    }
}

// MARK: - Internal Method

extension OrderMergeFeatureTests {

    /// 建立測試訂單；未指定的欄位使用預設值
    ///
    /// - Parameters:
    ///   - id: 訂單識別值，同一組測試內須互不相同
    ///   - status: 訂單狀態，決定訂單是否符合合併候選的資格
    ///   - customer: 客戶名稱，預設所有測試訂單屬於同一位客戶
    ///   - currency: 訂單幣別，預設日圓
    ///   - itemName: 商品名稱，預設為示範用的商品名稱
    ///   - date: 訂單日期，預設為固定時間點，不隨執行時間改變
    ///   - photos: 訂單照片，預設沒有照片
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
}
