//
//  OrdersFeatureTests+EditFields.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

extension OrdersFeatureTests {

    /// 修改既有訂單的客戶名稱後儲存，清單中的訂單換成新名稱並只寫入一次
    ///
    /// - Note: 既有訂單一律走更新操作；誤走建立操作時，未覆寫的 `createOrder` 會讓測試失敗
    @Test
    func presentation_儲存客戶名稱_更新呈現訂單() async {
        // Given
        let original = LedgerOrder.fixture(id: "order-1", categories: ["美妝"])
        let newName = "重新命名客戶"

        var draft = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        // 直接預塞草稿，避開 Swift 6 對 `BindingAction` 的 `Sendable` 限制
        draft.draft.customerName = newName

        var state = OrdersFeature.State(orders: [original])
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.presentation.destination = .edit(draft)

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
            customer: LedgerCustomer(name: "重新命名客戶", initials: "TC", tier: .regular),
            categories: ["美妝"]
        )

        // When
        await store.send(.presentation(.destination(.presented(.edit(.view(.saveTapped))))))

        // Then
        await store.receive(\.presentation.destination.presented.edit.delegate.saveRequested) {
            $0.$orders.withLock {
                $0 = [expectedOrder]
            }
        }
        await store.receive(\.presentation.delegate.saveRequested, draft)
        await store.receive(\.writes.saveRequested)
        // 通過必填驗證後會關閉表單
        await store.receive(\.presentation.destination.dismiss) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }
        await store.receive(\.writes.saveResponse)
        await store.receive(\.writes.delegate.saved)
        #expect(savedOrders.value == [expectedOrder])
    }

    /// 修改訂單備註後儲存，前後空白會被去掉，清單與寫入的內容都是去掉空白後的備註
    @Test
    func presentation_儲存訂單備註_更新呈現訂單() async {
        // Given
        let original = LedgerOrder.fixture(id: "order-1", categories: ["美妝"])

        var draft = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        draft.draft.notes = "  到貨後請先聯絡客戶確認尺寸  "

        var state = OrdersFeature.State(orders: [original])
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.presentation.destination = .edit(draft)

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
            categories: ["美妝"],
            notes: "到貨後請先聯絡客戶確認尺寸"
        )

        // When
        await store.send(.presentation(.destination(.presented(.edit(.view(.saveTapped))))))

        // Then
        await store.receive(\.presentation.destination.presented.edit.delegate.saveRequested) {
            $0.$orders.withLock {
                $0 = [expectedOrder]
            }
        }
        await store.receive(\.presentation.delegate.saveRequested, draft)
        await store.receive(\.writes.saveRequested)
        await store.receive(\.presentation.destination.dismiss) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }
        await store.receive(\.writes.saveResponse)
        await store.receive(\.writes.delegate.saved)
        #expect(savedOrders.value == [expectedOrder])
    }

    /// 客戶名稱前後有空白時儲存，去掉空白後寫入的名稱與原訂單相同
    @Test
    func presentation_客戶名稱含前後空白_去除空白後儲存() async {
        // Given
        let original = LedgerOrder.fixture(id: "order-1", categories: ["美妝"])

        var draft = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        draft.draft.customerName = "  測試客戶  "

        var state = OrdersFeature.State(orders: [original])
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.presentation.destination = .edit(draft)

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

        // When
        await store.send(.presentation(.destination(.presented(.edit(.view(.saveTapped))))))

        // Then
        await store.receive(\.presentation.destination.presented.edit.delegate.saveRequested)
        await store.receive(\.presentation.delegate.saveRequested, draft)
        await store.receive(\.writes.saveRequested)
        await store.receive(\.presentation.destination.dismiss) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }
        await store.receive(\.writes.saveResponse)
        await store.receive(\.writes.delegate.saved)
        #expect(savedOrders.value == [original])
    }

    /// 有未儲存變更時確認捨棄，關閉編輯表單且訂單清單不變
    @Test
    func presentation_確認捨棄變更_不修改訂單清單() async {
        // Given
        let original = LedgerOrder.fixture(id: "order-1")

        var draft = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        draft.draft.customerName = "暫定名字"
        draft.discardConfirmation = AlertState {
            TextState("orders.list.label.discardChanges")
        } actions: {
            ButtonState(role: .destructive, action: .discard) {
                TextState("orders.list.label.discardChanges")
            }
            ButtonState(role: .cancel) {
                TextState("orders.list.label.keepEditing")
            }
        } message: {
            TextState("orders.edit.message.orderHasUnsaved")
        }

        var state = OrdersFeature.State(orders: [original])
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.presentation.destination = .edit(draft)

        let store = TestStore(initialState: state) {
            OrdersFeature()
        }

        // When
        await store.send(
            .presentation(
                .destination(.presented(.edit(.discardConfirmation(.presented(.discard)))))
            )
        ) {
            $0.presentation.destination?.modify(\.edit) {
                $0.discardConfirmation = nil
            }
        }

        // Then
        await store.receive(\.presentation.destination.dismiss) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }
        #expect(store.state.orders == [original])
    }

    /// 新增訂單時，分類與開團名稱去掉前後空白、空字串與重複後才寫入
    @Test
    func presentation_儲存分類與開團選取_正規化陣列內容() async {
        // Given
        var draft = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.draft.customerName = "新客戶"
        draft.draft.orderSource = "IG"
        draft.draft.categories = [" 美妝 ", "美妝", "", "服飾", "   "]
        draft.draft.campaignNames = ["四月韓國團", " 四月韓國團 ", ""]
        var initial = OrdersFeature.State()
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.presentation.destination = .edit(draft)
        let createdOrders = LockIsolated<[LedgerOrder]>([])
        let expectedOrder = LedgerOrder.fixture(
            id: "BL-DRAFT-00000000-0000-0000-0000-000000000000",
            customer: LedgerCustomer(name: "新客戶", initials: "新客", tier: .new),
            status: .quoting,
            date: TestDependencies.fixedNow,
            orderSource: "IG",
            categories: ["美妝", "服飾"],
            paymentMethod: "",
            campaignNames: ["四月韓國團"]
        )
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.orderService.createOrder = { order in
                createdOrders.withValue {
                    $0.append(order)
                }
            }
        }

        // When
        await store.send(.presentation(.destination(.presented(.edit(.view(.saveTapped))))))

        // Then
        await store.receive(\.presentation.destination.presented.edit.delegate.saveRequested) {
            $0.$orders.withLock {
                $0 = [expectedOrder]
            }
        }
        await store.receive(\.presentation.delegate.saveRequested, draft)
        await store.receive(\.writes.saveRequested)
        await store.receive(\.presentation.destination.dismiss) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }
        await store.receive(\.writes.saveResponse)
        await store.receive(\.writes.delegate.saved) {
            $0.list.selectedOrderID = expectedOrder.id
        }
        await store.receive(\.list.delegate.selectionChanged, expectedOrder.id) {
            $0.detail.regularDetail = OrderDetailFeature.State(
                orderID: expectedOrder.id,
                orders: SharedReader($0.$orders)
            )
        }
        #expect(createdOrders.value == [expectedOrder])
    }
}
