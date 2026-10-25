//
//  LookupManagementFeatureFormsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/24.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `LookupManagementFeature` 的單元測試，以 TestStore 逐步驗證新增、改名與付款方式編輯表單的開啟、名稱檢查與送出
struct LookupManagementFeatureFormsTests {

    /// 驗證新增表單送出只含空白與換行的名稱時，表單保持開啟，清單也不新增項目
    @Test
    @MainActor
    func destination_新增名稱為空白_表單保持開啟() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            var initialState = LookupManagementFeature.State(kind: .category)
            initialState.destination = .add(LookupAddFormFeature.State(hasClassification: false))
            let expectedDestination = LookupManagementFeature.Destination.State.add(
                LookupAddFormFeature.State(hasClassification: false)
            )
            let store = TestStore(initialState: initialState) {
                LookupManagementFeature()
            }

            // When
            await store.send(
                .destination(.presented(.add(.view(.saveButtonTapped(name: "  \n", flags: .none)))))
            )

            // Then
            #expect(store.state.destination == expectedDestination)
            #expect(store.state.items.isEmpty)
            await store.finish()
        }
    }

    /// 驗證改名表單送出空白名稱或與原名稱相同的名稱時，表單保持開啟
    ///
    /// - Parameter name: 送出的名稱，空白或與原名稱相同
    @Test(arguments: ["", " \n ", "服飾"])
    @MainActor
    func destination_改名為空白或原名稱_表單保持開啟(name: String) async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            var initialState = LookupManagementFeature.State(kind: .category)
            initialState.destination = .rename(LookupRenameFormFeature.State(originalName: "服飾"))
            let expectedDestination = LookupManagementFeature.Destination.State.rename(
                LookupRenameFormFeature.State(originalName: "服飾")
            )
            let store = TestStore(initialState: initialState) {
                LookupManagementFeature()
            }

            // When
            await store.send(
                .destination(.presented(.rename(.view(.saveButtonTapped(name: name)))))
            )

            // Then
            #expect(store.state.destination == expectedDestination)
            await store.finish()
        }
    }

    /// 驗證點擊改名時，改名表單帶入該項目目前的名稱作為原名稱並呈現
    @Test
    @MainActor
    func renameButtonTapped_點擊改名_呈現改名表單() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            let state = LookupManagementFeature.State(kind: .category)
            state.$catalog.withLock {
                $0.categories = ["服飾"]
            }
            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            }

            // When
            await store.send(.view(.renameButtonTapped(name: "服飾"))) {
                $0.destination = .rename(LookupRenameFormFeature.State(originalName: "服飾"))
            }

            // Then
            #expect(
                store.state.destination
                    == .rename(LookupRenameFormFeature.State(originalName: "服飾"))
            )
            await store.finish()
        }
    }

    /// 驗證付款方式編輯表單送出只含空白與換行的名稱時，表單保持開啟且仍對應原付款方式
    @Test
    @MainActor
    func destination_付款方式名稱空白_表單保持開啟() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            var state = LookupManagementFeature.State(kind: .paymentMethod)
            state.$catalog.withLock {
                $0.paymentMethods = [PaymentMethodInfo(name: "信用卡", flags: .none)]
            }
            state.destination = .editPaymentMethod(
                PaymentMethodEditFormFeature.State(originalName: "信用卡", flags: .none)
            )
            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            }

            // When
            await store.send(
                .destination(
                    .presented(
                        .editPaymentMethod(.view(.saveButtonTapped(name: " \n ", flags: .none)))
                    )
                )
            )

            // Then
            #expect(
                store.state.destination
                    == .editPaymentMethod(
                        PaymentMethodEditFormFeature.State(originalName: "信用卡", flags: .none)
                    )
            )
            await store.finish()
        }
    }

    /// 驗證目錄有同名付款方式時，點擊編輯帶入的是第一筆的付款方式旗標，不是後面的同名項目
    @Test
    @MainActor
    func editButtonTapped_多筆付款方式同名_使用第一筆旗標() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            let firstFlags = PaymentMethodFlags(
                isCardless: true,
                isBankTransfer: false,
                isCashOnDelivery: false
            )
            let secondFlags = PaymentMethodFlags(
                isCardless: false,
                isBankTransfer: true,
                isCashOnDelivery: false
            )
            let state = LookupManagementFeature.State(kind: .paymentMethod)
            state.$catalog.withLock {
                $0.paymentMethods = [
                    PaymentMethodInfo(name: "匯款", flags: firstFlags),
                    PaymentMethodInfo(name: "匯款", flags: secondFlags),
                ]
            }
            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            }

            // When
            await store.send(.view(.editButtonTapped(name: "匯款"))) {
                $0.destination = .editPaymentMethod(
                    PaymentMethodEditFormFeature.State(originalName: "匯款", flags: firstFlags)
                )
            }

            // Then
            #expect(
                store.state.destination
                    == .editPaymentMethod(
                        PaymentMethodEditFormFeature.State(originalName: "匯款", flags: firstFlags)
                    )
            )
            await store.finish()
        }
    }

    /// 驗證查詢種類不是付款方式時，點擊編輯不呈現付款方式編輯表單，清單維持不變
    @Test
    @MainActor
    func editButtonTapped_查詢種類不是付款方式_不呈現編輯表單() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            let state = LookupManagementFeature.State(kind: .category)
            state.$catalog.withLock {
                $0.categories = ["服飾"]
            }
            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            }

            // When
            await store.send(.view(.editButtonTapped(name: "服飾")))

            // Then
            #expect(store.state.destination == nil)
            #expect(store.state.items == ["服飾"])
            await store.finish()
        }
    }

    /// 驗證 `classification(for:)` 查付款方式時取第一筆同名項目的旗標，其他種類的主檔回傳 `nil`
    ///
    /// - Parameter example: 查詢種類、查詢名稱、目錄內容與預期旗標
    @Test(arguments: LookupClassificationExample.examples)
    func classification_付款方式與其他主檔範例_取第一筆同名旗標或無分類(example: LookupClassificationExample) async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            let state = LookupManagementFeature.State(kind: example.kind)
            state.$catalog.withLock {
                $0.paymentMethods = example.paymentMethods
            }

            // When
            let classification = state.classification(for: example.name)

            // Then
            #expect(classification == example.expectedFlags)
        }
    }

    /// 驗證改名表單送出新名稱後，寫入服務收到改名內容、清單與共享目錄都改為新名稱，並送出 `delegate(.itemRenamed)` 給父層
    @Test
    @MainActor
    func destination_重新命名項目_寫入改名並更新目錄與清單後通知上層() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            var state = LookupManagementFeature.State(kind: .category)
            state.$catalog.withLock {
                $0.categories = ["服飾"]
            }
            state.destination = .rename(LookupRenameFormFeature.State(originalName: "服飾"))
            @Shared(.lookupCatalog) var sharedCatalog: LookupCatalog
            let observedKinds = LockIsolated<[LookupKind]>([])
            let writes = LockIsolated<[LookupItemRename]>([])
            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            } withDependencies: {
                $0.lookupService.renameItem = { kind, itemRename in
                    observedKinds.withValue {
                        $0.append(kind)
                    }
                    writes.withValue {
                        $0.append(itemRename)
                    }
                }
            }
            let rename = LookupItemRename(oldName: "服飾", newName: "衣著")

            // When
            await store.send(
                .destination(.presented(.rename(.view(.saveButtonTapped(name: " 衣著 ")))))
            )

            // Then
            await store.receive(\.destination.presented.rename.delegate.saved) {
                $0.destination = nil
                $0.isFormSheetDismissing = true
                $0.$catalog.withLock {
                    $0.categories = ["衣著"]
                }
            }
            await store.receive(\.renameResponse.success, rename)
            await store.receive(\.delegate.itemRenamed, rename)
            #expect(observedKinds.value == [.category])
            #expect(store.state.items == ["衣著"])
            #expect(writes.value == [rename])
            #expect(sharedCatalog.names(for: .category) == ["衣著"])
            await store.finish()
        }
    }
}

// MARK: - Nested Types

extension LookupManagementFeatureFormsTests {

    /// `classification(for:)` 的測試案例，每筆描述一組查詢條件、付款方式目錄與預期旗標
    struct LookupClassificationExample: Sendable {

        /// 同名付款方式取第一筆、其他種類無分類的兩組測試案例
        static let examples = [
            Self(
                expectedFlags: PaymentMethodFlags(
                    isCardless: true,
                    isBankTransfer: false,
                    isCashOnDelivery: false
                ),
                kind: .paymentMethod,
                name: "匯款",
                paymentMethods: [
                    PaymentMethodInfo(
                        name: "匯款",
                        flags: PaymentMethodFlags(
                            isCardless: true,
                            isBankTransfer: false,
                            isCashOnDelivery: false
                        )
                    ),
                    PaymentMethodInfo(
                        name: "匯款",
                        flags: PaymentMethodFlags(
                            isCardless: false,
                            isBankTransfer: true,
                            isCashOnDelivery: false
                        )
                    ),
                ]
            ),
            Self(
                expectedFlags: nil,
                kind: .category,
                name: "匯款",
                paymentMethods: []
            ),
        ]

        /// 預期回傳的付款方式旗標，無分類時為 `nil`
        let expectedFlags: PaymentMethodFlags?

        /// 要查詢的主檔種類
        let kind: LookupKind

        /// 查詢時使用的名稱
        let name: String

        /// 查詢前的付款方式目錄
        let paymentMethods: [PaymentMethodInfo]
    }
}
