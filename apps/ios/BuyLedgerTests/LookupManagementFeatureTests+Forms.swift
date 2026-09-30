//
//  LookupManagementFeatureTests+Forms.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/24.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

// MARK: - Tests

extension LookupManagementFeatureTests {

    /// 新增表單送出空白名稱時保持開啟且不新增項目
    @Test
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

    /// 改名表單拒絕空白名稱與原名稱
    ///
    /// - Parameter name: 要測試的無效名稱
    @Test(arguments: ["", " \n ", "服飾"])
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

    /// 點擊改名時以原名稱呈現改名表單
    @Test
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
                store.state.destination == .rename(
                    LookupRenameFormFeature.State(originalName: "服飾")
                )
            )
            await store.finish()
        }
    }

    /// 付款方式表單送出空白名稱時保持開啟
    @Test
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
                store.state.destination == .editPaymentMethod(
                    PaymentMethodEditFormFeature.State(originalName: "信用卡", flags: .none)
                )
            )
            await store.finish()
        }
    }

    /// 同名付款方式開啟編輯表單時使用第一筆的分類旗標
    @Test
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
                store.state.destination == .editPaymentMethod(
                    PaymentMethodEditFormFeature.State(originalName: "匯款", flags: firstFlags)
                )
            )
            await store.finish()
        }
    }

    /// 非付款方式主檔不會開啟付款方式編輯表單
    @Test
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

    /// 分類查詢取付款方式第一筆同名旗標，其他主檔沒有分類
    ///
    /// - Parameter example: 查詢種類、目錄內容與預期分類
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

    /// 改名表單成功後更新目錄、呼叫 service 並送出 `delegate(.itemRenamed)`
    @Test
    func destination_重新命名項目_更新主檔訂單並送出委派() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            var state = LookupManagementFeature.State(kind: .category)
            state.$catalog.withLock {
                $0.categories = ["服飾"]
            }
            state.destination = .rename(LookupRenameFormFeature.State(originalName: "服飾"))
            @Shared(.lookupCatalog) var sharedCatalog: LookupCatalog
            let writes = LockIsolated<[LookupItemRename]>([])
            let store = TestStore(initialState: state) {
                LookupManagementFeature()
            } withDependencies: {
                $0.orderService.applyCategoryRename = { oldName, newName in
                    writes.withValue {
                        $0.append(LookupItemRename(oldName: oldName, newName: newName))
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
            #expect(store.state.items == ["衣著"])
            #expect(writes.value == [rename])
            #expect(sharedCatalog.names(for: .category) == ["衣著"])
            await store.finish()
        }
    }
}
