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

/// `OrderEditFeature` 的單元測試，以 `TestStore` 逐步驗證必填守門，以及存檔請求如何經 `OrdersFeature` 寫入
@MainActor
struct OrderSaveGuardTests {

    /// 驗證訂單來源空白時從 `OrdersFeature` 送出表單的存檔動作，不寫入訂單，表單保持開啟且焦點維持在顧客名稱欄
    ///
    /// - Note: 未覆寫的 `createOrder` 被呼叫時測試會失敗
    @Test
    func presentation_訂單來源空白時存檔_不寫入且表單保持開啟() async {
        // Given
        var edit = Self.makeEditState()
        edit.draft.orderSource = ""
        edit.focusedField = .customerName
        var initial = OrdersFeature.State()
        initial.presentation.destination = .edit(edit)
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.uuid = .incrementing
        }

        // When
        await store.send(.presentation(.destination(.presented(.edit(.view(.saveTapped))))))

        // Then
        await store.finish()
        #expect(store.state == initial)
        #expect(store.state.presentation.destination?.edit?.focusedField == .customerName)
    }

    /// 驗證必填完整時存檔，只經 `orderService.createOrder` 寫入一次，編號在送出存檔請求通知之後才產生，寫入後關閉表單並選取新訂單
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
            // 編號在 reducer 內同步產生，可辨識寫入是否早於存檔請求通知
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
                orders: SharedReader(initial.$orders)
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

    /// 驗證任一必填欄位缺漏 (含只有空白字元) 時按下存檔，`OrderEditFeature` 的狀態不變、不送存檔請求通知，也不呼叫 `dismiss`
    ///
    /// - Parameter testCase: 必填欄位缺漏的草稿輸入
    @Test(arguments: [
        MissingRequiredFieldsCase(customerName: "", orderSource: "IG", categories: ["美妝"]),
        MissingRequiredFieldsCase(customerName: " \n\t ", orderSource: "IG", categories: ["美妝"]),
        MissingRequiredFieldsCase(customerName: "林書宇", orderSource: "", categories: ["美妝"]),
        MissingRequiredFieldsCase(customerName: "林書宇", orderSource: " \n\t ", categories: ["美妝"]),
        MissingRequiredFieldsCase(customerName: "林書宇", orderSource: "IG", categories: []),
        MissingRequiredFieldsCase(
            customerName: "林書宇",
            orderSource: "IG",
            categories: ["", " \n\t "]
        ),
    ])
    func saveTapped_必填缺漏_保留狀態且不送存檔請求(testCase: MissingRequiredFieldsCase) async {
        // Given
        var initial = Self.makeEditState()
        initial.draft.customerName = testCase.customerName
        initial.draft.orderSource = testCase.orderSource
        initial.draft.categories = testCase.categories
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

    /// 驗證必填欄位含前後空白時仍視為完整，存檔後清除焦點、送出存檔請求通知 並關閉表單，草稿內容維持含空白的原始輸入
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

// MARK: - Nested Types

extension OrderSaveGuardTests {

    /// 必填欄位缺漏的草稿輸入
    struct MissingRequiredFieldsCase: Sendable {

        /// 空白或只含空白字元時視為缺漏的顧客名稱
        let customerName: String

        /// 空白或只含空白字元時視為缺漏的訂單來源
        let orderSource: String

        /// 空陣列或所有項目皆空白時視為缺漏的商品類別
        let categories: [String]
    }
}

// MARK: - Private Method

private extension OrderSaveGuardTests {

    /// 建立必填欄位齊全的表單狀態
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
