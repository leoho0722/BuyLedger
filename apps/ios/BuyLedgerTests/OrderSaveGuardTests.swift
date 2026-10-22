//
//  OrderSaveGuardTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/7.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// 驗證訂單表單的必填守門與父層存檔接線
@MainActor
struct OrderSaveGuardTests {

    /// 來源缺漏時經父層請求存檔，不寫入也不關閉表單
    @Test
    func presentation_訂單來源空白時存檔_不寫入且表單保持開啟() async {
        // Given
        var edit = Self.makeEditState()
        edit.draft.orderSource = ""
        edit.focusedField = .customerName
        var initial = OrdersFeature.State()
        initial.presentation.destination = .edit(edit)
        let writeCount = LockIsolated(0)
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.orderService.createOrder = { _ in
                writeCount.withValue {
                    $0 += 1
                }
            }
        }

        // When
        await store.send(.presentation(.destination(.presented(.edit(.view(.saveTapped))))))

        // Then
        await store.finish()
        #expect(writeCount.value == 0)
        #expect(store.state == initial)
        #expect(store.state.presentation.destination?.edit?.focusedField == .customerName)
    }

    /// 必填完整時只經存檔 delegate 寫入一次，並關閉表單
    @Test
    func presentation_必填完整時存檔_寫入一次並關閉表單() async {
        // Given
        var initial = OrdersFeature.State()
        initial.presentation.destination = .edit(Self.makeEditState())
        let writeCount = LockIsolated(0)
        let writtenOrders = LockIsolated<[LedgerOrder]>([])
        let hasSaveRequest = LockIsolated(false)
        let idGeneratedAfterSaveRequest = LockIsolated<[Bool]>([])
        let expectedOrder = LedgerOrder.fixture(
            id: "BL-DRAFT-00000000-0000-0000-0000-000000000000",
            customer: LedgerCustomer(name: "林書宇", initials: "林書", tier: .new),
            status: .quoting,
            date: TestDependencies.fixedNow,
            orderSource: "IG",
            categories: ["美妝"],
            paymentMethod: ""
        )
        let store = TestStore(initialState: initial) {
            CombineReducers {
                Reduce<OrdersFeature.State, OrdersFeature.Action> { _, action in
                    if case .presentation(
                        .destination(.presented(.edit(.delegate(.saveRequested))))
                    ) = action {
                        hasSaveRequest.setValue(true)
                    }
                    return .none
                }
                OrdersFeature()
            }
        } withDependencies: {
            // 編號在 reducer 內同步產生，可辨識寫入是否早於存檔 delegate
            $0.uuid = UUIDGenerator {
                idGeneratedAfterSaveRequest.withValue {
                    $0.append(hasSaveRequest.value)
                }
                return UUID(0)
            }
            $0.orderService.createOrder = { order in
                writeCount.withValue {
                    $0 += 1
                }
                writtenOrders.withValue {
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
        await store.receive(\.presentation.delegate.saveRequested)
        await store.receive(\.writes.saveRequested)
        await store.receive(\.presentation.destination.dismiss) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }
        await store.receive(\.writes.saveResponse)
        await store.receive(\.writes.delegate.saved) {
            $0.list.selectedOrderID = "BL-DRAFT-00000000-0000-0000-0000-000000000000"
        }
        await store.receive(
            \.list.delegate.selectionChanged,
            "BL-DRAFT-00000000-0000-0000-0000-000000000000"
        ) {
            $0.detail.regularDetail = OrderDetailFeature.State(
                orderID: "BL-DRAFT-00000000-0000-0000-0000-000000000000",
                orders: SharedReader($0.$orders)
            )
        }
        await store.finish()
        #expect(writeCount.value == 1)
        #expect(writtenOrders.value == [expectedOrder])
        #expect(idGeneratedAfterSaveRequest.value == [true])
        #expect(store.state.presentation.destination?.edit == nil)
        #expect(
            store.state.detail.regularDetail?.order?.id
                == "BL-DRAFT-00000000-0000-0000-0000-000000000000"
        )
    }

    /// 任何必填缺漏時，子層不改狀態、不送 delegate，也不呼叫 dismiss
    ///
    /// - Parameters:
    ///   - customerName: 顧客名稱，空白或只含空白字元時視為缺漏
    ///   - orderSource: 訂單來源，空白或只含空白字元時視為缺漏
    ///   - categories: 商品類別，空陣列或所有項目皆為空白時視為缺漏
    @Test(arguments: [
        ("", "IG", ["美妝"]),
        (" \n\t ", "IG", ["美妝"]),
        ("林書宇", "", ["美妝"]),
        ("林書宇", " \n\t ", ["美妝"]),
        ("林書宇", "IG", [String]()),
        ("林書宇", "IG", ["", " \n\t "]),
    ])
    func saveTapped_必填缺漏_保留狀態且不送存檔請求(
        customerName: String,
        orderSource: String,
        categories: [String]
    ) async {
        // Given
        var initial = Self.makeEditState()
        initial.draft.customerName = customerName
        initial.draft.orderSource = orderSource
        initial.draft.categories = categories
        initial.focusedField = .chargedAmount
        let dismissCount = LockIsolated(0)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.dismiss = DismissEffect {
                dismissCount.withValue {
                    $0 += 1
                }
            }
        }

        // When
        await store.send(.view(.saveTapped))

        // Then
        await store.finish()
        #expect(store.state == initial)
        #expect(store.state.canSave == false)
        #expect(dismissCount.value == 0)
    }

    /// 去除前後空白後必填完整時，子層清焦點並送 delegate 後關閉
    @Test
    func saveTapped_必填含前後空白_送出存檔請求並關閉() async {
        // Given
        var initial = Self.makeEditState()
        initial.draft.customerName = " \n林書宇\t "
        initial.draft.orderSource = " IG "
        initial.draft.categories = ["", " \n ", " 美妝 "]
        initial.focusedField = .chargedAmount
        let dismissCount = LockIsolated(0)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.dismiss = DismissEffect {
                dismissCount.withValue {
                    $0 += 1
                }
            }
        }

        // When
        await store.send(.view(.saveTapped)) {
            $0.focusedField = nil
        }

        // Then
        await store.receive(\.delegate.saveRequested)
        await store.finish()
        #expect(store.state.canSave)
        #expect(store.state.draft == initial.draft)
        #expect(store.state.focusedField == nil)
        #expect(dismissCount.value == 1)
    }
}

// MARK: - Private Method

private extension OrderSaveGuardTests {

    /// 建立符合規格情境的必填完整草稿
    ///
    /// - Returns: 顧客林書宇、來源 IG、類別美妝的表單狀態
    static func makeEditState() -> OrderEditFeature.State {
        var state = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        state.draft.customerName = "林書宇"
        state.draft.orderSource = "IG"
        state.draft.categories = ["美妝"]
        return state
    }
}
