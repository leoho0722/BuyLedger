//
//  OrderEditFeatureTests+PaymentMethod.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension OrderEditFeatureTests {

    /// 付款方式依主檔的無卡旗標判斷；不在主檔的名稱視為非無卡
    ///
    /// - Parameters:
    ///   - paymentMethod: 要查詢的付款方式名稱
    ///   - isCardless: 預期是否為無卡付款方式
    @Test(arguments: [
        (paymentMethod: "信用卡", isCardless: false),
        (paymentMethod: "無卡存款", isCardless: true),
        (paymentMethod: "未知付款方式", isCardless: false),
    ])
    func isSelectedPaymentMethodCardless_依付款方式查主檔_回傳無卡旗標(paymentMethod: String, isCardless: Bool) {
        // Given
        var state = OrderEditFeature.State(
            id: UUID(0),
            options: OrderEditOptions(
                paymentMethods: Self.paymentMethodCatalog,
                calendar: TestDependencies.fixedCalendar
            ),
            currentDate: TestDependencies.fixedNow
        )
        state.draft.paymentMethod = paymentMethod

        // When
        let isActualCardless = state.isSelectedPaymentMethodCardless

        // Then
        #expect(isActualCardless == isCardless)
    }

    /// 付款方式為無卡或銀行匯款時才顯示對帳狀態欄位；不在主檔的名稱不顯示
    ///
    /// - Parameters:
    ///   - paymentMethod: 要查詢的付款方式名稱
    ///   - shouldShowRow: 預期是否顯示對帳狀態欄位
    @Test(arguments: [
        (paymentMethod: "信用卡", shouldShowRow: false),
        (paymentMethod: "無卡存款", shouldShowRow: true),
        (paymentMethod: "銀行匯款", shouldShowRow: true),
        (paymentMethod: "未知付款方式", shouldShowRow: false),
    ])
    func shouldShowReconciliationStatusRow_依付款方式旗標_無卡或匯款才顯示(
        paymentMethod: String,
        shouldShowRow: Bool
    ) {
        // Given
        var state = OrderEditFeature.State(
            id: UUID(0),
            options: OrderEditOptions(
                paymentMethods: Self.paymentMethodCatalog,
                calendar: TestDependencies.fixedCalendar
            ),
            currentDate: TestDependencies.fixedNow
        )
        state.draft.paymentMethod = paymentMethod

        // When
        let shouldShowActualRow = state.shouldShowReconciliationStatusRow

        // Then
        #expect(shouldShowActualRow == shouldShowRow)
    }

    /// 付款方式依主檔的銀行匯款旗標判斷
    ///
    /// - Parameters:
    ///   - paymentMethod: 要查詢的付款方式名稱
    ///   - isBankTransfer: 預期是否為銀行匯款
    @Test(arguments: [
        (paymentMethod: "信用卡", isBankTransfer: false),
        (paymentMethod: "銀行匯款", isBankTransfer: true),
    ])
    func isSelectedPaymentMethodBankTransfer_依付款方式查主檔_回傳匯款旗標(
        paymentMethod: String,
        isBankTransfer: Bool
    ) {
        // Given
        var state = OrderEditFeature.State(
            id: UUID(0),
            options: OrderEditOptions(
                paymentMethods: Self.paymentMethodCatalog,
                calendar: TestDependencies.fixedCalendar
            ),
            currentDate: TestDependencies.fixedNow
        )
        state.draft.paymentMethod = paymentMethod

        // When
        let isActualBankTransfer = state.isSelectedPaymentMethodBankTransfer

        // Then
        #expect(isActualBankTransfer == isBankTransfer)
    }

    /// 尚未開啟選擇器時，點選付款方式按鈕會推入付款方式選擇器
    @Test
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

    /// 草稿尚無付款方式時，選取付款方式會寫入名稱
    @Test
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
