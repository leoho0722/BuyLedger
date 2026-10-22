//
//  LookupCatalogFeatureTests+Additions.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension LookupCatalogFeatureTests {

    /// 新增成功時把名稱加入目錄，並回報已儲存
    @Test
    func additionRequested_寫入成功_更新目錄並回報已儲存() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            var initialState = LookupCatalogFeature.State()
            initialState.$catalog.withLock {
                $0.categories = ["美妝"]
            }
            let request = LookupAdditionRequest(
                id: UUID(0),
                kind: .category,
                name: "香氛",
                flags: .none
            )
            let store = TestStore(initialState: initialState) {
                LookupCatalogFeature()
            } withDependencies: {
                $0.date = .constant(TestDependencies.fixedNow)
                $0.calendar = TestDependencies.fixedCalendar
                $0.lookupService.addItem = { _, _ in
                }
            }

            // When
            await store.send(.additionRequested(request))

            // Then
            await store.receive(\.additionResponse) {
                $0.$catalog.withLock {
                    $0.categories = ["美妝", "香氛"]
                }
            }
            await store.receive(\.delegate, .additionCompleted(request, isStored: true))
            await store.finish()
        }
    }

    /// 新增失敗時目錄不變，並回報未儲存
    @Test
    func additionRequested_寫入失敗_目錄不變並回報未儲存() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            var initialState = LookupCatalogFeature.State()
            initialState.$catalog.withLock {
                $0.categories = ["美妝"]
            }
            let request = LookupAdditionRequest(
                id: UUID(0),
                kind: .category,
                name: "香氛",
                flags: .none
            )
            let underlying = TestDependencies.makeUnderlyingError(message: "寫入失敗")
            let failingAdd: LookupService.AddItem = { _, _ throws(PersistenceError) in
                throw .saveFailed(underlying: underlying)
            }
            let store = TestStore(initialState: initialState) {
                LookupCatalogFeature()
            } withDependencies: {
                $0.date = .constant(TestDependencies.fixedNow)
                $0.calendar = TestDependencies.fixedCalendar
                $0.lookupService.addItem = failingAdd
            }

            // When
            await store.send(.additionRequested(request))

            // Then
            await store.receive(\.additionResponse)
            await store.receive(\.delegate, .additionCompleted(request, isStored: false))
            #expect(store.state.catalog.categories == ["美妝"])
            await store.finish()
        }
    }

    /// 名稱去除空白後為空時略過，不寫入也不回報
    @Test
    func additionRequested_名稱為空白_略過不寫入() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            let request = LookupAdditionRequest(
                id: UUID(0),
                kind: .category,
                name: " \n ",
                flags: .none
            )
            let store = TestStore(initialState: LookupCatalogFeature.State()) {
                LookupCatalogFeature()
            } withDependencies: {
                $0.date = .constant(TestDependencies.fixedNow)
                $0.calendar = TestDependencies.fixedCalendar
            }

            // When
            await store.send(.additionRequested(request))

            // Then
            await store.finish()
        }
    }

    /// 新增付款方式成功時保留旗標，並連同旗標寫入目錄
    @Test
    func additionRequested_新增付款方式成功_保留付款方式旗標() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            let request = LookupAdditionRequest(
                id: UUID(0),
                kind: .paymentMethod,
                name: "信用卡",
                flags: PaymentMethodFlags(
                    isCardless: true,
                    isBankTransfer: false,
                    isCashOnDelivery: true
                )
            )
            let store = TestStore(initialState: LookupCatalogFeature.State()) {
                LookupCatalogFeature()
            } withDependencies: {
                $0.date = .constant(TestDependencies.fixedNow)
                $0.calendar = TestDependencies.fixedCalendar
                $0.lookupService.addItem = { _, _ in
                }
            }

            // When
            await store.send(.additionRequested(request))

            // Then
            await store.receive(\.additionResponse) {
                $0.$catalog.withLock {
                    $0.paymentMethods = [
                        PaymentMethodInfo(
                            name: "信用卡",
                            flags: PaymentMethodFlags(
                                isCardless: true,
                                isBankTransfer: false,
                                isCashOnDelivery: true
                            )
                        ),
                    ]
                }
            }
            await store.receive(\.delegate, .additionCompleted(request, isStored: true))
            await store.finish()
        }
    }
}
