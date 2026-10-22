//
//  OrderEditOptionsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/7.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// 驗證訂單編輯選項在初始化時整理，畫面出現時只處理焦點與照片
struct OrderEditOptionsTests {

    /// 新訂單表單出現時只設定初始焦點，所有服務維持未實作也不讀取選項
    @Test
    @MainActor
    func task_新訂單且所有服務維持未實作_只設定初始焦點() async {
        // Given
        var initial = OrderEditFeature.State(
            original: nil,
            id: UUID(0),
            options: OrderEditOptions(calendar: TestDependencies.fixedCalendar),
            currentDate: TestDependencies.fixedNow
        )
        initial.photos.photoLoadPhase = .loaded
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.task)) {
            $0.focusedField = .customerName
        }

        // Then
        await store.finish()
        #expect(store.state.photos.photoLoadPhase == .loaded)
    }

    /// 照片已載入的既有訂單表單出現時，所有服務維持未實作也不讀取選項
    @Test
    @MainActor
    func task_照片已載入的既有訂單且所有服務維持未實作_不讀取任何資料() async {
        // Given
        var initial = OrderEditFeature.State(
            original: LedgerOrder.fixture(),
            id: UUID(0),
            options: OrderEditOptions(calendar: TestDependencies.fixedCalendar),
            currentDate: TestDependencies.fixedNow
        )
        initial.photos.photoLoadPhase = .loaded
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.task))

        // Then
        await store.finish()
        #expect(store.state.focusedField == nil)
    }

    /// 選項依名稱去重並補入既有草稿的值，付款旗標以最後一筆主檔為準
    @Test
    func init_選項重複且缺少草稿值_整理清單並保留付款旗標() {
        // Given
        let cardless = PaymentMethodInfo(
            name: "A",
            isCardless: true,
            isBankTransfer: false,
            isCashOnDelivery: false
        )
        let ordinary = PaymentMethodInfo(
            name: "A",
            isCardless: false,
            isBankTransfer: false,
            isCashOnDelivery: false
        )
        let original = LedgerOrder.fixture(
            currency: .krw,
            orderSource: " B ",
            categories: [" B ", " "],
            paymentMethod: " B ",
            reconciliationStatus: " B ",
            campaignNames: [" B ", " "]
        )
        let options = OrderEditOptions(
            orderSources: ["A", "A"],
            categories: ["A", "A"],
            paymentMethods: [ordinary, cardless],
            reconciliationStatuses: ["A", "A"],
            campaigns: ["A", "A"],
            currencyCodes: [.jpy, .jpy],
            calendar: TestDependencies.fixedCalendar
        )

        // When
        let state = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            options: options,
            currentDate: TestDependencies.fixedNow
        )

        // Then
        #expect(state.pickers.options.orderSources == ["A", "B"])
        #expect(state.pickers.options.categories == ["A", "B"])
        #expect(state.pickers.options.reconciliationStatuses == ["A", "B"])
        #expect(state.pickers.options.campaigns == ["A", "B"])
        #expect(state.pickers.options.currencyCodes == [.jpy, .krw])
        #expect(
            state.pickers.options.paymentMethods == [
                cardless,
                PaymentMethodInfo(
                    name: "B",
                    isCardless: false,
                    isBankTransfer: false,
                    isCashOnDelivery: false
                ),
            ]
        )
        #expect(state.isDirty == false)
    }

    /// 草稿既有付款名稱與主檔相同時，保留主檔的三種分類旗標
    @Test
    func init_草稿付款方式存在主檔_保留主檔旗標() {
        // Given
        let method = PaymentMethodInfo(
            name: "A",
            isCardless: true,
            isBankTransfer: true,
            isCashOnDelivery: true
        )
        let options = OrderEditOptions(
            paymentMethods: [method],
            calendar: TestDependencies.fixedCalendar
        )

        // When
        let state = OrderEditFeature.State(
            original: LedgerOrder.fixture(paymentMethod: " A "),
            id: UUID(0),
            options: options,
            currentDate: TestDependencies.fixedNow
        )

        // Then
        #expect(state.pickers.options.paymentMethods == [method])
        #expect(state.isSelectedPaymentMethodCardless)
        #expect(state.isSelectedPaymentMethodBankTransfer)
        #expect(state.isSelectedPaymentMethodCOD)
    }

    /// 完整時間以表單建立時注入的東十四區時區 (`Pacific/Kiritimati`) 顯示
    ///
    /// - Throws: 時區或指定訂單時間無法建立時由 `#require` 丟出
    @Test
    func fullTimestamp_注入東十四區行事曆_顯示當地訂單時間() throws {
        // Given
        var calendar = TestDependencies.fixedCalendar
        calendar.timeZone = try #require(TimeZone(identifier: "Pacific/Kiritimati"))
        let components = DateComponents(
            year: 2026,
            month: 4,
            day: 26,
            hour: 14,
            minute: 30,
            second: 0
        )
        let date = try #require(calendar.date(from: components))
        let state = OrderEditFeature.State(
            original: LedgerOrder.fixture(date: date),
            id: UUID(0),
            options: OrderEditOptions(calendar: calendar),
            currentDate: TestDependencies.fixedNow
        )

        // When
        let timestamp = OrderFormatters.fullTimestamp(
            state.draft.date,
            calendar: state.calendar,
            locale: Locale(identifier: "zh-Hant_TW")
        )

        // Then
        #expect(timestamp == "2026/04/26 14:30:00")
    }

    /// 新增三種名稱選項時自然排序，重複名稱維持原清單，其餘選項與行事曆不變
    ///
    /// - Parameters:
    ///   - kind: 訂單來源、商品類別或對帳狀態
    ///   - name: 新增或重複的名稱
    ///   - expectedNames: 去重與自然排序後的名稱
    @Test(arguments: [
        (LookupKind.orderSource, "A2", ["A2", "A10", "A20"]),
        (.category, "A2", ["A2", "A10", "A20"]),
        (.reconciliationStatus, "A2", ["A2", "A10", "A20"]),
        (.orderSource, "A10", ["A10", "A20"]),
        (.category, "A10", ["A10", "A20"]),
        (.reconciliationStatus, "A10", ["A10", "A20"]),
    ])
    func applyAddition_新增或重複名稱_自然排序去重並保留其他欄位(
        kind: LookupKind,
        name: String,
        expectedNames: [String]
    ) {
        // Given
        let original = OrderEditOptions(
            orderSources: ["A10", "A20"],
            categories: ["A10", "A20"],
            paymentMethods: [PaymentMethodInfo(name: "現金", flags: .none)],
            reconciliationStatuses: ["A10", "A20"],
            campaigns: ["May-JP"],
            currencyCodes: [.twd],
            calendar: TestDependencies.fixedCalendar
        )
        var options = original
        let request = LookupAdditionRequest(
            id: UUID(0),
            kind: kind,
            name: name,
            flags: .none
        )
        var expected = original
        switch kind {
        case .orderSource:
            expected.orderSources = expectedNames

        case .category:
            expected.categories = expectedNames

        case .reconciliationStatus:
            expected.reconciliationStatuses = expectedNames

        case .paymentMethod:
            Issue.record("付款方式應使用專屬測試案例")
        }

        // When
        options.applyAddition(request)

        // Then
        #expect(options == expected)
    }

    /// 新付款方式自然排序插入，同名付款方式原位覆寫三種旗標且不重複加入
    ///
    /// - Parameters:
    ///   - name: 新增或覆寫的付款方式名稱
    ///   - isExisting: 名稱是否已在原清單中
    ///   - isBankTransfer: 新付款方式是否為銀行匯款
    @Test(arguments: [
        ("A2", false, true),
        ("A10", true, false),
    ])
    func applyAddition_新增或同名付款方式_自然排序去重並完整覆寫旗標(
        name: String,
        isExisting: Bool,
        isBankTransfer: Bool
    ) {
        // Given
        let first = PaymentMethodInfo(name: "A2", flags: .none)
        let existing = PaymentMethodInfo(
            name: "A10",
            isCardless: false,
            isBankTransfer: true,
            isCashOnDelivery: false
        )
        let original = OrderEditOptions(
            orderSources: ["LINE"],
            categories: ["美妝"],
            paymentMethods: isExisting ? [first, existing] : [existing],
            reconciliationStatuses: ["待對帳"],
            campaigns: ["May-JP"],
            currencyCodes: [.jpy],
            calendar: TestDependencies.fixedCalendar
        )
        var options = original
        let request = LookupAdditionRequest(
            id: UUID(0),
            kind: .paymentMethod,
            name: name,
            flags: PaymentMethodFlags(
                isCardless: true,
                isBankTransfer: isBankTransfer,
                isCashOnDelivery: true
            )
        )
        let updated = PaymentMethodInfo(
            name: name,
            isCardless: true,
            isBankTransfer: isBankTransfer,
            isCashOnDelivery: true
        )
        var expected = original
        expected.paymentMethods = isExisting ? [first, updated] : [updated, existing]

        // When
        options.applyAddition(request)

        // Then
        #expect(options == expected)
    }
}
