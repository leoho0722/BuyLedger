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

    @Test func reconciliationStatusKindLoadsFromRepository() async {
        let store = TestStore(initialState: LookupManagementFeature.State(kind: .reconciliationStatus)) {
            LookupManagementFeature()
        } withDependencies: {
            $0[ReconciliationStatusRepository.self] = ReconciliationStatusRepository(
                fetchReconciliationStatuses: { ["待對帳", "對帳成功"] },
                addReconciliationStatus: { _ in },
                removeReconciliationStatus: { _ in },
                renameReconciliationStatus: { _, _ in }
            )
        }

        await store.send(.task)
        await store.receive(\.reconciliationStatusItemsLoaded) {
            $0.items = ["待對帳", "對帳成功"]
            $0.hasLoaded = true
        }
    }

    @Test func reconciliationStatusAddConfirmedAppendsItem() async {
        let store = TestStore(initialState: LookupManagementFeature.State(kind: .reconciliationStatus)) {
            LookupManagementFeature()
        } withDependencies: {
            $0[ReconciliationStatusRepository.self] = .testValue
        }
        store.exhaustivity = .off

        // 對帳狀態無 isCardless / isBankTransfer 概念，旗標被忽略；僅把名稱加入 items
        await store.send(.addConfirmed(name: "待對帳", isCardless: false, isBankTransfer: false, isCashOnDelivery: false)) {
            $0.items = ["待對帳"]
        }
        await store.finish()
    }

    @Test func editConfirmedRenamesPaymentMethodAndClearsFlag() async {
        // 關鍵 edge case：改名同時「取消勾選」銀行匯款
        // rename 的合併規則會保留舊旗標，但編輯為權威設定，最終必須以使用者實際勾選 (false) 為準
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

        await store.send(.editConfirmed(originalName: "匯款", name: "銀行匯款", isCardless: false, isBankTransfer: false, isCashOnDelivery: false)) {
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

        // 名稱不變、把銀行匯款旗標打開
        await store.send(.editConfirmed(originalName: "銀行匯款", name: "銀行匯款", isCardless: false, isBankTransfer: true, isCashOnDelivery: false)) {
            $0.items = ["銀行匯款"]
            $0.paymentMethodIsBankTransfer = ["銀行匯款": true]
        }
        await store.finish()
    }

    // MARK: - 新增流程 (addButtonTapped) Tests

    /// 純名稱 kind 的新增併入 destination；互斥由型別系統保證，不再有獨立呈現旗標
    @Test func addButtonTappedForCategoryPresentsTheNameOnlyForm() async {
        let store = TestStore(initialState: LookupManagementFeature.State(kind: .category)) {
            LookupManagementFeature()
        }

        await store.send(.addButtonTapped) {
            $0.destination = .addNameOnly(LookupManagementFeature.Destination.AddNameOnlyFeature.State())
        }
    }

    @Test func addButtonTappedForPaymentMethodPresentsThePaymentMethodForm() async {
        let store = TestStore(initialState: LookupManagementFeature.State(kind: .paymentMethod)) {
            LookupManagementFeature()
        }

        await store.send(.addButtonTapped) {
            $0.destination = .addPaymentMethod(LookupManagementFeature.Destination.AddPaymentMethodFeature.State())
        }
    }

    @Test func addButtonTappedForReconciliationStatusPresentsTheNameOnlyForm() async {
        let store = TestStore(initialState: LookupManagementFeature.State(kind: .reconciliationStatus)) {
            LookupManagementFeature()
        }

        await store.send(.addButtonTapped) {
            $0.destination = .addNameOnly(LookupManagementFeature.Destination.AddNameOnlyFeature.State())
        }
    }

    // MARK: - 刪除流程 Tests

    /// 破壞性刪除一律先確認，確認前不得動到任何狀態
    @Test func deleteButtonTappedPresentsConfirmationWithoutMutatingState() async {
        var state = LookupManagementFeature.State(kind: .category)
        state.items = ["美妝", "零食"]
        let store = TestStore(initialState: state) {
            LookupManagementFeature()
        }

        await store.send(.deleteButtonTapped("美妝")) {
            $0.deletionConfirmation = AlertState {
                TextState("刪除項目")
            } actions: {
                ButtonState(role: .destructive, action: .confirmDelete("美妝")) {
                    TextState("刪除")
                }
                ButtonState(role: .cancel) {
                    TextState("取消")
                }
            } message: {
                TextState("刪除「美妝」後，引用它的既有訂單會失去這個欄位值。此操作無法復原。")
            }
        }

        #expect(store.state.items == ["美妝", "零食"])
    }

    /// 寫入成功後才更新狀態；寫入失敗時清單維持原狀，不會出現狀態與資料庫不一致
    @Test func deleteFailureLeavesTheListUnchanged() async {
        var state = LookupManagementFeature.State(kind: .category)
        state.items = ["美妝", "零食"]
        let store = TestStore(initialState: state) {
            LookupManagementFeature()
        } withDependencies: {
            $0[CategoryRepository.self].removeCategory = { _ in
                throw LookupTestFailure.boom
            }
        }
        store.exhaustivity = .off

        await store.send(.deleteRequested("美妝"))
        await store.receive(\.loadFailed)

        #expect(store.state.items == ["美妝", "零食"])
    }

    @Test func deleteSuccessRemovesTheItem() async {
        var state = LookupManagementFeature.State(kind: .category)
        state.items = ["美妝", "零食"]
        let store = TestStore(initialState: state) {
            LookupManagementFeature()
        } withDependencies: {
            $0[CategoryRepository.self].removeCategory = { _ in }
        }
        store.exhaustivity = .off

        await store.send(.deleteRequested("美妝"))
        await store.receive(\.deleteSucceeded)

        #expect(store.state.items == ["零食"])
    }

    // MARK: - Destination (改名 / 編輯付款方式) Tests

    @Test func renameCanSaveIsFalseWhenDraftEmptyOrUnchanged() {
        let unchanged = LookupManagementFeature.Destination.RenameFeature.State(originalName: "類別", draft: "類別")
        #expect(unchanged.canSave == false)

        let blank = LookupManagementFeature.Destination.RenameFeature.State(originalName: "類別", draft: "   ")
        #expect(blank.canSave == false)

        let changed = LookupManagementFeature.Destination.RenameFeature.State(originalName: "類別", draft: "新類別")
        #expect(changed.canSave == true)
    }

    @Test func renameButtonTappedPresentsRenameDestinationWithOriginalNameSnapshot() async {
        var state = LookupManagementFeature.State(kind: .category)
        state.items = ["舊類別"]
        state.hasLoaded = true

        let store = TestStore(initialState: state) {
            LookupManagementFeature()
        }

        // 由 reducer 以點擊當下的名稱同時初始化 originalName 與 draft，取代 view 端直接組裝表單初值
        await store.send(.renameButtonTapped(name: "舊類別")) {
            $0.destination = .rename(
                LookupManagementFeature.Destination.RenameFeature.State(originalName: "舊類別", draft: "舊類別")
            )
        }
    }

    @Test func renameDestinationLifecycleUpdatesDraftSavesAndDismisses() async {
        var state = LookupManagementFeature.State(kind: .category)
        state.items = ["舊類別"]
        state.hasLoaded = true

        let store = TestStore(initialState: state) {
            LookupManagementFeature()
        } withDependencies: {
            $0[CategoryRepository.self] = .testValue
            $0[OrderRepository.self] = .testValue
        }

        await store.send(.renameButtonTapped(name: "舊類別")) {
            $0.destination = .rename(
                LookupManagementFeature.Destination.RenameFeature.State(originalName: "舊類別", draft: "舊類別")
            )
        }

        await store.send(.destination(.presented(.rename(.draftChanged("新類別"))))) {
            $0.destination = .rename(
                LookupManagementFeature.Destination.RenameFeature.State(originalName: "舊類別", draft: "新類別")
            )
        }

        #expect(store.state.destination?.rename?.canSave == true)

        // 儲存：destination 攜帶的草稿轉送既有 renameRequested domain effect，並在同一步 dismiss
        await store.send(.destination(.presented(.rename(.saveButtonTapped)))) {
            $0.destination = nil
        }

        await store.receive(\.renameRequested) {
            $0.items = ["新類別"]
        }

        await store.finish()
    }

    @Test func renameSaveButtonTappedNoOpsWhenCannotSave() async {
        var state = LookupManagementFeature.State(kind: .category)
        state.items = ["類別"]
        state.hasLoaded = true

        let store = TestStore(initialState: state) {
            LookupManagementFeature()
        }

        await store.send(.renameButtonTapped(name: "類別")) {
            $0.destination = .rename(
                LookupManagementFeature.Destination.RenameFeature.State(originalName: "類別", draft: "類別")
            )
        }

        // 草稿與原名相同，canSave 為 false；儲存為 no-op，destination 維持呈現、不觸發 renameRequested
        await store.send(.destination(.presented(.rename(.saveButtonTapped))))
    }

    @Test func editButtonTappedPresentsEditPaymentMethodDestinationWithFlagSnapshot() async {
        var state = LookupManagementFeature.State(kind: .paymentMethod)
        state.items = ["匯款"]
        state.paymentMethodIsBankTransfer = ["匯款": true]
        state.hasLoaded = true

        let store = TestStore(initialState: state) {
            LookupManagementFeature()
        }

        // 由 reducer 自 paymentMethodIsCardless / paymentMethodIsBankTransfer / paymentMethodIsCashOnDelivery 快照三個旗標
        // 取代 view 端直接索引字典組裝表單初值
        await store.send(.editButtonTapped(name: "匯款")) {
            $0.destination = .editPaymentMethod(
                LookupManagementFeature.Destination.EditPaymentMethodFeature.State(
                    originalName: "匯款",
                    isCardless: false,
                    isBankTransfer: true,
                    isCashOnDelivery: false
                )
            )
        }
    }

    @Test func editButtonTappedNoOpsForNonPaymentMethodKind() async {
        var state = LookupManagementFeature.State(kind: .category)
        state.items = ["類別"]
        state.hasLoaded = true

        let store = TestStore(initialState: state) {
            LookupManagementFeature()
        }

        await store.send(.editButtonTapped(name: "類別"))
    }

    @Test func editPaymentMethodDestinationSaveTriggersEditConfirmedAndDismisses() async {
        var state = LookupManagementFeature.State(kind: .paymentMethod)
        state.items = ["匯款"]
        state.paymentMethodIsBankTransfer = ["匯款": true]
        state.hasLoaded = true

        let store = TestStore(initialState: state) {
            LookupManagementFeature()
        } withDependencies: {
            $0[PaymentMethodRepository.self] = .testValue
            $0[OrderRepository.self] = .testValue
        }

        await store.send(.editButtonTapped(name: "匯款")) {
            $0.destination = .editPaymentMethod(
                LookupManagementFeature.Destination.EditPaymentMethodFeature.State(
                    originalName: "匯款",
                    isCardless: false,
                    isBankTransfer: true,
                    isCashOnDelivery: false
                )
            )
        }

        // 儲存：destination 快照的 originalName 與表單最終值轉送既有 editConfirmed domain effect，並在同一步 dismiss
        await store.send(
            .destination(
                .presented(
                    .editPaymentMethod(
                        .saveButtonTapped(name: "銀行匯款", isCardless: false, isBankTransfer: false, isCashOnDelivery: false)
                    )
                )
            )
        ) {
            $0.destination = nil
        }

        await store.receive(\.editConfirmed) {
            $0.items = ["銀行匯款"]
            $0.paymentMethodIsBankTransfer = ["銀行匯款": false]
            $0.paymentMethodIsCardless = ["銀行匯款": false]
            $0.paymentMethodIsCashOnDelivery = ["銀行匯款": false]
        }

        await store.finish()
    }
}

/// 主檔刪除測試用的寫入失敗
private enum LookupTestFailure: Error {

    // MARK: - Cases

    /// 模擬資料庫寫入拋錯
    case boom
}
