//
//  OrderEditFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/05/01.
//

import ComposableArchitecture
import Foundation
import PhotosUI
import SwiftUI
import Testing
@testable import BuyLedger

/// 驗證訂單編輯功能
@MainActor
struct OrderEditFeatureTests {

    // MARK: - Tests

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func bindingUpdatesDraftCustomerName() async {
        // Given

        let store = TestStore(
            initialState: OrderEditFeature.State(
                id: UUID(0), currentDate: TestDependencies.fixedNow)
        ) {
            OrderEditFeature()
        }

        // When

        await store.send(.binding(.set(\.draft.customerName, "新客戶"))) {
            // Then

            $0.draft.customerName = "新客戶"
        }
    }

    // MARK: - Campaign Auto-Close Evaluation

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func availableCampaignsLoadedKeepsCloseDateTodayInOngoingList() async {
        // Given

        // 結單日當天仍算 ongoing，驗證以日期判斷而非直接信任 status
        let campaign = Campaign(
            id: "C1",
            name: "今天團",
            openDate: TestDependencies.fixedNow,
            closeDate: TestDependencies.fixedNow,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let store = TestStore(
            initialState: OrderEditFeature.State(
                id: UUID(0), currentDate: TestDependencies.fixedNow)
        ) {
            OrderEditFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When

        await store.send(.availableCampaignsLoaded([campaign])) {
            // Then

            $0.availableCampaigns = [campaign.name]
        }
    }

    // MARK: Dirty State

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func newOrderIsNotDirtyUntilEdited() async {
        // Given

        var state = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        // When

        let initialDirty = state.isDirty
        state.draft.customerName = "小明"
        let editedDirty = state.isDirty

        // Then

        #expect(initialDirty == false)
        #expect(editedDirty == true)
    }

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func existingOrderIsDirtyThenCleanWhenRestored() async {
        // Given

        let original = LedgerOrder.sampleOrders[0]
        var state = OrderEditFeature.State(
            original: original, id: UUID(0), currentDate: TestDependencies.fixedNow)
        // When

        let initialDirty = state.isDirty
        state.draft.chargedAmount += 1
        let editedDirty = state.isDirty
        state.draft.chargedAmount = original.chargedAmount
        let restoredDirty = state.isDirty

        // Then

        #expect(initialDirty == false)
        #expect(editedDirty == true)
        #expect(restoredDirty == false)
    }

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func nonDraftFieldChangeDoesNotMarkDirty() async {
        // Given

        var state = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        // When

        let initialDirty = state.isDirty
        state.pickerRoute = .category
        let routeDirty = state.isDirty

        // Then

        #expect(initialDirty == false)

        // 開啟選擇器 route 屬暫時性 UI 狀態、非草稿內容，不應觸發 dirty
        #expect(routeDirty == false)
    }

    /// 驗證草稿欄位與照片會影響 dirty，呈現狀態不會
    @Test func dirtySanityCoversDraftFieldsPhotosAndExcludesPresentationState() async {
        // Given

        var draftFieldState = OrderEditFeature.State(
            id: UUID(0), currentDate: TestDependencies.fixedNow)
        // When

        let draftInitialDirty = draftFieldState.isDirty
        draftFieldState.draft.notes = "新備註"
        let draftEditedDirty = draftFieldState.isDirty

        var photoEditState = OrderEditFeature.State(
            id: UUID(0), currentDate: TestDependencies.fixedNow)
        let photoInitialDirty = photoEditState.isDirty
        photoEditState.hasEditedPhotos = true
        let photoEditedDirty = photoEditState.isDirty

        var presentationState = OrderEditFeature.State(
            id: UUID(0), currentDate: TestDependencies.fixedNow)
        presentationState.focusedField = .customerName
        presentationState.pickerRoute = .category
        presentationState.photoPickerSelection = [PhotosPickerItem(itemIdentifier: "test-item")]
        let presentationDirty = presentationState.isDirty

        let original = LedgerOrder.sampleOrders[0]
        var loadedExistingOrderState = OrderEditFeature.State(
            original: original, id: UUID(0), currentDate: TestDependencies.fixedNow)
        loadedExistingOrderState.draftPhotos = [Data([0x01]), Data([0x02])]
        loadedExistingOrderState.photoLoadPhase = .loaded
        let loadedExistingOrderDirty = loadedExistingOrderState.isDirty

        // Then

        #expect(draftInitialDirty == false)
        #expect(draftEditedDirty == true)
        #expect(photoInitialDirty == false)
        #expect(photoEditedDirty == true)
        #expect(presentationDirty == false)
        #expect(loadedExistingOrderDirty == false)
    }

    // MARK: Cardless Deduction Cap

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func excessiveCardlessDeductionBindingIsCappedAndExplained() async {
        // Given

        // 超額折抵會立即限制並顯示已修正。
        var seeded = OrderEditFeature.State(
            id: UUID(0),
            availablePaymentMethods: [
                PaymentMethodInfo(
                    name: "無卡存款", isCardless: true, isBankTransfer: false, isCashOnDelivery: false)
            ],
            currentDate: TestDependencies.fixedNow
        )
        seeded.draft.paymentMethod = "無卡存款"
        seeded.draft.chargedAmount = 1_000

        let store = TestStore(initialState: seeded) {
            OrderEditFeature()
        }

        // 輸入超過實付金額的折抵：值收斂為上限，並標記已修正
        // When

        await store.send(.binding(.set(\.draft.cardlessDeductionAmount, 1_500))) {
            // Then

            $0.draft.cardlessDeductionAmount = 1_000
            $0.cardlessDeductionWasCapped = true
        }

        // 再輸入未超額的值：旗標清除、值維持使用者輸入 (輸入值本身不被夾住)
        await store.send(.binding(.set(\.draft.cardlessDeductionAmount, 300))) {
            // Then

            $0.draft.cardlessDeductionAmount = 300
            $0.cardlessDeductionWasCapped = false
        }
    }

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func loadingExistingOverCapOrderCorrectsDeductionAndMarksExplanation() {
        // Given

        // 既有超額資料在開啟表單時收斂。
        let overCapOrder = LedgerOrder(
            id: "BL-OVERCAP-001",
            customer: LedgerCustomer(name: "既有超額折抵", initials: "OC", tier: .regular),
            status: .delivered,
            currency: .twd,
            date: TestDependencies.fixedNow,
            items: [],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 1_000,
            cardlessDeductionAmount: 1_500,
            cardlessSupplementAmount: 0,
            orderSource: "測試來源",
            categories: ["測試"],
            paymentMethod: "無卡存款",
            notes: "",
            reconciliationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )

        let state = OrderEditFeature.State(
            original: overCapOrder,
            id: UUID(0),
            availablePaymentMethods: [
                PaymentMethodInfo(
                    name: "無卡存款", isCardless: true, isBankTransfer: false, isCashOnDelivery: false)
            ],
            currentDate: TestDependencies.fixedNow
        )

        // When

        let deduction = state.draft.cardlessDeductionAmount
        let wasCapped = state.cardlessDeductionWasCapped
        let isDirty = state.isDirty

        // Then

        #expect(deduction == 1_000)
        #expect(wasCapped == true)
        // 修正已反映進初始指紋，未經其他編輯前不會被誤判為「未儲存變更」
        #expect(isDirty == false)
    }

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func cancelWithChangesPresentsDiscardConfirmation() async {
        // Given

        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draft.customerName = "小明"
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.dismiss = DismissEffect {}
        }

        // When

        await store.send(.cancelTapped) {
            $0.discardConfirmation = AlertState {
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
        // Then

        #expect(store.state.discardConfirmation != nil)

        // 捨棄後關閉表單，AlertState 也會自動清空
        await store.send(.discardConfirmation(.presented(.discard))) {
            $0.discardConfirmation = nil
        }
    }

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func cancelWithoutChangesDismissesDirectly() async {
        // Given：未修改的新訂單表單
        let dismissCallCount = LockIsolated(0)
        let store = TestStore(
            initialState: OrderEditFeature.State(
                id: UUID(0), currentDate: TestDependencies.fixedNow)
        ) {
            OrderEditFeature()
        } withDependencies: {
            $0.dismiss = DismissEffect {
                dismissCallCount.withValue { $0 += 1 }
            }
        }

        // When
        await store.send(.cancelTapped)
        await store.finish()

        // Then
        #expect(store.state.discardConfirmation == nil)
        #expect(dismissCallCount.value == 1)
    }

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func bindingUpdatesDraftCategories() async {
        // Given

        let store = TestStore(
            initialState: OrderEditFeature.State(
                id: UUID(0), currentDate: TestDependencies.fixedNow)
        ) {
            OrderEditFeature()
        }

        // When

        await store.send(.binding(.set(\.draft.categories, ["美妝"]))) {
            // Then

            $0.draft.categories = ["美妝"]
        }
    }

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func bindingUpdatesDraftStatus() async {
        // Given

        let store = TestStore(
            initialState: OrderEditFeature.State(
                id: UUID(0), currentDate: TestDependencies.fixedNow)
        ) {
            OrderEditFeature()
        }

        // When

        await store.send(.binding(.set(\.draft.status, .delivered))) {
            // Then

            $0.draft.status = .delivered
        }
    }

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func bindingUpdatesDraftCurrency() async {
        // Given

        let store = TestStore(
            initialState: OrderEditFeature.State(
                id: UUID(0), currentDate: TestDependencies.fixedNow)
        ) {
            OrderEditFeature()
        }

        // When

        await store.send(.binding(.set(\.draft.currency, .jpy))) {
            // Then

            $0.draft.currency = .jpy
        }
    }

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func bindingUpdatesDraftChargedAmount() async {
        // Given

        let store = TestStore(
            initialState: OrderEditFeature.State(
                id: UUID(0), currentDate: TestDependencies.fixedNow)
        ) {
            OrderEditFeature()
        }

        // When

        await store.send(.binding(.set(\.draft.chargedAmount, 12_345))) {
            // Then

            $0.draft.chargedAmount = 12_345
        }
    }

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func bindingUpdatesDraftCostFields() async {
        // Given

        let store = TestStore(
            initialState: OrderEditFeature.State(
                id: UUID(0), currentDate: TestDependencies.fixedNow)
        ) {
            OrderEditFeature()
        }

        // When

        await store.send(.binding(.set(\.draft.itemCost, 5_000))) {
            // Then

            $0.draft.itemCost = 5_000
        }
        await store.send(.binding(.set(\.draft.domesticShipping, 80))) {
            // Then

            $0.draft.domesticShipping = 80
        }
        await store.send(.binding(.set(\.draft.internationalShipping, 320))) {
            // Then

            $0.draft.internationalShipping = 320
        }
        await store.send(.binding(.set(\.draft.cardFeeRate, 0.015))) {
            // Then

            $0.draft.cardFeeRate = 0.015
        }
        await store.send(.binding(.set(\.draft.platformFeeRate, 0.03))) {
            // Then

            $0.draft.platformFeeRate = 0.03
        }
    }

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func draftPrefillsFromOriginal() {
        // Given

        let original = LedgerOrder.sampleOrders[0]
        let state = OrderEditFeature.State(
            original: original, id: UUID(0), currentDate: TestDependencies.fixedNow)

        // When

        let draft = state.draft

        // Then

        #expect(draft.customerName == original.customer.name)
        #expect(draft.categories == original.categories)
        #expect(draft.status == original.status)
        #expect(draft.currency == original.currency)
        #expect(draft.chargedAmount == original.chargedAmount)
        #expect(draft.itemCost == original.itemCost)
        #expect(draft.domesticShipping == original.domesticShipping)
        #expect(draft.internationalShipping == original.internationalShipping)
        #expect(draft.cardFeeRate == original.cardFeeRate)
        #expect(draft.platformFeeRate == original.platformFeeRate)
        #expect(draft.notes == original.notes)
    }

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func photosImportedAppendsUpToCap() async {
        // Given

        // 新訂單 (original 為 nil) 一律直接視為 .loaded，加入控制項從一開始就可用
        let store = TestStore(
            initialState: OrderEditFeature.State(
                id: UUID(0), currentDate: TestDependencies.fixedNow)
        ) {
            OrderEditFeature()
        }

        // 0 + 5 → 5：全數收下；確實增刪過照片，標記 hasEditedPhotos
        let five = (1...5).map { Data([UInt8($0)]) }
        // When

        await store.send(.photosImported(PhotoImportResult(photos: five, failedCount: 0))) {
            $0.draftPhotos = five
            $0.hasEditedPhotos = true
        }

        // 5 + 1 → 5：已滿不再追加 (state 無變化，hasEditedPhotos 已是 true 不再重設)
        await store.send(
            .photosImported(PhotoImportResult(photos: [Data([0x06])], failedCount: 0))
        )
        // Then

        #expect(store.state.draftPhotos == five)
        #expect(store.state.hasEditedPhotos)
    }

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func photosImportedTruncatesBatchExceedingCap() async {
        // Given

        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draftPhotos = [Data([0x01]), Data([0x02]), Data([0x03])]
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // 3 + 4 → 5：依序只收前 2 張，超出上限的捨棄
        let batch = [Data([0x04]), Data([0x05]), Data([0x06]), Data([0x07])]
        // When

        await store.send(.photosImported(PhotoImportResult(photos: batch, failedCount: 0))) {
            $0.draftPhotos = [Data([0x01]), Data([0x02]), Data([0x03]), Data([0x04]), Data([0x05])]
            $0.hasEditedPhotos = true
        }
        // Then

        let expectedPhotos = initial.draftPhotos + Array(batch.prefix(2))
        #expect(store.state.draftPhotos == expectedPhotos)
        #expect(store.state.hasEditedPhotos)
    }

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func pickerSelectionImportsPhotosAndClearsSelection() async {
        // Given

        let imported = [Data([0xAA]), Data([0xBB]), Data([0xCC])]
        let store = TestStore(
            initialState: OrderEditFeature.State(
                id: UUID(0), currentDate: TestDependencies.fixedNow)
        ) {
            OrderEditFeature()
        } withDependencies: {
            $0[PhotoClient.self] = PhotoClient(
                importPhotos: { _ in PhotoImportResult(photos: imported, failedCount: 0) }
            )
        }

        let items = (1...3).map { PhotosPickerItem(itemIdentifier: "test-item-\($0)") }
        // When

        await store.send(\.binding.photoPickerSelection, items) {
            $0.photoPickerSelection = items
        }

        // 匯入完成：照片進草稿、picker 選取清空 (one-shot)、標記已更動
        // Then

        await store.receive(\.photosImported) {
            $0.draftPhotos = imported
            $0.photoPickerSelection = []
            $0.hasEditedPhotos = true
            $0.photoImportFailureCount = 0
        }
    }

    /// 新一批照片匯入前應清除舊失敗張數，並保留本批失敗張數
    @Test func pickerSelectionReportsOneLoadFailure() async {
        // Given

        let imported = [Data([0xAA]), Data([0xBB])]
        var initialState = OrderEditFeature.State(
            id: UUID(0), currentDate: TestDependencies.fixedNow
        )
        initialState.photoImportFailureCount = 2
        let store = TestStore(initialState: initialState) {
            OrderEditFeature()
        } withDependencies: {
            $0[PhotoClient.self] = PhotoClient(
                importPhotos: { _ in PhotoImportResult(photos: imported, failedCount: 1) }
            )
        }

        let items = (1...3).map { PhotosPickerItem(itemIdentifier: "load-failure-\($0)") }
        // When

        await store.send(\.binding.photoPickerSelection, items) {
            $0.photoPickerSelection = items
            $0.photoImportFailureCount = 0
        }

        // Then

        await store.receive(\.photosImported) {
            $0.draftPhotos = imported
            $0.photoPickerSelection = []
            $0.hasEditedPhotos = true
            $0.photoImportFailureCount = 1
        }
    }

    /// 兩張照片全部正規化失敗時，不應加入照片但應回報失敗張數
    @Test func pickerSelectionReportsAllNormalizationFailures() async {
        // Given

        let store = TestStore(
            initialState: OrderEditFeature.State(
                id: UUID(0), currentDate: TestDependencies.fixedNow)
        ) {
            OrderEditFeature()
        } withDependencies: {
            $0[PhotoClient.self] = PhotoClient(
                importPhotos: { _ in PhotoImportResult(photos: [], failedCount: 2) }
            )
        }

        let items = (1...2).map { PhotosPickerItem(itemIdentifier: "normalize-failure-\($0)") }
        // When

        await store.send(\.binding.photoPickerSelection, items) {
            $0.photoPickerSelection = items
        }

        // Then

        await store.receive(\.photosImported) {
            $0.photoPickerSelection = []
            $0.photoImportFailureCount = 2
        }
    }

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func deletePhotoRemovesExactIndexPreservingOrder() async {
        // Given

        let photoA = Data([0x0A])
        let photoB = Data([0x0B])
        let photoC = Data([0x0C])
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draftPhotos = [photoA, photoB, photoC]
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // [A, B, C] 刪 B → [A, C]，其餘保序；標記已更動
        // When

        await store.send(.deletePhotoTapped(1)) {
            $0.draftPhotos = [photoA, photoC]
            $0.hasEditedPhotos = true
        }

        // 越界 index 為 no-op (state 無變化)
        await store.send(.deletePhotoTapped(5))
        // Then

        #expect(store.state.draftPhotos == [photoA, photoC])
        #expect(store.state.hasEditedPhotos)
    }

    /// 驗證既有訂單照片不取自 original
    @Test func draftDoesNotPrefillPhotosFromOriginalUntilLoaded() {
        // Given

        let photos = [Data([0x01]), Data([0x02])]
        let sample = LedgerOrder.sampleOrders[0]
        let original = LedgerOrder(
            id: sample.id,
            customer: sample.customer,
            status: sample.status,
            currency: sample.currency,
            date: sample.date,
            items: sample.items,
            itemCost: sample.itemCost,
            domesticShipping: sample.domesticShipping,
            internationalShipping: sample.internationalShipping,
            foreignDomesticShipping: sample.foreignDomesticShipping,
            cardFeeRate: sample.cardFeeRate,
            platformFeeRate: sample.platformFeeRate,
            paymentFeeRate: sample.paymentFeeRate,
            chargedAmount: sample.chargedAmount,
            cardlessDeductionAmount: sample.cardlessDeductionAmount,
            cardlessSupplementAmount: sample.cardlessSupplementAmount,
            orderSource: sample.orderSource,
            categories: sample.categories,
            paymentMethod: sample.paymentMethod,
            notes: sample.notes,
            reconciliationStatus: sample.reconciliationStatus,
            campaignNames: sample.campaignNames,
            paymentReceiptStatus: sample.paymentReceiptStatus,
            isCashOnDelivery: sample.isCashOnDelivery,
            photos: photos,
            mergedSourceIDs: []
        )

        let state = OrderEditFeature.State(
            original: original, id: UUID(0), currentDate: TestDependencies.fixedNow)

        // When

        let draftPhotos = state.draftPhotos
        let photoLoadPhase = state.photoLoadPhase
        let photoPickerSelection = state.photoPickerSelection

        // Then

        #expect(draftPhotos.isEmpty)
        #expect(photoLoadPhase == .notLoaded)
        #expect(photoPickerSelection.isEmpty)
    }

    /// 新訂單直接視為已載入，不觸發載入 effect
    @Test func newOrderPhotoLoadPhaseIsLoadedImmediately() {
        // Given

        let state = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)

        // When

        let photoLoadPhase = state.photoLoadPhase
        let draftPhotos = state.draftPhotos
        let canAddMorePhotos = state.canAddMorePhotos

        // Then

        #expect(photoLoadPhase == .loaded)
        #expect(draftPhotos.isEmpty)
        #expect(canAddMorePhotos == true)
    }

    /// `.task` 觸發既有訂單的照片載入 effect，載入完成後草稿等於庫內照片
    @Test func editingExistingOrderLoadsPhotosOnAppear() async {
        // Given

        let original = LedgerOrder.sampleOrders[0]
        let photos = [Data([0x01]), Data([0x02])]
        let state = OrderEditFeature.State(
            original: original, id: UUID(0), currentDate: TestDependencies.fixedNow)
        // When

        let photoLoadPhase = state.photoLoadPhase

        // Then

        #expect(photoLoadPhase == .notLoaded)

        let store = TestStore(initialState: state) {
            OrderEditFeature()
        } withDependencies: {
            var orderRepository = OrderRepository.testValue
            orderRepository.fetchOrderPhotos = { id in
                #expect(id == original.id)
                return photos
            }
            $0[OrderRepository.self] = orderRepository
            // 抑制其他主檔載入，讓測試只接收照片完成 action
            var orderSourceRepository = OrderSourceRepository.testValue
            orderSourceRepository.fetchOrderSources = {
                () async throws(PersistenceError) -> [String] in
                throw PersistenceError.fetchFailed(
                    underlying: TestDependencies.makeUnderlyingError(message: "suppressed")
                )
            }
            $0[OrderSourceRepository.self] = orderSourceRepository

            var categoryRepository = CategoryRepository.testValue
            categoryRepository.fetchCategories = { () async throws(PersistenceError) -> [String] in
                throw PersistenceError.fetchFailed(
                    underlying: TestDependencies.makeUnderlyingError(message: "suppressed")
                )
            }
            $0[CategoryRepository.self] = categoryRepository

            var paymentMethodRepository = PaymentMethodRepository.testValue
            paymentMethodRepository.fetchPaymentMethodInfos = {
                () async throws(PersistenceError) -> [PaymentMethodInfo] in
                throw PersistenceError.fetchFailed(
                    underlying: TestDependencies.makeUnderlyingError(message: "suppressed")
                )
            }
            $0[PaymentMethodRepository.self] = paymentMethodRepository

            var reconciliationStatusRepository = ReconciliationStatusRepository.testValue
            reconciliationStatusRepository.fetchReconciliationStatuses = {
                () async throws(PersistenceError) -> [String] in
                throw PersistenceError.fetchFailed(
                    underlying: TestDependencies.makeUnderlyingError(message: "suppressed")
                )
            }
            $0[ReconciliationStatusRepository.self] = reconciliationStatusRepository

            var campaignRepository = CampaignRepository.testValue
            campaignRepository.fetchCampaigns = { () async throws(PersistenceError) -> [Campaign] in
                throw PersistenceError.fetchFailed(
                    underlying: TestDependencies.makeUnderlyingError(message: "suppressed")
                )
            }
            $0[CampaignRepository.self] = campaignRepository

            // 幣別回傳空陣列，避免送出 currenciesLoaded action
            var currencyMetadataRepository = CurrencyMetadataRepository.testValue
            currencyMetadataRepository.fetchCodes = { [] }
            $0[CurrencyMetadataRepository.self] = currencyMetadataRepository
        }

        await store.send(.task) {
            $0.photoLoadPhase = .loading
        }
        await store.receive(\.photosLoaded) {
            $0.draftPhotos = photos
            $0.photoLoadPhase = .loaded
        }
    }

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func isSelectedPaymentMethodCardlessReflectsMasterFlag() {
        // Given

        // 主檔中「無卡存款」isCardless == true、「信用卡」isCardless == false
        let state = OrderEditFeature.State(
            id: UUID(0),
            availablePaymentMethods: [
                PaymentMethodInfo(
                    name: "信用卡", isCardless: false, isBankTransfer: false, isCashOnDelivery: false),
                PaymentMethodInfo(
                    name: "無卡存款", isCardless: true, isBankTransfer: false, isCashOnDelivery: false),
            ],
            currentDate: TestDependencies.fixedNow
        )

        var mutable = state
        mutable.draft.paymentMethod = "信用卡"
        // When

        let creditCardIsCardless = mutable.isSelectedPaymentMethodCardless
        mutable.draft.paymentMethod = "無卡存款"
        let cardlessIsCardless = mutable.isSelectedPaymentMethodCardless

        // 不在主檔的暫存值預設視為非無卡
        mutable.draft.paymentMethod = "未知付款方式"
        let unknownIsCardless = mutable.isSelectedPaymentMethodCardless

        // Then

        #expect(creditCardIsCardless == false)
        #expect(cardlessIsCardless == true)
        #expect(unknownIsCardless == false)
    }

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func showsReconciliationStatusRowForCardlessOrBankTransfer() {
        // Given

        // 主檔旗標應正確對應付款方式。
        let state = OrderEditFeature.State(
            id: UUID(0),
            availablePaymentMethods: [
                PaymentMethodInfo(
                    name: "信用卡", isCardless: false, isBankTransfer: false, isCashOnDelivery: false),
                PaymentMethodInfo(
                    name: "無卡存款", isCardless: true, isBankTransfer: false, isCashOnDelivery: false),
                PaymentMethodInfo(
                    name: "銀行匯款", isCardless: false, isBankTransfer: true, isCashOnDelivery: false),
            ],
            currentDate: TestDependencies.fixedNow
        )

        var mutable = state
        // 信用卡：非無卡、非銀行匯款 → 不顯示對帳狀態 row
        mutable.draft.paymentMethod = "信用卡"
        // When

        let creditCardIsBankTransfer = mutable.isSelectedPaymentMethodBankTransfer
        let creditCardShowsRow = mutable.showsReconciliationStatusRow

        // 無卡存款：無卡 → 顯示
        mutable.draft.paymentMethod = "無卡存款"
        let cardlessShowsRow = mutable.showsReconciliationStatusRow

        // 銀行匯款：銀行匯款 → 顯示
        mutable.draft.paymentMethod = "銀行匯款"
        let bankTransferIsBankTransfer = mutable.isSelectedPaymentMethodBankTransfer
        let bankTransferShowsRow = mutable.showsReconciliationStatusRow

        // 不在主檔的暫存值預設視為兩者皆否 → 不顯示
        mutable.draft.paymentMethod = "未知付款方式"
        let unknownShowsRow = mutable.showsReconciliationStatusRow

        // Then

        #expect(creditCardIsBankTransfer == false)
        #expect(creditCardShowsRow == false)
        #expect(cardlessShowsRow == true)
        #expect(bankTransferIsBankTransfer == true)
        #expect(bankTransferShowsRow == true)
        #expect(unknownShowsRow == false)
    }

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func addReconciliationStatusTappedAppliesAndExtendsOptions() async {
        // Given

        let store = TestStore(
            initialState: OrderEditFeature.State(
                id: UUID(0), currentDate: TestDependencies.fixedNow)
        ) {
            OrderEditFeature()
        }

        // When

        await store.send(.addReconciliationStatusTapped("待對帳")) {
            // Then

            $0.availableReconciliationStatuses = ["待對帳"]
            $0.draft.reconciliationStatus = "待對帳"
        }

        // 清單依本地化排序，草稿切換為新項目
        await store.send(.addReconciliationStatusTapped("對帳成功")) {
            // Then

            $0.availableReconciliationStatuses = ["待對帳", "對帳成功"]
            $0.draft.reconciliationStatus = "對帳成功"
        }
    }

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func draftPrefillsReconciliationStatusFromOriginal() {
        // Given

        let original = LedgerOrder(
            id: "BL-TEST-RS",
            customer: LedgerCustomer(name: "對帳測試", initials: "RS", tier: .regular),
            status: .confirmed,
            currency: .twd,
            date: Date(timeIntervalSince1970: 0),
            items: [],
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
            orderSource: "蝦皮",
            categories: ["美妝"],
            paymentMethod: "銀行匯款",
            notes: "",
            reconciliationStatus: "待對帳",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )

        let state = OrderEditFeature.State(
            original: original, id: UUID(0), currentDate: TestDependencies.fixedNow)
        // When

        let reconciliationStatus = state.draft.reconciliationStatus
        let availableStatuses = state.availableReconciliationStatuses

        // Then

        #expect(reconciliationStatus == "待對帳")
        // 原訂單的對帳狀態若不在傳入清單，初始化時會補進可選清單
        #expect(availableStatuses.contains("待對帳"))
    }

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func newDraftStartsEmpty() {
        // Given

        let state = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)

        // When

        let draft = state.draft
        let original = state.original
        let availablePaymentMethods = state.availablePaymentMethods

        // Then

        #expect(draft.customerName.isEmpty)
        #expect(draft.categories.isEmpty)
        #expect(draft.status == .quoting)
        #expect(draft.currency == .twd)
        #expect(draft.chargedAmount == 0)
        #expect(draft.cardlessDeductionAmount == 0)
        #expect(draft.cardlessSupplementAmount == 0)
        #expect(draft.itemCost == 0)
        #expect(draft.domesticShipping == 0)
        #expect(draft.internationalShipping == 0)
        #expect(draft.cardFeeRate == 0)
        #expect(draft.platformFeeRate == 0)
        #expect(draft.notes.isEmpty)
        #expect(original == nil)
        #expect(availablePaymentMethods.isEmpty)
    }

    // MARK: 單/多選分流 (合併情境)

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func categorySelectedReplacesSelectionWithSingleElement() async {
        // Given

        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draft.categories = ["美妝", "服飾"]

        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When

        await store.send(.categorySelected("精品")) {
            // Then

            $0.draft.categories = ["精品"]
        }
    }

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func categoryToggledAddsAndRemovesSelection() async {
        // Given

        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draft.categories = ["美妝"]

        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When

        await store.send(.categoryToggled("服飾")) {
            // Then

            $0.draft.categories = ["美妝", "服飾"]
        }
        await store.send(.categoryToggled("美妝")) {
            // Then

            $0.draft.categories = ["服飾"]
        }
    }

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func campaignSelectedMapsEmptyStringToUnassigned() async {
        // Given

        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draft.campaignNames = ["四月韓國團"]

        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When

        await store.send(.campaignSelected("")) {
            // Then

            $0.draft.campaignNames = []
        }
        await store.send(.campaignSelected("三月日本團")) {
            // Then

            $0.draft.campaignNames = ["三月日本團"]
        }
    }

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func campaignToggledAddsAndRemovesSelection() async {
        // Given

        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draft.campaignNames = ["四月韓國團"]

        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When

        await store.send(.campaignToggled("三月日本團")) {
            // Then

            $0.draft.campaignNames = ["四月韓國團", "三月日本團"]
        }
        await store.send(.campaignToggled("四月韓國團")) {
            // Then

            $0.draft.campaignNames = ["三月日本團"]
        }
    }

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func isMergeContextReflectsMergeSources() {
        // Given

        // 一般新訂單與一般既有訂單皆非合併情境
        // When

        let newOrderIsMergeContext = OrderEditFeature.State(
            id: UUID(0), currentDate: TestDependencies.fixedNow
        ).isMergeContext
        let existingOrderIsMergeContext = OrderEditFeature.State(
            original: LedgerOrder.sampleOrders[0], id: UUID(0),
            currentDate: TestDependencies.fixedNow
        ).isMergeContext

        // 合併確認草稿 (mergeSourceIDs 非空)
        var mergeDraft = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        mergeDraft.mergeSourceIDs = ["BL-2604-018", "BL-2604-012"]
        let mergeDraftIsMergeContext = mergeDraft.isMergeContext

        // 編輯由合併產生的訂單 (original.mergedSourceIDs 非空)
        let mergedOrder = LedgerOrder.sampleOrders.first { !$0.mergedSourceIDs.isEmpty }
        let mergedOrderIsMergeContext = mergedOrder.map {
            OrderEditFeature.State(
                original: $0, id: UUID(0), currentDate: TestDependencies.fixedNow
            ).isMergeContext
        }

        // Then

        #expect(newOrderIsMergeContext == false)
        #expect(existingOrderIsMergeContext == false)
        #expect(mergeDraftIsMergeContext)
        #expect(mergedOrder != nil)
        #expect(mergedOrderIsMergeContext == true)
    }

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func addCategoryAppendsInMergeContextAndReplacesOtherwise() async {
        // Given

        // 合併情境：新增類別直接加入選取，不覆蓋既有選取
        var mergeDraft = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        mergeDraft.mergeSourceIDs = ["BL-A", "BL-B"]
        mergeDraft.draft.categories = ["美妝"]

        let mergeStore = TestStore(initialState: mergeDraft) {
            OrderEditFeature()
        }

        // When

        await mergeStore.send(.addCategoryTapped("服飾")) {
            // Then

            $0.availableCategories = ["服飾"]
            $0.draft.categories = ["美妝", "服飾"]
        }

        #expect(mergeStore.state.draft.categories == ["美妝", "服飾"])

        // 一般情境：新增類別覆寫為單元素陣列
        var singleDraft = OrderEditFeature.State(
            id: UUID(0), currentDate: TestDependencies.fixedNow)
        singleDraft.draft.categories = ["美妝"]

        let singleStore = TestStore(initialState: singleDraft) {
            OrderEditFeature()
        }

        await singleStore.send(.addCategoryTapped("服飾")) {
            // Then

            $0.availableCategories = ["服飾"]
            $0.draft.categories = ["服飾"]
        }
        #expect(singleStore.state.draft.categories == ["服飾"])
    }

    // MARK: 金額與明細欄位編輯性 (合併情境不鎖定)

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func mergeRelatedOrdersKeepAmountFieldsEditable() async {
        // Given

        // (1) 合併確認草稿：金額欄位 binding 寫入照常生效
        var mergeDraft = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        mergeDraft.mergeSourceIDs = ["BL-A", "BL-B"]

        let mergeStore = TestStore(initialState: mergeDraft) {
            OrderEditFeature()
        }
        // When

        await mergeStore.send(.binding(.set(\.draft.chargedAmount, 9_999))) {
            // Then

            $0.draft.chargedAmount = 9_999
        }
        await mergeStore.send(.binding(.set(\.draft.itemCost, 1_234))) {
            // Then

            $0.draft.itemCost = 1_234
        }

        // (2) 編輯由合併產生的訂單：同樣可編輯
        let mergedResult = LedgerOrder.sampleOrders.first { !$0.mergedSourceIDs.isEmpty }
        // Then

        #expect(mergedResult != nil)
        if let mergedResult {
            let store = TestStore(
                initialState: OrderEditFeature.State(
                    original: mergedResult, id: UUID(0), currentDate: TestDependencies.fixedNow)
            ) {
                OrderEditFeature()
            }
            await store.send(.binding(.set(\.draft.cardFeeRate, 0.02))) {
                // Then

                $0.draft.cardFeeRate = 0.02
            }
        }

        // (3) 編輯狀態為「已合併」的舊訂單：同樣可編輯
        let mergedAwayStore = TestStore(
            initialState: OrderEditFeature.State(
                original: Self.mergedAwayOrder, id: UUID(0), currentDate: TestDependencies.fixedNow)
        ) {
            OrderEditFeature()
        }
        await mergedAwayStore.send(.binding(.set(\.draft.chargedAmount, 777))) {
            // Then

            $0.draft.chargedAmount = 777
        }
    }

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func availableStatusesHidesMergedUnlessCurrent() {
        // Given

        // 一般訂單的狀態選單不提供「已合併」(只能由合併流程寫入)
        let normal = OrderEditFeature.State(
            original: LedgerOrder.sampleOrders[0], id: UUID(0),
            currentDate: TestDependencies.fixedNow)
        // When

        let normalStatuses = normal.availableStatuses
        let mergedAway = OrderEditFeature.State(
            original: Self.mergedAwayOrder, id: UUID(0), currentDate: TestDependencies.fixedNow)
        let mergedAwayStatuses = mergedAway.availableStatuses

        // Then

        #expect(!normalStatuses.contains(.merged))

        // 已合併舊單保留目前狀態，也可改回其他狀態。
        #expect(mergedAwayStatuses.contains(.merged))
        #expect(mergedAwayStatuses.contains(.purchased))
    }

    // MARK: 日期補秒

    /// 日期選擇器寫回年月日時分時保留注入時間的秒數
    ///
    /// - Throws: 固定日期無法建立時拋出測試錯誤
    @Test func dateComponentsChangedPreservesInjectedSeconds() async throws(any Error) {
        // Given：日期依賴提供帶有第 42 秒的固定現在時間
        let injectedNow = TestDependencies.fixedNow.addingTimeInterval(42)
        let store = TestStore(
            initialState: OrderEditFeature.State(
                id: UUID(0), currentDate: TestDependencies.fixedNow)
        ) {
            OrderEditFeature()
        } withDependencies: {
            $0.date = .constant(injectedNow)
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt

        // 日期選擇器選取的時間秒數為 0
        let pickedComponents = DateComponents(
            year: 2026,
            month: 6,
            day: 15,
            hour: 9,
            minute: 30,
            second: 0
        )
        let picked = try #require(calendar.date(from: pickedComponents))
        var expectedComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: picked
        )
        expectedComponents.second = 42
        let expected = try #require(calendar.date(from: expectedComponents))

        // When
        await store.send(.dateComponentsChanged(picked)) {
            $0.draft.date = expected
        }

        // Then
        #expect(store.state.draft.date == expected)
    }

    // MARK: OrderEditView 新 action (商品明細 / picker / 選取 / 照片)

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func addItemTappedAppendsBlankItem() async {
        // Given

        let store = TestStore(
            initialState: OrderEditFeature.State(
                id: UUID(0), currentDate: TestDependencies.fixedNow)
        ) {
            OrderEditFeature()
        } withDependencies: {
            $0.uuid = .incrementing
        }

        // 空清單會加入一筆預設商品。
        // When

        await store.send(.addItemTapped) {
            $0.draft.items = [
                LedgerOrderItem(id: UUID(0), name: "", quantity: 1, unitPrice: 0)
            ]
        }
        // Then

        #expect(store.state.draft.items.count == 1)
        #expect(store.state.draft.items[0].name.isEmpty)
        #expect(store.state.draft.items[0].quantity == 1)
        #expect(store.state.draft.items[0].unitPrice == 0)

        // 再點一次 → 兩筆
        await store.send(.addItemTapped) {
            $0.draft.items = [
                LedgerOrderItem(id: UUID(0), name: "", quantity: 1, unitPrice: 0),
                LedgerOrderItem(id: UUID(1), name: "", quantity: 1, unitPrice: 0),
            ]
        }
        #expect(store.state.draft.items.count == 2)
    }

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func deleteItemsRemovesAtOffsetsPreservingOrder() async {
        // Given

        let itemA = LedgerOrderItem(name: "A", quantity: 1, unitPrice: 100)
        let itemB = LedgerOrderItem(name: "B", quantity: 2, unitPrice: 200)
        let itemC = LedgerOrderItem(name: "C", quantity: 3, unitPrice: 300)
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draft.items = [itemA, itemB, itemC]
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // [A, B, C] 刪 index 1 → [A, C]，其餘保序
        // When

        await store.send(.deleteItems(IndexSet(integer: 1))) {
            // Then

            $0.draft.items = [itemA, itemC]
        }
    }

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func pickerTappedActionsSetCorrespondingPickerRoute() async {
        // Given

        let store = TestStore(
            initialState: OrderEditFeature.State(
                id: UUID(0), currentDate: TestDependencies.fixedNow)
        ) {
            OrderEditFeature()
        }

        // When

        await store.send(.orderSourcePickerTapped) {
            // Then

            $0.pickerRoute = .orderSource
        }
        await store.send(.categoryPickerTapped) {
            // Then

            $0.pickerRoute = .category
        }
        await store.send(.campaignPickerTapped) {
            // Then

            $0.pickerRoute = .campaign
        }
        await store.send(.currencyPickerTapped) {
            // Then

            $0.pickerRoute = .currency
        }
        await store.send(.paymentMethodPickerTapped) {
            // Then

            $0.pickerRoute = .paymentMethod
        }
        await store.send(.reconciliationStatusPickerTapped) {
            // Then

            $0.pickerRoute = .reconciliationStatus
        }
    }

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func selectionActionsUpdateDraftFields() async {
        // Given

        let store = TestStore(
            initialState: OrderEditFeature.State(
                id: UUID(0), currentDate: TestDependencies.fixedNow)
        ) {
            OrderEditFeature()
        }

        // When

        await store.send(.orderSourceSelected("蝦皮")) {
            // Then

            $0.draft.orderSource = "蝦皮"
        }
        await store.send(.paymentMethodSelected("信用卡")) {
            // Then

            $0.draft.paymentMethod = "信用卡"
        }
        await store.send(.reconciliationStatusSelected("待對帳")) {
            // Then

            $0.draft.reconciliationStatus = "待對帳"
        }
        await store.send(.currencySelected("JPY")) {
            // Then

            $0.draft.currency = .jpy
        }
    }

    /// 驗證訂單編輯功能在此情境下的狀態與效果
    @Test func photoTappedOpensViewerAndDismissClears() async {
        // Given

        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draftPhotos = [Data([0x01]), Data([0x02]), Data([0x03])]
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // 點第二張縮圖後進入照片檢視。
        // When

        await store.send(.photoTapped(2)) {
            // Then

            $0.pickerRoute = .photoViewer(index: 2)
        }

        // 宿主堆疊 Back 返回 → pickerPath binding 清空路徑
        await store.send(.binding(.set(\.pickerRoute, nil))) {
            // Then

            $0.pickerRoute = nil
        }
    }
}

// MARK: - Static Properties

private extension OrderEditFeatureTests {

    /// 已合併的來源訂單樣本
    static let mergedAwayOrder = LedgerOrder(
        id: "BL-MERGED-AWAY",
        customer: LedgerCustomer(name: "測試客戶", initials: "TC", tier: .regular),
        status: .merged,
        currency: .twd,
        date: Date(timeIntervalSince1970: 1_700_000_000),
        items: [],
        itemCost: 100,
        domesticShipping: 0,
        internationalShipping: 0,
        foreignDomesticShipping: 0,
        cardFeeRate: 0,
        platformFeeRate: 0,
        paymentFeeRate: 0,
        chargedAmount: 500,
        cardlessDeductionAmount: 0,
        cardlessSupplementAmount: 0,
        orderSource: "蝦皮",
        categories: ["美妝"],
        paymentMethod: "信用卡",
        notes: "",
        reconciliationStatus: "",
        campaignNames: [],
        paymentReceiptStatus: .pending,
        isCashOnDelivery: false,
        photos: [],
        mergedSourceIDs: []
    )
}
