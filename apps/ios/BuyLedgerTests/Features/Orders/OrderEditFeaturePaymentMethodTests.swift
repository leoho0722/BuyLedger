//
//  OrderEditFeaturePaymentMethodTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrderEditFeature` 的單元測試，涵蓋無卡與匯款旗標，以及付款方式選擇器的推入與選取
struct OrderEditFeaturePaymentMethodTests {

    // MARK: - Properties

    /// 三種常用付款方式與對應旗標
    private static let paymentMethodCatalog: [PaymentMethodInfo] = [
        PaymentMethodInfo(
            name: "信用卡",
            isCardless: false,
            isBankTransfer: false,
            isCashOnDelivery: false
        ),
        PaymentMethodInfo(
            name: "無卡存款",
            isCardless: true,
            isBankTransfer: false,
            isCashOnDelivery: false
        ),
        PaymentMethodInfo(
            name: "orders.edit.label.bankTransfer",
            isCardless: false,
            isBankTransfer: true,
            isCashOnDelivery: false
        ),
    ]

    /// 驗證依主檔的無卡旗標判斷付款方式，不在主檔的名稱視為非無卡
    ///
    /// - Parameter testCase: 測試輸入與字面值預期結果
    @Test(arguments: [
        PaymentMethodCardlessCase(paymentMethod: "信用卡", isCardless: false),
        PaymentMethodCardlessCase(paymentMethod: "無卡存款", isCardless: true),
        PaymentMethodCardlessCase(paymentMethod: "未知付款方式", isCardless: false),
    ])
    func isSelectedPaymentMethodCardless_依付款方式查主檔_回傳無卡旗標(testCase: PaymentMethodCardlessCase) {
        // Given
        var state = OrderEditFeature.State(
            id: UUID(0),
            options: OrderEditOptions(
                paymentMethods: Self.paymentMethodCatalog,
                calendar: TestDependencies.fixedCalendar
            ),
            currentDate: TestDependencies.fixedNow
        )
        state.draft.paymentMethod = testCase.paymentMethod

        // When
        let isActualCardless = state.isSelectedPaymentMethodCardless

        // Then
        #expect(isActualCardless == testCase.isCardless)
    }

    /// 驗證對帳狀態欄位只在付款方式為無卡或銀行匯款時顯示，不在主檔的名稱不顯示
    ///
    /// - Parameter testCase: 測試輸入與字面值預期結果
    @Test(arguments: [
        ReconciliationRowCase(paymentMethod: "信用卡", shouldShowRow: false),
        ReconciliationRowCase(paymentMethod: "無卡存款", shouldShowRow: true),
        ReconciliationRowCase(paymentMethod: "orders.edit.label.bankTransfer", shouldShowRow: true),
        ReconciliationRowCase(paymentMethod: "未知付款方式", shouldShowRow: false),
    ])
    func shouldShowReconciliationStatusRow_依付款方式旗標_無卡或匯款才顯示(testCase: ReconciliationRowCase) {
        // Given
        var state = OrderEditFeature.State(
            id: UUID(0),
            options: OrderEditOptions(
                paymentMethods: Self.paymentMethodCatalog,
                calendar: TestDependencies.fixedCalendar
            ),
            currentDate: TestDependencies.fixedNow
        )
        state.draft.paymentMethod = testCase.paymentMethod

        // When
        let shouldShowActualRow = state.shouldShowReconciliationStatusRow

        // Then
        #expect(shouldShowActualRow == testCase.shouldShowRow)
    }

    /// 驗證依主檔的銀行匯款旗標判斷付款方式，只有銀行匯款方式的旗標為真
    ///
    /// - Parameter testCase: 測試輸入與字面值預期結果
    @Test(arguments: [
        BankTransferCase(paymentMethod: "信用卡", isBankTransfer: false),
        BankTransferCase(paymentMethod: "orders.edit.label.bankTransfer", isBankTransfer: true),
    ])
    func isSelectedPaymentMethodBankTransfer_依付款方式查主檔_回傳匯款旗標(testCase: BankTransferCase) {
        // Given
        var state = OrderEditFeature.State(
            id: UUID(0),
            options: OrderEditOptions(
                paymentMethods: Self.paymentMethodCatalog,
                calendar: TestDependencies.fixedCalendar
            ),
            currentDate: TestDependencies.fixedNow
        )
        state.draft.paymentMethod = testCase.paymentMethod

        // When
        let isActualBankTransfer = state.isSelectedPaymentMethodBankTransfer

        // Then
        #expect(isActualBankTransfer == testCase.isBankTransfer)
    }

    /// 驗證尚未開啟選擇器時，點選付款方式按鈕會推入付款方式選擇器，並把 `pickerRoute` 設為 `.paymentMethod`
    @Test
    @MainActor
    func pickers_點選付款方式按鈕時尚未開啟選擇器_推入付款方式選擇器() async {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.pickers(.view(.paymentMethodPickerTapped))) {
            $0.pickers.pickerRoute = .paymentMethod
        }

        // Then
        #expect(store.state.pickers.pickerRoute == .paymentMethod)
    }

    /// 驗證草稿尚無付款方式時，選取付款方式後草稿的 `paymentMethod` 寫入所選名稱
    @Test
    @MainActor
    func pickers_選取付款方式且草稿尚無付款方式_更新草稿() async {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.pickers(.view(.paymentMethodSelected("信用卡"))))

        // Then
        await store.receive(\.pickers.delegate.paymentMethodSelected, "信用卡") {
            $0.draft.paymentMethod = "信用卡"
        }
        #expect(store.state.draft.paymentMethod == "信用卡")
    }
}

// MARK: - Nested Types

extension OrderEditFeaturePaymentMethodTests {

    /// 付款方式的銀行匯款旗標案例
    struct BankTransferCase: Sendable {

        /// 要查詢的付款方式名稱
        let paymentMethod: String

        /// 預期是否為銀行匯款
        let isBankTransfer: Bool
    }

    /// 付款方式的對帳狀態欄位顯示案例
    struct ReconciliationRowCase: Sendable {

        /// 要查詢的付款方式名稱
        let paymentMethod: String

        /// 預期是否顯示對帳狀態欄位
        let shouldShowRow: Bool
    }

    /// 付款方式的無卡旗標案例
    struct PaymentMethodCardlessCase: Sendable {

        /// 要查詢的付款方式名稱
        let paymentMethod: String

        /// 預期是否為無卡付款方式
        let isCardless: Bool
    }
}
