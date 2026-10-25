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

/// `OrderEditFeature` 與 `OrderEditOptions` 的單元測試，涵蓋初始化整理選項、畫面載入與新增選項套用
struct OrderEditOptionsTests {

    /// 驗證新訂單表單出現時只設定初始焦點，照片維持已載入，且不呼叫任何服務
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

    /// 驗證照片已載入的既有訂單表單出現時，不呼叫任何服務，也不設定焦點
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

    /// 驗證選項去重，將草稿已有但選項缺少的值去除前後空白後補入清單，同名付款方式旗標以最後一筆主檔為準，且初始化不算修改
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

    /// 驗證草稿的付款方式去除空白後與主檔同名時，無卡、匯款與貨到付款的旗標沿用主檔
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

    /// 驗證完整時間依注入行事曆的東十四區時區格式化，顯示為 2026/04/26 14:30:00，不跟隨執行環境的時區
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

    /// 驗證新增訂單來源、商品類別或對帳狀態時，名稱依自然排序插入 (如 A2 排在 A10 前)，重複名稱不改動清單，其餘選項與行事曆不變
    ///
    /// - Parameter testCase: 測試輸入與字面值預期結果
    @Test(arguments: [
        NameAdditionCase(kind: .orderSource, name: "A2", expectedNames: ["A2", "A10", "A20"]),
        NameAdditionCase(kind: .category, name: "A2", expectedNames: ["A2", "A10", "A20"]),
        NameAdditionCase(
            kind: .reconciliationStatus,
            name: "A2",
            expectedNames: ["A2", "A10", "A20"]
        ),
        NameAdditionCase(kind: .orderSource, name: "A10", expectedNames: ["A10", "A20"]),
        NameAdditionCase(kind: .category, name: "A10", expectedNames: ["A10", "A20"]),
        NameAdditionCase(kind: .reconciliationStatus, name: "A10", expectedNames: ["A10", "A20"]),
    ])
    func applyAddition_新增或重複名稱_自然排序去重並保留其他欄位(testCase: NameAdditionCase) {
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
            kind: testCase.kind.lookupKind,
            name: testCase.name,
            flags: .none
        )
        var expected = original
        switch testCase.kind {
        case .orderSource:
            expected.orderSources = testCase.expectedNames

        case .category:
            expected.categories = testCase.expectedNames

        case .reconciliationStatus:
            expected.reconciliationStatuses = testCase.expectedNames
        }

        // When
        options.applyAddition(request)

        // Then
        #expect(options == expected)
    }

    /// 驗證新增付款方式時，不同名的依自然排序插入，同名的原位覆寫為新的三種旗標且不重複加入
    ///
    /// - Parameter testCase: 測試輸入與字面值預期結果
    @Test(arguments: [
        PaymentMethodAdditionCase(name: "A2", isExisting: false, isBankTransfer: true),
        PaymentMethodAdditionCase(name: "A10", isExisting: true, isBankTransfer: false),
    ])
    func applyAddition_新增或同名付款方式_自然排序去重並完整覆寫旗標(testCase: PaymentMethodAdditionCase) {
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
            paymentMethods: testCase.isExisting ? [first, existing] : [existing],
            reconciliationStatuses: ["待對帳"],
            campaigns: ["May-JP"],
            currencyCodes: [.jpy],
            calendar: TestDependencies.fixedCalendar
        )
        var options = original
        let request = LookupAdditionRequest(
            id: UUID(0),
            kind: .paymentMethod,
            name: testCase.name,
            flags: PaymentMethodFlags(
                isCardless: true,
                isBankTransfer: testCase.isBankTransfer,
                isCashOnDelivery: true
            )
        )
        let updated = PaymentMethodInfo(
            name: testCase.name,
            isCardless: true,
            isBankTransfer: testCase.isBankTransfer,
            isCashOnDelivery: true
        )
        var expected = original
        expected.paymentMethods = testCase.isExisting ? [first, updated] : [updated, existing]

        // When
        options.applyAddition(request)

        // Then
        #expect(options == expected)
    }
}

// MARK: - Nested Types

extension OrderEditOptionsTests {

    /// 只包含以名稱新增的三種選項，付款方式另有旗標測試
    enum NameOptionKind: Sendable {

        /// 訂單來源
        case orderSource

        /// 商品類別
        case category

        /// 對帳狀態
        case reconciliationStatus

        /// 新增請求使用的主檔種類
        var lookupKind: LookupKind {
            switch self {
            case .orderSource:
                .orderSource

            case .category:
                .category

            case .reconciliationStatus:
                .reconciliationStatus
            }
        }
    }

    /// 付款方式新增或覆寫的輸入旗標
    struct PaymentMethodAdditionCase: Sendable {

        /// 新增或覆寫的付款方式名稱
        let name: String

        /// 名稱是否已在原清單中
        let isExisting: Bool

        /// 新付款方式是否為銀行匯款
        let isBankTransfer: Bool
    }

    /// 名稱選項的新增輸入與預期排序
    struct NameAdditionCase: Sendable {

        /// 訂單來源、商品類別或對帳狀態
        let kind: NameOptionKind

        /// 新增或重複的名稱
        let name: String

        /// 去重與自然排序後的名稱
        let expectedNames: [String]
    }
}
