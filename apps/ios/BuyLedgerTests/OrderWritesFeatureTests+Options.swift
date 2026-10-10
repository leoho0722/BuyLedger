//
//  OrderWritesFeatureTests+Options.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension OrderWritesFeatureTests {

    /// 四種主檔都先呼叫對應服務，成功回應才更新共用目錄
    ///
    /// - Parameter kind: 要新增的主檔種類
    @Test(arguments: LookupKind.allCases)
    func optionAddRequested_四種主檔寫入成功_先落盤再更新目錄(kind: LookupKind) async {
        // Given
        let catalog = LockIsolated<Shared<LookupCatalog>?>(nil)
        let observed = LockIsolated<[LookupCatalog]>([])
        let names = LockIsolated<[String]>([])
        let record: OrderSourceService.AddOrderSource = { name in
            if let catalog = catalog.value {
                observed.withValue {
                    $0.append(catalog.wrappedValue)
                }
            }
            names.withValue {
                $0.append(name)
            }
        }
        let plan = OrderOptionWritePlan(
            formID: UUID(3),
            kind: kind,
            name: "新增項目",
            flags: .none
        )
        let store = TestStore(initialState: Self.makeOptionWriteState()) {
            OrderWritesFeature()
        } withDependencies: {
            switch kind {
            case .orderSource:
                $0.orderSourceService.addOrderSource = record

            case .category:
                $0.categoryService.addCategory = record

            case .paymentMethod:
                $0.paymentMethodService.addPaymentMethod = { name, _ throws(PersistenceError) in
                    try await record(name)
                }

            case .reconciliationStatus:
                $0.reconciliationStatusService.addReconciliationStatus = record
            }
        }
        let lookupCatalog = store.state.$lookupCatalog
        catalog.withValue {
            $0 = lookupCatalog
        }

        // When
        await store.send(.optionAddRequested(plan)) {
            $0.$orders.withLock {
                $0 = [Self.original, Self.other]
            }
            $0.$lookupCatalog.withLock {
                $0 = LookupCatalog()
            }
        }

        // Then
        await store.receive(\.optionResponse) {
            $0.$lookupCatalog.withLock {
                switch kind {
                case .orderSource:
                    $0.orderSources = ["新增項目"]

                case .category:
                    $0.categories = ["新增項目"]

                case .paymentMethod:
                    $0.paymentMethods = [PaymentMethodInfo(name: "新增項目", flags: .none)]

                case .reconciliationStatus:
                    $0.reconciliationStatuses = ["新增項目"]
                }
            }
        }
        await store.receive(\.delegate, .optionAdded(plan))
        #expect(observed.value == [LookupCatalog()])
        #expect(names.value == ["新增項目"])
        #expect(store.state.lookupCatalog.names(for: kind) == ["新增項目"])
        await store.finish()
    }

    /// 四種主檔新增失敗都保留共用目錄，並沿既有文案回報一次
    ///
    /// - Parameter kind: 要新增的主檔種類
    @Test(arguments: LookupKind.allCases)
    func optionAddRequested_四種主檔寫入失敗_目錄不變且回報失敗(kind: LookupKind) async {
        // Given
        let failingAdd: CategoryService.AddCategory = { _ in
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "失敗"))
        }
        let store = TestStore(initialState: Self.makeOptionWriteState()) {
            OrderWritesFeature()
        } withDependencies: {
            switch kind {
            case .orderSource:
                $0.orderSourceService.addOrderSource = failingAdd

            case .category:
                $0.categoryService.addCategory = failingAdd

            case .paymentMethod:
                $0.paymentMethodService.addPaymentMethod = { name, _ throws(PersistenceError) in
                    try await failingAdd(name)
                }

            case .reconciliationStatus:
                $0.reconciliationStatusService.addReconciliationStatus = failingAdd
            }
        }
        let plan = OrderOptionWritePlan(
            formID: UUID(3),
            kind: kind,
            name: "新增項目",
            flags: .none
        )

        // When
        await store.send(.optionAddRequested(plan)) {
            $0.$orders.withLock {
                $0 = [Self.original, Self.other]
            }
            $0.$lookupCatalog.withLock {
                $0 = LookupCatalog()
            }
        }

        // Then
        await store.receive(\.optionResponse)
        await store.receive(\.delegate, .failed(.option(kind)))
        #expect(store.state.lookupCatalog == LookupCatalog())
        #expect(store.state.orders == [Self.original, Self.other])
        await store.finish()
    }

    /// 表單已關閉時的成功回應只更新目錄，不重開表單
    @Test
    func writes_成功回應抵達時表單已關閉_只更新目錄() async {
        // Given
        var initial = OrdersFeatureTests.makeOptionState()
        initial.presentation.destination = nil
        let plan = OrderOptionWritePlan(
            formID: UUID(0),
            kind: .category,
            name: "香氛",
            flags: .none
        )
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        }

        // When
        await store.send(.writes(.optionResponse(plan: plan, result: .success(())))) {
            $0.$lookupCatalog.withLock {
                $0.categories = ["美妝", "香氛"]
            }
        }

        // Then
        await store.receive(\.writes.delegate, .optionAdded(plan))
        #expect(store.state.presentation.destination?.edit == nil)
        #expect(store.state.lookupCatalog.categories == ["美妝", "香氛"])
        await store.finish()
    }

    /// 成功新增類別時，合併表單保留既有類別並追加新選取
    @Test
    func writes_合併表單收到新增成功_保留既有類別並追加() async {
        // Given
        var initial = OrdersFeatureTests.makeOptionState()
        initial.presentation.destination?.modify(\.edit) {
            $0.mergeSourceIDs = ["A", "B"]
        }
        let plan = OrderOptionWritePlan(
            formID: UUID(0),
            kind: .category,
            name: "香氛",
            flags: .none
        )
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        }

        // When
        await store.send(.writes(.optionResponse(plan: plan, result: .success(())))) {
            $0.$lookupCatalog.withLock {
                $0.categories = ["美妝", "香氛"]
            }
        }

        // Then
        await store.receive(\.writes.delegate, .optionAdded(plan)) {
            $0.presentation.destination?.modify(\.edit) {
                $0.pickers.availableCategories = ["美妝", "香氛"]
            }
            $0.presentation.destination?.modify(\.edit) {
                $0.draft.categories = ["美妝", "香氛"]
            }
        }
        #expect(store.state.presentation.destination?.edit?.draft.categories == ["美妝", "香氛"])
        await store.finish()
    }

    /// 四種新增回應在表單識別值相符時，都加入清單並選取新值
    ///
    /// - Parameter kind: 已寫入的主檔種類
    @Test(arguments: LookupKind.allCases)
    func writes_四種新增成功回應與表單相符_加入清單並選取(kind: LookupKind) async {
        // Given
        let initial = OrdersFeatureTests.makeOptionState()
        let plan = OrderOptionWritePlan(
            formID: UUID(0),
            kind: kind,
            name: "香氛",
            flags: .none
        )
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        }

        // When
        await store.send(.writes(.optionResponse(plan: plan, result: .success(())))) {
            $0.$lookupCatalog.withLock {
                switch kind {
                case .orderSource:
                    $0.orderSources = ["香氛"]

                case .category:
                    $0.categories = ["美妝", "香氛"]

                case .paymentMethod:
                    $0.paymentMethods = [PaymentMethodInfo(name: "香氛", flags: .none)]

                case .reconciliationStatus:
                    $0.reconciliationStatuses = ["香氛"]
                }
            }
        }

        // Then
        await store.receive(\.writes.delegate, .optionAdded(plan)) {
            switch kind {
            case .orderSource:
                $0.presentation.destination?.modify(\.edit) {
                    $0.pickers.availableOrderSources = ["香氛"]
                }
                $0.presentation.destination?.modify(\.edit) {
                    $0.draft.orderSource = "香氛"
                }

            case .category:
                $0.presentation.destination?.modify(\.edit) {
                    $0.pickers.availableCategories = ["美妝", "香氛"]
                }
                $0.presentation.destination?.modify(\.edit) {
                    $0.draft.categories = ["香氛"]
                }

            case .paymentMethod:
                $0.presentation.destination?.modify(\.edit) {
                    $0.pickers.availablePaymentMethods = [
                        PaymentMethodInfo(name: "香氛", flags: .none),
                    ]
                }
                $0.presentation.destination?.modify(\.edit) {
                    $0.draft.paymentMethod = "香氛"
                }

            case .reconciliationStatus:
                $0.presentation.destination?.modify(\.edit) {
                    $0.pickers.availableReconciliationStatuses = ["香氛"]
                }
                $0.presentation.destination?.modify(\.edit) {
                    $0.draft.reconciliationStatus = "香氛"
                }
            }
        }
        #expect(store.state.lookupCatalog.names(for: kind).contains("香氛"))
        await store.finish()
    }
}

// MARK: - Private Method

private extension OrderWritesFeatureTests {

    /// 在隔離儲存內建立空目錄與共用訂單引用
    ///
    /// - Returns: 不會影響其他測試的寫入狀態
    static func makeOptionWriteState() -> OrderWritesFeature.State {
        withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
        } operation: {
            let state = Self.makeState()
            state.$lookupCatalog.withLock {
                $0 = LookupCatalog()
            }
            return state
        }
    }
}
