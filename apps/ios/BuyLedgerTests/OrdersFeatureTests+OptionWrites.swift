//
//  OrdersFeatureTests+OptionWrites.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension OrdersFeatureTests {

    /// 新增類別要先存進資料，存好後才出現在表單的選項中，並自動選取該類別
    @Test
    func presentation_新增類別寫入成功_加入清單並選取() async {
        // Given
        let clock = TestClock()
        let stored = LockIsolated<[String]>([])
        let delayedAdd: CategoryService.AddCategory = { name throws(PersistenceError) in
            do {
                try await clock.sleep(for: .seconds(1))
            } catch {
                throw .saveFailed(underlying: error)
            }
            stored.withValue {
                $0.append(name)
            }
        }
        let initialState = Self.makeOptionState()
        let initialEdit = initialState.presentation.destination?.edit
        let store = TestStore(initialState: initialState) {
            OrdersFeature()
        } withDependencies: {
            $0.categoryService.addCategory = delayedAdd
        }
        let plan = OrderOptionWritePlan(
            formID: UUID(0),
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
        await store.receive(\.presentation.delegate, .optionAddRequested(plan))
        await store.receive(\.writes.optionAddRequested, plan)
        #expect(store.state.lookupCatalog.categories == ["美妝"])
        #expect(store.state.presentation.destination?.edit == initialEdit)
        #expect(stored.value == [])
        await clock.advance(by: .seconds(1))
        await store.receive(\.writes.optionResponse) {
            $0.$lookupCatalog.withLock {
                $0.categories = ["美妝", "香氛"]
            }
        }
        await store.receive(\.writes.delegate, .optionAdded(plan)) {
            $0.presentation.destination?.modify(\.edit) {
                $0.pickers.availableCategories = ["美妝", "香氛"]
            }
            $0.presentation.destination?.modify(\.edit) {
                $0.draft.categories = ["香氛"]
            }
        }
        #expect(stored.value == ["香氛"])
        #expect(store.state.presentation.destination?.edit?.draft.categories == ["香氛"])
        await store.finish()
    }

    /// 同一筆訂單的表單 A 關閉後重開表單 B，之後才到的結果只更新類別清單，不改動表單 B
    @Test
    func list_新增後關閉表單再重開_只更新目錄不改新表單() async {
        // Given
        let clock = TestClock()
        let original = LedgerOrder.fixture(id: "O1", categories: ["美妝"])
        let formA = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            options: OrderEditOptions(categories: ["美妝"], calendar: TestDependencies.fixedCalendar),
            currentDate: TestDependencies.fixedNow
        )
        var initial = Self.makeOptionState()
        initial.$orders.withLock {
            $0 = [original]
        }
        initial.presentation.destination = .edit(formA)
        let delayedAdd: CategoryService.AddCategory = { _ throws(PersistenceError) in
            do {
                try await clock.sleep(for: .seconds(1))
            } catch {
                throw .saveFailed(underlying: error)
            }
        }
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.uuid = .constant(UUID(1))
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.categoryService.addCategory = delayedAdd
        }
        let plan = OrderOptionWritePlan(
            formID: UUID(0),
            kind: .category,
            name: "香氛",
            flags: .none
        )
        await store.send(
            .presentation(
                .destination(.presented(.edit(.pickers(.view(.addCategoryTapped("香氛"))))))
            )
        )
        await store.receive(
            \.presentation.destination.presented.edit.pickers.delegate,
            .addOptionRequested(kind: .category, name: "香氛", flags: .none)
        )
        await store.receive(
            \.presentation.destination.presented.edit.delegate,
            .addOptionRequested(kind: .category, name: "香氛", flags: .none)
        )
        await store.receive(\.presentation.delegate, .optionAddRequested(plan))
        await store.receive(\.writes.optionAddRequested, plan)
        await store.send(.presentation(.destination(.dismiss))) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }
        let formB = OrderEditFeature.State(
            original: original,
            id: UUID(1),
            options: OrderEditOptions(categories: ["美妝"], calendar: TestDependencies.fixedCalendar),
            currentDate: TestDependencies.fixedNow
        )

        // When
        await store.send(.list(.delegate(.requested(.edit("O1"))))) {
            $0.presentation.destination = .edit(formB)
        }

        // Then
        await clock.advance(by: .seconds(1))
        await store.receive(\.writes.optionResponse) {
            $0.$lookupCatalog.withLock {
                $0.categories = ["美妝", "香氛"]
            }
        }
        await store.receive(\.writes.delegate, .optionAdded(plan))
        #expect(store.state.presentation.destination?.edit?.id == UUID(1))
        #expect(formA.id != formB.id)
        #expect(store.state.presentation.destination?.edit == formB)
        #expect(store.state.lookupCatalog.categories == ["美妝", "香氛"])
        await store.finish()
    }

    /// 新增無卡付款方式成功後，儲存的資料、付款方式清單與表單選項都帶著無卡旗標
    @Test
    func presentation_新增無卡付款方式_落盤目錄清單保留旗標() async {
        // Given
        let stored = LockIsolated<[PaymentMethodInfo]>([])
        let flags = PaymentMethodFlags(
            isCardless: true,
            isBankTransfer: false,
            isCashOnDelivery: false
        )
        let store = TestStore(initialState: Self.makeOptionState()) {
            OrdersFeature()
        } withDependencies: {
            $0.paymentMethodService.addPaymentMethod = { name, flags in
                stored.withValue {
                    $0.append(PaymentMethodInfo(name: name, flags: flags))
                }
            }
        }
        let plan = OrderOptionWritePlan(
            formID: UUID(0),
            kind: .paymentMethod,
            name: "街口支付",
            flags: flags
        )
        let info = PaymentMethodInfo(
            name: "街口支付",
            isCardless: true,
            isBankTransfer: false,
            isCashOnDelivery: false
        )

        // When
        await store.send(
            .presentation(
                .destination(
                    .presented(
                        .edit(.pickers(.view(.addPaymentMethodTapped(name: "街口支付", flags: flags))))
                    )
                )
            )
        ) {
            $0.$lookupCatalog.withLock {
                $0.categories = ["美妝"]
            }
        }

        // Then
        await store.receive(
            \.presentation.destination.presented.edit.pickers.delegate,
            .addOptionRequested(kind: .paymentMethod, name: "街口支付", flags: flags)
        ) {
            $0.$lookupCatalog.withLock {
                $0.paymentMethods = [info]
            }
        }
        await store.receive(
            \.presentation.destination.presented.edit.delegate,
            .addOptionRequested(kind: .paymentMethod, name: "街口支付", flags: flags)
        )
        await store.receive(\.presentation.delegate, .optionAddRequested(plan))
        await store.receive(\.writes.optionAddRequested, plan)
        await store.receive(\.writes.optionResponse)
        await store.receive(\.writes.delegate, .optionAdded(plan)) {
            $0.presentation.destination?.modify(\.edit) {
                $0.pickers.availablePaymentMethods = [info]
            }
            $0.presentation.destination?.modify(\.edit) {
                $0.draft.paymentMethod = "街口支付"
            }
        }
        #expect(stored.value == [info])
        #expect(store.state.lookupCatalog.paymentMethods == [info])
        #expect(
            store.state.presentation.destination?.edit?.pickers.availablePaymentMethods == [info]
        )
        #expect(store.state.presentation.destination?.edit?.isSelectedPaymentMethodCardless == true)
        await store.finish()
    }
}
