//
//  LookupManagementFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/29.
//

import ComposableArchitecture
import Foundation
import SwiftUI
import Testing
@testable import BuyLedger

/// 驗證主檔管理
@MainActor
struct LookupManagementFeatureTests {

    // MARK: - Tests

    @Test func reconciliationStatusKindLoadsFromRepository() async {
        await Self.withIsolatedCatalog {
            let store = TestStore(
                initialState: LookupManagementFeature.State(kind: .reconciliationStatus)
            ) {
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
                $0.$catalog.withLock { $0.reconciliationStatuses = ["待對帳", "對帳成功"] }
                $0.hasLoaded = true
            }
        }
    }

    @Test func reconciliationStatusAddConfirmedAppendsItem() async {
        await Self.withIsolatedCatalog {
            let store = TestStore(
                initialState: LookupManagementFeature.State(kind: .reconciliationStatus)
            ) {
                LookupManagementFeature()
            } withDependencies: {
                $0[ReconciliationStatusRepository.self] = .testValue
            }
            // 對帳狀態無 isCardless / isBankTransfer 概念，旗標被忽略；僅把名稱加入 items
            await store.send(.addConfirmed(name: "待對帳", flags: .none)) {
                $0.$catalog.withLock { $0.reconciliationStatuses = ["待對帳"] }
            }
            await store.finish()
        }
    }

    /// 使用獨立主檔 feature 容器，驗證新增後目錄同步
    @Test func addConfirmedWritesThroughToTheSharedCatalogFromAStandaloneContainer() async {
        await Self.withIsolatedCatalog {
            let store = TestStore(initialState: LookupManagementFeature.State(kind: .category)) {
                LookupManagementFeature()
            } withDependencies: {
                $0[CategoryRepository.self] = .testValue
            }

            await store.send(.addConfirmed(name: "手工藝品", flags: .none)) {
                $0.$catalog.withLock { $0.categories = ["手工藝品"] }
            }

            // 直接讀共享目錄，確認跨 feature 共用同一份儲存。
            #expect(store.state.catalog.categories == ["手工藝品"])
            await store.finish()
        }
    }

    @Test func editConfirmedRenamesPaymentMethodAndClearsFlag() async {
        await Self.withIsolatedCatalog {
            // 改名同時取消銀行匯款旗標。
            var state = LookupManagementFeature.State(kind: .paymentMethod)
            state.$catalog.withLock {
                $0.paymentMethods = [
                    PaymentMethodInfo(
                        name: "匯款",
                        isCardless: false,
                        isBankTransfer: true,
                        isCashOnDelivery: false
                    )
                ]
            }
            state.hasLoaded = true

            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            } withDependencies: {
                $0[PaymentMethodRepository.self] = .testValue
                $0[OrderRepository.self] = .testValue
            }

            await store.send(
                .editConfirmed(
                    originalName: "匯款",
                    name: "銀行匯款",
                    flags: .none
                )
            )
            await store.receive(\.paymentMethodEditPrepared) {
                $0.$catalog.withLock {
                    $0.paymentMethods = [
                        PaymentMethodInfo(
                            name: "銀行匯款",
                            isCardless: false,
                            isBankTransfer: false,
                            isCashOnDelivery: false
                        )
                    ]
                }
            }
            await store.receive(\.paymentMethodEditSucceeded)
        }
    }

    @Test func editConfirmedKeepsNameAndUpdatesFlags() async {
        await Self.withIsolatedCatalog {
            var state = LookupManagementFeature.State(kind: .paymentMethod)
            state.$catalog.withLock {
                $0.paymentMethods = [
                    PaymentMethodInfo(
                        name: "銀行匯款",
                        isCardless: false,
                        isBankTransfer: false,
                        isCashOnDelivery: false
                    )
                ]
            }
            state.hasLoaded = true

            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            } withDependencies: {
                $0[PaymentMethodRepository.self] = .testValue
                $0[OrderRepository.self] = .testValue
            }

            // 名稱不變、把銀行匯款旗標打開
            await store.send(
                .editConfirmed(
                    originalName: "銀行匯款",
                    name: "銀行匯款",
                    flags: PaymentMethodFlags(
                        isCardless: false,
                        isBankTransfer: true,
                        isCashOnDelivery: false
                    )
                )
            )
            // 目錄變更會在此接收點反映。
            await store.receive(\.paymentMethodEditPrepared) {
                $0.$catalog.withLock {
                    $0.paymentMethods = [
                        PaymentMethodInfo(
                            name: "銀行匯款",
                            isCardless: false,
                            isBankTransfer: true,
                            isCashOnDelivery: false
                        )
                    ]
                }
            }
            await store.receive(\.paymentMethodEditSucceeded)
        }
    }

    // MARK: - 新增流程 (addButtonTapped) Tests

    /// 名稱主檔新增表單併入 destination
    @Test func addButtonTappedForCategoryPresentsTheNameOnlyForm() async {
        await Self.withIsolatedCatalog {
            let store = TestStore(initialState: LookupManagementFeature.State(kind: .category)) {
                LookupManagementFeature()
            }

            await store.send(.addButtonTapped) {
                $0.destination = .addNameOnly(
                    LookupManagementFeature.Destination.AddNameOnlyFeature.State()
                )
            }
        }
    }

    @Test func addButtonTappedForPaymentMethodPresentsThePaymentMethodForm() async {
        await Self.withIsolatedCatalog {
            let store = TestStore(initialState: LookupManagementFeature.State(kind: .paymentMethod)) {
                LookupManagementFeature()
            }

            await store.send(.addButtonTapped) {
                $0.destination = .addPaymentMethod(
                    LookupManagementFeature.Destination.AddPaymentMethodFeature.State()
                )
            }
        }
    }

    @Test func addButtonTappedForReconciliationStatusPresentsTheNameOnlyForm() async {
        await Self.withIsolatedCatalog {
            let store = TestStore(
                initialState: LookupManagementFeature.State(kind: .reconciliationStatus)
            ) {
                LookupManagementFeature()
            }

            await store.send(.addButtonTapped) {
                $0.destination = .addNameOnly(
                    LookupManagementFeature.Destination.AddNameOnlyFeature.State()
                )
            }
        }
    }

    // MARK: - 刪除流程 Tests

    /// 破壞性刪除一律先確認，確認前不得動到任何狀態
    @Test func deleteButtonTappedPresentsConfirmationWithoutMutatingState() async {
        await Self.withIsolatedCatalog {
            let state = LookupManagementFeature.State(kind: .category)
            state.$catalog.withLock { $0.categories = ["美妝", "零食"] }
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
    }

    /// 寫入成功後才更新狀態
    @Test func deleteFailureLeavesTheListUnchanged() async {
        await Self.withIsolatedCatalog {
            let state = LookupManagementFeature.State(kind: .category)
            state.$catalog.withLock { $0.categories = ["美妝", "零食"] }
            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            } withDependencies: {
                $0[CategoryRepository.self].removeCategory = { (_: String) async throws(PersistenceError) in
                    throw PersistenceError.saveFailed(message: "boom")
                }
            }
            await store.send(.deleteRequested("美妝"))
            await store.receive(\.loadFailed) {
                $0.errorMessage = "刪除失敗，請稍後再試。"
            }

            #expect(store.state.items == ["美妝", "零食"])
        }
    }

    @Test func deleteSuccessRemovesTheItem() async {
        await Self.withIsolatedCatalog {
            let state = LookupManagementFeature.State(kind: .category)
            state.$catalog.withLock { $0.categories = ["美妝", "零食"] }
            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            } withDependencies: {
                $0[CategoryRepository.self].removeCategory = { _ in }
            }
            await store.send(.deleteRequested("美妝"))
            await store.receive(\.deleteSucceeded) {
                $0.$catalog.withLock { $0.categories = ["零食"] }
            }

            #expect(store.state.items == ["零食"])
        }
    }

    // MARK: - Destination (改名 / 編輯付款方式) Tests

    @Test func renameCanSaveIsFalseWhenDraftEmptyOrUnchanged() {
        let unchanged = LookupManagementFeature.Destination.RenameFeature.State(
            originalName: "類別",
            draft: "類別"
        )
        #expect(unchanged.canSave == false)

        let blank = LookupManagementFeature.Destination.RenameFeature.State(
            originalName: "類別",
            draft: "   "
        )
        #expect(blank.canSave == false)

        let changed = LookupManagementFeature.Destination.RenameFeature.State(
            originalName: "類別",
            draft: "新類別"
        )
        #expect(changed.canSave == true)
    }

    @Test func renameButtonTappedPresentsRenameDestinationWithOriginalNameSnapshot() async {
        await Self.withIsolatedCatalog {
            var state = LookupManagementFeature.State(kind: .category)
            state.$catalog.withLock { $0.categories = ["舊類別"] }
            state.hasLoaded = true

            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            }

            // reducer 會用點擊當下的名稱初始化表單
            await store.send(.renameButtonTapped(name: "舊類別")) {
                $0.destination = .rename(
                    LookupManagementFeature.Destination.RenameFeature.State(
                        originalName: "舊類別",
                        draft: "舊類別"
                    )
                )
            }
        }
    }

    @Test func renameDestinationLifecycleUpdatesDraftSavesAndDismisses() async {
        await Self.withIsolatedCatalog {
            var state = LookupManagementFeature.State(kind: .category)
            state.$catalog.withLock { $0.categories = ["舊類別"] }
            state.hasLoaded = true

            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            } withDependencies: {
                $0[CategoryRepository.self] = .testValue
                $0[OrderRepository.self] = .testValue
            }

            await store.send(.renameButtonTapped(name: "舊類別")) {
                $0.destination = .rename(
                    LookupManagementFeature.Destination.RenameFeature.State(
                        originalName: "舊類別",
                        draft: "舊類別"
                    )
                )
            }

            await store.send(.destination(.presented(.rename(.draftChanged("新類別"))))) {
                $0.destination = .rename(
                    LookupManagementFeature.Destination.RenameFeature.State(
                        originalName: "舊類別",
                        draft: "新類別"
                    )
                )
            }

            #expect(store.state.destination?.rename?.canSave == true)

            // 儲存時送出既有的重新命名 action，並關閉表單
            await store.send(.destination(.presented(.rename(.saveButtonTapped)))) {
                $0.destination = nil
                $0.$catalog.withLock { $0.categories = ["新類別"] }
            }

            await store.receive(\.renameRequested)

            await store.finish()
        }
    }

    @Test func renameSaveButtonTappedNoOpsWhenCannotSave() async {
        await Self.withIsolatedCatalog {
            var state = LookupManagementFeature.State(kind: .category)
            state.$catalog.withLock { $0.categories = ["類別"] }
            state.hasLoaded = true

            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            }

            await store.send(.renameButtonTapped(name: "類別")) {
                $0.destination = .rename(
                    LookupManagementFeature.Destination.RenameFeature.State(
                        originalName: "類別",
                        draft: "類別"
                    )
                )
            }

            // 名稱未變時儲存為 no-op，表單仍保持開啟
            await store.send(.destination(.presented(.rename(.saveButtonTapped))))
        }
    }

    @Test func editButtonTappedPresentsEditPaymentMethodDestinationWithFlagSnapshot() async {
        await Self.withIsolatedCatalog {
            var state = LookupManagementFeature.State(kind: .paymentMethod)
            state.$catalog.withLock {
                $0.paymentMethods = [
                    PaymentMethodInfo(
                        name: "匯款",
                        isCardless: false,
                        isBankTransfer: true,
                        isCashOnDelivery: false
                    )
                ]
            }
            state.hasLoaded = true

            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            }

            // 由 reducer 讀取付款方式的三個旗標
            // 表單初值由 reducer 統一建立
            await store.send(.editButtonTapped(name: "匯款")) {
                $0.destination = .editPaymentMethod(
                    LookupManagementFeature.Destination.EditPaymentMethodFeature.State(
                        originalName: "匯款",
                        flags: PaymentMethodFlags(
                            isCardless: false,
                            isBankTransfer: true,
                            isCashOnDelivery: false
                        )
                    )
                )
            }
        }
    }

    @Test func editButtonTappedNoOpsForNonPaymentMethodKind() async {
        await Self.withIsolatedCatalog {
            var state = LookupManagementFeature.State(kind: .category)
            state.$catalog.withLock { $0.categories = ["類別"] }
            state.hasLoaded = true

            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            }

            await store.send(.editButtonTapped(name: "類別"))
        }
    }

    @Test func editPaymentMethodDestinationSaveTriggersEditConfirmedAndDismisses() async {
        await Self.withIsolatedCatalog {
            var state = LookupManagementFeature.State(kind: .paymentMethod)
            state.$catalog.withLock {
                $0.paymentMethods = [
                    PaymentMethodInfo(
                        name: "匯款",
                        isCardless: false,
                        isBankTransfer: true,
                        isCashOnDelivery: false
                    )
                ]
            }
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
                        flags: PaymentMethodFlags(
                            isCardless: false,
                            isBankTransfer: true,
                            isCashOnDelivery: false
                        )
                    )
                )
            }

            // 儲存時送出既有的重新命名 action，並關閉表單
            await store.send(
                .destination(
                    .presented(
                        .editPaymentMethod(
                            .saveButtonTapped(
                                name: "銀行匯款",
                                flags: .none
                            )
                        )
                    )
                )
            )

            // 先收到 editConfirmed，再驗證 @Shared 目錄已更新
            await store.receive(\.editConfirmed) {
                $0.$catalog.withLock {
                    $0.paymentMethods = [
                        PaymentMethodInfo(
                            name: "銀行匯款",
                            isCardless: false,
                            isBankTransfer: false,
                            isCashOnDelivery: false
                        )
                    ]
                }
            }
            await store.receive(\.paymentMethodEditPrepared)
            await store.receive(\.paymentMethodEditSucceeded) {
                $0.destination = nil
            }
        }
    }

    // MARK: - 付款旗標更新 Tests

    @Test func editConfirmedUsesOneFilteredSnapshotForCountAndPayloadAndConfirmation() async {
        await Self.withIsolatedCatalog {
            let first = Self.makePaymentOrder(id: "PM-1", paymentMethod: "匯款")
            let second = Self.makePaymentOrder(id: "PM-2", paymentMethod: "匯款")
            let unrelated = Self.makePaymentOrder(id: "PM-3", paymentMethod: "信用卡")
            let box = PaymentMethodEditTestBox(fetchResults: [[first, second, unrelated], [first]])

            var state = LookupManagementFeature.State(kind: .paymentMethod)
            state.$catalog.withLock {
                $0.paymentMethods = [
                    PaymentMethodInfo(
                        name: "匯款",
                        isCardless: false,
                        isBankTransfer: true,
                        isCashOnDelivery: false
                    )
                ]
            }
            state.hasLoaded = true

            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            } withDependencies: {
                $0[OrderRepository.self].fetchOrders = { [box] in box.fetchOrders() }
                $0[PaymentMethodRepository.self].applyPaymentMethodEdit = { [box] _, _, _, orders in
                    box.applyCount += 1
                    box.appliedOrders = orders
                }
            }

            let expectedOrders = [
                first
                    .renamingPaymentMethod(to: "銀行匯款")
                    .applyingPaymentMethodFlags(flags: .none),
                second
                    .renamingPaymentMethod(to: "銀行匯款")
                    .applyingPaymentMethodFlags(flags: .none),
            ]
            let expectedPlan = LookupManagementFeature.PaymentMethodEditPlan(
                originalName: "匯款",
                newName: "銀行匯款",
                flags: .none,
                flagsChanged: true,
                affectedOrders: expectedOrders
            )

            await store.send(
                .editConfirmed(
                    originalName: "匯款",
                    name: "銀行匯款",
                    flags: .none
                )
            )
            await store.receive(.paymentMethodEditPrepared(expectedPlan)) {
                $0.pendingPaymentMethodEdit = expectedPlan
                $0.retroactiveConfirmation = Self.retroactiveConfirmationAlert(count: 2)
            }

            #expect(box.fetchCount == 1)
            #expect(
                store.state.pendingPaymentMethodEdit?.affectedOrders.map(\.id) == ["PM-1", "PM-2"]
            )
            #expect(store.state.retroactiveConfirmation != nil)

            await store.send(.retroactiveConfirmation(.presented(.confirmPaymentMethodEdit))) {
                $0.pendingPaymentMethodEdit = nil
                $0.retroactiveConfirmation = nil
            }

            await store.receive(.paymentMethodEditSucceeded(expectedPlan)) {
                $0.$catalog.withLock {
                    $0.paymentMethods = [
                        PaymentMethodInfo(
                            name: "銀行匯款",
                            isCardless: false,
                            isBankTransfer: false,
                            isCashOnDelivery: false
                        )
                    ]
                }
            }

            #expect(store.state.items == ["銀行匯款"])
            #expect(store.state.paymentMethodIsBankTransfer == ["銀行匯款": false])
            #expect(box.fetchCount == 1)
            #expect(box.applyCount == 1)
            #expect(box.appliedOrders == expectedOrders)
        }
    }

    @Test func editConfirmationFailureLeavesLookupStateUntouched() async {
        await Self.withIsolatedCatalog {
            let original = Self.makePaymentOrder(id: "PM-FAIL", paymentMethod: "匯款")
            let box = PaymentMethodEditTestBox(fetchResults: [[original]])

            var state = LookupManagementFeature.State(kind: .paymentMethod)
            state.$catalog.withLock {
                $0.paymentMethods = [
                    PaymentMethodInfo(
                        name: "匯款",
                        isCardless: false,
                        isBankTransfer: true,
                        isCashOnDelivery: false
                    )
                ]
            }
            state.hasLoaded = true

            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            } withDependencies: {
                $0[OrderRepository.self].fetchOrders = { [box] in box.fetchOrders() }
                $0[PaymentMethodRepository.self].applyPaymentMethodEdit = { [box] (_: String, _: String, _: PaymentMethodFlags, _: [LedgerOrder]) async throws(PaymentMethodPersistenceError) in
                    box.applyCount += 1
                    throw PaymentMethodPersistenceError.storage(.saveFailed(message: "boom"))
                }
            }

            let expectedPlan = LookupManagementFeature.PaymentMethodEditPlan(
                originalName: "匯款",
                newName: "銀行匯款",
                flags: .none,
                flagsChanged: true,
                affectedOrders: [
                    original
                        .renamingPaymentMethod(to: "銀行匯款")
                        .applyingPaymentMethodFlags(flags: .none)
                ]
            )

            await store.send(
                .editConfirmed(
                    originalName: "匯款",
                    name: "銀行匯款",
                    flags: .none
                )
            )
            await store.receive(.paymentMethodEditPrepared(expectedPlan)) {
                $0.pendingPaymentMethodEdit = expectedPlan
                $0.retroactiveConfirmation = Self.retroactiveConfirmationAlert(count: 1)
            }
            await store.send(.retroactiveConfirmation(.presented(.confirmPaymentMethodEdit))) {
                $0.pendingPaymentMethodEdit = nil
                $0.retroactiveConfirmation = nil
            }
            await store.receive(.paymentMethodEditFailed("付款方式編輯失敗，請稍後再試。")) {
                $0.writeFailureAlert = AlertState {
                    TextState("操作失敗")
                } actions: {
                    ButtonState(role: .cancel) {
                        TextState("知道了")
                    }
                } message: {
                    TextState("付款方式編輯失敗，請稍後再試。")
                }
            }

            #expect(box.applyCount == 1)
            #expect(store.state.items == ["匯款"])
            #expect(store.state.paymentMethodIsBankTransfer == ["匯款": true])
            #expect(store.state.paymentMethodIsCardless == ["匯款": false])
            #expect(store.state.errorMessage == nil)
            #expect(store.state.writeFailureAlert != nil)

            await store.send(.writeFailureAlert(.dismiss)) {
                $0.writeFailureAlert = nil
            }
        }
    }

    @Test func editWithNoAffectedOrdersAppliesFlagsWithoutConfirmation() async {
        await Self.withIsolatedCatalog {
            let unrelated = Self.makePaymentOrder(id: "PM-ZERO", paymentMethod: "信用卡")
            let box = PaymentMethodEditTestBox(fetchResults: [[unrelated]])

            var state = LookupManagementFeature.State(kind: .paymentMethod)
            state.$catalog.withLock {
                $0.paymentMethods = [
                    PaymentMethodInfo(
                        name: "匯款",
                        isCardless: false,
                        isBankTransfer: true,
                        isCashOnDelivery: false
                    )
                ]
            }
            state.hasLoaded = true

            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            } withDependencies: {
                $0[OrderRepository.self].fetchOrders = { [box] in box.fetchOrders() }
                $0[PaymentMethodRepository.self].applyPaymentMethodEdit = { [box] _, _, _, orders in
                    box.applyCount += 1
                    box.appliedOrders = orders
                }
            }

            // 沒有受影響訂單時直接套用，不顯示確認
            await store.send(
                .editConfirmed(
                    originalName: "匯款",
                    name: "銀行匯款",
                    flags: .none
                )
            )
            await store.receive(\.paymentMethodEditPrepared) {
                $0.$catalog.withLock {
                    $0.paymentMethods = [
                        PaymentMethodInfo(
                            name: "銀行匯款",
                            isCardless: false,
                            isBankTransfer: false,
                            isCashOnDelivery: false
                        )
                    ]
                }
            }
            #expect(store.state.retroactiveConfirmation == nil)
            await store.receive(\.paymentMethodEditSucceeded)

            #expect(box.fetchCount == 1)
            #expect(box.applyCount == 1)
            #expect(box.appliedOrders == [])
            #expect(store.state.retroactiveConfirmation == nil)
        }
    }

    @Test func editWithUnchangedFlagsRenamesWithoutRetroactiveConfirmation() async {
        await Self.withIsolatedCatalog {
            let original = Self.makePaymentOrder(id: "PM-RENAME", paymentMethod: "信用卡")
            let box = PaymentMethodEditTestBox(fetchResults: [[original]])

            var state = LookupManagementFeature.State(kind: .paymentMethod)
            state.$catalog.withLock {
                $0.paymentMethods = [
                    PaymentMethodInfo(
                        name: "信用卡",
                        isCardless: false,
                        isBankTransfer: false,
                        isCashOnDelivery: true
                    )
                ]
            }
            state.hasLoaded = true

            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            } withDependencies: {
                $0[OrderRepository.self].fetchOrders = { [box] in box.fetchOrders() }
                $0[PaymentMethodRepository.self].applyPaymentMethodEdit = { [box] _, _, _, orders in
                    box.applyCount += 1
                    box.appliedOrders = orders
                }
            }
            // 只有改名且旗標未變更時，不顯示確認。
            await store.send(
                .editConfirmed(
                    originalName: "信用卡",
                    name: "信用卡（新）",
                    flags: PaymentMethodFlags(
                        isCardless: false,
                        isBankTransfer: false,
                        isCashOnDelivery: true
                    )
                )
            )
            await store.receive(\.paymentMethodEditPrepared) {
                $0.$catalog.withLock {
                    $0.paymentMethods = [
                        PaymentMethodInfo(
                            name: "信用卡（新）",
                            isCardless: false,
                            isBankTransfer: false,
                            isCashOnDelivery: true
                        )
                    ]
                }
            }

            #expect(store.state.retroactiveConfirmation == nil)
            await store.receive(\.paymentMethodEditSucceeded)
            #expect(store.state.items == ["信用卡（新）"])
            #expect(box.fetchCount == 1)
            #expect(box.applyCount == 1)
        }
    }

    @Test func editFlagsChangedCoversEachFlagAndMissingStoredEntry() async {
        let changedFlagCases: [(Bool, Bool, Bool)] = [
            (true, false, false),
            (false, true, false),
            (false, false, true),
        ]

        for (isCardless, isBankTransfer, isCashOnDelivery) in changedFlagCases {
            await Self.withIsolatedCatalog {
                var state = LookupManagementFeature.State(kind: .paymentMethod)
                state.$catalog.withLock {
                    $0.paymentMethods = [
                        PaymentMethodInfo(
                            name: "付款方式",
                            isCardless: false,
                            isBankTransfer: false,
                            isCashOnDelivery: false
                        )
                    ]
                }
                state.hasLoaded = true

                let store = TestStore(initialState: state) {
                    LookupManagementFeature()
                } withDependencies: {
                    $0[OrderRepository.self].fetchOrders = { [] }
                    $0[PaymentMethodRepository.self].applyPaymentMethodEdit = { _, _, _, _ in }
                }
                let expectedPlan = LookupManagementFeature.PaymentMethodEditPlan(
                    originalName: "付款方式",
                    newName: "付款方式",
                    flags: PaymentMethodFlags(
                        isCardless: isCardless,
                        isBankTransfer: isBankTransfer,
                        isCashOnDelivery: isCashOnDelivery
                    ),
                    flagsChanged: true,
                    affectedOrders: []
                )

                await store.send(
                    .editConfirmed(
                        originalName: "付款方式",
                        name: "付款方式",
                        flags: PaymentMethodFlags(
                            isCardless: isCardless,
                            isBankTransfer: isBankTransfer,
                            isCashOnDelivery: isCashOnDelivery
                        )
                    )
                )
                await store.receive(.paymentMethodEditPrepared(expectedPlan)) {
                    $0.$catalog.withLock {
                        $0.paymentMethods = [
                            PaymentMethodInfo(
                                name: "付款方式",
                                isCardless: isCardless,
                                isBankTransfer: isBankTransfer,
                                isCashOnDelivery: isCashOnDelivery
                            )
                        ]
                    }
                }
                await store.receive(.paymentMethodEditSucceeded(expectedPlan))
            }
        }

        await Self.withIsolatedCatalog {
            var state = LookupManagementFeature.State(kind: .paymentMethod)
            state.hasLoaded = true

            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            } withDependencies: {
                $0[OrderRepository.self].fetchOrders = { [] }
                $0[PaymentMethodRepository.self].applyPaymentMethodEdit = { _, _, _, _ in }
            }
            let expectedPlan = LookupManagementFeature.PaymentMethodEditPlan(
                originalName: "缺少旗標",
                newName: "缺少旗標",
                flags: .none,
                flagsChanged: false,
                affectedOrders: []
            )

            await store.send(
                .editConfirmed(
                    originalName: "缺少旗標",
                    name: "缺少旗標",
                    flags: .none
                )
            )
            await store.receive(.paymentMethodEditPrepared(expectedPlan)) {
                $0.$catalog.withLock {
                    $0.paymentMethods = [
                        PaymentMethodInfo(
                            name: "缺少旗標",
                            isCardless: false,
                            isBankTransfer: false,
                            isCashOnDelivery: false
                        )
                    ]
                }
            }
            await store.receive(.paymentMethodEditSucceeded(expectedPlan))
        }
    }
}

/// 可控制回傳資料的 repository 替身
private final class PaymentMethodEditTestBox: @unchecked Sendable {

    // MARK: - Data Properties

    /// 每次 fetch 要回傳的集合；超過數量時沿用最後一組
    let fetchResults: [[LedgerOrder]]

    /// fetch 被呼叫次數
    var fetchCount = 0

    /// atomic apply 收到的 payload
    var appliedOrders: [LedgerOrder] = []

    /// atomic apply 被呼叫次數
    var applyCount = 0

    // MARK: - Init

    /// 建立替身
    init(fetchResults: [[LedgerOrder]]) {
        self.fetchResults = fetchResults
    }
}

// MARK: - Internal Method

private extension PaymentMethodEditTestBox {

    /// 回傳下一組 fetch 結果
    /// - Returns: 訂單清單
    func fetchOrders() -> [LedgerOrder] {
        defer { fetchCount += 1 }
        return fetchResults[min(fetchCount, fetchResults.count - 1)]
    }
}

// MARK: - Private Method

private extension LookupManagementFeatureTests {

    /// 為每個測試建立獨立的記憶體儲存
    /// - Parameter operation: 要執行的操作
    /// - Returns: operation 的結果
    /// - Throws: operation 拋出的錯誤
    static func withIsolatedCatalog<R>(
        _ operation: () async throws(any Error) -> R
    ) async rethrows -> R {
        try await withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
        } operation: {
            try await operation()
        }
    }

    /// 建立帶有舊旗標的訂單
    /// - Returns: 建立的訂單
    static func makePaymentOrder(id: String, paymentMethod: String) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: "付款測試", initials: "PM", tier: .regular),
            status: .delivered,
            currency: .twd,
            date: TestDependencies.fixedNow,
            items: [LedgerOrderItem(name: "商品", quantity: 1, unitPrice: 5_000)],
            itemCost: 3_000,
            domesticShipping: 125,
            internationalShipping: 275,
            foreignDomesticShipping: 425,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 5_000,
            cardlessDeductionAmount: 750,
            cardlessSupplementAmount: 250,
            orderSource: "來源",
            categories: ["測試"],
            paymentMethod: paymentMethod,
            notes: "",
            reconciliationStatus: "待對帳",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }

    /// 建立付款方式更新確認 alert
    /// - Returns: 補登提示狀態
    static func retroactiveConfirmationAlert(count: Int) -> AlertState<LookupManagementFeature.Action.Alert> {
        let message: LocalizedStringKey = "確認後將重算 \(count) 筆既有訂單的付款旗標與獲利；折抵、補款或對帳狀態可能被清除。此操作無法復原。"
        return AlertState {
            TextState("更正付款方式")
        } actions: {
            ButtonState(role: .destructive, action: .confirmPaymentMethodEdit) {
                TextState("確認更正")
            }
            ButtonState(role: .cancel) {
                TextState("取消")
            }
        } message: {
            TextState(message)
        }
    }
}
