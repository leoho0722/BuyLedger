//
//  OrdersFeatureTests+ListEntry.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

extension OrdersFeatureTests {

    /// 點選既有訂單時開啟編輯表單，草稿帶入該訂單內容，選項來自清單中的訂單
    ///
    /// - Note: 預期選項只來自訂單，主檔目錄需為空，因此在 `LookupCatalog.withIsolatedStorage` 內執行
    @Test
    func list_點選既有訂單_呈現編輯狀態() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            var state = OrdersFeature.State()
            state.refreshDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            let original = LedgerOrder.fixture(
                id: "order-1",
                orderSource: "蝦皮",
                categories: ["美妝"],
                paymentMethod: "信用卡"
            )
            state.$orders.withLock {
                $0 = [original]
            }

            let store = TestStore(initialState: state) {
                OrdersFeature()
            } withDependencies: {
                $0.date = .constant(TestDependencies.fixedNow)
                $0.calendar = TestDependencies.fixedCalendar
                $0.uuid = .incrementing
            }

            let expectedEditState = OrderEditFeature.State(
                original: original,
                id: UUID(0),
                options: OrderEditOptions(
                    orderSources: ["蝦皮"],
                    categories: ["美妝"],
                    paymentMethods: [
                        PaymentMethodInfo(
                            name: "信用卡",
                            isCardless: false,
                            isBankTransfer: false,
                            isCashOnDelivery: false
                        ),
                    ],
                    calendar: TestDependencies.fixedCalendar
                ),
                currentDate: TestDependencies.fixedNow
            )

            // When
            await store.send(.list(.delegate(.requested(.edit("order-1"))))) {
                $0.presentation.destination = .edit(expectedEditState)
            }

            // Then
            let edit = store.state.presentation.destination?.edit
            #expect(edit?.original?.id == "order-1")
            #expect(store.state.presentation.destination?.edit?.draft.customerName == "測試客戶")
            #expect(store.state.presentation.destination?.edit?.draft.categories == ["美妝"])
        }
    }

    /// 點選新增訂單時開啟空白編輯表單
    @Test
    func list_點選新增訂單_呈現空白編輯狀態() async {
        // Given
        let initial = withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
        } operation: {
            OrdersFeature.State()
        }
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .incrementing
        }

        let expectedEditState = OrderEditFeature.State(
            id: UUID(0),
            options: OrderEditOptions(calendar: TestDependencies.fixedCalendar),
            currentDate: TestDependencies.fixedNow
        )

        // When
        await store.send(.list(.delegate(.requested(.create)))) {
            $0.presentation.destination = .edit(expectedEditState)
        }

        // Then
        #expect(store.state.presentation.destination?.edit?.original == nil)
        #expect(store.state.presentation.destination?.edit?.draft.customerName.isEmpty == true)
        #expect(store.state.presentation.destination?.edit?.draft.categories.isEmpty == true)
    }

    /// 編輯既有訂單並儲存後，清單原本選取的其他訂單維持不變
    @Test
    func presentation_編輯既有訂單_保留目前選取() async {
        // Given
        let original = LedgerOrder.fixture(id: "order-1", categories: ["美妝"])
        let otherOrder = LedgerOrder.fixture(id: "order-2")

        var draft = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        draft.draft.customerName = "改過的客戶"

        var state = OrdersFeature.State(orders: [original, otherOrder])
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.presentation.destination = .edit(draft)
        state.list.selectedOrderID = "order-2"
        state.detail.syncRegularDetail(selectedOrderID: state.list.selectedOrderID)

        let savedOrders = LockIsolated<[LedgerOrder]>([])
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.saveOrder = { order in
                savedOrders.withValue {
                    $0.append(order)
                }
            }
        }
        let expectedOrder = LedgerOrder.fixture(
            id: "order-1",
            customer: LedgerCustomer(name: "改過的客戶", initials: "TC", tier: .regular),
            categories: ["美妝"]
        )

        // When
        await store.send(.presentation(.destination(.presented(.edit(.view(.saveTapped))))))

        // Then
        await store.receive(\.presentation.destination.presented.edit.delegate.saveRequested) {
            $0.$orders.withLock {
                $0 = [expectedOrder, otherOrder]
            }
        }
        await store.receive(\.presentation.delegate.saveRequested)
        await store.receive(\.writes.saveRequested)
        await store.receive(\.presentation.destination.dismiss) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }
        await store.receive(\.writes.saveResponse)
        await store.receive(\.writes.delegate.saved)
        #expect(store.state.list.selectedOrderID == "order-2")
        #expect(savedOrders.value == [expectedOrder])
    }

    /// 推入訂單明細後，堆疊多一個指向該訂單的明細頁
    @Test
    func detail_推入訂單明細路徑_增加堆疊元素() async {
        // Given
        let orderID = "BL-2604-018"
        var state = OrdersFeature.State()
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        let store = TestStore(initialState: state) {
            OrdersFeature()
        }

        // When
        await store.send(
            .detail(
                .path(
                    .push(
                        id: 0,
                        state: .detail(
                            OrderDetailFeature.State(
                                orderID: orderID,
                                orders: SharedReader(state.$orders)
                            )
                        )
                    )
                )
            )
        ) {
            $0.detail.path[id: 0] = .detail(
                OrderDetailFeature.State(orderID: orderID, orders: SharedReader($0.$orders))
            )
        }

        // Then
        #expect(store.state.detail.path.count == 1)
        #expect(store.state.detail.path[id: 0]?.detail?.orderID == orderID)
    }
}
