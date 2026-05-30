//
//  OrderEditFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import BuyLedger

@MainActor
struct OrderEditFeatureTests {
    
    // MARK: - Tests
    
    @Test func bindingUpdatesDraftCustomerName() async {
        let store = TestStore(initialState: OrderEditFeature.State()) {
            OrderEditFeature()
        }
        
        await store.send(\.binding.draftCustomerName, "新客戶") {
            $0.draftCustomerName = "新客戶"
        }
    }
    
    @Test func bindingUpdatesDraftCategory() async {
        let store = TestStore(initialState: OrderEditFeature.State()) {
            OrderEditFeature()
        }
        
        await store.send(\.binding.draftCategory, "美妝") {
            $0.draftCategory = "美妝"
        }
    }
    
    @Test func bindingUpdatesDraftStatus() async {
        let store = TestStore(initialState: OrderEditFeature.State()) {
            OrderEditFeature()
        }
        
        await store.send(\.binding.draftStatus, .delivered) {
            $0.draftStatus = .delivered
        }
    }
    
    @Test func bindingUpdatesDraftCurrency() async {
        let store = TestStore(initialState: OrderEditFeature.State()) {
            OrderEditFeature()
        }
        
        await store.send(\.binding.draftCurrency, .jpy) {
            $0.draftCurrency = .jpy
        }
    }
    
    @Test func bindingUpdatesDraftChargedAmount() async {
        let store = TestStore(initialState: OrderEditFeature.State()) {
            OrderEditFeature()
        }
        
        await store.send(\.binding.draftChargedAmount, 12_345) {
            $0.draftChargedAmount = 12_345
        }
    }
    
    @Test func bindingUpdatesDraftCostFields() async {
        let store = TestStore(initialState: OrderEditFeature.State()) {
            OrderEditFeature()
        }
        
        await store.send(\.binding.draftItemCost, 5_000) {
            $0.draftItemCost = 5_000
        }
        await store.send(\.binding.draftDomesticShipping, 80) {
            $0.draftDomesticShipping = 80
        }
        await store.send(\.binding.draftInternationalShipping, 320) {
            $0.draftInternationalShipping = 320
        }
        await store.send(\.binding.draftCardFeeRate, 0.015) {
            $0.draftCardFeeRate = 0.015
        }
        await store.send(\.binding.draftPlatformFeeRate, 0.03) {
            $0.draftPlatformFeeRate = 0.03
        }
    }
    
    @Test func draftPrefillsFromOriginal() {
        let original = LedgerOrder.sampleOrders[0]
        let state = OrderEditFeature.State(original: original)
        
        #expect(state.draftCustomerName == original.customer.name)
        #expect(state.draftCategory == original.category)
        #expect(state.draftStatus == original.status)
        #expect(state.draftCurrency == original.currency)
        #expect(state.draftChargedAmount == original.chargedAmount)
        #expect(state.draftItemCost == original.itemCost)
        #expect(state.draftDomesticShipping == original.domesticShipping)
        #expect(state.draftInternationalShipping == original.internationalShipping)
        #expect(state.draftCardFeeRate == original.cardFeeRate)
        #expect(state.draftPlatformFeeRate == original.platformFeeRate)
        #expect(state.draftNotes == original.notes)
    }
    
    @Test func isSelectedPaymentMethodCardlessReflectsMasterFlag() {
        // 主檔中「無卡存款」isCardless == true、「信用卡」isCardless == false。
        let state = OrderEditFeature.State(
            availablePaymentMethods: [
                PaymentMethodInfo(name: "信用卡", isCardless: false, isBankTransfer: false),
                PaymentMethodInfo(name: "無卡存款", isCardless: true, isBankTransfer: false),
            ]
        )

        var mutable = state
        mutable.draftPaymentMethod = "信用卡"
        #expect(mutable.isSelectedPaymentMethodCardless == false)

        mutable.draftPaymentMethod = "無卡存款"
        #expect(mutable.isSelectedPaymentMethodCardless == true)

        // 不在主檔的暫存值預設視為非無卡。
        mutable.draftPaymentMethod = "未知付款方式"
        #expect(mutable.isSelectedPaymentMethodCardless == false)
    }

    @Test func showsVerificationStatusRowForCardlessOrBankTransfer() {
        // 主檔中「無卡存款」為無卡、「銀行匯款」為銀行匯款、「信用卡」兩者皆否。
        let state = OrderEditFeature.State(
            availablePaymentMethods: [
                PaymentMethodInfo(name: "信用卡", isCardless: false, isBankTransfer: false),
                PaymentMethodInfo(name: "無卡存款", isCardless: true, isBankTransfer: false),
                PaymentMethodInfo(name: "銀行匯款", isCardless: false, isBankTransfer: true),
            ]
        )

        var mutable = state
        // 信用卡：非無卡、非銀行匯款 → 不顯示對帳狀態 row。
        mutable.draftPaymentMethod = "信用卡"
        #expect(mutable.isSelectedPaymentMethodBankTransfer == false)
        #expect(mutable.showsVerificationStatusRow == false)

        // 無卡存款：無卡 → 顯示。
        mutable.draftPaymentMethod = "無卡存款"
        #expect(mutable.showsVerificationStatusRow == true)

        // 銀行匯款：銀行匯款 → 顯示。
        mutable.draftPaymentMethod = "銀行匯款"
        #expect(mutable.isSelectedPaymentMethodBankTransfer == true)
        #expect(mutable.showsVerificationStatusRow == true)

        // 不在主檔的暫存值預設視為兩者皆否 → 不顯示。
        mutable.draftPaymentMethod = "未知付款方式"
        #expect(mutable.showsVerificationStatusRow == false)
    }

    @Test func addVerificationStatusTappedAppliesAndExtendsOptions() async {
        let store = TestStore(initialState: OrderEditFeature.State()) {
            OrderEditFeature()
        }

        await store.send(.addVerificationStatusTapped("待對帳")) {
            $0.availableVerificationStatuses = ["待對帳"]
            $0.draftVerificationStatus = "待對帳"
        }

        // 再新增一筆，清單依 locale 排序 (localizedStandardCompare 下「待」排在「對」前)、draft 切換為最新值。
        await store.send(.addVerificationStatusTapped("對帳成功")) {
            $0.availableVerificationStatuses = ["待對帳", "對帳成功"]
            $0.draftVerificationStatus = "對帳成功"
        }
    }

    @Test func draftPrefillsVerificationStatusFromOriginal() {
        let original = LedgerOrder(
            id: "BL-TEST-RS",
            customer: LedgerCustomer(name: "對帳測試", initials: "RS", tier: .regular),
            status: .confirmed,
            currency: .twd,
            date: Date(timeIntervalSince1970: 0),
            items: [],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 0,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "蝦皮",
            category: "美妝",
            paymentMethod: "銀行匯款",
            notes: "",
            verificationStatus: "待對帳",
            campaignName: "",
            paymentReceiptStatus: .pending
        )

        let state = OrderEditFeature.State(original: original)
        #expect(state.draftVerificationStatus == "待對帳")
        // 原訂單的對帳狀態若不在傳入清單，初始化時會補進可選清單。
        #expect(state.availableVerificationStatuses.contains("待對帳"))
    }

    @Test func newDraftStartsEmpty() {
        let state = OrderEditFeature.State()

        #expect(state.draftCustomerName.isEmpty)
        #expect(state.draftCategory.isEmpty)
        #expect(state.draftStatus == .quoting)
        #expect(state.draftCurrency == .twd)
        #expect(state.draftChargedAmount == 0)
        #expect(state.draftCardlessDeductionAmount == 0)
        #expect(state.draftCardlessSupplementAmount == 0)
        #expect(state.draftItemCost == 0)
        #expect(state.draftDomesticShipping == 0)
        #expect(state.draftInternationalShipping == 0)
        #expect(state.draftCardFeeRate == 0)
        #expect(state.draftPlatformFeeRate == 0)
        #expect(state.draftNotes.isEmpty)
        #expect(state.original == nil)
        #expect(state.availablePaymentMethods.isEmpty)
    }
}
