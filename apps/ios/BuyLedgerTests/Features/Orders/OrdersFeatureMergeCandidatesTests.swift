//
//  OrdersFeatureMergeCandidatesTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import Clocks
import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

/// `OrdersFeature` 的單元測試，以 TestStore 搭配 TestClock 逐步驗證合併候選的資格與確認草稿的延遲呈現
@MainActor
struct OrdersFeatureMergeCandidatesTests {

    /// 驗證從可合併的訂單開始合併時，候選清單只列出同客戶、同幣別且尚未合併或取消的訂單
    ///
    /// - Throws: 找不到指定的主訂單時由 `#require` 丟出
    @Test
    func list_主訂單可合併_列出同客戶同幣別候選() async throws {
        // Given
        var state = OrdersFeature.State(orders: LedgerOrder.sampleOrders)
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let primaryID = "BL-2604-018"
        let primary = try #require(state.orders.first { $0.id == primaryID })

        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.uuid = .incrementing
        }

        let expectedOrderMerge = withDependencies {
            $0.uuid = .incrementing
        } operation: {
            OrderMergeFeature.State(
                primary: primary,
                orders: state.orders,
                dateContext: OrderDateContext(
                    now: TestDependencies.fixedNow,
                    calendar: TestDependencies.fixedCalendar
                )
            )
        }

        // When
        await store.send(.list(.delegate(.requested(.merge(primaryID))))) {
            $0.presentation.destination = .merge(expectedOrderMerge)
        }

        // Then
        #expect(store.state.presentation.destination?.merge?.primary.id == primaryID)
        // 主訂單為林書宇的 KRW 訂單，候選需同客戶與幣別且未合併或取消
        #expect(
            store.state.presentation.destination?.merge?.candidates.map(\.id) == ["BL-2604-012"]
        )
    }

    /// 驗證主訂單已合併或已取消時，點合併不開啟候選清單
    ///
    /// - Parameter status: 主訂單目前的狀態
    @Test(arguments: [OrderStatus.merged, .cancelled])
    func list_主訂單已合併或已取消_不開啟候選清單(status: OrderStatus) async {
        // Given
        let initialOrders = [
            OrdersFeatureTestSupport.makeOrder(id: "O1", category: "美妝", status: status),
        ]
        var initial = OrdersFeature.State(orders: initialOrders)
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        }

        // When
        await store.send(.list(.delegate(.requested(.merge("O1")))))

        // Then
        #expect(store.state.presentation.destination?.merge == nil)
    }

    /// 驗證在合併候選清單選好訂單後，先關閉清單，半秒後開啟已預填兩筆訂單內容的合併草稿
    ///
    /// - Throws: 樣本訂單不存在、品項數不符，或合併草稿沒有開啟時由 `#require` 丟出
    @Test
    func formSheetDismissed_選取候選訂單_延遲開啟預填合併草稿() async throws {
        // Given
        let initialOrders = LedgerOrder.sampleOrders
        let primaryID = "BL-2604-018"
        let secondaryID = "BL-2604-012"
        let primary = try #require(initialOrders.first { $0.id == primaryID })
        let secondary = try #require(initialOrders.first { $0.id == secondaryID })
        try #require(primary.items.count == 2)
        try #require(secondary.items.count == 1)
        let expectedItemIDs = primary.items.map(\.id) + secondary.items.map(\.id)
        let expectedItems = [
            LedgerOrderItem(
                id: expectedItemIDs[0],
                name: "Tamburins 香水 Chamo 50ml",
                quantity: 1,
                unitPrice: 95_000
            ),
            LedgerOrderItem(
                id: expectedItemIDs[1],
                name: "Gentle Monster Her 02",
                quantity: 1,
                unitPrice: 295_000
            ),
            LedgerOrderItem(
                id: expectedItemIDs[2],
                name: "Adererror 標準 Logo Tee 黑",
                quantity: 2,
                unitPrice: 89_000
            ),
        ]
        let clock = TestClock()
        let requestedPhotoOrderIDs = LockIsolated<[LedgerOrder.ID]>([])
        var initial = withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
        } operation: {
            OrdersFeature.State(orders: initialOrders)
        }
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.presentation.destination = .merge(
            withDependencies {
                $0.uuid = .constant(UUID(0))
            } operation: {
                OrderMergeFeature.State(
                    primary: primary,
                    orders: initialOrders,
                    dateContext: OrderDateContext(
                        now: TestDependencies.fixedNow,
                        calendar: TestDependencies.fixedCalendar
                    )
                )
            }
        )
        let expectedOptions = OrderEditOptions(
            orderSources: ["蝦皮", "官方網站", "Instagram", "代購社團"],
            categories: ["美妝", "服飾", "精品"],
            paymentMethods: [
                PaymentMethodInfo(
                    name: "信用卡",
                    isCardless: false,
                    isBankTransfer: false,
                    isCashOnDelivery: false
                ),
                PaymentMethodInfo(
                    name: "銀行轉帳",
                    isCardless: false,
                    isBankTransfer: false,
                    isCashOnDelivery: false
                ),
                PaymentMethodInfo(
                    name: "LINE Pay",
                    isCardless: false,
                    isBankTransfer: false,
                    isCashOnDelivery: false
                ),
                PaymentMethodInfo(
                    name: "Apple Pay",
                    isCardless: false,
                    isBankTransfer: false,
                    isCashOnDelivery: false
                ),
            ],
            calendar: TestDependencies.fixedCalendar
        )
        var expectedDraft = OrderDraft(original: nil, currentDate: TestDependencies.fixedNow)
        expectedDraft.customerName = "林書宇"
        expectedDraft.orderSource = "蝦皮"
        expectedDraft.categories = ["美妝", "服飾"]
        expectedDraft.status = .shipping
        expectedDraft.currency = .krw
        expectedDraft.chargedAmount = 17_480
        expectedDraft.cardlessDeductionAmount = 0
        expectedDraft.cardlessSupplementAmount = 0
        expectedDraft.itemCost = 12_950.4
        expectedDraft.domesticShipping = 140
        expectedDraft.internationalShipping = 600
        expectedDraft.foreignDomesticShipping = 0
        expectedDraft.cardFeeRate = 0.015
        expectedDraft.platformFeeRate = 0
        expectedDraft.paymentFeeRate = 0
        expectedDraft.items = expectedItems
        expectedDraft.notes = "客戶指定到貨後先拍照確認，再安排出貨。"
        expectedDraft.date = TestDependencies.fixedNow
        expectedDraft.paymentMethod = "信用卡"
        expectedDraft.reconciliationStatus = ""
        expectedDraft.campaignNames = []
        expectedDraft.paymentReceiptStatus = .pending
        let expectedEdit = OrderEditFeature.State(
            id: UUID(0),
            options: expectedOptions,
            currentDate: TestDependencies.fixedNow,
            prefill: OrderEditFeature.State.Prefill(
                draft: expectedDraft,
                mergeSourceIDs: [primaryID, secondaryID],
                keptPhotos: []
            )
        )

        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .constant(UUID(0))
            $0.continuousClock = clock
            $0.orderService.fetchOrderPhotos = { id in
                requestedPhotoOrderIDs.withValue {
                    $0.append(id)
                }
                return []
            }
        }

        await store.send(
            .presentation(.destination(.presented(.merge(.view(.candidateTapped(secondaryID))))))
        )

        await store.receive(
            \.presentation.destination.presented.merge.candidatePhotosResponse.success
        )
        await store.receive(\.presentation.destination.presented.merge.delegate.completed)
        await store.receive(
            \.presentation.delegate,
            .mergeCandidatesCompleted(primary: primary, secondary: secondary, keptPhotos: [])
        )
        await store.receive(\.presentation.mergeCandidateCompleted) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
            $0.presentation.queue.isAwaitingMergeConfirmation = true
        }

        // When
        await store.send(.view(.formSheetDismissed)) {
            $0.presentation.queue.isFormClosing = false
        }

        // Then
        await clock.advance(by: .milliseconds(500))
        await store.receive(\.presentation.delegate.mergeConfirmationDue) {
            $0.presentation.destination = .edit(expectedEdit)
            $0.presentation.queue.isAwaitingMergeConfirmation = false
        }
        let edit = try #require(store.state.presentation.destination?.edit)
        #expect(edit.isMergeContext)
        #expect(requestedPhotoOrderIDs.value.sorted() == ["BL-2604-012", "BL-2604-018"])
    }
}
