//
//  OrderDraftTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/8/2.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import BuyLedger

/// 驗證 OrderDraft 的訂單建構邏輯
struct OrderDraftTests {
    
    // MARK: - Tests
    
    /// 編輯時空白主檔欄位回退既有值
    @Test func editingExistingOrderFallsBackToExistingValuesWhenDraftFieldsAreEmpty() {
        let existing = Self.makeOrder(
            id: "BL-001",
            customerName: "老客戶",
            orderSource: "蝦皮",
            categories: ["舊類別"],
            paymentMethod: "舊付款"
        )
        var editState = OrderEditFeature.State(
            original: existing, id: UUID(0), currentDate: TestDependencies.fixedNow)
        editState.draft.customerName = "   "
        editState.draft.orderSource = ""
        editState.draft.categories = []
        editState.draft.paymentMethod = ""
        
        let result = OrderDraft.resolveWriteResult(
            editState, existingOrders: [existing], newOrderID: { "unused" })
        
        #expect(result?.order.customer.name == "老客戶")
        #expect(result?.order.orderSource == "蝦皮")
        #expect(result?.order.categories == ["舊類別"])
        #expect(result?.order.paymentMethod == "舊付款")
        #expect(result?.isNewOrder == false)
        #expect(result?.order.id == existing.id)
    }
    
    /// 新建時空白欄位使用預設值；付款方式保持空白
    @Test func newOrderUsesDefaultsWhenDraftFieldsAreEmpty() {
        var editState = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        editState.draft.customerName = ""
        editState.draft.orderSource = ""
        editState.draft.categories = []
        editState.draft.paymentMethod = ""
        
        let result = OrderDraft.resolveWriteResult(
            editState, existingOrders: [], newOrderID: { "GENID" })
        
        #expect(result?.order.customer.name == "未命名客戶")
        #expect(result?.order.customer.initials == "未命")
        #expect(result?.order.customer.tier == .new)
        #expect(result?.order.orderSource == "未指定")
        #expect(result?.order.categories == ["未分類"])
        #expect(result?.order.paymentMethod == "")
        #expect(result?.isNewOrder == true)
        #expect(result?.order.id == "BL-DRAFT-GENID")
    }
    
    /// 非無卡付款時，無卡金額歸零且清空對帳狀態
    @Test func nonCardlessPaymentMethodZeroesCardlessAmountsAndClearsReconciliationStatus() {
        var editState = OrderEditFeature.State(
            id: UUID(0),
            availablePaymentMethods: [
                PaymentMethodInfo(
                    name: "信用卡", isCardless: false, isBankTransfer: false, isCashOnDelivery: false)
            ],
            currentDate: TestDependencies.fixedNow
        )
        editState.draft.paymentMethod = "信用卡"
        editState.draft.cardlessDeductionAmount = 500
        editState.draft.cardlessSupplementAmount = 300
        editState.draft.reconciliationStatus = "已對帳"
        
        let result = OrderDraft.resolveWriteResult(
            editState, existingOrders: [], newOrderID: { "GENID" })
        
        #expect(result?.order.cardlessDeductionAmount == 0)
        #expect(result?.order.cardlessSupplementAmount == 0)
        #expect(result?.order.reconciliationStatus == "")
    }
    
    /// 無卡付款方式時，對帳狀態保留 (僅 trim)，無卡金額維持草稿值
    @Test func cardlessPaymentMethodPreservesCardlessAmountsAndReconciliationStatus() {
        var editState = OrderEditFeature.State(
            id: UUID(0),
            availablePaymentMethods: [
                PaymentMethodInfo(
                    name: "無卡存款", isCardless: true, isBankTransfer: false, isCashOnDelivery: false)
            ],
            currentDate: TestDependencies.fixedNow
        )
        editState.draft.paymentMethod = "無卡存款"
        editState.draft.chargedAmount = 1_000
        editState.draft.cardlessDeductionAmount = 500
        editState.draft.cardlessSupplementAmount = 300
        editState.draft.reconciliationStatus = " 已對帳 "
        
        let result = OrderDraft.resolveWriteResult(
            editState, existingOrders: [], newOrderID: { "GENID" })
        
        #expect(result?.order.cardlessDeductionAmount == 500)
        #expect(result?.order.cardlessSupplementAmount == 300)
        #expect(result?.order.reconciliationStatus == "已對帳")
    }
    
    /// 費率超過上限時被夾擠到 1，負值被夾擠到 0
    @Test func feeRatesAreClampedToUnitInterval() {
        var editState = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        editState.draft.cardFeeRate = 1.5
        editState.draft.platformFeeRate = -0.5
        editState.draft.paymentFeeRate = 2
        
        let result = OrderDraft.resolveWriteResult(
            editState, existingOrders: [], newOrderID: { "GENID" })
        
        #expect(result?.order.cardFeeRate == 1)
        #expect(result?.order.platformFeeRate == 0)
        #expect(result?.order.paymentFeeRate == 1)
    }
    
    /// 金額欄位為負值時被夾擠到 0
    @Test func negativeAmountsAreClampedToZero() {
        var editState = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        editState.draft.chargedAmount = -100
        editState.draft.itemCost = -50
        editState.draft.domesticShipping = -10
        editState.draft.internationalShipping = -20
        editState.draft.foreignDomesticShipping = -30
        
        let result = OrderDraft.resolveWriteResult(
            editState, existingOrders: [], newOrderID: { "GENID" })
        
        #expect(result?.order.chargedAmount == 0)
        #expect(result?.order.itemCost == 0)
        #expect(result?.order.domesticShipping == 0)
        #expect(result?.order.internationalShipping == 0)
        #expect(result?.order.foreignDomesticShipping == 0)
    }
    
    /// 合併草稿沿用主訂單的客戶縮寫與分級
    @Test func mergeDraftReusesPrimaryOrderCustomerInitialsAndTier() {
        let primary = Self.makeOrder(
            id: "BL-PRIMARY", customerName: "王小明", initials: "PP", tier: .vip)
        var editState = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        editState.draft.customerName = "王小明"
        editState.mergeSourceIDs = [primary.id]
        
        let result = OrderDraft.resolveWriteResult(
            editState, existingOrders: [primary], newOrderID: { "MERGEID" })
        
        #expect(result?.order.customer.name == "王小明")
        #expect(result?.order.customer.initials == "PP")
        #expect(result?.order.customer.tier == .vip)
        #expect(result?.order.mergedSourceIDs == [primary.id])
        #expect(result?.order.id == "BL-DRAFT-MERGEID")
    }
    
    /// 一般新單 (非合併) 客戶分級維持 `.new`，縮寫取自輸入名稱前兩碼
    @Test func plainNewOrderDerivesInitialsFromNameAndDefaultsToNewTier() {
        var editState = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        editState.draft.customerName = "陳大文"
        
        let result = OrderDraft.resolveWriteResult(
            editState, existingOrders: [], newOrderID: { "GENID" })
        
        #expect(result?.order.customer.initials == "陳大")
        #expect(result?.order.customer.tier == .new)
        #expect(result?.order.mergedSourceIDs == [])
    }
    
    /// 既有訂單且使用者確實增刪過照片、照片已完整載入時，才顯式寫入照片
    @Test func existingOrderWritesPhotosOnlyWhenLoadedAndEdited() {
        let existing = Self.makeOrder(id: "BL-001", customerName: "客戶")
        var editState = OrderEditFeature.State(
            original: existing, id: UUID(0), currentDate: TestDependencies.fixedNow)
        editState.draftPhotos = [Data([1, 2, 3])]
        editState.photoLoadPhase = .loaded
        editState.hasEditedPhotos = true
        
        let editedResult = OrderDraft.resolveWriteResult(
            editState, existingOrders: [existing], newOrderID: { "unused" })
        #expect(editedResult?.order.photos == [Data([1, 2, 3])])
        #expect(editedResult?.writesPhotos == true)
        
        editState.hasEditedPhotos = false
        let untouchedResult = OrderDraft.resolveWriteResult(
            editState, existingOrders: [existing], newOrderID: { "unused" })
        #expect(untouchedResult?.order.photos == [])
        #expect(untouchedResult?.writesPhotos == false)
    }
    
    /// 新建列 (含合併草稿) 一律帶入照片，不受 `hasEditedPhotos` 影響
    @Test func newOrderAlwaysWritesPhotosRegardlessOfEditedFlag() {
        var editState = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        editState.draftPhotos = [Data([9, 9, 9])]
        editState.hasEditedPhotos = false
        
        let result = OrderDraft.resolveWriteResult(
            editState, existingOrders: [], newOrderID: { "GENID" })
        
        #expect(result?.order.photos == [Data([9, 9, 9])])
        #expect(result?.writesPhotos == true)
        #expect(result?.isNewOrder == true)
    }
    
    /// 類別／開團陣列正規化：trim、去除空字串與重複 (保序)
    @Test func categoriesAndCampaignNamesAreNormalized() {
        var editState = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        editState.draft.categories = [" 美妝 ", "美妝", "", "服飾"]
        editState.draft.campaignNames = ["A團", " A團 ", "", "B團"]
        
        let result = OrderDraft.resolveWriteResult(
            editState, existingOrders: [], newOrderID: { "GENID" })
        
        #expect(result?.order.categories == ["美妝", "服飾"])
        #expect(result?.order.campaignNames == ["A團", "B團"])
    }
    
    /// 備註可清空並存回空字串
    @Test func notesClearedIsPersistedAsEmptyStringNotFallenBackToExistingValue() {
        let existing = Self.makeOrder(id: "BL-001", customerName: "客戶", notes: "舊備註")
        var editState = OrderEditFeature.State(
            original: existing, id: UUID(0), currentDate: TestDependencies.fixedNow)
        editState.draft.notes = "   "
        
        let result = OrderDraft.resolveWriteResult(
            editState, existingOrders: [existing], newOrderID: { "unused" })
        
        #expect(result?.order.notes == "")
    }
}

// MARK: - Private Method

private extension OrderDraftTests {
    
    /// 建立僅供草稿建構測試使用的最小訂單；非相關欄位以零值/佔位填入
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - customerName: 客戶名稱
    ///   - initials: 客戶縮寫
    ///   - tier: 客戶等級
    ///   - orderSource: 訂單來源
    ///   - categories: 商品類別
    ///   - paymentMethod: 付款方式
    ///   - notes: 備註
    /// - Returns: 建立的測試訂單
    static func makeOrder(
        id: String,
        customerName: String,
        initials: String = "XX",
        tier: CustomerTier = .regular,
        orderSource: String = "來源",
        categories: [String] = ["類別"],
        paymentMethod: String = "付款",
        notes: String = ""
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: customerName, initials: initials, tier: tier),
            status: .quoting,
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
            chargedAmount: 0,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: orderSource,
            categories: categories,
            paymentMethod: paymentMethod,
            notes: notes,
            reconciliationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }
}
