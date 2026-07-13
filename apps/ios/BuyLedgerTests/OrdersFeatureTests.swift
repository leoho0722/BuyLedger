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
        // 主檔載入由其他測試覆蓋，這裡關掉 exhaustivity 避免重複斷言所有平行 effect
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
            $0.calendar = TestDependencies.fixedCalendar
        }

        await store.send(.searchTextChanged("mika")) {
            $0.searchText = "mika"
            $0.selectedOrderID = "BL-2604-017"
        }

        // 樣本中 "Mika 周" 有兩筆訂單 (BL-2604-017 與合併樣本 BL-2604-011)，依日期由新到舊排序
        #expect(store.state.filteredOrders(referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar).map(\.id) == ["BL-2604-017", "BL-2604-011"])

        await store.send(.searchTextChanged("Aesop")) {
            $0.searchText = "Aesop"
            $0.selectedOrderID = "BL-2604-016"
        }

        #expect(store.state.filteredOrders(referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar).map(\.id) == ["BL-2604-016"])
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

        let filtered = store.state.filteredOrders(referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar)
        #expect(filtered.allSatisfy { $0.status == .shipping })
        // 樣本中集運中的訂單有兩筆 (BL-2604-018 與合併樣本 BL-2604-011)
        #expect(filtered.map(\.id) == ["BL-2604-018", "BL-2604-011"])
    }

    @Test func editFlowPersistsCustomerNameAfterSave() async {
        // 直接以草稿狀態預塞 `editOrder` 來測試 `applyEditDraft` 的寫回邏輯，
        // 因為使用 `BindingAction.set` 會踩到 Swift 6 對 `WritableKeyPath` 的 `Sendable` 限制
        // 此路徑跳過 `@Presents` 啟動 lifecycle，所以 `await dismiss()` 不會清掉 `state.editOrder`，
        // 因此本測試只驗證 orders 寫回，不驗證 sheet dismiss
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
        // 驗證備註欄位經 save 後寫回 orders，且首尾空白會被 trim
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

    @Test func editFlowPersistsPhotosAfterSave() async {
        // 驗證照片草稿經 save 後寫回 orders (更新分支)
        let originalID = "BL-2604-018"
        let original = LedgerOrder.sampleOrders.first { $0.id == originalID }!
        let photos = [Data([0x01]), Data([0x02])]

        var draft = OrderEditFeature.State(original: original)
        draft.draftPhotos = photos

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
        #expect(updated?.photos == photos)
    }

    @Test func editFlowPersistsPhotosForNewOrder() async {
        // 驗證新增訂單分支 (original == nil) 也會把照片草稿寫進新訂單
        let photos = [Data([0xA1])]

        var draft = OrderEditFeature.State()
        draft.draftCustomerName = "新照片客戶"
        draft.draftPhotos = photos

        var state = OrdersFeature.State()
        state.editOrder = draft

        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.uuid = .incrementing
        }
        store.exhaustivity = .off

        await store.send(.editOrder(.presented(.saveTapped)))
        await store.finish()

        let created = store.state.orders.first { $0.customer.name == "新照片客戶" }
        #expect(created?.photos == photos)
    }

    @Test func editFlowKeepsVerificationStatusForBankTransfer() async {
        // 付款方式屬於銀行匯款 → 對帳狀態有意義，save 後應保留
        let originalID = "BL-2604-018"
        let original = LedgerOrder.sampleOrders.first { $0.id == originalID }!

        var draft = OrderEditFeature.State(
            original: original,
            availablePaymentMethods: [
                PaymentMethodInfo(name: "銀行匯款", isCardless: false, isBankTransfer: true, isCashOnDelivery: false),
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
        // 付款方式非無卡／非銀行匯款 (信用卡) → 對帳狀態無意義，save 後應清成空字串，避免殘留
        let originalID = "BL-2604-018"
        let original = LedgerOrder.sampleOrders.first { $0.id == originalID }!

        // 原訂單付款方式為「信用卡」(預設無旗標)；殘留一個對帳狀態草稿
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
        // 同上：以預塞 state 驗證 cancel 不會觸發 `applyEditDraft`，因此不檢查 `editOrder == nil`
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
        }
        store.exhaustivity = .off

        let originalID = "BL-2604-018"
        let original = LedgerOrder.sampleOrders.first { $0.id == originalID }!

        await store.send(.editOrderTapped(originalID))

        let editState = store.state.editOrder
        #expect(editState?.original?.id == originalID)
        #expect(editState?.draftCustomerName == original.customer.name)
        #expect(editState?.draftCategories == original.categories)
    }

    @Test func newOrderTappedSetsEmptyEditState() async {
        let store = TestStore(initialState: OrdersFeature.State()) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        store.exhaustivity = .off

        await store.send(.newOrderTapped)

        let editState = store.state.editOrder
        #expect(editState?.original == nil)
        #expect(editState?.draftCustomerName.isEmpty == true)
        #expect(editState?.draftCategories.isEmpty == true)
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
        // 新訂單 `date` 落在測試實際執行的當下，與下方斷言期待的 fixedDate 不符
        var draft = OrderEditFeature.State(currentDate: fixedDate)
        draft.draftCustomerName = "新客戶"
        draft.draftCategories = ["美妝"]

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
        #expect(inserted?.categories == ["美妝"])
        #expect(inserted?.status == .quoting)
        #expect(inserted?.currency == .twd)
        #expect(inserted?.date == fixedDate)
    }

    @Test func saveNormalizesCategoryAndCampaignArrays() async {
        // 儲存時逐元素 trim、去除空字串與重複 (保序)
        var draft = OrderEditFeature.State(currentDate: TestDependencies.fixedNow)
        draft.draftCustomerName = "新客戶"
        draft.draftCategories = [" 美妝 ", "美妝", "", "服飾", "   "]
        draft.draftCampaignNames = ["四月韓國團", " 四月韓國團 ", ""]

        var state = OrdersFeature.State()
        state.editOrder = draft

        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        store.exhaustivity = .off

        await store.send(.editOrder(.presented(.saveTapped)))
        await store.finish()

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
        }
        store.exhaustivity = .off

        await store.send(.mergeOrderTapped(primaryID))

        // 主訂單為林書宇 (KRW)：候選僅同幣別、同客戶且非已合併/已取消的 BL-2604-012
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
        store.exhaustivity = .off

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
            // 測試 target 未連結 swift-clocks 的 ImmediateClock，改注入真實 clock；延遲僅 0.5 秒，配合下方 finish timeout
            $0.continuousClock = ContinuousClock()
        }
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
        #expect(edit?.draftChargedAmount == 17_480)
        // 類別聯集：美妝 (主) + 服飾 (副)
        #expect(edit?.draftCategories == ["美妝", "服飾"])
        // 訂購日期為合併當下
        #expect(edit?.draftDate == TestDependencies.fixedNow)
        #expect(edit?.isMergeContext == true)
    }

    @Test func mergeDraftSaveCommitsNewOrderAndMarksSourcesMerged() async {
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        let primaryID = "BL-2604-018"
        let secondaryID = "BL-2604-012"

        // 預塞合併確認草稿 (帶 mergeSourceIDs)，直接驗證 saveTapped 的合併寫回路徑
        var draft = OrderEditFeature.State(currentDate: TestDependencies.fixedNow)
        draft.draftCustomerName = "林書宇"
        draft.draftCategories = ["美妝", "服飾"]
        draft.draftChargedAmount = 17_480
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
        store.exhaustivity = .off

        await store.send(.editOrder(.presented(.saveTapped)))
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

    @Test func mergeDraftCancelLeavesOrdersUntouched() async {
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders

        var draft = OrderEditFeature.State(currentDate: TestDependencies.fixedNow)
        draft.mergeSourceIDs = ["BL-2604-018", "BL-2604-012"]
        state.editOrder = draft

        let snapshot = state.orders

        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        store.exhaustivity = .off

        await store.send(.editOrder(.presented(.cancelTapped)))
        await store.finish()

        // 取消不留任何變更：筆數與每筆內容皆不變
        #expect(store.state.orders == snapshot)
    }

    // MARK: - Category Filter

    @Test func categoryFilterShowsMatchingCategoryOnly() async {
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        let targetCategory = LedgerOrder.sampleOrders.first!.categories.first ?? ""

        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        let expectedFirstID = state
            .filteredOrders(referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar)
            .first { ($0.categories.first ?? "") == targetCategory }?
            .id

        await store.send(.categoryFilterSelected(targetCategory)) {
            $0.selectedCategory = targetCategory
            $0.selectedOrderID = expectedFirstID
        }

        let filtered = store.state.filteredOrders(referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar)
        #expect(!filtered.isEmpty)
        #expect(filtered.allSatisfy { ($0.categories.first ?? "") == targetCategory })

        await store.send(.categoryFilterSelected(nil)) {
            $0.selectedCategory = nil
            $0.selectedOrderID = state.filteredOrders(referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar).first?.id
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

        let filtered = store.state.filteredOrders(referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar)
        #expect(filtered.map(\.id) == ["O1"])
    }

    // MARK: - Payment Method Filter

    @Test func paymentMethodFilterShowsMatchingPaymentMethodOnly() async {
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        let targetPaymentMethod = LedgerOrder.sampleOrders.first!.paymentMethod

        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        let expectedFirstID = state
            .filteredOrders(referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar)
            .first { $0.paymentMethod == targetPaymentMethod }?
            .id

        await store.send(.paymentMethodFilterSelected(targetPaymentMethod)) {
            $0.selectedPaymentMethod = targetPaymentMethod
            $0.selectedOrderID = expectedFirstID
        }

        let filtered = store.state.filteredOrders(referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar)
        #expect(!filtered.isEmpty)
        #expect(filtered.allSatisfy { $0.paymentMethod == targetPaymentMethod })

        await store.send(.paymentMethodFilterSelected(nil)) {
            $0.selectedPaymentMethod = nil
            $0.selectedOrderID = state.filteredOrders(referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar).first?.id
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

        let filtered = store.state.filteredOrders(referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar)
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
                prompt: state.aiSummaryPrompt(referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar),
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
        store.exhaustivity = .off

        await store.send(.aiSummaryTapped)

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
        store.exhaustivity = .off

        // 類別 beauty + 狀態已下單：spec 例「conjunction of filters with multi-category orders」
        await store.send(.statusFilterSelected(.status(.purchased)))
        await store.send(.categoryFilterSelected("beauty"))

        let filtered = store.state.filteredOrders(referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar)
        #expect(filtered.map(\.id) == ["O1", "O4"])
    }

    @Test func specificCampaignFilterMatchesAnyAssignedCampaign() async {
        // spec 例「specific-campaign filter with multi-campaign orders」
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
        store.exhaustivity = .off

        await store.send(.campaignFilterSelected("May-JP"))

        let filtered = store.state.filteredOrders(referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar)
        #expect(filtered.map(\.id) == ["O1", "O2"])
    }

    @Test func campaignStatusFilterMatchesWhenAnyAssignedCampaignHasStatus() async {
        // spec 例「campaign-status filter with multi-campaign orders」：跨團 (一進行中、一已收單) 的訂單兩種篩選都命中
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
        store.exhaustivity = .off

        await store.send(.campaignStatusFilterSelected(.ongoing))
        var filtered = store.state.filteredOrders(referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar)
        #expect(filtered.map(\.id) == ["O1", "O3"])

        await store.send(.campaignStatusFilterSelected(.closed))
        filtered = store.state.filteredOrders(referenceDate: TestDependencies.fixedNow, calendar: TestDependencies.fixedCalendar)
        #expect(filtered.map(\.id) == ["O2", "O3"])
    }

    // MARK: - Batch Status Tests

    @Test func selectionModeToggleEntersSelectsAndClearsOnExit() async {
        // 對齊 spec「Orders list provides a multi-select mode」：進出多選、勾選切換、退出清空
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
        // 對齊 spec「Orders list provides a multi-select mode」：全選目前篩選後清單、清除
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
        // 對齊 spec「Batch apply a single target status to selected orders」：
        // O1/O3 為 shipping、O2 已是目標 arrived；批次套用 arrived 只重建並落盤 O1/O3，O2 略過，最後退出多選
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
        store.exhaustivity = .off

        await store.send(.batchStatusChanged(.arrived))
        await store.finish()

        #expect(store.state.orders.first { $0.id == "O1" }?.status == .arrived)
        #expect(store.state.orders.first { $0.id == "O2" }?.status == .arrived)
        #expect(store.state.orders.first { $0.id == "O3" }?.status == .arrived)
        #expect(store.state.isSelecting == false)
        #expect(store.state.selectedOrderIDs.isEmpty)
        // 只落盤實際變更的 O1/O3 (O2 已是 arrived 被略過)，且為單次批次呼叫
        #expect(Set((box.saved ?? []).map(\.id)) == ["O1", "O3"])
    }

    @Test func batchStatusChangedRejectsMerged() async {
        // 對齊 spec「Batch target status list excludes merged」：merged 僅由合併流程寫入，批次防衛拒絕、不改狀態
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

    // MARK: - Compact Detail Navigation Stack

    @Test func detailPathPushAddsStackElement() async {
        // 對齊 design「訂單 compact 導覽改用 OrdersFeature 的 StackState」：push 一筆訂單詳情後，堆疊應有對應元素
        let orderID = "BL-2604-018"
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders

        let store = TestStore(initialState: state) {
            OrdersFeature()
        }
        store.exhaustivity = .off

        await store.send(.detailPath(.push(id: 0, state: OrderDetailPath.State(orderID: orderID))))

        #expect(store.state.detailPath.count == 1)
        #expect(store.state.detailPath[id: 0]?.orderID == orderID)
    }

    @Test func detailPathPrunesRemovedOrderAfterDelete() async {
        // push 進堆疊的訂單詳情被刪除後，對應 detailPath 元素應同步被移除，
        // 等價於原本 View 端 onChange(of: store.orders) 的收斂邏輯 (現已收進 reducer)
        let originalID = "BL-2604-018"
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.detailPath = StackState([OrderDetailPath.State(orderID: originalID)])

        let store = TestStore(initialState: state) {
            OrdersFeature()
        }
        store.exhaustivity = .off

        await store.send(.deleteOrderTapped(originalID))
        #expect(store.state.deletionConfirmation != nil)

        await store.send(.deletionConfirmation(.presented(.confirmDelete(originalID))))
        await store.finish()

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
}

// MARK: - Private Method

private extension OrdersFeatureTests {

    /// 建立僅供篩選測試使用的最小訂單；非相關欄位以零值/佔位填入
    func makeOrder(
        id: String,
        category: String,
        status: OrderStatus = .quoting,
        paymentMethod: String = "付款"
    ) -> LedgerOrder {
        makeOrder(id: id, categories: [category], status: status, paymentMethod: paymentMethod)
    }

    /// 多類別/多開團版本的最小訂單 helper
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
            verificationStatus: "",
            campaignNames: campaignNames,
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }
}

/// 捕捉批次落盤訂單的容器；避免引入 `ConcurrencyExtras.LockIsolated` 在測試 target 中遭遇連結問題
private final class BatchBox: @unchecked Sendable {

    // MARK: - Data Properties

    /// 由 `saveOrders` closure 寫入、測試讀取的批次訂單
    var saved: [LedgerOrder]?
}
