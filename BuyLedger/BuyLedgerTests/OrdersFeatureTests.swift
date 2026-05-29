//
//  OrdersFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import BuyLedger

@MainActor
struct OrdersFeatureTests {
    
    // MARK: - Tests
    
    @Test func taskLoadsOrdersAndSelectsFirstOrder() async {
        let orders = LedgerOrder.sampleOrders
        let store = TestStore(initialState: OrdersFeature.State()) {
            OrdersFeature()
        } withDependencies: {
            $0[OrderRepository.self].fetchOrders = { LedgerOrder.sampleOrders }
        }
        // `.task` 還會並行送出 `categoryMasterLoaded` 與 `paymentMethodMasterLoaded`；本測試只驗證訂單載入流程，
        // 主檔載入由其他測試覆蓋，這裡關掉 exhaustivity 避免重複斷言所有平行 effect。
        store.exhaustivity = .off

        await store.send(.task) {
            $0.isLoading = true
            $0.errorMessage = nil
        }

        await store.receive(\.ordersLoaded) {
            $0.isLoading = false
            $0.hasLoaded = true
            $0.orders = orders
            $0.selectedOrderID = orders.first?.id
        }
    }
    
    @Test func searchTextFiltersOrdersByCustomerIdAndItemName() async {
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
        }

        await store.send(.searchTextChanged("mika")) {
            $0.searchText = "mika"
            $0.selectedOrderID = "BL-2604-017"
        }

        #expect(store.state.filteredOrders(referenceDate: TestDependencies.fixedNow).map(\.id) == ["BL-2604-017"])

        await store.send(.searchTextChanged("Aesop")) {
            $0.searchText = "Aesop"
            $0.selectedOrderID = "BL-2604-016"
        }

        #expect(store.state.filteredOrders(referenceDate: TestDependencies.fixedNow).map(\.id) == ["BL-2604-016"])
    }

    @Test func statusFilterShowsMatchingOrdersOnly() async {
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
        }

        await store.send(.statusFilterSelected(.shipping)) {
            $0.selectedStatus = .shipping
            $0.selectedOrderID = "BL-2604-018"
        }

        let filtered = store.state.filteredOrders(referenceDate: TestDependencies.fixedNow)
        #expect(filtered.allSatisfy { $0.status == .shipping })
        #expect(filtered.map(\.id) == ["BL-2604-018"])
    }
    
    @Test func editFlowPersistsCustomerNameAfterSave() async {
        // 直接以草稿狀態預塞 `editOrder` 來測試 `applyEditDraft` 的寫回邏輯，
        // 因為使用 `BindingAction.set` 會踩到 Swift 6 對 `WritableKeyPath` 的 `Sendable` 限制。
        // 此路徑跳過 `@Presents` 啟動 lifecycle，所以 `await dismiss()` 不會清掉 `state.editOrder`，
        // 因此本測試只驗證 orders 寫回，不驗證 sheet dismiss。
        let originalID = "BL-2604-018"
        let original = LedgerOrder.sampleOrders.first { $0.id == originalID }!
        let newName = "重新命名客戶"
        
        var draft = OrderEditFeature.State(original: original)
        draft.draftCustomerName = newName
        
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.editOrder = draft
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        }
        store.exhaustivity = .off
        
        await store.send(.editOrder(.presented(.saveTapped)))
        await store.finish()
        
        let updated = store.state.orders.first { $0.id == originalID }
        #expect(updated?.customer.name == newName)
    }

    @Test func editFlowPersistsNotes() async {
        // 驗證備註欄位經 save 後寫回 orders，且首尾空白會被 trim。
        let originalID = "BL-2604-018"
        let original = LedgerOrder.sampleOrders.first { $0.id == originalID }!

        var draft = OrderEditFeature.State(original: original)
        draft.draftNotes = "  到貨後請先聯絡客戶確認尺寸  "

        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.editOrder = draft

        let store = TestStore(initialState: state) {
            OrdersFeature()
        }
        store.exhaustivity = .off

        await store.send(.editOrder(.presented(.saveTapped)))
        await store.finish()

        let updated = store.state.orders.first { $0.id == originalID }
        #expect(updated?.notes == "到貨後請先聯絡客戶確認尺寸")
    }

    @Test func editFlowKeepsVerificationStatusForBankTransfer() async {
        // 付款方式屬於銀行匯款 → 對帳狀態有意義，save 後應保留。
        let originalID = "BL-2604-018"
        let original = LedgerOrder.sampleOrders.first { $0.id == originalID }!

        var draft = OrderEditFeature.State(
            original: original,
            availablePaymentMethods: [
                PaymentMethodInfo(name: "銀行匯款", isCardless: false, isBankTransfer: true),
            ]
        )
        draft.draftPaymentMethod = "銀行匯款"
        draft.draftVerificationStatus = "待對帳"

        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.editOrder = draft

        let store = TestStore(initialState: state) {
            OrdersFeature()
        }
        store.exhaustivity = .off

        await store.send(.editOrder(.presented(.saveTapped)))
        await store.finish()

        let updated = store.state.orders.first { $0.id == originalID }
        #expect(updated?.verificationStatus == "待對帳")
    }

    @Test func editFlowClearsVerificationStatusForNonReconcilingMethod() async {
        // 付款方式非無卡／非銀行匯款 (信用卡) → 對帳狀態無意義，save 後應清成空字串，避免殘留。
        let originalID = "BL-2604-018"
        let original = LedgerOrder.sampleOrders.first { $0.id == originalID }!

        // 原訂單付款方式為「信用卡」(預設無旗標)；殘留一個對帳狀態草稿。
        var draft = OrderEditFeature.State(original: original)
        draft.draftVerificationStatus = "待對帳"

        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.editOrder = draft

        let store = TestStore(initialState: state) {
            OrdersFeature()
        }
        store.exhaustivity = .off

        await store.send(.editOrder(.presented(.saveTapped)))
        await store.finish()

        let updated = store.state.orders.first { $0.id == originalID }
        #expect(updated?.verificationStatus == "")
    }

    @Test func editFlowSavingEmptyNameKeepsOriginalName() async {
        let originalID = "BL-2604-018"
        let original = LedgerOrder.sampleOrders.first { $0.id == originalID }!
        
        var draft = OrderEditFeature.State(original: original)
        draft.draftCustomerName = "   "
        
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.editOrder = draft
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        }
        store.exhaustivity = .off
        
        await store.send(.editOrder(.presented(.saveTapped)))
        await store.finish()
        
        let updated = store.state.orders.first { $0.id == originalID }
        #expect(updated?.customer.name == original.customer.name)
    }
    
    @Test func cancellingEditDoesNotMutateOrders() async {
        // 同上：以預塞 state 驗證 cancel 不會觸發 `applyEditDraft`，因此不檢查 `editOrder == nil`。
        let originalID = "BL-2604-018"
        let original = LedgerOrder.sampleOrders.first { $0.id == originalID }!
        
        var draft = OrderEditFeature.State(original: original)
        draft.draftCustomerName = "暫定名字"
        
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.editOrder = draft
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        }
        store.exhaustivity = .off
        
        await store.send(.editOrder(.presented(.cancelTapped)))
        await store.finish()
        
        let unchanged = store.state.orders.first { $0.id == originalID }
        #expect(unchanged?.customer.name == original.customer.name)
    }
    
    @Test func editOrderTappedSetsEditState() async {
        // 驗證 .editOrderTapped 走 @Presents 把 editOrder 設成對應草稿。
        // dismiss lifecycle 的 sheet 關閉行為由實機 UI 與 OrderEditFeature 標準
        // BindingReducer + DismissEffect 保證，這裡不重複驗證。
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders

        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
        }
        store.exhaustivity = .off
        
        let originalID = "BL-2604-018"
        let original = LedgerOrder.sampleOrders.first { $0.id == originalID }!
        
        await store.send(.editOrderTapped(originalID))
        
        let editState = store.state.editOrder
        #expect(editState?.original?.id == originalID)
        #expect(editState?.draftCustomerName == original.customer.name)
        #expect(editState?.draftCategory == original.category)
    }
    
    @Test func newOrderTappedSetsEmptyEditState() async {
        let store = TestStore(initialState: OrdersFeature.State()) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
        }
        store.exhaustivity = .off

        await store.send(.newOrderTapped)

        let editState = store.state.editOrder
        #expect(editState?.original == nil)
        #expect(editState?.draftCustomerName.isEmpty == true)
        #expect(editState?.draftCategory.isEmpty == true)
    }
    
    @Test func editingExistingOrderKeepsSelection() async {
        // 編輯既有訂單 save 後不該改變 selectedOrderID (即使原本選的是別張)
        let originalID = "BL-2604-018"
        let original = LedgerOrder.sampleOrders.first { $0.id == originalID }!
        let unrelatedSelection = "BL-2604-016"
        
        var draft = OrderEditFeature.State(original: original)
        draft.draftCustomerName = "改過的客戶"
        
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.editOrder = draft
        state.selectedOrderID = unrelatedSelection
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        }
        store.exhaustivity = .off
        
        await store.send(.editOrder(.presented(.saveTapped)))
        await store.finish()
        
        #expect(store.state.selectedOrderID == unrelatedSelection)
        #expect(store.state.orders.first { $0.id == originalID }?.customer.name == "改過的客戶")
    }
    
    @Test func editFlowPersistsStatusCurrencyAndAmount() async {
        let originalID = "BL-2604-018"
        let original = LedgerOrder.sampleOrders.first { $0.id == originalID }!
        
        var draft = OrderEditFeature.State(original: original)
        draft.draftStatus = .delivered
        draft.draftCurrency = .jpy
        draft.draftChargedAmount = 9_876
        
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.editOrder = draft
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        }
        store.exhaustivity = .off
        
        await store.send(.editOrder(.presented(.saveTapped)))
        await store.finish()
        
        let updated = store.state.orders.first { $0.id == originalID }
        #expect(updated?.status == .delivered)
        #expect(updated?.currency == .jpy)
        #expect(updated?.chargedAmount == 9_876)
        // 客戶名沒改 → 應與原本相同
        #expect(updated?.customer.name == original.customer.name)
    }
    
    @Test func editFlowPersistsCostBreakdownFields() async {
        let originalID = "BL-2604-018"
        let original = LedgerOrder.sampleOrders.first { $0.id == originalID }!
        
        var draft = OrderEditFeature.State(original: original)
        draft.draftItemCost = 5_000
        draft.draftDomesticShipping = 100
        draft.draftInternationalShipping = 250
        draft.draftCardFeeRate = 0.025
        draft.draftPlatformFeeRate = 0.04
        
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.editOrder = draft
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        }
        store.exhaustivity = .off
        
        await store.send(.editOrder(.presented(.saveTapped)))
        await store.finish()
        
        let updated = store.state.orders.first { $0.id == originalID }
        #expect(updated?.itemCost == 5_000)
        #expect(updated?.domesticShipping == 100)
        #expect(updated?.internationalShipping == 250)
        #expect(updated?.cardFeeRate == 0.025)
        #expect(updated?.platformFeeRate == 0.04)
    }
    
    @Test func editFlowClampsFeeRatesIntoZeroToOneRange() async {
        let originalID = "BL-2604-018"
        let original = LedgerOrder.sampleOrders.first { $0.id == originalID }!
        
        var draft = OrderEditFeature.State(original: original)
        draft.draftCardFeeRate = -0.5
        draft.draftPlatformFeeRate = 5
        
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.editOrder = draft
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        }
        store.exhaustivity = .off
        
        await store.send(.editOrder(.presented(.saveTapped)))
        await store.finish()
        
        let updated = store.state.orders.first { $0.id == originalID }
        #expect(updated?.cardFeeRate == 0)
        #expect(updated?.platformFeeRate == 1)
    }
    
    @Test func editFlowClampsNegativeChargedAmountToZero() async {
        let originalID = "BL-2604-018"
        let original = LedgerOrder.sampleOrders.first { $0.id == originalID }!
        
        var draft = OrderEditFeature.State(original: original)
        draft.draftChargedAmount = -500
        
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.editOrder = draft
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        }
        store.exhaustivity = .off
        
        await store.send(.editOrder(.presented(.saveTapped)))
        await store.finish()
        
        let updated = store.state.orders.first { $0.id == originalID }
        #expect(updated?.chargedAmount == 0)
    }
    
    @Test func newOrderSaveInsertsAndSelectsTheNewOrder() async {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

        // 直接把 fixedDate 帶進 `currentDate`，避免 `OrderEditFeature.State()` 內部 fallback 到 `Date()` 造成
        // 新訂單 `date` 落在測試實際執行的當下，與下方斷言期待的 fixedDate 不符。
        var draft = OrderEditFeature.State(currentDate: fixedDate)
        draft.draftCustomerName = "新客戶"
        draft.draftCategory = "美妝"

        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.editOrder = draft

        let originalCount = state.orders.count

        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.date = .constant(fixedDate)
        }
        store.exhaustivity = .off

        await store.send(.editOrder(.presented(.saveTapped)))
        await store.finish()

        let expectedID = "BL-DRAFT-000000"
        #expect(store.state.selectedOrderID == expectedID)
        #expect(store.state.orders.count == originalCount + 1)

        let inserted = store.state.orders.first
        #expect(inserted?.id == expectedID)
        #expect(inserted?.customer.name == "新客戶")
        #expect(inserted?.customer.tier == .new)
        #expect(inserted?.category == "美妝")
        #expect(inserted?.status == .quoting)
        #expect(inserted?.currency == .twd)
        #expect(inserted?.date == fixedDate)
    }

    // MARK: - Category Filter

    @Test func categoryFilterShowsMatchingCategoryOnly() async {
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        let targetCategory = LedgerOrder.sampleOrders.first!.category

        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
        }

        let expectedFirstID = state
            .filteredOrders(referenceDate: TestDependencies.fixedNow)
            .first { $0.category == targetCategory }?
            .id

        await store.send(.categoryFilterSelected(targetCategory)) {
            $0.selectedCategory = targetCategory
            $0.selectedOrderID = expectedFirstID
        }

        let filtered = store.state.filteredOrders(referenceDate: TestDependencies.fixedNow)
        #expect(!filtered.isEmpty)
        #expect(filtered.allSatisfy { $0.category == targetCategory })

        await store.send(.categoryFilterSelected(nil)) {
            $0.selectedCategory = nil
            $0.selectedOrderID = state.filteredOrders(referenceDate: TestDependencies.fixedNow).first?.id
        }
    }

    @Test func categoryFilterCombinesWithStatusFilter() async {
        var state = OrdersFeature.State()
        state.orders = [
            makeOrder(id: "O1", category: "beauty", status: .shipping),
            makeOrder(id: "O2", category: "beauty", status: .quoting),
            makeOrder(id: "O3", category: "snacks", status: .shipping),
        ]
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
        }

        await store.send(.statusFilterSelected(.shipping)) {
            $0.selectedStatus = .shipping
            $0.selectedOrderID = "O1"
        }
        await store.send(.categoryFilterSelected("beauty")) {
            $0.selectedCategory = "beauty"
            $0.selectedOrderID = "O1"
        }

        let filtered = store.state.filteredOrders(referenceDate: TestDependencies.fixedNow)
        #expect(filtered.map(\.id) == ["O1"])
    }

    // MARK: - AI Summary Entry

    @Test func aiSummaryTappedWithSettingEnabledPresentsSheet() async {
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders

        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0[SettingsStorage.self] = SettingsStorage(
                load: {
                    var snapshot = SettingsSnapshot.default
                    snapshot.useAiSummary = true
                    snapshot.aiSummaryModel = "gpt-oss:120b"
                    return snapshot
                },
                save: { _ in }
            )
        }

        await store.send(.aiSummaryTapped) {
            $0.aiSummary = AISummaryFeature.State(
                prompt: state.aiSummaryPrompt(referenceDate: TestDependencies.fixedNow),
                model: "gpt-oss:120b"
            )
        }

        #expect(store.state.aiSummary?.prompt.isEmpty == false)
        #expect(store.state.aiDisabledAlert == nil)
    }

    @Test func aiSummaryTappedWithSettingDisabledPresentsAlert() async {
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders

        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0[SettingsStorage.self] = SettingsStorage(
                load: { .default },
                save: { _ in }
            )
        }
        store.exhaustivity = .off

        await store.send(.aiSummaryTapped)

        #expect(store.state.aiDisabledAlert != nil)
        #expect(store.state.aiSummary == nil)
    }

    // MARK: - Helpers

    /// 建立僅供篩選測試使用的最小訂單；非相關欄位以零值/佔位填入。
    private func makeOrder(id: String, category: String, status: OrderStatus) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: "客戶", initials: "XX", tier: .new),
            status: status,
            currency: .twd,
            date: TestDependencies.fixedNow,
            items: [LedgerOrderItem(id: UUID(), name: "商品", quantity: 1, unitPrice: 100)],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 0,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "來源",
            category: category,
            paymentMethod: "付款",
            notes: "",
            verificationStatus: ""
        )
    }
}
