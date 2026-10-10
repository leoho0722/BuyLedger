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
        #expect(state.pickers.availableOrderSources == ["A", "B"])
        #expect(state.pickers.availableCategories == ["A", "B"])
        #expect(state.pickers.availableReconciliationStatuses == ["A", "B"])
        #expect(state.pickers.availableCampaigns == ["A", "B"])
        #expect(state.pickers.availableCurrencies == [.jpy, .krw])
        #expect(
            state.pickers.availablePaymentMethods == [
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
        #expect(state.pickers.availablePaymentMethods == [method])
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
}
