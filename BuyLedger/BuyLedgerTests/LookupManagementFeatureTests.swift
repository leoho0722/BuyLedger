//
//  LookupManagementFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/29.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import BuyLedger

@MainActor
struct LookupManagementFeatureTests {

    // MARK: - Tests

    @Test func verificationStatusKindLoadsFromRepository() async {
        let store = TestStore(initialState: LookupManagementFeature.State(kind: .verificationStatus)) {
            LookupManagementFeature()
        } withDependencies: {
            $0[VerificationStatusRepository.self] = VerificationStatusRepository(
                fetchVerificationStatuses: { ["待對帳", "對帳成功"] },
                addVerificationStatus: { _ in },
                removeVerificationStatus: { _ in },
                renameVerificationStatus: { _, _ in }
            )
        }

        await store.send(.task)
        await store.receive(\.verificationStatusItemsLoaded) {
            $0.items = ["待對帳", "對帳成功"]
            $0.hasLoaded = true
        }
    }

    @Test func verificationStatusAddConfirmedAppendsItem() async {
        let store = TestStore(initialState: LookupManagementFeature.State(kind: .verificationStatus)) {
            LookupManagementFeature()
        } withDependencies: {
            $0[VerificationStatusRepository.self] = .testValue
        }
        store.exhaustivity = .off

        // 對帳狀態無 isCardless / isBankTransfer 概念，旗標被忽略；僅把名稱加入 items。
        await store.send(.addConfirmed(name: "待對帳", isCardless: false, isBankTransfer: false)) {
            $0.items = ["待對帳"]
        }
        await store.finish()
    }

    @Test func editConfirmedRenamesPaymentMethodAndClearsFlag() async {
        // 關鍵 edge case：改名同時「取消勾選」銀行匯款。
        // rename 的合併規則會保留舊旗標，但編輯為權威設定，最終必須以使用者實際勾選 (false) 為準。
        var state = LookupManagementFeature.State(kind: .paymentMethod)
        state.items = ["匯款"]
        state.paymentMethodIsBankTransfer = ["匯款": true]
        state.paymentMethodIsCardless = ["匯款": false]
        state.hasLoaded = true

        let store = TestStore(initialState: state) {
            LookupManagementFeature()
        } withDependencies: {
            $0[PaymentMethodRepository.self] = .testValue
            $0[OrderRepository.self] = .testValue
        }
        store.exhaustivity = .off

        await store.send(.editConfirmed(originalName: "匯款", name: "銀行匯款", isCardless: false, isBankTransfer: false)) {
            $0.items = ["銀行匯款"]
            $0.paymentMethodIsBankTransfer = ["銀行匯款": false]
            $0.paymentMethodIsCardless = ["銀行匯款": false]
        }
        await store.finish()
    }

    @Test func editConfirmedKeepsNameAndUpdatesFlags() async {
        var state = LookupManagementFeature.State(kind: .paymentMethod)
        state.items = ["銀行匯款"]
        state.paymentMethodIsBankTransfer = ["銀行匯款": false]
        state.paymentMethodIsCardless = ["銀行匯款": false]
        state.hasLoaded = true

        let store = TestStore(initialState: state) {
            LookupManagementFeature()
        } withDependencies: {
            $0[PaymentMethodRepository.self] = .testValue
            $0[OrderRepository.self] = .testValue
        }
        store.exhaustivity = .off

        // 名稱不變、把銀行匯款旗標打開。
        await store.send(.editConfirmed(originalName: "銀行匯款", name: "銀行匯款", isCardless: false, isBankTransfer: true)) {
            $0.items = ["銀行匯款"]
            $0.paymentMethodIsBankTransfer = ["銀行匯款": true]
        }
        await store.finish()
    }
}
