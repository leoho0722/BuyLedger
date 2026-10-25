//
//  OrdersFeatureOptionWritesTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrdersFeature` 的單元測試，以 TestStore 逐步驗證主檔選項的新增請求、寫入結果與來源表單更新
@MainActor
struct OrdersFeatureOptionWritesTests {

    /// 驗證編輯表單的選擇器按下新增類別時，名稱去除頭尾空白後，連同來源表單識別值交給根功能，主檔與草稿都不變
    @Test
    func presentation_新增類別_轉送來源表單的新增請求() async {
        // Given
        let initial = OrdersFeatureTestSupport.makeOptionState()
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        let request = LookupAdditionRequest(
            id: UUID(0),
            kind: .category,
            name: "香氛",
            flags: .none
        )

        // When
        await store.send(
            .presentation(
                .destination(.presented(.edit(.pickers(.view(.addCategoryTapped(" 香氛 "))))))
            )
        )

        // Then
        await store.receive(
            \.presentation.destination.presented.edit.pickers.delegate,
            .addOptionRequested(kind: .category, name: "香氛", flags: .none)
        )
        await store.receive(
            \.presentation.destination.presented.edit.delegate,
            .addOptionRequested(kind: .category, name: "香氛", flags: .none)
        )
        await store.receive(\.presentation.delegate, .optionAddRequested(request))
        await store.receive(\.delegate, .optionAddRequested(request))
        #expect(store.state.lookupCatalog.categories == ["美妝"])
        #expect(store.state.presentation.destination?.edit?.draft.categories == ["美妝"])
        await store.finish()
    }

    /// 驗證根功能回報類別新增成功時，來源表單的選項加入新類別並設為草稿的選取，共享主檔清單不在此更新
    @Test
    func rootRequest_新增類別寫入成功_加入清單並選取() async {
        // Given
        let initial = OrdersFeatureTestSupport.makeOptionState()
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        let request = LookupAdditionRequest(
            id: UUID(0),
            kind: .category,
            name: "香氛",
            flags: .none
        )

        // When
        await store.send(.rootRequest(.optionAdditionCompleted(request, isStored: true))) {
            $0.presentation.destination?.modify(\.edit) {
                $0.pickers.options.categories = ["美妝", "香氛"]
                $0.draft.categories = ["香氛"]
            }
        }

        // Then
        #expect(store.state.presentation.destination?.edit?.draft.categories == ["香氛"])
        #expect(store.state.lookupCatalog.categories == ["美妝"])
        await store.finish()
    }

    /// 驗證來源表單已關閉、同一筆訂單重開為表單 B 後，表單 A 的新增結果晚到時，表單 B 的識別值與內容都不變，主檔清單也維持原樣
    @Test
    func rootRequest_來源表單已關閉且重開_不改新表單() async {
        // Given
        let original = LedgerOrder.fixture(id: "O1", categories: ["美妝"])
        let formB = OrderEditFeature.State(
            original: original,
            id: UUID(1),
            options: OrderEditOptions(categories: ["美妝"], calendar: TestDependencies.fixedCalendar),
            currentDate: TestDependencies.fixedNow
        )
        var initial = OrdersFeatureTestSupport.makeOptionState()
        initial.$orders.withLock {
            $0 = [original]
        }
        initial.$lookupCatalog = SharedReader(value: LookupCatalog(categories: ["美妝", "香氛"]))
        initial.list.$lookupCatalog = initial.$lookupCatalog
        initial.presentation.destination = .edit(formB)
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        let request = LookupAdditionRequest(
            id: UUID(0),
            kind: .category,
            name: "香氛",
            flags: .none
        )

        // When
        await store.send(.rootRequest(.optionAdditionCompleted(request, isStored: true)))

        // Then
        #expect(store.state.presentation.destination?.edit?.id == UUID(1))
        #expect(store.state.presentation.destination?.edit == formB)
        #expect(store.state.lookupCatalog.categories == ["美妝", "香氛"])
        await store.finish()
    }

    /// 驗證根功能回報無卡付款方式新增成功時，表單的付款方式選項加入該項並選為草稿付款方式，`isSelectedPaymentMethodCardless` 為 `true`
    @Test
    func rootRequest_新增無卡付款方式成功_表單選項與選取保留旗標() async {
        // Given
        let flags = PaymentMethodFlags(
            isCardless: true,
            isBankTransfer: false,
            isCashOnDelivery: false
        )
        let info = PaymentMethodInfo(
            name: "街口支付",
            isCardless: true,
            isBankTransfer: false,
            isCashOnDelivery: false
        )
        let initial = OrdersFeatureTestSupport.makeOptionState()
        initial.$lookupCatalog = SharedReader(
            value: LookupCatalog(categories: ["美妝"], paymentMethods: [info])
        )
        initial.list.$lookupCatalog = initial.$lookupCatalog
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        let request = LookupAdditionRequest(
            id: UUID(0),
            kind: .paymentMethod,
            name: "街口支付",
            flags: flags
        )

        // When
        await store.send(.rootRequest(.optionAdditionCompleted(request, isStored: true))) {
            $0.presentation.destination?.modify(\.edit) {
                $0.pickers.options.paymentMethods = [info]
                $0.draft.paymentMethod = "街口支付"
            }
        }

        // Then
        #expect(store.state.lookupCatalog.paymentMethods == [info])
        #expect(
            store.state.presentation.destination?.edit?.pickers.options.paymentMethods == [info]
        )
        #expect(store.state.presentation.destination?.edit?.isSelectedPaymentMethodCardless == true)
        await store.finish()
    }

    /// 驗證編輯表單送出新增選項請求時，表單識別值、種類、名稱與旗標原樣交給根功能，清單的選取仍為 `nil`
    @Test
    func presentation_新增主檔選項_轉送來源表單與旗標且不改選取() async {
        // Given
        var state = OrdersFeatureTestSupport.makeOptionState()
        state.presentation.destination = .edit(
            OrderEditFeature.State(id: UUID(5), currentDate: TestDependencies.fixedNow)
        )
        let flags = PaymentMethodFlags(
            isCardless: true,
            isBankTransfer: false,
            isCashOnDelivery: false
        )
        let request = LookupAdditionRequest(
            id: UUID(5),
            kind: .category,
            name: "新類別",
            flags: flags
        )
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(
            .presentation(
                .destination(
                    .presented(
                        .edit(
                            .delegate(
                                .addOptionRequested(kind: .category, name: "新類別", flags: flags)
                            )
                        )
                    )
                )
            )
        )

        // Then
        await store.receive(\.presentation.delegate, .optionAddRequested(request))
        await store.receive(\.delegate, .optionAddRequested(request))
        #expect(store.state.list.selectedOrderID == nil)
        await store.finish()
    }

    /// 驗證表單送出的名稱含頭尾空白時，交給根功能的請求會去除空白，只帶整理後的名稱，清單的選取仍為 `nil`
    @Test
    func presentation_新增主檔選項名稱含空白_轉送去除空白的請求() async {
        // Given
        var state = OrdersFeatureTestSupport.makeOptionState()
        state.presentation.destination = .edit(
            OrderEditFeature.State(id: UUID(5), currentDate: TestDependencies.fixedNow)
        )
        let request = LookupAdditionRequest(
            id: UUID(5),
            kind: .category,
            name: "新類別",
            flags: .none
        )
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(
            .presentation(
                .destination(
                    .presented(
                        .edit(
                            .delegate(
                                .addOptionRequested(kind: .category, name: " 新類別 ", flags: .none)
                            )
                        )
                    )
                )
            )
        )

        // Then
        await store.receive(\.presentation.delegate, .optionAddRequested(request))
        await store.receive(\.delegate, .optionAddRequested(request))
        #expect(store.state.list.selectedOrderID == nil)
        await store.finish()
    }
}
