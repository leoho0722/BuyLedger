//
//  OrderEditFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import PhotosUI
import SwiftUI
import Testing

@testable import BuyLedger

/// `OrderEditFeature` 的單元測試，以 TestStore 逐步驗證每個 Action 造成的狀態變化與後續 Action，並驗證 State 的初始值與衍生狀態
@MainActor
struct OrderEditFeatureTests {

    // MARK: - Properties

    /// 已合併的來源訂單樣本
    private static let mergedAwayOrder = LedgerOrder(
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

    /// 三種常用付款方式與對應旗標
    private static let paymentMethodCatalog: [PaymentMethodInfo] = [
        PaymentMethodInfo(
            name: "信用卡",
            isCardless: false,
            isBankTransfer: false,
            isCashOnDelivery: false
        ),
        PaymentMethodInfo(
            name: "無卡存款",
            isCardless: true,
            isBankTransfer: false,
            isCashOnDelivery: false
        ),
        PaymentMethodInfo(
            name: "銀行匯款",
            isCardless: false,
            isBankTransfer: true,
            isCashOnDelivery: false
        ),
    ]

    /// 對帳狀態不在可選清單中的既有訂單樣本
    private static let orderWithReconciliationStatus = LedgerOrder(
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

    // MARK: - Tests

    /// 在表單輸入顧客名稱時，草稿的顧客名稱跟著更新
    ///
    /// - Note: 此測試守住 `BindingReducer()` 的 binding 接線
    @Test
    func binding_顧客名稱改變_同步更新草稿() async {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.binding(.set(\.draft.customerName, "新客戶"))) {
            $0.draft.customerName = "新客戶"
        }

        // Then
        #expect(store.state.draft.customerName == "新客戶")
    }

    /// 結單日就是今天的開團仍在收單，列在可選的開團清單中
    @Test
    func availableCampaignsLoaded_開團今日到期_仍列入進行中清單() async {
        // Given
        let campaign = Campaign(
            id: "C1",
            name: "今天團",
            openDate: TestDependencies.fixedNow,
            closeDate: TestDependencies.fixedNow,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.availableCampaignsLoaded([campaign])) {
            $0.availableCampaigns = ["今天團"]
        }

        // Then
        #expect(store.state.availableCampaigns == ["今天團"])
    }

    /// 狀態仍為進行中但結單日已過的開團，不列入可選清單
    @Test
    func availableCampaignsLoaded_結單日已過但狀態仍進行中_不列入清單() async {
        // Given
        let yesterdayCampaign = Campaign(
            id: "C1",
            name: "昨天團",
            openDate: TestDependencies.fixedNow.addingTimeInterval(-172_800),
            closeDate: TestDependencies.fixedNow.addingTimeInterval(-86_400),
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let todayCampaign = Campaign(
            id: "C2",
            name: "今天團",
            openDate: TestDependencies.fixedNow,
            closeDate: TestDependencies.fixedNow,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.availableCampaignsLoaded([yesterdayCampaign, todayCampaign])) {
            $0.availableCampaigns = ["今天團"]
        }

        // Then
        #expect(store.state.availableCampaigns == ["今天團"])
    }

    /// 剛開啟、還沒改過任何欄位的新訂單，不算有未儲存的變更
    @Test
    func isDirty_新建訂單尚未編輯_回傳未修改() {
        // Given
        let state = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)

        // When
        let isDirty = state.isDirty

        // Then
        #expect(isDirty == false)
    }

    /// 開啟既有訂單後尚未改動草稿，不算有未儲存的變更
    @Test
    func isDirty_既有訂單尚未編輯_回傳未修改() {
        // Given
        let state = OrderEditFeature.State(
            original: LedgerOrder.sampleOrders[0],
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )

        // When
        let isDirty = state.isDirty

        // Then
        #expect(isDirty == false)
    }

    /// 既有訂單的欄位改掉又改回原值時，不算有未儲存的變更
    ///
    /// - Throws: 草稿欄位變更後若未標記為修改，測試即失敗
    @Test
    func isDirty_既有訂單編輯後還原_回傳未修改() throws {
        // Given
        var state = OrderEditFeature.State(
            original: LedgerOrder.sampleOrders[0],
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        state.draft.chargedAmount = 11_801
        try #require(state.isDirty)
        state.draft.chargedAmount = 11_800

        // When
        let isDirty = state.isDirty

        // Then
        #expect(isDirty == false)
    }

    /// 只打開選項選擇器、沒改草稿內容時，不算有未儲存的變更
    ///
    /// - Note: 選擇器路徑是暫時的呈現狀態，不屬於訂單草稿
    @Test
    func isDirty_只改選擇器路徑_不標記修改() {
        // Given
        var state = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        state.pickerRoute = .category

        // When
        let isDirty = state.isDirty

        // Then
        #expect(isDirty == false)
    }

    /// 新訂單的顧客名稱變更會標記為未儲存
    @Test
    func isDirty_新建訂單改顧客名稱_回傳已修改() {
        // Given
        var state = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        state.draft.customerName = "小明"

        // When
        let isDirty = state.isDirty

        // Then
        #expect(isDirty)
    }

    /// 新訂單的備註變更會標記為未儲存
    @Test
    func isDirty_新建訂單改備註_回傳已修改() {
        // Given
        var state = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        state.draft.notes = "新備註"

        // When
        let isDirty = state.isDirty

        // Then
        #expect(isDirty)
    }

    /// 新訂單增刪照片後會標記為未儲存
    @Test
    func isDirty_新建訂單增刪過照片_回傳已修改() {
        // Given
        var state = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        state.hasEditedPhotos = true

        // When
        let isDirty = state.isDirty

        // Then
        #expect(isDirty)
    }

    /// 只改焦點與照片選取時，不算有未儲存的變更
    @Test
    func isDirty_只改焦點與照片選取_不標記修改() {
        // Given
        var state = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        state.focusedField = .customerName
        state.photoPickerSelection = [PhotosPickerItem(itemIdentifier: "test-item")]

        // When
        let isDirty = state.isDirty

        // Then
        #expect(isDirty == false)
    }

    /// 既有訂單照片載入完成時，不算使用者編輯過照片
    @Test
    func photosLoaded_既有訂單照片載入完成_不算未儲存變更() async {
        // Given
        var initial = OrderEditFeature.State(
            original: LedgerOrder.sampleOrders[0],
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        initial.photoLoadPhase = .loading
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }
        let photos = [Data([0x01]), Data([0x02])]

        // When
        await store.send(.photosLoaded(photos)) {
            $0.draftPhotos = photos
            $0.photoLoadPhase = .loaded
        }

        // Then
        #expect(store.state.isDirty == false)
    }

    /// 折抵超過實收金額時，金額夾到上限並標示已修正
    @Test
    func binding_無卡折抵超過實收金額_夾到上限並標示() async {
        // Given
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draft.chargedAmount = 1_000
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.binding(.set(\.draft.cardlessDeductionAmount, 1_500))) {
            $0.draft.cardlessDeductionAmount = 1_000
            $0.cardlessDeductionWasCapped = true
        }

        // Then
        #expect(store.state.draft.cardlessDeductionAmount == 1_000)
        #expect(store.state.cardlessDeductionWasCapped)
    }

    /// 已夾限後輸入未超額折抵時，保留輸入並清除提示
    @Test
    func binding_已夾限後輸入未超額折抵_保留輸入並清除標示() async {
        // Given
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draft.chargedAmount = 1_000
        initial.draft.cardlessDeductionAmount = 1_000
        initial.cardlessDeductionWasCapped = true
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.binding(.set(\.draft.cardlessDeductionAmount, 300))) {
            $0.draft.cardlessDeductionAmount = 300
            $0.cardlessDeductionWasCapped = false
        }

        // Then
        #expect(store.state.cardlessDeductionWasCapped == false)
        #expect(store.state.draft.cardlessDeductionAmount == 300)
    }

    /// 實收金額降到折抵以下時，折抵會同步夾到新的上限
    @Test
    func binding_實收金額降到折抵以下_折抵夾到新上限() async {
        // Given
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draft.chargedAmount = 1_000
        initial.draft.cardlessDeductionAmount = 800
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.binding(.set(\.draft.chargedAmount, 300))) {
            $0.draft.chargedAmount = 300
            $0.draft.cardlessDeductionAmount = 300
            $0.cardlessDeductionWasCapped = true
        }

        // Then
        #expect(store.state.draft.chargedAmount == 300)
        #expect(store.state.draft.cardlessDeductionAmount == 300)
        #expect(store.state.cardlessDeductionWasCapped)
    }

    /// 開啟折抵超過實付金額的既有訂單時，折抵降到上限並標示修正，但不算未儲存變更
    @Test
    func init_既有訂單折抵超過上限_修正並標示原因() {
        // Given
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

        // When
        let state = OrderEditFeature.State(
            original: overCapOrder,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        let deduction = state.draft.cardlessDeductionAmount
        let wasCapped = state.cardlessDeductionWasCapped
        let isDirty = state.isDirty

        // Then
        #expect(deduction == 1_000)
        #expect(wasCapped)
        // 初始化時先修正既有資料，避免尚未編輯就被視為未儲存
        #expect(isDirty == false)
    }

    /// 草稿有變更時按取消，先詢問是否捨棄，不直接關閉表單
    ///
    /// - Note: 不覆寫 `dismiss`，若誤呼叫，TCA 預設的 `DismissEffect` 測試替身會回報 issue
    @Test
    func cancelTapped_草稿已有變更_呈現捨棄確認() async {
        // Given
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draft.customerName = "小明"
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
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
    }

    /// 確認捨棄未儲存變更時關閉表單
    @Test
    func discardConfirmation_選擇捨棄_關閉表單() async {
        // Given
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.discardConfirmation = AlertState {
            TextState("捨棄變更")
        } actions: {
            ButtonState(role: .destructive, action: .discard) {
                TextState("捨棄變更")
            }
        }
        let dismissCallCount = LockIsolated(0)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.dismiss = DismissEffect {
                dismissCallCount.withValue {
                    $0 += 1
                }
            }
        }

        // When
        await store.send(.discardConfirmation(.presented(.discard))) {
            $0.discardConfirmation = nil
        }

        // Then
        await store.finish()
        #expect(dismissCallCount.value == 1)
    }

    /// 沒改過任何欄位時按取消，不詢問就關閉表單
    @Test
    func cancelTapped_草稿沒有變更_直接關閉畫面() async {
        // Given
        let dismissCallCount = LockIsolated(0)
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.dismiss = DismissEffect {
                dismissCallCount.withValue {
                    $0 += 1
                }
            }
        }

        // When
        await store.send(.cancelTapped)

        // Then
        await store.finish()
        #expect(dismissCallCount.value == 1)
    }

    /// 在表單選擇商品類別時，草稿的類別跟著更新
    ///
    /// - Note: 此測試守住 `BindingReducer()` 的 binding 接線
    @Test
    func binding_分類選取改變_同步更新草稿() async {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.binding(.set(\.draft.categories, ["美妝"]))) {
            $0.draft.categories = ["美妝"]
        }

        // Then
        #expect(store.state.draft.categories == ["美妝"])
    }

    /// 在表單切換訂單狀態時，草稿的狀態跟著更新
    ///
    /// - Note: 此測試守住 `BindingReducer()` 的 binding 接線
    @Test
    func binding_訂單狀態改變_同步更新草稿() async {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.binding(.set(\.draft.status, .delivered))) {
            $0.draft.status = .delivered
        }

        // Then
        #expect(store.state.draft.status == .delivered)
    }

    /// 在表單切換幣別時，草稿的幣別跟著更新
    ///
    /// - Note: 此測試守住 `BindingReducer()` 的 binding 接線
    @Test
    func binding_來源幣別改變_同步更新草稿() async {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.binding(.set(\.draft.currency, .jpy))) {
            $0.draft.currency = .jpy
        }

        // Then
        #expect(store.state.draft.currency == .jpy)
    }

    /// 折抵為 0 時輸入實收金額，草稿金額跟著更新，不觸發折抵夾限
    ///
    /// - Note: 夾限行為由 `binding_實收金額降到折抵以下_折抵夾到新上限()` 覆蓋
    @Test
    func binding_實收金額改變_同步更新草稿() async {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.binding(.set(\.draft.chargedAmount, 12_345))) {
            $0.draft.chargedAmount = 12_345
        }

        // Then
        #expect(store.state.draft.chargedAmount == 12_345)
    }

    /// 金額或費率欄位透過 binding 寫入後，草稿保留指定值
    ///
    /// - Parameter field: 要更新的訂單草稿欄位
    /// - Note: 此測試守住 `BindingReducer()` 的 binding 接線
    @Test(arguments: CostField.allCases)
    func binding_成本欄位改變_同步更新草稿(field: CostField) async {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.binding(.set(field.keyPath, field.value))) {
            $0[keyPath: field.keyPath] = field.value
        }

        // Then
        #expect(store.state[keyPath: field.keyPath] == field.value)
    }

    /// 編輯既有訂單時，草稿帶入原有欄位內容
    @Test
    func init_編輯既有訂單_草稿帶入原始欄位() {
        // Given
        let original = LedgerOrder.sampleOrders[0]

        // When
        let state = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        let draft = state.draft

        // Then
        #expect(draft.customerName == "林書宇")
        #expect(draft.categories == ["美妝"])
        #expect(draft.status == .shipping)
        #expect(draft.currency == .krw)
        #expect(draft.chargedAmount == 11_800)
        #expect(draft.itemCost == 8_892)
        #expect(draft.domesticShipping == 80)
        #expect(draft.internationalShipping == 320)
        #expect(draft.cardFeeRate == 0.015)
        #expect(draft.notes == "客戶指定到貨後先拍照確認，再安排出貨。")
    }

    /// 照片已滿五張時再匯入，照片不增加，也不算改過照片
    @Test
    func photosImported_照片已滿_不再追加() async {
        // Given
        let fullPhotos = (1...5).map { Data([UInt8($0)]) }
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draftPhotos = fullPhotos
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.photosImported(PhotoImportResult(photos: [Data([0x06])], failedCount: 0)))

        // Then
        #expect(store.state.draftPhotos == fullPhotos)
        #expect(store.state.hasEditedPhotos == false)
    }

    /// 一次匯入的照片超過剩餘名額時，只依序收到名額用完為止
    @Test
    func photosImported_匯入照片超過上限_截取至上限() async {
        // Given
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draftPhotos = [Data([0x01]), Data([0x02]), Data([0x03])]
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }
        let batch = [Data([0x04]), Data([0x05]), Data([0x06]), Data([0x07])]
        let expectedPhotos = [Data([0x01]), Data([0x02]), Data([0x03]), Data([0x04]), Data([0x05])]

        // When
        await store.send(.photosImported(PhotoImportResult(photos: batch, failedCount: 0))) {
            $0.draftPhotos = expectedPhotos
            $0.hasEditedPhotos = true
        }

        // Then
        #expect(store.state.draftPhotos == expectedPhotos)
        #expect(store.state.hasEditedPhotos)
    }

    /// 選好照片後匯入草稿，並清空選取，下次才能重新選
    @Test
    func binding_選取照片_匯入並清空選取() async {
        // Given
        let imported = [Data([0xAA]), Data([0xBB]), Data([0xCC])]
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.photoService.importPhotos = { _ in
                PhotoImportResult(photos: imported, failedCount: 0)
            }
        }
        let items = (1...3).map { PhotosPickerItem(itemIdentifier: "test-item-\($0)") }

        // When
        await store.send(\.binding.photoPickerSelection, items) {
            $0.photoPickerSelection = items
        }

        // Then
        await store.receive(\.photosImported) {
            $0.draftPhotos = imported
            $0.photoPickerSelection = []
            $0.hasEditedPhotos = true
        }
    }

    /// 新一批照片匯入前應清除舊失敗張數，並保留本批失敗張數
    @Test
    func binding_一張照片載入失敗_回報失敗數() async {
        // Given
        let imported = [Data([0xAA]), Data([0xBB])]
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.photoImportFailureCount = 2
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.photoService.importPhotos = { _ in
                PhotoImportResult(photos: imported, failedCount: 1)
            }
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
    @Test
    func binding_照片正規化全數失敗_回報失敗數() async {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.photoService.importPhotos = { _ in
                PhotoImportResult(photos: [], failedCount: 2)
            }
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

    /// 刪除中間那張照片後，其餘照片維持原本順序
    @Test
    func deletePhotoTapped_刪除指定照片_保留其餘順序() async {
        // Given
        let photoA = Data([0x0A])
        let photoB = Data([0x0B])
        let photoC = Data([0x0C])
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draftPhotos = [photoA, photoB, photoC]
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.deletePhotoTapped(1)) {
            $0.draftPhotos = [photoA, photoC]
            $0.hasEditedPhotos = true
        }

        // Then
        #expect(store.state.draftPhotos == [photoA, photoC])
        #expect(store.state.hasEditedPhotos)
    }

    /// 索引超出照片範圍時，照片與編輯狀態都不變
    @Test
    func deletePhotoTapped_索引超出範圍_不變更照片() async {
        // Given
        let photoA = Data([0x0A])
        let photoB = Data([0x0B])
        let photoC = Data([0x0C])
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draftPhotos = [photoA, photoB, photoC]
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.deletePhotoTapped(5))

        // Then
        #expect(store.state.draftPhotos == [photoA, photoB, photoC])
        #expect(store.state.hasEditedPhotos == false)
    }

    /// 編輯既有訂單時，表單一開始不帶入訂單上的照片，等載入完成才放進草稿
    @Test
    func init_既有訂單照片尚未載入_不帶入原照片() {
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

        // When
        let state = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )

        // Then
        #expect(state.draftPhotos.isEmpty)
        #expect(state.photoLoadPhase == .notLoaded)
    }

    /// 新訂單一開啟照片就算載入完成，可以直接加入照片
    @Test
    func init_新建訂單_照片直接視為已載入() {
        // Given

        // When
        let state = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)

        // Then
        #expect(state.photoLoadPhase == .loaded)
        #expect(state.canAddMorePhotos == true)
    }

    /// `.task` 載入既有訂單照片並放進草稿，不算使用者修改照片
    @Test
    func task_編輯既有訂單_載入原始照片() async {
        // Given
        let original = LedgerOrder.sampleOrders[0]
        let photos = [Data([0x01]), Data([0x02])]
        let state = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        let fetchedPhotoOrderIDs = LockIsolated<[LedgerOrder.ID]>([])
        let failingOrderSourcesFetch: OrderSourceService.FetchOrderSources = {
            throw .fetchFailed(
                underlying: TestDependencies.makeUnderlyingError(message: "suppressed")
            )
        }
        let failingCategoriesFetch: CategoryService.FetchCategories = {
            throw .fetchFailed(
                underlying: TestDependencies.makeUnderlyingError(message: "suppressed")
            )
        }
        let failingPaymentMethodsFetch: PaymentMethodService.FetchPaymentMethodInfos = {
            throw .fetchFailed(
                underlying: TestDependencies.makeUnderlyingError(message: "suppressed")
            )
        }
        let failingStatusesFetch: ReconciliationStatusService.FetchReconciliationStatuses = {
            throw .fetchFailed(
                underlying: TestDependencies.makeUnderlyingError(message: "suppressed")
            )
        }
        let failingCampaignsFetch: CampaignService.FetchCampaigns = {
            throw .fetchFailed(
                underlying: TestDependencies.makeUnderlyingError(message: "suppressed")
            )
        }
        let store = TestStore(initialState: state) {
            OrderEditFeature()
        } withDependencies: {
            $0.orderService.fetchOrderPhotos = { id in
                fetchedPhotoOrderIDs.withValue {
                    $0.append(id)
                }
                return photos
            }
            $0.orderSourceService.fetchOrderSources = failingOrderSourcesFetch
            $0.categoryService.fetchCategories = failingCategoriesFetch
            $0.paymentMethodService.fetchPaymentMethodInfos = failingPaymentMethodsFetch
            $0.reconciliationStatusService.fetchReconciliationStatuses = failingStatusesFetch
            $0.campaignService.fetchCampaigns = failingCampaignsFetch
            // 幣別回傳空陣列，不送出 `availableCurrenciesLoaded`
            $0.currencyMetadataService.fetchCodes = {
                []
            }
        }

        // When
        await store.send(.task) {
            $0.photoLoadPhase = .loading
        }

        // Then
        await store.receive(\.photosLoaded) {
            $0.draftPhotos = photos
            $0.photoLoadPhase = .loaded
        }
        #expect(fetchedPhotoOrderIDs.value == ["BL-2604-018"])
    }

    /// 付款方式依主檔的無卡旗標判斷；不在主檔的名稱視為非無卡
    ///
    /// - Parameters:
    ///   - paymentMethod: 要查詢的付款方式名稱
    ///   - expected: 預期是否為無卡付款方式
    @Test(arguments: [
        (paymentMethod: "信用卡", expected: false),
        (paymentMethod: "無卡存款", expected: true),
        (paymentMethod: "未知付款方式", expected: false),
    ])
    func isSelectedPaymentMethodCardless_依付款方式查主檔_回傳無卡旗標(paymentMethod: String, expected: Bool) {
        // Given
        var state = OrderEditFeature.State(
            id: UUID(0),
            availablePaymentMethods: Self.paymentMethodCatalog,
            currentDate: TestDependencies.fixedNow
        )
        state.draft.paymentMethod = paymentMethod

        // When
        let isCardless = state.isSelectedPaymentMethodCardless

        // Then
        #expect(isCardless == expected)
    }

    /// 付款方式為無卡或銀行匯款時才顯示對帳狀態欄位；不在主檔的名稱不顯示
    ///
    /// - Parameters:
    ///   - paymentMethod: 要查詢的付款方式名稱
    ///   - expected: 預期是否顯示對帳狀態欄位
    @Test(arguments: [
        (paymentMethod: "信用卡", expected: false),
        (paymentMethod: "無卡存款", expected: true),
        (paymentMethod: "銀行匯款", expected: true),
        (paymentMethod: "未知付款方式", expected: false),
    ])
    func showsReconciliationStatusRow_依付款方式旗標_無卡或匯款才顯示(paymentMethod: String, expected: Bool) {
        // Given
        var state = OrderEditFeature.State(
            id: UUID(0),
            availablePaymentMethods: Self.paymentMethodCatalog,
            currentDate: TestDependencies.fixedNow
        )
        state.draft.paymentMethod = paymentMethod

        // When
        let showsRow = state.showsReconciliationStatusRow

        // Then
        #expect(showsRow == expected)
    }

    /// 付款方式依主檔的銀行匯款旗標判斷
    ///
    /// - Parameters:
    ///   - paymentMethod: 要查詢的付款方式名稱
    ///   - expected: 預期是否為銀行匯款
    @Test(arguments: [
        (paymentMethod: "信用卡", expected: false),
        (paymentMethod: "銀行匯款", expected: true),
    ])
    func isSelectedPaymentMethodBankTransfer_依付款方式查主檔_回傳匯款旗標(
        paymentMethod: String,
        expected: Bool
    ) {
        // Given
        var state = OrderEditFeature.State(
            id: UUID(0),
            availablePaymentMethods: Self.paymentMethodCatalog,
            currentDate: TestDependencies.fixedNow
        )
        state.draft.paymentMethod = paymentMethod

        // When
        let isBankTransfer = state.isSelectedPaymentMethodBankTransfer

        // Then
        #expect(isBankTransfer == expected)
    }

    /// 新增對帳狀態時套用到草稿，並加入可選清單
    @Test
    func addReconciliationStatusTapped_已有其他對帳狀態_套用新狀態並加入選項() async {
        // Given
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.availableReconciliationStatuses = ["待對帳"]
        initial.draft.reconciliationStatus = "待對帳"
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.addReconciliationStatusTapped("對帳成功")) {
            $0.availableReconciliationStatuses = ["待對帳", "對帳成功"]
            $0.draft.reconciliationStatus = "對帳成功"
        }

        // Then
        #expect(store.state.availableReconciliationStatuses == ["待對帳", "對帳成功"])
        #expect(store.state.draft.reconciliationStatus == "對帳成功")
    }

    /// 既有訂單的對帳狀態帶入草稿；不在可選清單時補進清單
    ///
    /// - Note: 舊資料中的對帳狀態不能因主檔清單未載入而消失
    @Test
    func init_既有訂單對帳狀態不在清單_帶入草稿並補進選項() {
        // Given
        let original = Self.orderWithReconciliationStatus

        // When
        let state = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )

        // Then
        #expect(state.draft.reconciliationStatus == "待對帳")
        #expect(state.availableReconciliationStatuses == ["待對帳"])
    }

    /// 新訂單的草稿欄位以空白與預設值起始
    @Test
    func init_新訂單_草稿帶入預設值() {
        // Given

        // When
        let state = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)

        // Then
        #expect(state.draft.customerName.isEmpty)
        #expect(state.draft.categories.isEmpty)
        #expect(state.draft.status == .quoting)
        #expect(state.draft.currency == .twd)
        #expect(state.draft.date == TestDependencies.fixedNow)
        #expect(state.draft.chargedAmount == 0)
        #expect(state.draft.cardlessDeductionAmount == 0)
        #expect(state.draft.cardlessSupplementAmount == 0)
        #expect(state.draft.itemCost == 0)
        #expect(state.draft.domesticShipping == 0)
        #expect(state.draft.internationalShipping == 0)
        #expect(state.draft.cardFeeRate == 0)
        #expect(state.draft.platformFeeRate == 0)
        #expect(state.draft.notes.isEmpty)
    }

    /// 單選分類時以新分類取代原本的所有選取
    @Test
    func categorySelected_已選多個分類_改為只選新分類() async {
        // Given
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draft.categories = ["美妝", "服飾"]
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.categorySelected("精品")) {
            $0.draft.categories = ["精品"]
        }

        // Then
        #expect(store.state.draft.categories == ["精品"])
    }

    /// 分類切換會依初始選取狀態加入或移除分類
    ///
    /// - Parameter testCase: 分類切換的起始選取、切換項目與預期結果
    @Test(arguments: [
        CategoryToggleCase(initialCategories: ["美妝"], category: "服飾", expected: ["美妝", "服飾"]),
        CategoryToggleCase(initialCategories: ["美妝", "服飾"], category: "美妝", expected: ["服飾"]),
    ])
    func categoryToggled_分類未選或已選_加入或移除選取(testCase: CategoryToggleCase) async {
        // Given
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draft.categories = testCase.initialCategories
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.categoryToggled(testCase.category)) {
            $0.draft.categories = testCase.expected
        }

        // Then
        #expect(store.state.draft.categories == testCase.expected)
    }

    /// 選擇一個開團會取代原選取，選擇空白則清除歸屬
    ///
    /// - Parameters:
    ///   - selection: 要選取的開團名稱
    ///   - expected: 預期寫入草稿的開團名稱
    @Test(arguments: [
        (selection: "", expected: [String]()),
        (selection: "三月日本團", expected: ["三月日本團"]),
    ])
    func campaignSelected_空白或有效名稱_清空或改為單一開團(selection: String, expected: [String]) async {
        // Given
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draft.campaignNames = ["四月韓國團"]
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.campaignSelected(selection)) {
            $0.draft.campaignNames = expected
        }

        // Then
        #expect(store.state.draft.campaignNames == expected)
    }

    /// 開團切換會依初始選取狀態加入或移除開團
    ///
    /// - Parameter testCase: 開團切換的起始選取、切換項目與預期結果
    @Test(arguments: [
        CampaignToggleCase(
            initialCampaigns: ["四月韓國團"],
            campaign: "三月日本團",
            expected: ["四月韓國團", "三月日本團"]
        ),
        CampaignToggleCase(
            initialCampaigns: ["四月韓國團", "三月日本團"],
            campaign: "四月韓國團",
            expected: ["三月日本團"]
        ),
    ])
    func campaignToggled_開團未選或已選_加入或移除選取(testCase: CampaignToggleCase) async {
        // Given
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draft.campaignNames = testCase.initialCampaigns
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.campaignToggled(testCase.campaign)) {
            $0.draft.campaignNames = testCase.expected
        }

        // Then
        #expect(store.state.draft.campaignNames == testCase.expected)
    }

    /// 只有帶合併來源編號的草稿或合併產生的訂單才算合併情境
    ///
    /// - Parameters:
    ///   - scenario: 要建立的訂單起始情境
    ///   - expected: 預期是否為合併情境
    /// - Throws: 找不到合併產生的樣本訂單時由 `#require` 丟出
    @Test(arguments: [
        (scenario: EditScenario.newOrder, expected: false),
        (scenario: EditScenario.existingOrder, expected: false),
        (scenario: EditScenario.mergeDraft, expected: true),
        (scenario: EditScenario.mergedResult, expected: true),
    ])
    func isMergeContext_各訂單情境_依合併來源判定(scenario: EditScenario, expected: Bool) throws {
        // Given
        let state = try Self.makeState(for: scenario)

        // When
        let isMergeContext = state.isMergeContext

        // Then
        #expect(isMergeContext == expected)
    }

    /// 新增分類時，合併情境追加分類，一般情境則取代選取
    ///
    /// - Parameters:
    ///   - scenario: 要建立的訂單起始情境
    ///   - expected: 新增分類後預期保留的分類
    /// - Throws: `makeState(for:)` 只在 `mergedResult` 情境找不到樣本時丟出，本測試的兩個情境不會觸發
    @Test(arguments: [
        (scenario: EditScenario.mergeDraft, expected: ["美妝", "服飾"]),
        (scenario: EditScenario.newOrder, expected: ["服飾"]),
    ])
    func addCategoryTapped_合併或一般情境新增分類_依情境追加或取代(
        scenario: EditScenario,
        expected: [String]
    ) async throws {
        // Given
        var initial = try Self.makeState(for: scenario)
        initial.draft.categories = ["美妝"]
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.addCategoryTapped("服飾")) {
            $0.availableCategories = ["服飾"]
            $0.draft.categories = expected
        }

        // Then
        #expect(store.state.availableCategories == ["服飾"])
        #expect(store.state.draft.categories == expected)
    }

    /// 合併草稿、合併結果與已合併舊單的金額與費率欄位都可透過 binding 更新
    ///
    /// - Parameter testCase: 要驗證的合併訂單情境、欄位與值
    /// - Throws: 找不到指定合併訂單樣本時由 `#require` 丟出
    /// - Note: 目前 reducer 未針對合併單分流；此測試守住合併單欄位仍可編輯
    @Test(arguments: [
        MergeEditCase(scenario: .mergeDraft, field: .chargedAmount, value: Decimal(9_999)),
        MergeEditCase(scenario: .mergeDraft, field: .itemCost, value: Decimal(1_234)),
        MergeEditCase(scenario: .mergedResult, field: .cardFeeRate, value: Decimal(0.02)),
        MergeEditCase(scenario: .mergedAway, field: .chargedAmount, value: Decimal(777)),
    ])
    func binding_合併訂單編輯金額與費率欄位_允許更新(testCase: MergeEditCase) async throws {
        // Given
        let initial = try Self.makeState(for: testCase.scenario)
        let keyPath = testCase.field.keyPath
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.binding(.set(keyPath, testCase.value))) {
            $0[keyPath: keyPath] = testCase.value
        }

        // Then
        #expect(store.state[keyPath: keyPath] == testCase.value)
    }

    /// 一般訂單的狀態選單不含「已合併」
    ///
    /// - Note: 「已合併」只能由合併流程寫入
    @Test
    func availableStatuses_一般既有訂單_不提供已合併() {
        // Given
        let state = OrderEditFeature.State(
            original: LedgerOrder.sampleOrders[0],
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )

        // When
        let statuses = state.availableStatuses

        // Then
        #expect(!statuses.contains(.merged))
    }

    /// 已合併舊單保留「已合併」，也能改回其他狀態
    @Test
    func availableStatuses_已合併舊單_保留已合併並可改回其他狀態() {
        // Given
        let state = OrderEditFeature.State(
            original: Self.mergedAwayOrder,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )

        // When
        let statuses = state.availableStatuses

        // Then
        #expect(statuses.contains(.merged))
        #expect(statuses.contains(.purchased))
    }

    /// 日期選擇器寫回年月日時分時，保留注入時間的秒數
    @Test
    func dateComponentsChanged_更新年月日時分_保留注入秒數() async {
        // Given
        let picked = Date(timeIntervalSince1970: 1_781_515_800) // 2026-06-15 09:30:00 UTC
        let expected = Date(timeIntervalSince1970: 1_781_515_842) // 同一分鐘，秒數取自注入時間的 42
        let injectedNow = TestDependencies.fixedNow.addingTimeInterval(42)
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.date = .constant(injectedNow)
        }

        // When
        await store.send(.dateComponentsChanged(picked)) {
            $0.draft.date = expected
        }

        // Then
        #expect(store.state.draft.date == expected)
    }

    /// 新增商品列時，既有商品資料會保留並追加空白列
    @Test
    func addItemTapped_新增訂單項目_追加空白列() async {
        // Given
        let existingItem = LedgerOrderItem(
            id: UUID(9),
            name: "既有商品",
            quantity: 2,
            unitPrice: 100
        )
        let blankItem = LedgerOrderItem(
            id: UUID(0),
            name: "",
            quantity: 1,
            unitPrice: 0
        )
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draft.items = [existingItem]
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.uuid = .incrementing
        }

        // When
        await store.send(.addItemTapped) {
            $0.draft.items = [existingItem, blankItem]
        }

        // Then
        #expect(store.state.draft.items == [existingItem, blankItem])
    }

    /// 刪除指定位置的商品列後，其餘商品維持原順序
    @Test
    func deleteItems_刪除指定索引_保留其他項目順序() async {
        // Given
        let itemA = LedgerOrderItem(
            id: UUID(0),
            name: "A",
            quantity: 1,
            unitPrice: 100
        )
        let itemB = LedgerOrderItem(
            id: UUID(1),
            name: "B",
            quantity: 2,
            unitPrice: 200
        )
        let itemC = LedgerOrderItem(
            id: UUID(2),
            name: "C",
            quantity: 3,
            unitPrice: 300
        )
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draft.items = [itemA, itemB, itemC]
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.deleteItems(IndexSet(integer: 1))) {
            $0.draft.items = [itemA, itemC]
        }

        // Then
        #expect(store.state.draft.items == [itemA, itemC])
    }

    /// 尚未開啟選擇器時，點選訂單來源按鈕會推入訂單來源選擇器
    @Test
    func orderSourcePickerTapped_尚未開啟選擇器_推入訂單來源選擇器() async {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.orderSourcePickerTapped) {
            $0.pickerRoute = .orderSource
        }

        // Then
        #expect(store.state.pickerRoute == .orderSource)
    }

    /// 尚未開啟選擇器時，點選分類按鈕會推入分類選擇器
    @Test
    func categoryPickerTapped_尚未開啟選擇器_推入分類選擇器() async {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.categoryPickerTapped) {
            $0.pickerRoute = .category
        }

        // Then
        #expect(store.state.pickerRoute == .category)
    }

    /// 尚未開啟選擇器時，點選開團按鈕會推入開團選擇器
    @Test
    func campaignPickerTapped_尚未開啟選擇器_推入開團選擇器() async {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.campaignPickerTapped) {
            $0.pickerRoute = .campaign
        }

        // Then
        #expect(store.state.pickerRoute == .campaign)
    }

    /// 尚未開啟選擇器時，點選幣別按鈕會推入幣別選擇器
    @Test
    func currencyPickerTapped_尚未開啟選擇器_推入幣別選擇器() async {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.currencyPickerTapped) {
            $0.pickerRoute = .currency
        }

        // Then
        #expect(store.state.pickerRoute == .currency)
    }

    /// 尚未開啟選擇器時，點選付款方式按鈕會推入付款方式選擇器
    @Test
    func paymentMethodPickerTapped_尚未開啟選擇器_推入付款方式選擇器() async {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.paymentMethodPickerTapped) {
            $0.pickerRoute = .paymentMethod
        }

        // Then
        #expect(store.state.pickerRoute == .paymentMethod)
    }

    /// 尚未開啟選擇器時，點選對帳狀態按鈕會推入對帳狀態選擇器
    @Test
    func reconciliationStatusPickerTapped_尚未開啟選擇器_推入對帳狀態選擇器() async {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.reconciliationStatusPickerTapped) {
            $0.pickerRoute = .reconciliationStatus
        }

        // Then
        #expect(store.state.pickerRoute == .reconciliationStatus)
    }

    /// 草稿尚無訂單來源時，選取來源會寫入名稱
    @Test
    func orderSourceSelected_草稿尚無來源_更新草稿() async {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.orderSourceSelected("蝦皮")) {
            $0.draft.orderSource = "蝦皮"
        }

        // Then
        #expect(store.state.draft.orderSource == "蝦皮")
    }

    /// 草稿尚無付款方式時，選取付款方式會寫入名稱
    @Test
    func paymentMethodSelected_草稿尚無付款方式_更新草稿() async {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.paymentMethodSelected("信用卡")) {
            $0.draft.paymentMethod = "信用卡"
        }

        // Then
        #expect(store.state.draft.paymentMethod == "信用卡")
    }

    /// 草稿尚無對帳狀態時，選取狀態會寫入名稱
    @Test
    func reconciliationStatusSelected_草稿尚無對帳狀態_更新草稿() async {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.reconciliationStatusSelected("待對帳")) {
            $0.draft.reconciliationStatus = "待對帳"
        }

        // Then
        #expect(store.state.draft.reconciliationStatus == "待對帳")
    }

    /// 草稿使用預設台幣時，選取幣別會更新代碼
    @Test
    func currencySelected_草稿為預設台幣_更新草稿() async {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.currencySelected("JPY")) {
            $0.draft.currency = .jpy
        }

        // Then
        #expect(store.state.draft.currency == .jpy)
    }

    /// 關閉照片檢視器後，選擇器路徑會清空
    ///
    /// - Note: 此測試守住 `BindingReducer()` 的 binding 接線
    @Test
    func binding_檢視照片後關閉_清除照片檢視路徑() async {
        // Given
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draftPhotos = [Data([0x01]), Data([0x02]), Data([0x03])]
        initial.pickerRoute = .photoViewer(index: 2)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.binding(.set(\.pickerRoute, nil))) {
            $0.pickerRoute = nil
        }

        // Then
        #expect(store.state.pickerRoute == nil)
    }

    /// 點選第三張照片後，以推進方式開啟照片檢視器
    @Test
    func photoTapped_點選第三張照片_推入照片檢視器() async {
        // Given
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draftPhotos = [Data([0x01]), Data([0x02]), Data([0x03])]
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.photoTapped(2)) {
            $0.pickerRoute = .photoViewer(index: 2)
        }

        // Then
        #expect(store.state.pickerRoute == .photoViewer(index: 2))
    }
}

// MARK: - Nested Types

extension OrderEditFeatureTests {

    /// `binding_成本欄位改變_同步更新草稿(field:)` 逐一代入的草稿金額與費率欄位
    enum CostField: CaseIterable, Sendable {

        /// 商品成本
        case itemCost

        /// 國內運費
        case domesticShipping

        /// 國際運費
        case internationalShipping

        /// 刷卡手續費率
        case cardFeeRate

        /// 平台手續費率
        case platformFeeRate

        /// 取得送 binding 與讀回結果時使用的草稿欄位路徑
        var keyPath: WritableKeyPath<OrderEditFeature.State, Decimal> & Sendable {
            switch self {
            case .itemCost:
                \.draft.itemCost

            case .domesticShipping:
                \.draft.domesticShipping

            case .internationalShipping:
                \.draft.internationalShipping

            case .cardFeeRate:
                \.draft.cardFeeRate

            case .platformFeeRate:
                \.draft.platformFeeRate
            }
        }

        /// 取得各欄位用於測試的固定值
        var value: Decimal {
            switch self {
            case .itemCost:
                5_000

            case .domesticShipping:
                80

            case .internationalShipping:
                320

            case .cardFeeRate:
                0.015

            case .platformFeeRate:
                0.03
            }
        }
    }

    /// 合併情境測試使用的訂單起始狀態
    enum EditScenario: CaseIterable, Sendable {

        /// 新建訂單
        case newOrder

        /// 編輯一般既有訂單
        case existingOrder

        /// 帶有兩筆合併來源的草稿
        case mergeDraft

        /// 編輯由合併產生的訂單
        case mergedResult

        /// 編輯已被合併的舊訂單
        case mergedAway
    }

    /// 合併情境 binding 測試的金額或費率欄位
    enum MergeEditField: CaseIterable, Sendable {

        /// 實收金額
        case chargedAmount

        /// 商品成本
        case itemCost

        /// 刷卡手續費率
        case cardFeeRate

        /// 取得 binding 與結果斷言使用的草稿欄位路徑
        var keyPath: WritableKeyPath<OrderEditFeature.State, Decimal> & Sendable {
            switch self {
            case .chargedAmount:
                \.draft.chargedAmount

            case .itemCost:
                \.draft.itemCost

            case .cardFeeRate:
                \.draft.cardFeeRate
            }
        }
    }

    /// 分類切換測試使用的輸入與預期結果
    struct CategoryToggleCase: Sendable {

        /// 送出 action 前已選取的分類
        let initialCategories: [String]

        /// 要切換的分類
        let category: String

        /// 切換後預期保留的分類
        let expected: [String]
    }

    /// 開團切換測試使用的輸入與預期結果
    struct CampaignToggleCase: Sendable {

        /// 送出 action 前已選取的開團
        let initialCampaigns: [String]

        /// 要切換的開團名稱
        let campaign: String

        /// 切換後預期保留的開團
        let expected: [String]
    }

    /// 合併訂單 binding 測試使用的情境、欄位與預期值
    struct MergeEditCase: Sendable {

        /// 要建立的訂單起始情境
        let scenario: EditScenario

        /// 要更新的金額或費率欄位
        let field: MergeEditField

        /// 要寫入欄位的值
        let value: Decimal
    }
}

// MARK: - Private Method

private extension OrderEditFeatureTests {

    /// 依照訂單情境建立編輯表單狀態
    ///
    /// - Parameter scenario: 要建立的訂單起始情境
    /// - Returns: 尚未編輯的表單狀態，識別碼固定為 `UUID(0)`、目前日期固定為 `TestDependencies.fixedNow`
    /// - Throws: 找不到合併產生的樣本訂單時由 `#require` 丟出
    static func makeState(for scenario: EditScenario) throws -> OrderEditFeature.State {
        let state: OrderEditFeature.State
        switch scenario {
        case .newOrder:
            state = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)

        case .existingOrder:
            state = OrderEditFeature.State(
                original: LedgerOrder.sampleOrders[0],
                id: UUID(0),
                currentDate: TestDependencies.fixedNow
            )

        case .mergeDraft:
            var initial = OrderEditFeature.State(
                id: UUID(0),
                currentDate: TestDependencies.fixedNow
            )
            initial.mergeSourceIDs = ["BL-A", "BL-B"]
            state = initial

        case .mergedResult:
            let mergedOrder = LedgerOrder.sampleOrders.first {
                !$0.mergedSourceIDs.isEmpty
            }
            let original = try #require(mergedOrder)
            state = OrderEditFeature.State(
                original: original,
                id: UUID(0),
                currentDate: TestDependencies.fixedNow
            )

        case .mergedAway:
            state = OrderEditFeature.State(
                original: Self.mergedAwayOrder,
                id: UUID(0),
                currentDate: TestDependencies.fixedNow
            )
        }
        return state
    }
}
