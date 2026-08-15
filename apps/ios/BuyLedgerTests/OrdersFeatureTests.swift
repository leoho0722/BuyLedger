//
//  OrdersFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import Foundation
import SwiftUI
import Testing
@testable import BuyLedger

/// 驗證訂單功能
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
        // 主檔效果並行且順序不固定，本測試只驗證訂單載入
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
    
    // MARK: - Campaign Auto-Close Evaluation
    
    @Test func campaignsLoadedKeepsCloseDateTodayOngoing() async {
        // 結單日當天仍算 ongoing，驗證使用日期而非時間戳判斷
        let campaign = Campaign(
            id: "C1",
            name: "今天團",
            openDate: TestDependencies.fixedNow,
            closeDate: TestDependencies.fixedNow,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let store = TestStore(initialState: OrdersFeature.State()) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        
        await store.send(.campaignsLoaded([campaign])) {
            $0.campaigns = [campaign]
        }
    }
    
    @Test func searchTextFiltersOrdersByCustomerIdAndItemName() async {
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        
        await store.send(.searchTextChanged("mika")) {
            $0.searchText = "mika"
            $0.selectedOrderID = "BL-2604-017"
        }
        
        // "Mika 周" 有兩筆樣本訂單，依日期由新到舊排序。
        #expect(
            store.state.filteredOrders(
                referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar
            ).map(\.id) == ["BL-2604-017", "BL-2604-011"])
        
        await store.send(.searchTextChanged("Aesop")) {
            $0.searchText = "Aesop"
            $0.selectedOrderID = "BL-2604-016"
        }
        
        #expect(
            store.state.filteredOrders(
                referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar
            ).map(\.id) == ["BL-2604-016"])
    }
    
    @Test func statusFilterShowsMatchingOrdersOnly() async {
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        
        await store.send(.statusFilterSelected(.shipping)) {
            $0.selectedStatus = .shipping
            $0.selectedOrderID = "BL-2604-018"
        }
        
        let filtered = store.state.filteredOrders(
            referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar)
        #expect(filtered.allSatisfy { $0.status == .shipping })
        // 樣本中集運中的訂單有兩筆 (BL-2604-018 與合併樣本 BL-2604-011)
        #expect(filtered.map(\.id) == ["BL-2604-018", "BL-2604-011"])
    }
    
    @Test func editFlowPersistsCustomerNameAfterSave() async {
        // 直接預塞 `editOrder` 草稿，測試 `applyEditDraft` 的寫回邏輯。
        // 直接預塞草稿，避開 Swift 6 的 BindingAction Sendable 限制
        let originalID = "BL-2604-018"
        let original = LedgerOrder.sampleOrders.first { $0.id == originalID }!
        let newName = "重新命名客戶"
        
        var draft = OrderEditFeature.State(
            original: original, id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.draft.customerName = newName
        
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.editOrder = draft
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        }
        
        let expected = Self.expectedWriteResult(draft, existingOrders: state.orders)
        
        await store.send(.editOrder(.presented(.saveTapped)))
        await store.receive(\.orderSavePersisted) { state in
            Self.applyExpectedWriteResult(expected, to: &state)
        }
        // saveTapped 會一律 dismiss 表單
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        
        let updated = store.state.orders.first { $0.id == originalID }
        #expect(updated?.customer.name == newName)
    }
    
    @Test func editFlowPersistsNotes() async {
        // 驗證備註欄位經 save 後寫回 orders，且首尾空白會被 trim
        let originalID = "BL-2604-018"
        let original = LedgerOrder.sampleOrders.first { $0.id == originalID }!
        
        var draft = OrderEditFeature.State(
            original: original, id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.draft.notes = "  到貨後請先聯絡客戶確認尺寸  "
        
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.editOrder = draft
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        }
        
        let expected = Self.expectedWriteResult(draft, existingOrders: state.orders)
        
        await store.send(.editOrder(.presented(.saveTapped)))
        await store.receive(\.orderSavePersisted) { state in
            Self.applyExpectedWriteResult(expected, to: &state)
        }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        
        let updated = store.state.orders.first { $0.id == originalID }
        #expect(updated?.notes == "到貨後請先聯絡客戶確認尺寸")
    }
    
    @Test func editFlowPersistsPhotosAfterSave() async {
        // 驗證照片只有在已載入且被編輯過時才會寫回
        let originalID = "BL-2604-018"
        let original = LedgerOrder.sampleOrders.first { $0.id == originalID }!
        let photos = [Data([0x01]), Data([0x02])]
        
        var draft = OrderEditFeature.State(
            original: original, id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.photoLoadPhase = .loaded
        draft.hasEditedPhotos = true
        draft.draftPhotos = photos
        
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.editOrder = draft
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        }
        
        let expected = Self.expectedWriteResult(draft, existingOrders: state.orders)
        
        await store.send(.editOrder(.presented(.saveTapped)))
        await store.receive(\.orderSavePersisted) { state in
            Self.applyExpectedWriteResult(expected, to: &state)
        }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        
        let updated = store.state.orders.first { $0.id == originalID }
        #expect(updated?.photos == photos)
    }
    
    @Test func editFlowPersistsPhotosForNewOrder() async {
        // 驗證新增訂單分支 (original == nil) 也會把照片草稿寫進新訂單
        let photos = [Data([0xA1])]
        
        var draft = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.draft.customerName = "新照片客戶"
        draft.draftPhotos = photos
        
        var state = OrdersFeature.State()
        state.editOrder = draft
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.uuid = .incrementing
        }
        
        let expected = Self.expectedWriteResult(draft, existingOrders: state.orders)
        
        await store.send(.editOrder(.presented(.saveTapped)))
        await store.receive(\.orderSavePersisted) { state in
            Self.applyExpectedWriteResult(expected, to: &state)
        }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        
        let created = store.state.orders.first { $0.customer.name == "新照片客戶" }
        #expect(created?.photos == photos)
    }
    
    @Test func editFlowKeepsReconciliationStatusForBankTransfer() async {
        // 付款方式屬於銀行匯款 → 對帳狀態有意義，save 後應保留
        let originalID = "BL-2604-018"
        let original = LedgerOrder.sampleOrders.first { $0.id == originalID }!
        
        var draft = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            availablePaymentMethods: [
                PaymentMethodInfo(
                    name: "銀行匯款", isCardless: false, isBankTransfer: true, isCashOnDelivery: false)
            ],
            currentDate: TestDependencies.fixedNow
        )
        draft.draft.paymentMethod = "銀行匯款"
        draft.draft.reconciliationStatus = "待對帳"
        
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.editOrder = draft
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        }
        
        let expected = Self.expectedWriteResult(draft, existingOrders: state.orders)
        
        await store.send(.editOrder(.presented(.saveTapped)))
        await store.receive(\.orderSavePersisted) { state in
            Self.applyExpectedWriteResult(expected, to: &state)
        }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        
        let updated = store.state.orders.first { $0.id == originalID }
        #expect(updated?.reconciliationStatus == "待對帳")
    }
    
    @Test func editFlowClearsReconciliationStatusForNonReconcilingMethod() async {
        // 非無卡或銀行匯款時，儲存後清空對帳狀態。
        let originalID = "BL-2604-018"
        let original = LedgerOrder.sampleOrders.first { $0.id == originalID }!
        
        // 原訂單付款方式為「信用卡」(預設無旗標)；殘留一個對帳狀態草稿
        var draft = OrderEditFeature.State(
            original: original, id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.draft.reconciliationStatus = "待對帳"
        
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.editOrder = draft
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        }
        
        let expected = Self.expectedWriteResult(draft, existingOrders: state.orders)
        
        await store.send(.editOrder(.presented(.saveTapped)))
        // 對帳狀態清空後與原值相同，因此 state 不變。
        #expect(expected.order == original, "本測試前提：清空對帳狀態後應與原訂單完全相同，才會是沒有可觀察變化的寫回")
        await store.receive(\.orderSavePersisted)
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        
        let updated = store.state.orders.first { $0.id == originalID }
        #expect(updated?.reconciliationStatus == "")
    }
    
    @Test func editFlowSavingEmptyNameKeepsOriginalName() async {
        let originalID = "BL-2604-018"
        let original = LedgerOrder.sampleOrders.first { $0.id == originalID }!
        
        var draft = OrderEditFeature.State(
            original: original, id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.draft.customerName = "   "
        
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.editOrder = draft
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        }
        
        let expected = Self.expectedWriteResult(draft, existingOrders: state.orders)
        
        await store.send(.editOrder(.presented(.saveTapped)))
        // 空白客戶名回退後與原訂單相同。
        #expect(expected.order == original, "本測試前提：回退空白名稱後應與原訂單完全相同，才會是沒有可觀察變化的寫回")
        await store.receive(\.orderSavePersisted)
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        
        let updated = store.state.orders.first { $0.id == originalID }
        #expect(updated?.customer.name == original.customer.name)
    }
    
    @Test func cancellingEditDoesNotMutateOrders() async {
        // 預塞草稿驗證取消不會套用變更
        let originalID = "BL-2604-018"
        let original = LedgerOrder.sampleOrders.first { $0.id == originalID }!
        
        var draft = OrderEditFeature.State(
            original: original, id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.draft.customerName = "暫定名字"
        
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.editOrder = draft
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        }
        
        await store.send(.editOrder(.presented(.cancelTapped))) {
            $0.editOrder?.discardConfirmation = AlertState {
                TextState("捨棄變更")
            } actions: {
                ButtonState(role: .destructive, action: .discard) {
                    TextState("捨棄變更")
                }
                ButtonState(role: .cancel) {
                    TextState("繼續編輯")
                }
            } message: {
                TextState("這張訂單有尚未儲存的變更，離開後將不會保留。")
            }
        }
        await store.finish()
        
        let unchanged = store.state.orders.first { $0.id == originalID }
        #expect(unchanged?.customer.name == original.customer.name)
    }
    
    @Test func editOrderTappedSetsEditState() async {
        // 驗證 .editOrderTapped 走 @Presents 把 editOrder 設成對應草稿
        // dismiss lifecycle 的 sheet 關閉行為由實機 UI 與 OrderEditFeature 標準
        // BindingReducer + DismissEffect 保證，這裡不重複驗證
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .incrementing
        }
        
        let originalID = "BL-2604-018"
        let original = LedgerOrder.sampleOrders.first { $0.id == originalID }!
        // 表單選項來自現有訂單的主檔資料
        let expectedEditState = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            availableOrderSources: state.availableOrderSources,
            availableCategories: state.availableCategories,
            availablePaymentMethods: state.availablePaymentMethods,
            availableReconciliationStatuses: state.availableReconciliationStatuses,
            availableCampaigns: state.ongoingCampaigns,
            currentDate: TestDependencies.fixedNow
        )
        
        await store.send(.editOrderTapped(originalID)) {
            $0.editOrder = expectedEditState
        }
        
        let editState = store.state.editOrder
        #expect(editState?.original?.id == originalID)
        #expect(editState?.draft.customerName == original.customer.name)
        #expect(editState?.draft.categories == original.categories)
    }
    
    @Test func newOrderTappedSetsEmptyEditState() async {
        let store = TestStore(initialState: OrdersFeature.State()) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .incrementing
        }
        
        let expectedEditState = OrderEditFeature.State(
            id: UUID(0), currentDate: TestDependencies.fixedNow)
        
        await store.send(.newOrderTapped) {
            $0.editOrder = expectedEditState
        }
        
        let editState = store.state.editOrder
        #expect(editState?.original == nil)
        #expect(editState?.draft.customerName.isEmpty == true)
        #expect(editState?.draft.categories.isEmpty == true)
    }
    
    @Test func editingExistingOrderKeepsSelection() async {
        // 編輯既有訂單 save 後不該改變 selectedOrderID (即使原本選的是別張)
        let originalID = "BL-2604-018"
        let original = LedgerOrder.sampleOrders.first { $0.id == originalID }!
        let unrelatedSelection = "BL-2604-016"
        
        var draft = OrderEditFeature.State(
            original: original, id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.draft.customerName = "改過的客戶"
        
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.editOrder = draft
        state.selectedOrderID = unrelatedSelection
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        }
        
        let expected = Self.expectedWriteResult(draft, existingOrders: state.orders)
        
        await store.send(.editOrder(.presented(.saveTapped)))
        await store.receive(\.orderSavePersisted) { state in
            Self.applyExpectedWriteResult(expected, to: &state)
        }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        
        #expect(store.state.selectedOrderID == unrelatedSelection)
        #expect(store.state.orders.first { $0.id == originalID }?.customer.name == "改過的客戶")
    }
    
    @Test func editFlowPersistsStatusCurrencyAndAmount() async {
        let originalID = "BL-2604-018"
        let original = LedgerOrder.sampleOrders.first { $0.id == originalID }!
        
        var draft = OrderEditFeature.State(
            original: original, id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.draft.status = .delivered
        draft.draft.currency = .jpy
        draft.draft.chargedAmount = 9_876
        
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.editOrder = draft
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        }
        
        let expected = Self.expectedWriteResult(draft, existingOrders: state.orders)
        
        await store.send(.editOrder(.presented(.saveTapped)))
        await store.receive(\.orderSavePersisted) { state in
            Self.applyExpectedWriteResult(expected, to: &state)
        }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        
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
        
        var draft = OrderEditFeature.State(
            original: original, id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.draft.itemCost = 5_000
        draft.draft.domesticShipping = 100
        draft.draft.internationalShipping = 250
        draft.draft.cardFeeRate = 0.025
        draft.draft.platformFeeRate = 0.04
        
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.editOrder = draft
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        }
        
        let expected = Self.expectedWriteResult(draft, existingOrders: state.orders)
        
        await store.send(.editOrder(.presented(.saveTapped)))
        await store.receive(\.orderSavePersisted) { state in
            Self.applyExpectedWriteResult(expected, to: &state)
        }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        
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
        
        var draft = OrderEditFeature.State(
            original: original, id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.draft.cardFeeRate = -0.5
        draft.draft.platformFeeRate = 5
        
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.editOrder = draft
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        }
        
        let expected = Self.expectedWriteResult(draft, existingOrders: state.orders)
        
        await store.send(.editOrder(.presented(.saveTapped)))
        await store.receive(\.orderSavePersisted) { state in
            Self.applyExpectedWriteResult(expected, to: &state)
        }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        
        let updated = store.state.orders.first { $0.id == originalID }
        #expect(updated?.cardFeeRate == 0)
        #expect(updated?.platformFeeRate == 1)
    }
    
    @Test func editFlowClampsNegativeChargedAmountToZero() async {
        let originalID = "BL-2604-018"
        let original = LedgerOrder.sampleOrders.first { $0.id == originalID }!
        
        var draft = OrderEditFeature.State(
            original: original, id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.draft.chargedAmount = -500
        
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.editOrder = draft
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        }
        
        let expected = Self.expectedWriteResult(draft, existingOrders: state.orders)
        
        await store.send(.editOrder(.presented(.saveTapped)))
        await store.receive(\.orderSavePersisted) { state in
            Self.applyExpectedWriteResult(expected, to: &state)
        }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        
        let updated = store.state.orders.first { $0.id == originalID }
        #expect(updated?.chargedAmount == 0)
    }
    
    @Test func newOrderSaveInsertsAndSelectsTheNewOrder() async {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        
        // 顯式把 fixedDate 帶進 `currentDate`，讓新訂單的 `draft.date` 為固定值、
        // 與下方斷言期待的 fixedDate 一致 (不落在測試實際執行的當下)
        var draft = OrderEditFeature.State(id: UUID(0), currentDate: fixedDate)
        draft.draft.customerName = "新客戶"
        draft.draft.categories = ["美妝"]
        
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.editOrder = draft
        
        let originalCount = state.orders.count
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.date = .constant(fixedDate)
            $0.calendar = TestDependencies.fixedCalendar
        }
        
        let expected = Self.expectedWriteResult(draft, existingOrders: state.orders)
        
        await store.send(.editOrder(.presented(.saveTapped)))
        await store.receive(\.orderSavePersisted) { state in
            Self.applyExpectedWriteResult(expected, to: &state)
        }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        
        // 使用完整的隨機識別碼；incrementing 的第一個 UUID 為全零。
        let expectedID = "BL-DRAFT-00000000-0000-0000-0000-000000000000"
        #expect(store.state.selectedOrderID == expectedID)
        #expect(store.state.orders.count == originalCount + 1)
        
        let inserted = store.state.orders.first
        #expect(inserted?.id == expectedID)
        #expect(inserted?.customer.name == "新客戶")
        #expect(inserted?.customer.tier == .new)
        #expect(inserted?.categories == ["美妝"])
        #expect(inserted?.status == .quoting)
        #expect(inserted?.currency == .twd)
        #expect(inserted?.date == fixedDate)
    }
    
    @Test func newOrderSaveUsesCreateIntentNotUpdateIntent() async {
        // 新訂單必須使用 createOrder，避免撞號時覆寫既有資料
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        var draft = OrderEditFeature.State(id: UUID(0), currentDate: fixedDate)
        draft.draft.customerName = "新客戶"
        draft.draft.categories = ["美妝"]
        
        var state = OrdersFeature.State()
        state.editOrder = draft
        
        let box = WriteIntentBox()
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.date = .constant(fixedDate)
            $0.calendar = TestDependencies.fixedCalendar
            $0[OrderRepository.self].createOrder = { box.createdOrders.append($0) }
            $0[OrderRepository.self].saveOrder = { box.savedOrders.append($0) }
        }
        
        let expected = Self.expectedWriteResult(draft, existingOrders: state.orders)
        
        await store.send(.editOrder(.presented(.saveTapped)))
        await store.receive(\.orderSavePersisted) { state in
            Self.applyExpectedWriteResult(expected, to: &state)
        }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        
        #expect(box.createdOrders.count == 1, "新建訂單必須經由 createOrder (建立意圖) 寫入")
        #expect(box.savedOrders.isEmpty, "新建訂單不可誤用 saveOrder (更新意圖)")
    }
    
    @Test func newOrderSaveDoesNotInsertWhenCreateFails() async {
        // 寫入失敗時，訂單狀態與重新載入結果都不變
        // 建立失敗不會樂觀插入訂單，只顯示寫入失敗對話框。
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        var draft = OrderEditFeature.State(id: UUID(0), currentDate: fixedDate)
        draft.draft.customerName = "新客戶"
        draft.draft.categories = ["美妝"]
        
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.editOrder = draft
        
        let originalOrders = state.orders
        let expectedID = "BL-DRAFT-00000000-0000-0000-0000-000000000000"
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.date = .constant(fixedDate)
            $0.calendar = TestDependencies.fixedCalendar
            $0[OrderRepository.self].createOrder = {
                (_: LedgerOrder) async throws(OrderPersistenceError) in
                throw OrderPersistenceError.identifierCollision(id: expectedID)
            }
        }
        
        await store.send(.editOrder(.presented(.saveTapped)))
        // 先接收失敗 action，再斷言 state。
        // (比照 CampaignReminderFailureTests 的既有慣例；exhaustivity 全程未關閉)
        await store.receive(\.orderWriteFailed) {
            $0.writeFailureAlert = expectedWriteFailureAlert("訂單儲存失敗，請稍後再試。")
        }
        // `OrderEditFeature.saveTapped` 一律觸發 `dismiss()`，與寫入結果無關。
        // 故仍會收到子層的關閉表單事件；窮舉檢查下需明確承接
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        
        #expect(store.state.orders == originalOrders, "create 失敗時畫面狀態從未被樂觀插入，維持與寫入前相同")
        #expect(!store.state.orders.contains { $0.id == expectedID }, "被拒的新訂單不應出現在清單中")
        #expect(store.state.errorMessage == nil, "建立失敗屬一次性操作失敗，不應殘留於載入失敗欄位")
        await store.finish()
    }
    
    @Test func editExistingOrderSaveUsesUpdateIntentNotCreateIntent() async {
        // 既有訂單必須使用 saveOrder，避免誤走建立流程
        let originalID = "BL-2604-018"
        let original = LedgerOrder.sampleOrders.first { $0.id == originalID }!
        
        var draft = OrderEditFeature.State(
            original: original, id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.draft.customerName = "改名後"
        
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.editOrder = draft
        
        let box = WriteIntentBox()
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0[OrderRepository.self].createOrder = { box.createdOrders.append($0) }
            $0[OrderRepository.self].saveOrder = { box.savedOrders.append($0) }
        }
        
        let expected = Self.expectedWriteResult(draft, existingOrders: state.orders)
        
        await store.send(.editOrder(.presented(.saveTapped)))
        await store.receive(\.orderSavePersisted) { state in
            Self.applyExpectedWriteResult(expected, to: &state)
        }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        
        #expect(box.savedOrders.count == 1, "編輯既有訂單必須經由 saveOrder (更新意圖) 寫入")
        #expect(box.createdOrders.isEmpty, "編輯既有訂單不可誤用 createOrder (建立意圖)")
    }
    
    // MARK: - Photo Write Gating
    
    @Test func savingBeforePhotoLoadCompletesKeepsStoredPhotos() async {
        // 照片載入中一律走不帶照片的儲存路徑。
        let originalID = "BL-2604-018"
        let original = LedgerOrder.sampleOrders.first { $0.id == originalID }!
        
        var draft = OrderEditFeature.State(
            original: original, id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.photoLoadPhase = .loading
        draft.draftPhotos = [Data([0xAA])]
        draft.draft.customerName = "載入中就儲存"
        
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.editOrder = draft
        
        let box = WriteIntentBox()
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0[OrderRepository.self].saveOrder = { box.savedOrders.append($0) }
            $0[OrderRepository.self].saveOrderPersistingPhotos = {
                box.photoPersistedOrders.append($0)
            }
        }
        
        let expected = Self.expectedWriteResult(draft, existingOrders: state.orders)
        
        await store.send(.editOrder(.presented(.saveTapped)))
        await store.receive(\.orderSavePersisted) { state in
            Self.applyExpectedWriteResult(expected, to: &state)
        }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        
        #expect(box.savedOrders.count == 1, "載入中儲存必須走不帶照片的 saveOrder")
        #expect(box.photoPersistedOrders.isEmpty, "載入中儲存不可誤用 saveOrderPersistingPhotos")
    }
    
    @Test func savingAfterPhotoLoadFailureKeepsStoredPhotos() async {
        // 照片載入失敗時也走不帶照片的儲存路徑。
        let originalID = "BL-2604-018"
        let original = LedgerOrder.sampleOrders.first { $0.id == originalID }!
        
        var draft = OrderEditFeature.State(
            original: original, id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.photoLoadPhase = .failed
        draft.draft.customerName = "載入失敗就儲存"
        
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.editOrder = draft
        
        let box = WriteIntentBox()
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0[OrderRepository.self].saveOrder = { box.savedOrders.append($0) }
            $0[OrderRepository.self].saveOrderPersistingPhotos = {
                box.photoPersistedOrders.append($0)
            }
        }
        
        let expected = Self.expectedWriteResult(draft, existingOrders: state.orders)
        
        await store.send(.editOrder(.presented(.saveTapped)))
        await store.receive(\.orderSavePersisted) { state in
            Self.applyExpectedWriteResult(expected, to: &state)
        }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        
        #expect(box.savedOrders.count == 1, "載入失敗後儲存必須走不帶照片的 saveOrder")
        #expect(box.photoPersistedOrders.isEmpty, "載入失敗後儲存不可誤用 saveOrderPersistingPhotos")
    }
    
    @Test func savingWithEditedPhotosWritesEditedSet() async {
        // 照片已載入且有變更時，使用帶照片的寫入路徑。
        let originalID = "BL-2604-018"
        let original = LedgerOrder.sampleOrders.first { $0.id == originalID }!
        let editedPhotos = [Data([0x09]), Data([0x10])]
        
        var draft = OrderEditFeature.State(
            original: original, id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.photoLoadPhase = .loaded
        draft.hasEditedPhotos = true
        draft.draftPhotos = editedPhotos
        
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.editOrder = draft
        
        let box = WriteIntentBox()
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0[OrderRepository.self].saveOrder = { box.savedOrders.append($0) }
            $0[OrderRepository.self].saveOrderPersistingPhotos = {
                box.photoPersistedOrders.append($0)
            }
        }
        
        let expected = Self.expectedWriteResult(draft, existingOrders: state.orders)
        
        await store.send(.editOrder(.presented(.saveTapped)))
        await store.receive(\.orderSavePersisted) { state in
            Self.applyExpectedWriteResult(expected, to: &state)
        }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        
        #expect(box.photoPersistedOrders.count == 1, "已編輯照片時必須走帶照片的 saveOrderPersistingPhotos")
        #expect(box.photoPersistedOrders.first?.photos == editedPhotos, "傳入的照片必須等於編輯後的草稿")
        #expect(box.savedOrders.isEmpty, "已編輯照片時不可誤用不帶照片的 saveOrder")
    }
    
    @Test func savingWithEditedFlagBeforePhotoLoadCompletesKeepsStoredPhotos() async {
        // photoLoadPhase 未完成時，即使 hasEditedPhotos 為 true 也不能寫入照片
        let originalID = "BL-2604-018"
        let original = LedgerOrder.sampleOrders.first { $0.id == originalID }!
        
        var draft = OrderEditFeature.State(
            original: original, id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.photoLoadPhase = .loading
        draft.hasEditedPhotos = true
        draft.draftPhotos = [Data([0xBB])]
        draft.draft.customerName = "載入中卻已標記編輯過"
        
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.editOrder = draft
        
        let box = WriteIntentBox()
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0[OrderRepository.self].saveOrder = { box.savedOrders.append($0) }
            $0[OrderRepository.self].saveOrderPersistingPhotos = {
                box.photoPersistedOrders.append($0)
            }
        }
        
        let expected = Self.expectedWriteResult(draft, existingOrders: state.orders)
        
        await store.send(.editOrder(.presented(.saveTapped)))
        await store.receive(\.orderSavePersisted) { state in
            Self.applyExpectedWriteResult(expected, to: &state)
        }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        
        #expect(box.savedOrders.count == 1, "hasEditedPhotos 為真但尚未 .loaded 時仍須走不帶照片的 saveOrder")
        #expect(
            box.photoPersistedOrders.isEmpty,
            "尚未 .loaded 時不可誤用 saveOrderPersistingPhotos，即使 hasEditedPhotos 已為真")
    }
    
    @Test func saveNormalizesCategoryAndCampaignArrays() async {
        // 儲存時逐元素 trim、去除空字串與重複 (保序)
        var draft = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.draft.customerName = "新客戶"
        draft.draft.categories = [" 美妝 ", "美妝", "", "服飾", "   "]
        draft.draft.campaignNames = ["四月韓國團", " 四月韓國團 ", ""]
        
        var state = OrdersFeature.State()
        state.editOrder = draft
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        
        let expected = Self.expectedWriteResult(draft, existingOrders: state.orders)
        
        await store.send(.editOrder(.presented(.saveTapped)))
        await store.receive(\.orderSavePersisted) { state in
            Self.applyExpectedWriteResult(expected, to: &state)
        }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        
        let inserted = store.state.orders.first
        #expect(inserted?.categories == ["美妝", "服飾"])
        #expect(inserted?.campaignNames == ["四月韓國團"])
        #expect(inserted?.mergedSourceIDs.isEmpty == true)
    }
    
    // MARK: - Merge Entry
    
    @Test func mergeOrderTappedOpensCandidateSheet() async {
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        let primaryID = "BL-2604-018"
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .incrementing
        }
        
        let expectedOrderMerge = withDependencies {
            $0.uuid = .incrementing
        } operation: {
            OrderMergeFeature.State(
                primary: LedgerOrder.sampleOrders.first { $0.id == primaryID }!,
                orders: state.orders)
        }
        
        await store.send(.mergeOrderTapped(primaryID)) {
            $0.orderMerge = expectedOrderMerge
        }
        
        // 主訂單為林書宇的 KRW 訂單，候選需同客戶與幣別且未合併或取消。
        #expect(store.state.orderMerge?.primary.id == primaryID)
        #expect(store.state.orderMerge?.candidates.map(\.id) == ["BL-2604-012"])
    }
    
    @Test func mergeOrderTappedRejectsMergedAndCancelledPrimary() async {
        var state = OrdersFeature.State()
        state.orders = [
            makeOrder(id: "M1", category: "美妝", status: .merged),
            makeOrder(id: "C1", category: "美妝", status: .cancelled),
        ]
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        
        await store.send(.mergeOrderTapped("M1"))
        #expect(store.state.orderMerge == nil)
        
        await store.send(.mergeOrderTapped("C1"))
        #expect(store.state.orderMerge == nil)
    }
    
    @Test func mergeCompletionOpensPrefilledDraft() async {
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        let primaryID = "BL-2604-018"
        let secondaryID = "BL-2604-012"
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .incrementing
            // 使用真實 clock，讓延遲效果可被測試
            $0.continuousClock = ContinuousClock()
        }
        
        // `.candidateTapped` 先產生子層 delegate，再由 `continuousClock.sleep` 延遲送出
        // 並行效果完成順序不固定，因此保留所有關閉路徑。
        store.exhaustivity = .off
        
        await store.send(.mergeOrderTapped(primaryID))
        await store.send(.orderMerge(.presented(.candidateTapped(secondaryID))))
        // 依序收到：子 feature 的完成 delegate → 延遲一拍後的確認表單開啟
        await store.receive(\.orderMerge.presented.delegate)
        await store.receive(\.mergeConfirmationReady, timeout: .seconds(3))
        
        // 合併 sheet 收合、確認表單以合併草稿預填 (全部欄位可編輯)
        #expect(store.state.orderMerge == nil)
        
        let edit = store.state.editOrder
        #expect(edit?.mergeSourceIDs == [primaryID, secondaryID])
        // 客戶實付加總：11,800 + 5,680
        #expect(edit?.draft.chargedAmount == 17_480)
        // 類別聯集：美妝 (主) + 服飾 (副)
        #expect(edit?.draft.categories == ["美妝", "服飾"])
        // 訂購日期為合併當下
        #expect(edit?.draft.date == TestDependencies.fixedNow)
        #expect(edit?.isMergeContext == true)
    }
    
    @Test func mergeDraftSaveCommitsNewOrderAndMarksSourcesMerged() async {
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        let primaryID = "BL-2604-018"
        let secondaryID = "BL-2604-012"
        
        // 預塞合併確認草稿 (帶 mergeSourceIDs)，直接驗證 saveTapped 的合併寫回路徑
        var draft = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.draft.customerName = "林書宇"
        draft.draft.categories = ["美妝", "服飾"]
        draft.draft.chargedAmount = 17_480
        draft.mergeSourceIDs = [primaryID, secondaryID]
        state.editOrder = draft
        
        let originalCount = state.orders.count
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        
        let expected = Self.expectedWriteResult(draft, existingOrders: state.orders)
        var expectedOrders = state.orders
        expectedOrders.insert(expected.order, at: 0)
        expectedOrders = expectedOrders.map { order in
            draft.mergeSourceIDs.contains(order.id) && order.id != expected.order.id
                ? order.withStatus(.merged)
                : order
        }
        
        await store.send(.editOrder(.presented(.saveTapped))) {
            $0.orders = expectedOrders
            $0.selectedOrderID = expected.order.id
        }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        await store.finish()
        
        // 新訂單插入且記錄來源 id；兩筆來源訂單轉「已合併」
        #expect(store.state.orders.count == originalCount + 1)
        
        let inserted = store.state.orders.first
        #expect(inserted?.mergedSourceIDs == [primaryID, secondaryID])
        #expect(inserted?.categories == ["美妝", "服飾"])
        // 合併草稿沿用主訂單客戶的 initials 與 tier
        #expect(inserted?.customer.initials == "SY")
        #expect(inserted?.customer.tier == .vip)
        
        #expect(store.state.orders.first { $0.id == primaryID }?.status == .merged)
        #expect(store.state.orders.first { $0.id == secondaryID }?.status == .merged)
    }
    
    /// 合併確認會以保留的照片建立新訂單
    @Test func mergeWritesKeptPhotosExplicitly() async {
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        let primaryID = "BL-2604-018"
        let secondaryID = "BL-2604-012"
        let keptPhotos = [Data([0x21]), Data([0x22]), Data([0x23])]
        
        // 預先放入合併流程保留的照片。
        var draft = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.draft.customerName = "林書宇"
        draft.draft.categories = ["美妝", "服飾"]
        draft.draft.chargedAmount = 17_480
        draft.mergeSourceIDs = [primaryID, secondaryID]
        draft.draftPhotos = keptPhotos
        state.editOrder = draft
        
        let mergedOrdersBox = WriteIntentBox()
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0[OrderRepository.self].mergeOrders = { newOrder, _ in
                mergedOrdersBox.createdOrders.append(newOrder)
            }
        }
        
        let expected = Self.expectedWriteResult(draft, existingOrders: state.orders)
        var expectedOrders = state.orders
        expectedOrders.insert(expected.order, at: 0)
        expectedOrders = expectedOrders.map { order in
            draft.mergeSourceIDs.contains(order.id) && order.id != expected.order.id
                ? order.withStatus(.merged)
                : order
        }
        
        await store.send(.editOrder(.presented(.saveTapped))) {
            $0.orders = expectedOrders
            $0.selectedOrderID = expected.order.id
        }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        await store.finish()
        
        #expect(mergedOrdersBox.createdOrders.count == 1, "合併必須經由 mergeOrders 寫入新訂單")
        #expect(mergedOrdersBox.createdOrders.first?.photos == keptPhotos, "傳入的照片必須等於使用者勾選保留的集合")
    }
    
    @Test func mergeDraftCancelLeavesOrdersUntouched() async {
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        
        // 合併草稿預填了欄位，因此取消時應顯示未儲存變更提示
        var draft = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.mergeSourceIDs = ["BL-2604-018", "BL-2604-012"]
        draft.draft.customerName = "林書宇"
        state.editOrder = draft
        
        let snapshot = state.orders
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        
        await store.send(.editOrder(.presented(.cancelTapped))) {
            $0.editOrder?.discardConfirmation = AlertState {
                TextState("捨棄變更")
            } actions: {
                ButtonState(role: .destructive, action: .discard) {
                    TextState("捨棄變更")
                }
                ButtonState(role: .cancel) {
                    TextState("繼續編輯")
                }
            } message: {
                TextState("這張訂單有尚未儲存的變更，離開後將不會保留。")
            }
        }
        await store.finish()
        
        // 取消不留任何變更：筆數與每筆內容皆不變
        #expect(store.state.orders == snapshot)
    }
    
    // MARK: - Category Filter
    
    @Test func categoryFilterShowsMatchingCategoryOnly() async {
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        guard let firstSample = LedgerOrder.sampleOrders.first else {
            Issue.record("測試樣本不得為空")
            return
        }
        let targetCategory = firstSample.categories.first ?? ""
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        
        let expectedFirstID =
            state
            .filteredOrders(
                referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar
            )
            .first { ($0.categories.first ?? "") == targetCategory }?
            .id
        
        await store.send(.categoryFilterSelected(targetCategory)) {
            $0.selectedCategory = targetCategory
            $0.selectedOrderID = expectedFirstID
        }
        
        let filtered = store.state.filteredOrders(
            referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar)
        #expect(!filtered.isEmpty)
        #expect(filtered.allSatisfy { ($0.categories.first ?? "") == targetCategory })
        
        await store.send(.categoryFilterSelected(nil)) {
            $0.selectedCategory = nil
            $0.selectedOrderID =
                state.filteredOrders(
                    referenceDate: TestDependencies.fixedNow,
                    calendar: TestDependencies.fixedCalendar
                ).first?.id
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
            $0.calendar = TestDependencies.fixedCalendar
        }
        
        await store.send(.statusFilterSelected(.shipping)) {
            $0.selectedStatus = .shipping
            $0.selectedOrderID = "O1"
        }
        await store.send(.categoryFilterSelected("beauty")) {
            $0.selectedCategory = "beauty"
            $0.selectedOrderID = "O1"
        }
        
        let filtered = store.state.filteredOrders(
            referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar)
        #expect(filtered.map(\.id) == ["O1"])
    }
    
    // MARK: - Payment Method Filter
    
    @Test func paymentMethodFilterShowsMatchingPaymentMethodOnly() async {
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        guard let firstSample = LedgerOrder.sampleOrders.first else {
            Issue.record("測試樣本不得為空")
            return
        }
        let targetPaymentMethod = firstSample.paymentMethod
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        
        let expectedFirstID =
            state
            .filteredOrders(
                referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar
            )
            .first { $0.paymentMethod == targetPaymentMethod }?
            .id
        
        await store.send(.paymentMethodFilterSelected(targetPaymentMethod)) {
            $0.selectedPaymentMethod = targetPaymentMethod
            $0.selectedOrderID = expectedFirstID
        }
        
        let filtered = store.state.filteredOrders(
            referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar)
        #expect(!filtered.isEmpty)
        #expect(filtered.allSatisfy { $0.paymentMethod == targetPaymentMethod })
        
        await store.send(.paymentMethodFilterSelected(nil)) {
            $0.selectedPaymentMethod = nil
            $0.selectedOrderID =
                state.filteredOrders(
                    referenceDate: TestDependencies.fixedNow,
                    calendar: TestDependencies.fixedCalendar
                ).first?.id
        }
    }
    
    @Test func paymentMethodFilterCombinesWithCategoryFilter() async {
        var state = OrdersFeature.State()
        state.orders = [
            makeOrder(id: "P1", category: "beauty", paymentMethod: "信用卡"),
            makeOrder(id: "P2", category: "beauty", paymentMethod: "現金"),
            makeOrder(id: "P3", category: "snacks", paymentMethod: "信用卡"),
        ]
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        
        await store.send(.categoryFilterSelected("beauty")) {
            $0.selectedCategory = "beauty"
            $0.selectedOrderID = "P1"
        }
        await store.send(.paymentMethodFilterSelected("信用卡")) {
            $0.selectedPaymentMethod = "信用卡"
            $0.selectedOrderID = "P1"
        }
        
        let filtered = store.state.filteredOrders(
            referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar)
        #expect(filtered.map(\.id) == ["P1"])
    }
    
    // MARK: - AI Summary Entry
    
    @Test func aiSummaryTappedWithSettingEnabledPresentsSheet() async {
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
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
                prompt: state.aiSummaryPrompt(
                    referenceDate: TestDependencies.fixedNow,
                    calendar: TestDependencies.fixedCalendar),
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
            $0.calendar = TestDependencies.fixedCalendar
            $0[SettingsStorage.self] = SettingsStorage(
                load: { .default },
                save: { _ in }
            )
        }
        
        await store.send(.aiSummaryTapped) {
            $0.aiDisabledAlert = AlertState {
                TextState("AI 商品明細總結")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("關閉")
                }
                ButtonState(action: .goToAISettings) {
                    TextState("前往開啟")
                }
            } message: {
                TextState("此功能需要先在「更多 → 設定」開啟 AI 商品明細總結。")
            }
        }
        
        #expect(store.state.aiDisabledAlert != nil)
        #expect(store.state.aiSummary == nil)
    }
    
    // MARK: - Multi-Value Filter (contains)
    
    @Test func categoryFilterMatchesAnyAssignedCategory() async {
        // 多類別訂單：類別陣列「包含」所選類別即命中
        var state = OrdersFeature.State()
        state.orders = [
            makeOrder(id: "O1", categories: ["beauty"], status: .purchased),
            makeOrder(id: "O2", categories: ["beauty", "snacks"], status: .quoting),
            makeOrder(id: "O3", categories: ["snacks"], status: .purchased),
            makeOrder(id: "O4", categories: ["beauty", "snacks"], status: .purchased),
        ]
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        
        // 類別與狀態篩選應同時套用
        await store.send(.statusFilterSelected(.status(.purchased))) {
            $0.selectedStatus = .status(.purchased)
            $0.selectedOrderID = "O1"
        }
        await store.send(.categoryFilterSelected("beauty")) {
            $0.selectedCategory = "beauty"
            $0.selectedOrderID = "O1"
        }
        
        let filtered = store.state.filteredOrders(
            referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar)
        #expect(filtered.map(\.id) == ["O1", "O4"])
    }
    
    @Test func specificCampaignFilterMatchesAnyAssignedCampaign() async {
        // 任一所屬開團符合條件時，訂單應命中
        var state = OrdersFeature.State()
        state.orders = [
            makeOrder(id: "O1", categories: ["x"], campaignNames: ["May-JP"]),
            makeOrder(id: "O2", categories: ["x"], campaignNames: ["May-JP", "June-KR"]),
            makeOrder(id: "O3", categories: ["x"], campaignNames: ["June-KR"]),
            makeOrder(id: "O4", categories: ["x"], campaignNames: []),
        ]
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        
        await store.send(.campaignFilterSelected("May-JP")) {
            $0.selectedCampaign = "May-JP"
            $0.selectedOrderID = "O1"
        }
        
        let filtered = store.state.filteredOrders(
            referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar)
        #expect(filtered.map(\.id) == ["O1", "O2"])
    }
    
    @Test func campaignStatusFilterMatchesWhenAnyAssignedCampaignHasStatus() async {
        // 任一所屬開團符合狀態時，訂單應被篩選命中
        var state = OrdersFeature.State()
        state.campaigns = [
            Campaign(
                id: "C-ONGOING",
                name: "May-JP",
                openDate: TestDependencies.fixedNow,
                closeDate: TestDependencies.fixedNow,
                status: .ongoing,
                settledDate: nil,
                notes: ""
            ),
            Campaign(
                id: "C-CLOSED",
                name: "April-KR",
                openDate: TestDependencies.fixedNow,
                closeDate: TestDependencies.fixedNow,
                status: .closed,
                settledDate: nil,
                notes: ""
            ),
        ]
        state.orders = [
            makeOrder(id: "O1", categories: ["x"], campaignNames: ["May-JP"]),
            makeOrder(id: "O2", categories: ["x"], campaignNames: ["April-KR"]),
            makeOrder(id: "O3", categories: ["x"], campaignNames: ["April-KR", "May-JP"]),
            makeOrder(id: "O4", categories: ["x"], campaignNames: []),
        ]
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        
        await store.send(.campaignStatusFilterSelected(.ongoing)) {
            $0.selectedCampaignStatus = .ongoing
            $0.selectedOrderID = "O1"
        }
        var filtered = store.state.filteredOrders(
            referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar)
        #expect(filtered.map(\.id) == ["O1", "O3"])
        
        await store.send(.campaignStatusFilterSelected(.closed)) {
            $0.selectedCampaignStatus = .closed
            $0.selectedOrderID = "O2"
        }
        filtered = store.state.filteredOrders(
            referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar)
        #expect(filtered.map(\.id) == ["O2", "O3"])
    }
    
    // MARK: - Batch Status Tests
    
    @Test func selectionModeToggleEntersSelectsAndClearsOnExit() async {
        // 寫入失敗時，訂單狀態與重新載入結果都不變
        let orders = [makeOrder(id: "O1", categories: ["beauty"], status: .shipping)]
        var state = OrdersFeature.State()
        state.orders = orders
        let store = TestStore(initialState: state) {
            OrdersFeature()
        }
        
        await store.send(.selectionModeToggled) { $0.isSelecting = true }
        await store.send(.orderSelectionToggled("O1")) { $0.selectedOrderIDs = ["O1"] }
        await store.send(.orderSelectionToggled("O1")) { $0.selectedOrderIDs = [] }
        await store.send(.orderSelectionToggled("O1")) { $0.selectedOrderIDs = ["O1"] }
        await store.send(.selectionModeToggled) {
            $0.isSelecting = false
            $0.selectedOrderIDs = []
        }
    }
    
    @Test func selectAllSelectsFilteredThenClear() async {
        // 寫入失敗時，訂單狀態與重新載入結果都不變
        let orders = [
            makeOrder(id: "O1", categories: ["beauty"], status: .shipping),
            makeOrder(id: "O2", categories: ["snacks"], status: .quoting),
        ]
        var state = OrdersFeature.State()
        state.orders = orders
        state.isSelecting = true
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        
        await store.send(.selectAllTapped) { $0.selectedOrderIDs = ["O1", "O2"] }
        await store.send(.clearSelectionTapped) { $0.selectedOrderIDs = [] }
    }
    
    @Test func batchStatusChangedAppliesToSelectedSkipsAlreadyTargetAndExits() async {
        // 寫入失敗時，訂單狀態與重新載入結果都不變
        // 只重建狀態不同的 O1、O3，O2 維持原狀
        let orders = [
            makeOrder(id: "O1", categories: ["beauty"], status: .shipping),
            makeOrder(id: "O2", categories: ["beauty"], status: .arrived),
            makeOrder(id: "O3", categories: ["snacks"], status: .shipping),
        ]
        var state = OrdersFeature.State()
        state.orders = orders
        state.isSelecting = true
        state.selectedOrderIDs = ["O1", "O2", "O3"]
        
        let box = BatchBox()
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0[OrderRepository.self].saveOrders = { box.saved = $0 }
        }
        
        await store.send(.batchStatusChanged(.arrived)) {
            $0.isSelecting = false
            $0.selectedOrderIDs = []
        }
        await store.receive(\.batchStatusChangePersisted) { state in
            state.orders = state.orders.map { order in
                ["O1", "O3"].contains(order.id) ? order.withStatus(.arrived) : order
            }
        }
        
        #expect(store.state.orders.first { $0.id == "O1" }?.status == .arrived)
        #expect(store.state.orders.first { $0.id == "O2" }?.status == .arrived)
        #expect(store.state.orders.first { $0.id == "O3" }?.status == .arrived)
        #expect(store.state.isSelecting == false)
        #expect(store.state.selectedOrderIDs.isEmpty)
        // 只落盤實際變更的 O1/O3 (O2 已是 arrived 被略過)，且為單次批次呼叫
        #expect(Set((box.saved ?? []).map(\.id)) == ["O1", "O3"])
    }
    
    @Test func batchStatusChangedRejectsMerged() async {
        // 寫入失敗時，訂單狀態與重新載入結果都不變
        let orders = [makeOrder(id: "O1", categories: ["beauty"], status: .shipping)]
        var state = OrdersFeature.State()
        state.orders = orders
        state.isSelecting = true
        state.selectedOrderIDs = ["O1"]
        let store = TestStore(initialState: state) {
            OrdersFeature()
        }
        
        await store.send(.batchStatusChanged(.merged))
        await store.finish()
    }
    
    @Test func revertingMergeSourceStatusPersistsSuccessfully() async {
        let source = makeOrder(id: "source", categories: ["beauty"], status: .merged)
        var state = OrdersFeature.State()
        state.orders = [source]
        let box = WriteIntentBox()
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0[OrderRepository.self].saveOrder = { box.savedOrders.append($0) }
        }
        
        await store.send(.statusChanged("source", .confirmed))
        await store.receive(\.statusChangePersisted) {
            $0.orders[0] = source.withStatus(.confirmed)
        }
        
        #expect(box.savedOrders == [source.withStatus(.confirmed)])
        await store.finish()
    }
    
    // MARK: - Write-Then-Update Failure Handling
    
    @Test func writeFailureAlertLeavesNoResidueAndDoesNotShadowLaterSuccess() async {
        // 寫入失敗時，訂單狀態與重新載入結果都不變
        // 關閉錯誤提示後，下一次成功寫入不應再顯示錯誤
        // 保持完整窮舉，逐一驗證每個 action 的 state 變更
        let original = makeOrder(id: "O1", categories: ["beauty"], status: .shipping)
        var state = OrdersFeature.State()
        state.orders = [original]
        
        let toggle = ToggleableFailureBox()
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0[OrderRepository.self].saveOrder = {
                (_: LedgerOrder) async throws(PersistenceError) in
                if toggle.shouldFail {
                    throw .saveFailed(message: "boom")
                }
            }
        }
        
        await store.send(.statusChanged("O1", .arrived))
        await store.receive(\.orderWriteFailed) {
            $0.writeFailureAlert = expectedWriteFailureAlert("訂單狀態更新失敗，請稍後再試。")
        }
        
        #expect(store.state.orders == [original], "失敗時畫面狀態應維持不變")
        #expect(store.state.errorMessage == nil, "一次性操作失敗不得殘留於列表標頭的錯誤文字欄位")
        
        await store.send(.writeFailureAlert(.dismiss)) {
            $0.writeFailureAlert = nil
        }
        
        toggle.shouldFail = false
        await store.send(.statusChanged("O1", .arrived))
        await store.receive(\.statusChangePersisted) {
            $0.orders[0] = original.withStatus(.arrived)
        }
        
        #expect(store.state.writeFailureAlert == nil, "後續成功不應被先前失敗的對話框殘留遮蔽")
        await store.finish()
    }
    
    @Test func statusChangeFailurePreservesPresentedOrderAcrossReload() async {
        // 寫入失敗時，訂單狀態與重新載入結果都不變
        // 直接送出 ordersLoaded 模擬重載，避免平行主檔載入造成不確定性
        let original = makeOrder(id: "O1", categories: ["beauty"], status: .shipping)
        var state = OrdersFeature.State()
        state.orders = [original]
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0[OrderRepository.self].saveOrder = {
                (_: LedgerOrder) async throws(PersistenceError) in
                throw .saveFailed(message: "boom")
            }
        }
        
        await store.send(.statusChanged("O1", .arrived))
        await store.receive(\.orderWriteFailed) {
            $0.writeFailureAlert = expectedWriteFailureAlert("訂單狀態更新失敗，請稍後再試。")
        }
        
        #expect(store.state.orders == [original], "寫入失敗時畫面狀態應與操作前完全相同")
        
        await store.send(.ordersLoaded([original])) {
            $0.isLoading = false
            $0.hasLoaded = true
            $0.orders = [original]
            $0.selectedOrderID = original.id
        }
        
        #expect(store.state.orders == [original], "冷啟動前後畫面呈現的訂單集合應一致")
    }
    
    @Test func receiptStatusChangeFailurePreservesPresentedOrderAcrossReload() async {
        // 寫入失敗時，訂單狀態與重新載入結果都不變
        let original = makeOrder(id: "O1", categories: ["beauty"])
        var state = OrdersFeature.State()
        state.orders = [original]
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0[OrderRepository.self].saveOrder = {
                (_: LedgerOrder) async throws(PersistenceError) in
                throw .saveFailed(message: "boom")
            }
        }
        
        await store.send(.receiptStatusChanged("O1", .received))
        await store.receive(\.orderWriteFailed) {
            $0.writeFailureAlert = expectedWriteFailureAlert("收款狀態更新失敗，請稍後再試。")
        }
        
        #expect(store.state.orders == [original], "寫入失敗時畫面狀態應與操作前完全相同")
        
        await store.send(.ordersLoaded([original])) {
            $0.isLoading = false
            $0.hasLoaded = true
            $0.orders = [original]
            $0.selectedOrderID = original.id
        }
        
        #expect(store.state.orders == [original], "冷啟動前後畫面呈現的訂單集合應一致")
    }
    
    @Test func batchStatusChangeFailureLeavesAllSelectedOrdersUnchangedAcrossReload() async {
        // 寫入失敗時，訂單狀態與重新載入結果都不變
        let orders = [
            makeOrder(id: "O1", categories: ["beauty"], status: .shipping),
            makeOrder(id: "O2", categories: ["beauty"], status: .shipping),
            makeOrder(id: "O3", categories: ["beauty"], status: .shipping),
            makeOrder(id: "O4", categories: ["beauty"], status: .shipping),
        ]
        var state = OrdersFeature.State()
        state.orders = orders
        state.isSelecting = true
        state.selectedOrderIDs = Set(orders.map(\.id))
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0[OrderRepository.self].saveOrders = {
                (_: [LedgerOrder]) async throws(PersistenceError) in
                throw .saveFailed(message: "boom")
            }
        }
        
        // 多選狀態的退出與寫入結果無關。
        await store.send(.batchStatusChanged(.arrived)) {
            $0.isSelecting = false
            $0.selectedOrderIDs = []
        }
        await store.receive(\.orderWriteFailed) {
            $0.writeFailureAlert = expectedWriteFailureAlert("批次更新狀態失敗，請稍後再試。")
        }
        
        #expect(store.state.orders == orders, "批次寫入失敗時，所有被選取訂單的狀態皆應與操作前相同")
        
        await store.send(.ordersLoaded(orders)) {
            $0.isLoading = false
            $0.hasLoaded = true
            $0.orders = orders
            $0.selectedOrderID = orders.first?.id
        }
        
        #expect(store.state.orders == orders, "冷啟動前後畫面呈現的訂單集合應一致")
    }
    
    @Test func deletionFailurePreservesPresentedOrderAcrossReload() async {
        // 寫入失敗時，訂單狀態與重新載入結果都不變
        let original = makeOrder(id: "O1", categories: ["beauty"])
        var state = OrdersFeature.State()
        state.orders = [original]
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0[OrderRepository.self].removeOrder = {
                (_: LedgerOrder.ID) async throws(PersistenceError) in
                throw .saveFailed(message: "boom")
            }
            // 由真正的 `.task` 重載讀回，確認儲存層沒有留下半套資料。
            $0[OrderRepository.self].fetchOrders = { [original] }
            // 本測試只驗訂單重載，主檔載入另行失敗。
            // 避免其完成順序不可預測地混入斷言
            $0[OrderSourceRepository.self].fetchOrderSources = {
                () async throws(PersistenceError) -> [String] in
                throw PersistenceError.fetchFailed(message: "suppressed")
            }
            $0[CampaignRepository.self].fetchCampaigns = {
                () async throws(PersistenceError) -> [Campaign] in
                throw PersistenceError.fetchFailed(message: "suppressed")
            }
            $0[CategoryRepository.self].fetchCategories = {
                () async throws(PersistenceError) -> [String] in
                throw PersistenceError.fetchFailed(message: "suppressed")
            }
            $0[PaymentMethodRepository.self].fetchPaymentMethodInfos = {
                () async throws(PersistenceError) -> [PaymentMethodInfo] in
                throw PersistenceError.fetchFailed(message: "suppressed")
            }
            $0[ReconciliationStatusRepository.self].fetchReconciliationStatuses = {
                () async throws(PersistenceError) -> [String] in
                throw PersistenceError.fetchFailed(message: "suppressed")
            }
        }
        
        await store.send(.deleteOrderTapped("O1")) {
            $0.deletionConfirmation = AlertState {
                TextState("刪除訂單")
            } actions: {
                ButtonState(role: .destructive, action: .confirmDelete("O1")) {
                    TextState("刪除")
                }
                ButtonState(role: .cancel) {
                    TextState("取消")
                }
            } message: {
                TextState("刪除「\(original.customer.name)」的這筆訂單後無法復原。")
            }
        }
        
        // 選擇 alert 按鈕會由 TCA 隱含關閉該次呈現 (同 aiDisabledAlert 的既有慣例)
        await store.send(.deletionConfirmation(.presented(.confirmDelete("O1")))) {
            $0.deletionConfirmation = nil
        }
        await store.receive(\.orderWriteFailed) {
            $0.writeFailureAlert = expectedWriteFailureAlert("訂單刪除失敗，請稍後再試。")
        }
        
        #expect(store.state.orders == [original], "刪除失敗時項目應維持可見")
        
        // 冷啟動實際觸發 `.task` 重載，而非直接送出 `ordersLoaded`。
        // 才能證明失敗的寫入沒有在 DB 留下半套資料
        await store.send(.task) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        await store.receive(\.ordersLoaded) {
            $0.isLoading = false
            $0.hasLoaded = true
            $0.orders = [original]
            $0.selectedOrderID = original.id
        }
        
        #expect(store.state.orders == [original], "冷啟動前後畫面呈現的訂單集合應一致")
    }
    
    @Test func editSaveFailurePreservesPresentedOrderAcrossReload() async {
        // 寫入失敗時，訂單狀態與重新載入結果都不變
        let originalID = "BL-2604-018"
        let original = LedgerOrder.sampleOrders.first { $0.id == originalID }!
        
        var draft = OrderEditFeature.State(
            original: original, id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.draft.customerName = "改名嘗試"
        
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.editOrder = draft
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0[OrderRepository.self].saveOrder = {
                (_: LedgerOrder) async throws(PersistenceError) in
                throw .saveFailed(message: "boom")
            }
        }
        
        await store.send(.editOrder(.presented(.saveTapped)))
        await store.receive(\.orderWriteFailed) {
            $0.writeFailureAlert = expectedWriteFailureAlert("訂單儲存失敗，請稍後再試。")
        }
        // `OrderEditFeature.saveTapped` 一律觸發 `dismiss()`，與寫入結果無關。
        // 故仍會收到子層的關閉表單事件；窮舉檢查下需明確承接
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        
        #expect(store.state.orders.first { $0.id == originalID } == original, "編輯儲存失敗時訂單應維持原本內容")
        
        await store.send(.ordersLoaded(LedgerOrder.sampleOrders)) {
            $0.isLoading = false
            $0.hasLoaded = true
            $0.orders = LedgerOrder.sampleOrders
            $0.selectedOrderID = LedgerOrder.sampleOrders.first?.id
        }
        
        #expect(store.state.orders == LedgerOrder.sampleOrders, "冷啟動前後畫面呈現的訂單集合應一致")
        await store.finish()
    }
    
    // MARK: - Cardless Deduction Cap
    
    @Test func saveClampsExcessiveCardlessDeductionToChargedAmount() async {
        // 折抵上限為實付金額，避免 revenue 變成負數
        let original = makeOrder(
            id: "O-CAP-1", categories: ["測試"], status: .shipping, paymentMethod: "信用卡")
        
        var draft = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            availablePaymentMethods: [
                PaymentMethodInfo(
                    name: "無卡存款", isCardless: true, isBankTransfer: false, isCashOnDelivery: false)
            ],
            currentDate: TestDependencies.fixedNow
        )
        draft.draft.paymentMethod = "無卡存款"
        draft.draft.chargedAmount = 1_000
        draft.draft.cardlessDeductionAmount = 50_000  // 遠大於實付金額
        
        var state = OrdersFeature.State()
        state.orders = [original]
        state.editOrder = draft
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        }
        
        await store.send(.editOrder(.presented(.saveTapped)))
        await store.receive(\.orderSavePersisted) {
            $0.orders[0] = original.withCardlessAmounts(
                chargedAmount: 1_000,
                cardlessDeductionAmount: 1_000,  // 收斂為 chargedAmount，而非使用者輸入的 50_000
                paymentMethod: "無卡存款"
            )
        }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        
        let saved = store.state.orders[0]
        #expect(saved.cardlessDeductionAmount == 1_000)
        #expect(OrderSummary(order: saved).revenue == 0)
        await store.finish()
    }
    
    @Test func existingOverCapDeductionIsCorrectedOnNextSave() async {
        // 既有超額資料在開啟表單時收斂，儲存後保留上限。
        let legacyOverCap = makeOrder(
            id: "O-CAP-2", categories: ["測試"], status: .shipping, paymentMethod: "無卡存款"
        )
        .withCardlessAmounts(
            chargedAmount: 1_000, cardlessDeductionAmount: 1_500, paymentMethod: "無卡存款")
        
        let draft = OrderEditFeature.State(
            original: legacyOverCap,
            id: UUID(0),
            availablePaymentMethods: [
                PaymentMethodInfo(
                    name: "無卡存款", isCardless: true, isBankTransfer: false, isCashOnDelivery: false)
            ],
            currentDate: TestDependencies.fixedNow
        )
        // 表單載入時已在使用者眼前收斂，草稿值不再是規則生效前的 1_500
        #expect(draft.draft.cardlessDeductionAmount == 1_000)
        
        var state = OrdersFeature.State()
        state.orders = [legacyOverCap]
        state.editOrder = draft
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        }
        
        await store.send(.editOrder(.presented(.saveTapped)))
        await store.receive(\.orderSavePersisted) {
            $0.orders[0] = legacyOverCap.withCardlessAmounts(
                chargedAmount: 1_000,
                cardlessDeductionAmount: 1_000,
                paymentMethod: "無卡存款"
            )
        }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        
        #expect(store.state.orders[0].cardlessDeductionAmount == 1_000)
        await store.finish()
    }
    
    @Test func manualPaymentMethodEditAndRetroactiveCorrectionProduceIdenticalOrderFields() async throws(any Error) {
        let original = LedgerOrder(
            id: "O-PARITY",
            customer: LedgerCustomer(name: "對照測試", initials: "PT", tier: .regular),
            status: .delivered,
            currency: .twd,
            date: TestDependencies.fixedNow,
            items: [LedgerOrderItem(name: "測試商品", quantity: 1, unitPrice: 5_000)],
            itemCost: 3_000,
            domesticShipping: 125,
            internationalShipping: 275,
            foreignDomesticShipping: 425,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 5_000,
            cardlessDeductionAmount: 750,
            cardlessSupplementAmount: 250,
            orderSource: "來源",
            categories: ["測試"],
            paymentMethod: "舊付款",
            notes: "備註",
            reconciliationStatus: " 待對帳 ",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
        let newPaymentMethod = PaymentMethodInfo(
            name: "新付款",
            isCardless: false,
            isBankTransfer: true,
            isCashOnDelivery: true
        )
        var draft = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            availablePaymentMethods: [newPaymentMethod],
            currentDate: TestDependencies.fixedNow
        )
        draft.draft.paymentMethod = newPaymentMethod.name
        draft.draft.reconciliationStatus = original.reconciliationStatus
        
        let retroactive =
            original
            .renamingPaymentMethod(to: newPaymentMethod.name)
            .applyingPaymentMethodFlags(
                isCardless: newPaymentMethod.isCardless,
                isBankTransfer: newPaymentMethod.isBankTransfer,
                isCashOnDelivery: newPaymentMethod.isCashOnDelivery
            )
        var state = OrdersFeature.State()
        state.orders = [original]
        state.editOrder = draft
        let box = WriteIntentBox()
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0[OrderRepository.self].saveOrder = { box.savedOrders.append($0) }
        }
        
        await store.send(.editOrder(.presented(.saveTapped)))
        await store.receive(\.orderSavePersisted) {
            $0.orders = [retroactive]
        }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        
        let manual = try #require(box.savedOrders.first)
        
        #expect(manual == retroactive)
        #expect(manual.cardlessDeductionAmount == 0)
        #expect(manual.cardlessSupplementAmount == 0)
        #expect(manual.reconciliationStatus == "待對帳")
        #expect(manual.isCashOnDelivery)
    }
    
    // MARK: - Compact Detail Navigation Stack
    
    @Test func detailPathPushAddsStackElement() async {
        // 推入訂單詳情後，StackState 應新增對應項目
        let orderID = "BL-2604-018"
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        }
        
        await store.send(.detailPath(.push(id: 0, state: OrderDetailPath.State(orderID: orderID)))) {
            $0.detailPath = StackState([OrderDetailPath.State(orderID: orderID)])
        }
        
        #expect(store.state.detailPath.count == 1)
        #expect(store.state.detailPath[id: 0]?.orderID == orderID)
    }
    
    @Test func detailPathPrunesRemovedOrderAfterDelete() async {
        // 堆疊中的訂單詳情被刪除後，對應的 detailPath 元素也應移除。
        // 等價於原本 View 端 onChange(of: store.orders) 的收斂邏輯 (現已收進 reducer)
        let originalID = "BL-2604-018"
        let original = LedgerOrder.sampleOrders.first { $0.id == originalID }!
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.detailPath = StackState([OrderDetailPath.State(orderID: originalID)])
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        }
        
        await store.send(.deleteOrderTapped(originalID)) {
            $0.deletionConfirmation = AlertState {
                TextState("刪除訂單")
            } actions: {
                ButtonState(role: .destructive, action: .confirmDelete(originalID)) {
                    TextState("刪除")
                }
                ButtonState(role: .cancel) {
                    TextState("取消")
                }
            } message: {
                TextState("刪除「\(original.customer.name)」的這筆訂單後無法復原。")
            }
        }
        #expect(store.state.deletionConfirmation != nil)
        
        await store.send(.deletionConfirmation(.presented(.confirmDelete(originalID)))) {
            $0.deletionConfirmation = nil
        }
        await store.receive(\.orderDeleted) {
            $0.orders.removeAll { $0.id == originalID }
            $0.detailPath = StackState()
        }
        
        #expect(store.state.detailPath.isEmpty)
    }
    
    // MARK: - Filter Sheet Binding
    
    @Test func bindingTogglesShowsFilterSheet() async {
        let store = TestStore(initialState: OrdersFeature.State()) {
            OrdersFeature()
        }
        
        await store.send(\.binding.showsFilterSheet, true) {
            $0.showsFilterSheet = true
        }
    }
    
    @Test func bindingTogglesRegularPickerSheets() async {
        // iPad regular 的類別／付款方式篩選 picker 開關已下放 State，走 binding 管理
        let store = TestStore(initialState: OrdersFeature.State()) {
            OrdersFeature()
        }
        
        await store.send(\.binding.showsCategoryPicker, true) {
            $0.showsCategoryPicker = true
        }
        
        await store.send(\.binding.showsPaymentMethodPicker, true) {
            $0.showsPaymentMethodPicker = true
        }
    }
    
    // MARK: - Filter Sheet Unapplied Flow
    
    @Test func filterSheetTappedSeedsPendingFilterFromCommittedValues() async {
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.selectedDatePeriod = .thisMonth
        state.selectedCategory = "beauty"
        state.selectedPaymentMethod = nil
        // 開啟時重設為已套用篩選，並清空搜尋文字。
        state.pendingFilterSelection = OrdersFeature.State.PendingFilterSelection(
            datePeriod: .all,
            category: "stale",
            paymentMethod: "stale"
        )
        state.filterSheetSearchText = "leftover"
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        
        await store.send(.filterSheetTapped) {
            $0.pendingFilterSelection = OrdersFeature.State.PendingFilterSelection(
                datePeriod: .thisMonth,
                category: "beauty",
                paymentMethod: nil
            )
            $0.filterSheetSearchText = ""
            $0.showsFilterSheet = true
        }
    }
    
    @Test func pendingSelectionsDoNotTouchCommittedFilters() async {
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.selectedDatePeriod = .all
        state.selectedCategory = nil
        state.selectedPaymentMethod = nil
        state.showsFilterSheet = true
        state.pendingFilterSelection = state.committedFilterSelection
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        
        await store.send(.filterPendingDatePeriodSelected(.thisMonth)) {
            $0.pendingFilterSelection.datePeriod = .thisMonth
        }
        await store.send(.filterPendingCategorySelected("beauty")) {
            $0.pendingFilterSelection.category = "beauty"
        }
        await store.send(.filterPendingPaymentMethodSelected("信用卡")) {
            $0.pendingFilterSelection.paymentMethod = "信用卡"
        }
        
        #expect(store.state.hasUnappliedFilterChanges)
        #expect(store.state.selectedDatePeriod == .all)
        #expect(store.state.selectedCategory == nil)
        #expect(store.state.selectedPaymentMethod == nil)
    }
    
    @Test func filterSheetSearchTextFiltersCategoriesAndPaymentMethods() async {
        let state = OrdersFeature.State()
        state.$lookupCatalog.withLock {
            $0.categories = ["beauty", "snacks", "books"]
            $0.paymentMethods = [
                PaymentMethodInfo(
                    name: "轉帳", isCardless: false, isBankTransfer: true, isCashOnDelivery: false),
                PaymentMethodInfo(
                    name: "貨到付款", isCardless: false, isBankTransfer: false, isCashOnDelivery: true),
            ]
        }
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        }
        
        await store.send(\.binding.filterSheetSearchText, "boo") {
            $0.filterSheetSearchText = "boo"
        }
        #expect(store.state.filterSheetFilteredCategories == ["books"])
        #expect(store.state.filterSheetFilteredPaymentMethods.isEmpty)
        
        // 中綴文字也應命中，不能只比對開頭
        await store.send(\.binding.filterSheetSearchText, "ook") {
            $0.filterSheetSearchText = "ook"
        }
        #expect(store.state.filterSheetFilteredCategories == ["books"])
        
        // 比對不分大小寫，"BOO" 應命中 "books"。
        await store.send(\.binding.filterSheetSearchText, "BOO") {
            $0.filterSheetSearchText = "BOO"
        }
        #expect(store.state.filterSheetFilteredCategories == ["books"])
        
        await store.send(\.binding.filterSheetSearchText, "轉帳") {
            $0.filterSheetSearchText = "轉帳"
        }
        #expect(store.state.filterSheetFilteredCategories.isEmpty)
        #expect(store.state.filterSheetFilteredPaymentMethods == ["轉帳"])
    }
    
    @Test func filterApplyCommitsChangedPendingValuesAndClosesSheet() async {
        var state = OrdersFeature.State()
        // 只有 N2 符合新篩選，期望值直接寫死，不重用被測邏輯。
        // 避免期望值與實作共用同一份邏輯 (實作算錯時期望值也會跟著算錯)
        state.orders = [
            makeOrder(id: "N1", category: "electronics"),
            makeOrder(id: "N2", category: "beauty"),
            makeOrder(id: "N3", category: "electronics"),
        ]
        state.selectedDatePeriod = .all
        state.selectedCategory = nil
        state.selectedPaymentMethod = nil
        state.selectedOrderID = "N1"
        state.showsFilterSheet = true
        state.pendingFilterSelection = OrdersFeature.State.PendingFilterSelection(
            datePeriod: .all,
            category: "beauty",
            paymentMethod: nil
        )
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        
        await store.send(.filterApplyTapped) {
            $0.selectedCategory = "beauty"
            $0.selectedOrderID = "N2"
            $0.showsFilterSheet = false
        }
    }
    
    @Test func filterApplyWithNoPendingChangesClosesSheetAndChangesNothing() async {
        var state = OrdersFeature.State()
        // 兩筆都命中篩選；選取 N2 用來確認不會重算。
        state.orders = [
            makeOrder(id: "N1", category: "beauty"),
            makeOrder(id: "N2", category: "beauty"),
        ]
        state.selectedDatePeriod = .all
        state.selectedCategory = "beauty"
        state.selectedPaymentMethod = nil
        state.selectedOrderID = "N2"
        state.showsFilterSheet = true
        state.pendingFilterSelection = state.committedFilterSelection
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        
        await store.send(.filterApplyTapped) {
            $0.showsFilterSheet = false
        }
    }
    
    @Test func filterCancelWithPendingChangesPresentsDiscardConfirmation() async {
        var state = OrdersFeature.State()
        state.selectedDatePeriod = .all
        state.selectedCategory = nil
        state.selectedPaymentMethod = nil
        state.showsFilterSheet = true
        state.pendingFilterSelection = OrdersFeature.State.PendingFilterSelection(
            datePeriod: .thisMonth,
            category: nil,
            paymentMethod: nil
        )
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        }
        
        await store.send(.filterCancelTapped) {
            $0.filterDiscardConfirmation = AlertState {
                TextState("捨棄變更")
            } actions: {
                ButtonState(role: .destructive, action: .discard) {
                    TextState("捨棄變更")
                }
                ButtonState(role: .cancel) {
                    TextState("繼續編輯")
                }
            } message: {
                TextState("這些篩選條件尚未套用，離開後將不會保留。")
            }
        }
        #expect(store.state.showsFilterSheet)
    }
    
    @Test func filterDiscardConfirmedRevertsPendingFilterAndClosesSheet() async {
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.selectedDatePeriod = .all
        state.selectedCategory = nil
        state.selectedPaymentMethod = nil
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        
        // 開啟、修改、取消並確認捨棄後，已套用篩選不變。
        await store.send(.filterSheetTapped) {
            $0.pendingFilterSelection = OrdersFeature.State.PendingFilterSelection(
                datePeriod: .all, category: nil, paymentMethod: nil)
            $0.filterSheetSearchText = ""
            $0.showsFilterSheet = true
        }
        
        await store.send(.filterPendingDatePeriodSelected(.thisMonth)) {
            $0.pendingFilterSelection.datePeriod = .thisMonth
        }
        await store.send(.filterPendingCategorySelected("beauty")) {
            $0.pendingFilterSelection.category = "beauty"
        }
        await store.send(.filterPendingPaymentMethodSelected("信用卡")) {
            $0.pendingFilterSelection.paymentMethod = "信用卡"
        }
        
        await store.send(.filterCancelTapped) {
            $0.filterDiscardConfirmation = AlertState {
                TextState("捨棄變更")
            } actions: {
                ButtonState(role: .destructive, action: .discard) {
                    TextState("捨棄變更")
                }
                ButtonState(role: .cancel) {
                    TextState("繼續編輯")
                }
            } message: {
                TextState("這些篩選條件尚未套用，離開後將不會保留。")
            }
        }
        
        // 捨棄後清除未套用篩選並關閉 sheet
        await store.send(.filterDiscardConfirmation(.presented(.discard))) {
            $0.filterDiscardConfirmation = nil
            $0.pendingFilterSelection = OrdersFeature.State.PendingFilterSelection(
                datePeriod: .all, category: nil, paymentMethod: nil)
            $0.showsFilterSheet = false
        }
        
        #expect(store.state.selectedDatePeriod == .all)
        #expect(store.state.selectedCategory == nil)
        #expect(store.state.selectedPaymentMethod == nil)
    }
    
    @Test func filterCancelWithoutPendingChangesClosesSheetDirectly() async {
        var state = OrdersFeature.State()
        state.selectedDatePeriod = .thisMonth
        state.selectedCategory = "beauty"
        state.selectedPaymentMethod = nil
        state.showsFilterSheet = true
        state.pendingFilterSelection = state.committedFilterSelection
        
        let store = TestStore(initialState: state) {
            OrdersFeature()
        }
        
        await store.send(.filterCancelTapped) {
            $0.showsFilterSheet = false
        }
    }
}

// MARK: - Private Method

private extension OrdersFeatureTests {
    
    /// 重建預期寫入結果，供完整 state 比對
    /// - Parameters:
    ///   - draft: 訂單編輯草稿
    ///   - existingOrders: 目前已存在的訂單
    ///   - uuid: 新訂單使用的識別值
    /// - Returns: 預期寫入的訂單與是否為新訂單
    static func expectedWriteResult(
        _ draft: OrderEditFeature.State,
        existingOrders: [LedgerOrder],
        uuid: UUID = UUID(0)
    ) -> (order: LedgerOrder, isNewOrder: Bool) {
        let trimmedName = draft.draft.customerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedOrderSource = draft.draft.orderSource.trimmingCharacters(
            in: .whitespacesAndNewlines)
        let normalizedCategories = normalizedNames(draft.draft.categories)
        let trimmedPaymentMethod = draft.draft.paymentMethod.trimmingCharacters(
            in: .whitespacesAndNewlines)
        let trimmedNotes = draft.draft.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedCampaignNames = normalizedNames(draft.draft.campaignNames)
        let normalizedAmount = max(0, draft.draft.chargedAmount)
        let normalizedItemCost = max(0, draft.draft.itemCost)
        let normalizedDomesticShipping = max(0, draft.draft.domesticShipping)
        let normalizedInternationalShipping = max(0, draft.draft.internationalShipping)
        let normalizedForeignDomesticShipping = max(0, draft.draft.foreignDomesticShipping)
        let normalizedCardFeeRate = clampRate(draft.draft.cardFeeRate)
        let normalizedPlatformFeeRate = clampRate(draft.draft.platformFeeRate)
        let normalizedPaymentFeeRate = clampRate(draft.draft.paymentFeeRate)
        // 付款旗標只在適用的付款方式下保留，其他值清零
        let normalizedDeductionAmount =
            draft.isSelectedPaymentMethodCardless
            ? min(normalizedAmount, max(0, draft.draft.cardlessDeductionAmount))
            : 0
        let normalizedSupplementAmount =
            draft.isSelectedPaymentMethodCardless
            ? max(0, draft.draft.cardlessSupplementAmount)
            : 0
        let normalizedReconciliationStatus =
            (draft.isSelectedPaymentMethodCardless || draft.isSelectedPaymentMethodBankTransfer)
            ? draft.draft.reconciliationStatus.trimmingCharacters(in: .whitespacesAndNewlines)
            : ""
        
        if let original = draft.original,
            let existing = existingOrders.first(where: { $0.id == original.id }) {
            let updatedCustomer = LedgerCustomer(
                name: trimmedName.isEmpty ? existing.customer.name : trimmedName,
                initials: existing.customer.initials,
                tier: existing.customer.tier
            )
            let updatedOrder = LedgerOrder(
                id: existing.id,
                customer: updatedCustomer,
                status: draft.draft.status,
                currency: draft.draft.currency,
                date: draft.draft.date,
                items: draft.draft.items,
                itemCost: normalizedItemCost,
                domesticShipping: normalizedDomesticShipping,
                internationalShipping: normalizedInternationalShipping,
                foreignDomesticShipping: normalizedForeignDomesticShipping,
                cardFeeRate: normalizedCardFeeRate,
                platformFeeRate: normalizedPlatformFeeRate,
                paymentFeeRate: normalizedPaymentFeeRate,
                chargedAmount: normalizedAmount,
                cardlessDeductionAmount: normalizedDeductionAmount,
                cardlessSupplementAmount: normalizedSupplementAmount,
                orderSource: trimmedOrderSource.isEmpty ? existing.orderSource : trimmedOrderSource,
                categories: normalizedCategories.isEmpty
                    ? existing.categories : normalizedCategories,
                paymentMethod: trimmedPaymentMethod.isEmpty
                    ? existing.paymentMethod : trimmedPaymentMethod,
                notes: trimmedNotes,
                reconciliationStatus: normalizedReconciliationStatus,
                campaignNames: normalizedCampaignNames,
                paymentReceiptStatus: draft.draft.paymentReceiptStatus,
                isCashOnDelivery: draft.isSelectedPaymentMethodCOD,
                // 只有載入完成且編輯過照片才寫回，避免覆蓋原照片
                photos: (draft.photoLoadPhase == .loaded && draft.hasEditedPhotos)
                    ? draft.draftPhotos : [],
                mergedSourceIDs: existing.mergedSourceIDs
            )
            return (updatedOrder, false)
        }
        
        let resolvedName = trimmedName.isEmpty ? "未命名客戶" : trimmedName
        let resolvedOrderSource = trimmedOrderSource.isEmpty ? "未指定" : trimmedOrderSource
        let resolvedCategories = normalizedCategories.isEmpty ? ["未分類"] : normalizedCategories
        let initials = String(resolvedName.prefix(2)).uppercased()
        let mergePrimaryCustomer = draft.mergeSourceIDs.first
            .flatMap { primaryID in existingOrders.first { $0.id == primaryID }?.customer }
        let resolvedCustomer =
            mergePrimaryCustomer.map {
                LedgerCustomer(name: resolvedName, initials: $0.initials, tier: $0.tier)
            } ?? LedgerCustomer(name: resolvedName, initials: initials, tier: .new)
        let newOrder = LedgerOrder(
            id: "BL-DRAFT-\(uuid.uuidString)",
            customer: resolvedCustomer,
            status: draft.draft.status,
            currency: draft.draft.currency,
            date: draft.draft.date,
            items: draft.draft.items,
            itemCost: normalizedItemCost,
            domesticShipping: normalizedDomesticShipping,
            internationalShipping: normalizedInternationalShipping,
            foreignDomesticShipping: normalizedForeignDomesticShipping,
            cardFeeRate: normalizedCardFeeRate,
            platformFeeRate: normalizedPlatformFeeRate,
            paymentFeeRate: normalizedPaymentFeeRate,
            chargedAmount: normalizedAmount,
            cardlessDeductionAmount: normalizedDeductionAmount,
            cardlessSupplementAmount: normalizedSupplementAmount,
            orderSource: resolvedOrderSource,
            categories: resolvedCategories,
            paymentMethod: trimmedPaymentMethod,
            notes: trimmedNotes,
            reconciliationStatus: normalizedReconciliationStatus,
            campaignNames: normalizedCampaignNames,
            paymentReceiptStatus: draft.draft.paymentReceiptStatus,
            isCashOnDelivery: draft.isSelectedPaymentMethodCOD,
            photos: draft.draftPhotos,
            mergedSourceIDs: draft.mergeSourceIDs
        )
        return (newOrder, true)
    }
    
    /// 將預期的持久化結果套用到 TestStore 狀態
    static func applyExpectedWriteResult(
        _ result: (order: LedgerOrder, isNewOrder: Bool),
        to state: inout OrdersFeature.State
    ) {
        if result.isNewOrder {
            state.orders.insert(result.order, at: 0)
            state.selectedOrderID = result.order.id
        } else if let index = state.orders.firstIndex(where: { $0.id == result.order.id }) {
            state.orders[index] = result.order
        }
    }
    
    /// 正規化類別／開團名稱，保留首次出現順序
    /// - Parameter names: 要正規化的名稱清單
    /// - Returns: 去除空白與重複後的名稱清單
    static func normalizedNames(_ names: [String]) -> [String] {
        var seen = Set<String>()
        return
            names
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && seen.insert($0).inserted }
    }
    
    /// 將費率限制在產品規則使用的 `[0, 1]` 範圍
    /// - Parameter value: 要限制的費率
    /// - Returns: 限制在 0 至 1 之間的費率
    static func clampRate(_ value: Decimal) -> Decimal {
        max(0, min(1, value))
    }
    
    /// 建立寫入失敗 alert，供測試比對
    /// - Parameter message: alert 顯示的錯誤訊息
    /// - Returns: 寫入失敗時顯示的 alert
    func expectedWriteFailureAlert(_ message: LocalizedStringKey) -> AlertState<
        OrdersFeature.Action.Alert
    > {
        AlertState {
            TextState("操作失敗")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("知道了")
            }
        } message: {
            TextState(message)
        }
    }
    
    /// 建立僅供篩選測試使用的最小訂單；非相關欄位以零值/佔位填入
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - category: 商品類別
    ///   - status: 訂單狀態
    ///   - paymentMethod: 付款方式
    /// - Returns: 建立的測試訂單
    func makeOrder(
        id: String,
        category: String,
        status: OrderStatus = .quoting,
        paymentMethod: String = "付款"
    ) -> LedgerOrder {
        makeOrder(id: id, categories: [category], status: status, paymentMethod: paymentMethod)
    }
    
    /// 多類別/多開團版本的最小訂單 helper
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - categories: 商品類別
    ///   - status: 訂單狀態
    ///   - paymentMethod: 付款方式
    ///   - campaignNames: 開團名稱
    /// - Returns: 建立的測試訂單
    func makeOrder(
        id: String,
        categories: [String],
        status: OrderStatus = .quoting,
        paymentMethod: String = "付款",
        campaignNames: [String] = []
    ) -> LedgerOrder {
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
            categories: categories,
            paymentMethod: paymentMethod,
            notes: "",
            reconciliationStatus: "",
            campaignNames: campaignNames,
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }
}

/// 捕捉批次落盤訂單的呼叫
private final class BatchBox: @unchecked Sendable {
    
    // MARK: - Data Properties
    
    /// 由 `saveOrders` closure 寫入、測試讀取的批次訂單
    var saved: [LedgerOrder]?
}

/// 捕捉建立、更新與帶照片寫入收到的訂單
private final class WriteIntentBox: @unchecked Sendable {
    
    // MARK: - Data Properties
    
    /// 經 `createOrder` (建立意圖) 寫入的訂單
    var createdOrders: [LedgerOrder] = []
    
    /// 經 `saveOrder` (更新意圖、不帶照片) 寫入的訂單
    var savedOrders: [LedgerOrder] = []
    
    /// 經 `saveOrderPersistingPhotos` (更新意圖、顯式帶照片) 寫入的訂單
    var photoPersistedOrders: [LedgerOrder] = []
}

/// 可切換成功或失敗的落盤替身
private final class ToggleableFailureBox: @unchecked Sendable {
    
    // MARK: - Data Properties
    
    /// 是否讓落盤呼叫失敗；預設為 `true`
    var shouldFail = true
}

// MARK: - Private Method

/// 供窮舉測試建構「落盤成功後預期呈現」的訂單複本
private extension LedgerOrder {
    
    /// 回傳僅變更狀態的複本
    /// - Parameter newStatus: 要套用的訂單狀態
    /// - Returns: 套用新狀態後的訂單
    func withStatus(_ newStatus: OrderStatus) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: customer,
            status: newStatus,
            currency: currency,
            date: date,
            items: items,
            itemCost: itemCost,
            domesticShipping: domesticShipping,
            internationalShipping: internationalShipping,
            foreignDomesticShipping: foreignDomesticShipping,
            cardFeeRate: cardFeeRate,
            platformFeeRate: platformFeeRate,
            paymentFeeRate: paymentFeeRate,
            chargedAmount: chargedAmount,
            cardlessDeductionAmount: cardlessDeductionAmount,
            cardlessSupplementAmount: cardlessSupplementAmount,
            orderSource: orderSource,
            categories: categories,
            paymentMethod: paymentMethod,
            notes: notes,
            reconciliationStatus: reconciliationStatus,
            campaignNames: campaignNames,
            paymentReceiptStatus: paymentReceiptStatus,
            isCashOnDelivery: isCashOnDelivery,
            photos: photos,
            mergedSourceIDs: mergedSourceIDs
        )
    }
    
    /// 建立折抵上限測試所需的訂單複本
    /// - Parameters:
    ///   - chargedAmount: 客戶實付金額
    ///   - cardlessDeductionAmount: 無卡折抵金額
    ///   - paymentMethod: 付款方式
    /// - Returns: 套用新無卡金額後的訂單
    func withCardlessAmounts(
        chargedAmount: Decimal,
        cardlessDeductionAmount: Decimal,
        paymentMethod: String
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: customer,
            status: status,
            currency: currency,
            date: date,
            items: items,
            itemCost: itemCost,
            domesticShipping: domesticShipping,
            internationalShipping: internationalShipping,
            foreignDomesticShipping: foreignDomesticShipping,
            cardFeeRate: cardFeeRate,
            platformFeeRate: platformFeeRate,
            paymentFeeRate: paymentFeeRate,
            chargedAmount: chargedAmount,
            cardlessDeductionAmount: cardlessDeductionAmount,
            cardlessSupplementAmount: cardlessSupplementAmount,
            orderSource: orderSource,
            categories: categories,
            paymentMethod: paymentMethod,
            notes: notes,
            reconciliationStatus: reconciliationStatus,
            campaignNames: campaignNames,
            paymentReceiptStatus: paymentReceiptStatus,
            isCashOnDelivery: isCashOnDelivery,
            photos: photos,
            mergedSourceIDs: mergedSourceIDs
        )
    }
}
