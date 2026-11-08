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

/// `OrderMergeCandidates` 與 `OrderMergeFeature` 的單元測試，涵蓋合併候選的資格、搜尋、分組與日期脈絡
struct OrderMergeFeatureTests {

    /// 驗證只有同客戶、同幣別、狀態非已合併或已取消，且不是主訂單本身的訂單會列為候選
    @Test
    func eligible_各種資格組合_只回傳符合資格訂單() {
        // Given
        let primary = OrderMergeFeatureTestSupport.makeOrder(id: "O1", status: .shipping)
        let orders = [
            primary,
            OrderMergeFeatureTestSupport.makeOrder(id: "O2", status: .purchased),
            OrderMergeFeatureTestSupport.makeOrder(id: "O3", status: .merged),
            OrderMergeFeatureTestSupport.makeOrder(id: "O4", status: .cancelled),
            OrderMergeFeatureTestSupport.makeOrder(id: "O5", status: .purchased, currency: .krw),
            OrderMergeFeatureTestSupport.makeOrder(id: "O6", status: .purchased, customer: "Bob"),
            OrderMergeFeatureTestSupport.makeOrder(id: "O7", status: .delivered),
        ]

        // When
        let eligible = OrderMergeCandidates.eligible(for: primary, in: orders)

        // Then
        #expect(eligible.map(\.id) == ["O2", "O7"])
    }

    /// 驗證輸入搜尋文字後，候選區段即時篩選，只保留商品名稱符合的訂單
    @Test
    @MainActor
    func binding_輸入搜尋文字_即時篩選候選訂單() async {
        // Given
        let primary = OrderMergeFeatureTestSupport.makeOrder(id: "O1", status: .shipping)
        let orders = [
            primary,
            OrderMergeFeatureTestSupport.makeOrder(id: "O2", status: .purchased, itemName: "香水"),
            OrderMergeFeatureTestSupport.makeOrder(id: "O3", status: .purchased, itemName: "外套"),
        ]

        let store = TestStore(
            initialState: OrderMergeFeature.State(
                primary: primary,
                orders: orders,
                dateContext: OrderMergeFeatureTestSupport.fixedDateContext
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

    /// 驗證候選訂單依日期分成今天與昨天區段，區段間與區段內都由新到舊排列，主訂單不列入
    @Test
    func candidateSections_多日期候選訂單_依日期分組並新到舊排序() {
        // Given
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt

        let reference = Date(timeIntervalSince1970: 1_770_000_000)
        let primary = OrderMergeFeatureTestSupport.makeOrder(id: "O1", status: .shipping)
        let orders = [
            primary,
            OrderMergeFeatureTestSupport.makeOrder(
                id: "O2",
                status: .purchased,
                date: reference.addingTimeInterval(-3_600)
            ),
            OrderMergeFeatureTestSupport.makeOrder(
                id: "O3",
                status: .purchased,
                date: reference.addingTimeInterval(-60)
            ),
            OrderMergeFeatureTestSupport.makeOrder(
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

    /// 驗證先依搜尋文字篩選再分組，沒有符合訂單的日期不產生區段，本例的昨天因此不出現
    @Test
    func candidateSections_輸入搜尋文字_只分組符合候選項目() {
        // Given
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt

        let reference = Date(timeIntervalSince1970: 1_770_000_000)
        let primary = OrderMergeFeatureTestSupport.makeOrder(id: "O1", status: .shipping)
        let orders = [
            primary,
            OrderMergeFeatureTestSupport.makeOrder(
                id: "O2",
                status: .purchased,
                itemName: "香水",
                date: reference.addingTimeInterval(-3_600)
            ),
            OrderMergeFeatureTestSupport.makeOrder(
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

    /// 驗證候選依建立合併流程時帶入的日期脈絡分組，即使注入的現在時間不同，東十四區午夜前後的候選仍分入今天、昨天與更早區段
    ///
    /// - Throws: 無法建立測試時區時由 `#require` 丟出
    /// - Note: 台北與 UTC 會把昨天候選併入今天，台北另會把更早候選歸為昨天
    @Test
    func candidateSections_日期脈絡為東十四區午夜_分成今天昨天與更早() throws {
        // Given
        var calendar = TestDependencies.fixedCalendar
        calendar.timeZone = try #require(TimeZone(identifier: "Pacific/Kiritimati"))
        let reference = Date(timeIntervalSince1970: 1_777_458_600)
        let primary = OrderMergeFeatureTestSupport.makeOrder(id: "PRIMARY", status: .shipping)
        let orders = [
            primary,
            OrderMergeFeatureTestSupport.makeOrder(
                id: "YESTERDAY",
                status: .purchased,
                date: Date(timeIntervalSince1970: 1_777_456_740)
            ),
            OrderMergeFeatureTestSupport.makeOrder(
                id: "EARLIER",
                status: .purchased,
                date: Date(timeIntervalSince1970: 1_777_309_200)
            ),
            OrderMergeFeatureTestSupport.makeOrder(
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

    /// 驗證候選清單最後一個區段附上篩選說明，並保留等於本地化鍵的客戶名稱
    ///
    /// - Throws: 候選區段為空時丟出測試錯誤
    @Test
    func candidateFilterNotice_最後一個區段_附上篩選說明() throws {
        // Given
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let reference = Date(timeIntervalSince1970: 1_770_000_000)
        let customerName = "orders.list.label.merged"
        let primary = OrderMergeFeatureTestSupport.makeOrder(
            id: "O1",
            status: .shipping,
            customer: customerName
        )
        let orders = [
            primary,
            OrderMergeFeatureTestSupport.makeOrder(
                id: "O2",
                status: .purchased,
                customer: customerName,
                date: reference.addingTimeInterval(-3_600)
            ),
            OrderMergeFeatureTestSupport.makeOrder(
                id: "O4",
                status: .purchased,
                customer: customerName,
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
        let sections = state.candidateSections(locale: Locale(identifier: "zh-Hant"))
        let lastSection = try #require(sections.last)

        // When
        let notice = state.candidateFilterNotice(for: lastSection, in: sections)

        // Then
        let resource = try #require(notice)
        #expect(resource.key == "orders.merge.message.candidateFilterNotice")
        let traditionalChineseNotice = "僅列出與主訂單同幣別 (JPY)、同客戶「orders.list.label.merged」的訂單；選擇後會以兩筆訂單整合的資料開啟確認表單。"
        let englishNotice = "Only orders with the same currency (JPY) and customer “orders.list.label.merged” are listed; selecting one opens the confirmation form with merged data."
        #expect(
            AppLanguage.resolve(resource, locale: Locale(identifier: "zh-Hant"))
                == traditionalChineseNotice
        )
        #expect(AppLanguage.resolve(resource, locale: Locale(identifier: "en")) == englishNotice)
    }

    /// 驗證兩個日期區段中較新的第一個區段不附上篩選說明
    ///
    /// - Throws: 候選區段為空時丟出測試錯誤
    @Test
    func candidateFilterNotice_非最後一個區段_不附上篩選說明() throws {
        // Given
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let reference = Date(timeIntervalSince1970: 1_770_000_000)
        let primary = OrderMergeFeatureTestSupport.makeOrder(id: "O1", status: .shipping)
        let orders = [
            primary,
            OrderMergeFeatureTestSupport.makeOrder(
                id: "O2",
                status: .purchased,
                date: reference.addingTimeInterval(-3_600)
            ),
            OrderMergeFeatureTestSupport.makeOrder(
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
        let sections = state.candidateSections(locale: Locale(identifier: "zh-Hant"))
        let firstSection = try #require(sections.first)

        // When
        let notice = state.candidateFilterNotice(for: firstSection, in: sections)

        // Then
        #expect(notice == nil)
    }
}
