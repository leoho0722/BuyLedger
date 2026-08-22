//
//  OrderDraft.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/8/2.
//

import ComposableArchitecture
import Foundation

/// 訂單編輯表單的草稿值型別
@ObservableState
struct OrderDraft: Equatable, Sendable {
    
    // MARK: - Data Properties
    
    /// 客戶名稱草稿
    var customerName: String
    
    /// 訂單來源草稿
    var orderSource: String
    
    /// 商品類別草稿；一般編輯單選，合併時可多選
    var categories: [String]
    
    /// 訂單狀態草稿
    var status: OrderStatus
    
    /// 商品幣別草稿
    var currency: CurrencyCode
    
    /// 客戶收款金額草稿 (新台幣)
    var chargedAmount: Decimal
    
    /// 無卡折抵金額；不可超過實付金額
    var cardlessDeductionAmount: Decimal
    
    /// 無卡補款金額草稿 (TWD)
    var cardlessSupplementAmount: Decimal
    
    /// 商品折合 TWD 後的成本草稿
    var itemCost: Decimal
    
    /// 國內運費草稿 (TWD)
    var domesticShipping: Decimal
    
    /// 國際運費草稿 (TWD)
    var internationalShipping: Decimal
    
    /// 外國國內運費草稿 (TWD)
    var foreignDomesticShipping: Decimal
    
    /// 刷卡手續費比例草稿 (0–1，例如 0.015 = 1.5%)
    var cardFeeRate: Decimal
    
    /// 平台手續費比例草稿 (0–1，例如 0.03 = 3%)
    var platformFeeRate: Decimal
    
    /// 金流手續費比例草稿 (0–1)
    var paymentFeeRate: Decimal
    
    /// 商品明細草稿；可在編輯表單內新增、刪除、修改
    var items: [LedgerOrderItem]
    
    /// 訂單備註草稿；對應 ``LedgerOrder/notes``，留空代表無備註
    var notes: String
    
    /// 訂購日期草稿
    var date: Date
    
    /// 付款方式草稿
    var paymentMethod: String
    
    /// 對帳狀態草稿；僅在無卡或銀行匯款付款方式下於 UI 顯示與編輯
    var reconciliationStatus: String
    
    /// 歸屬開團名稱草稿；空陣列代表未歸團 (散單)
    var campaignNames: [String]
    
    /// 收款狀態草稿 (待收款／已收款)
    var paymentReceiptStatus: PaymentReceiptStatus
    
    // MARK: - Init
    
    /// 依原始訂單建立草稿；`original` 為 `nil` 時各欄位採新訂單預設值
    /// - Parameters:
    ///   - original: 要編輯的訂單；`nil` 表示新訂單
    ///   - currentDate: 新訂單的預設日期
    init(original: LedgerOrder?, currentDate: Date) {
        self.customerName = original?.customer.name ?? ""
        self.orderSource = original?.orderSource ?? ""
        self.categories = original?.categories ?? []
        self.status = original?.status ?? .quoting
        self.currency = original?.currency ?? .twd
        self.chargedAmount = original?.chargedAmount ?? 0
        // 載入時把折抵金額限制在實付金額內。
        let originalCardlessDeduction = original?.cardlessDeductionAmount ?? 0
        self.cardlessDeductionAmount = min(
            originalCardlessDeduction, max(0, original?.chargedAmount ?? 0)
        )
        self.cardlessSupplementAmount = original?.cardlessSupplementAmount ?? 0
        self.itemCost = original?.itemCost ?? 0
        self.domesticShipping = original?.domesticShipping ?? 0
        self.internationalShipping = original?.internationalShipping ?? 0
        self.foreignDomesticShipping = original?.foreignDomesticShipping ?? 0
        self.cardFeeRate = original?.cardFeeRate ?? 0
        self.platformFeeRate = original?.platformFeeRate ?? 0
        self.paymentFeeRate = original?.paymentFeeRate ?? 0
        self.items = original?.items ?? []
        self.notes = original?.notes ?? ""
        self.date = original?.date ?? currentDate
        self.paymentMethod = original?.paymentMethod ?? ""
        self.reconciliationStatus = original?.reconciliationStatus ?? ""
        self.campaignNames = original?.campaignNames ?? []
        self.paymentReceiptStatus = original?.paymentReceiptStatus ?? .pending
    }
}

// MARK: - Nested Types

extension OrderDraft {
    
    /// ``resolveWriteResult(_:existingOrders:newOrderID:)`` 的計算結果
    struct WriteResult {
        
        // MARK: - Data Properties
        
        /// 套用後的訂單
        let order: LedgerOrder
        
        /// 是否為新建列 (插入分支，一律寫入照片)
        let isNewOrder: Bool
        
        /// 是否應寫入照片；只有既有訂單且照片曾變更時為 true
        let writesPhotos: Bool
    }
}

// MARK: - Internal Method

extension OrderDraft {
    
    /// 依草稿與訂單清單計算寫入結果
    /// - Parameters:
    ///   - editState: 編輯表單狀態
    ///   - existingOrders: 用於比對既有訂單與合併主訂單客戶
    ///   - newOrderID: 新訂單的編號產生器
    /// - Returns: 套用後的訂單、是否為新建列、以及是否應顯式寫入照片
    static func resolveWriteResult(
        _ editState: OrderEditFeature.State,
        existingOrders: [LedgerOrder],
        newOrderID: () -> String
    ) -> WriteResult? {
        if let original = editState.original,
           let existing = existingOrders.first(where: { $0.id == original.id }) {
            // 照片完成載入且有變更時才寫入，避免覆蓋既有照片。
            let writesPhotos = editState.photoLoadPhase == .loaded && editState.hasEditedPhotos
            let order = editState.draft.makeOrder(
                existingOrder: existing,
                mergePrimaryCustomer: nil,
                draftPhotos: editState.draftPhotos,
                writesPhotos: writesPhotos,
                mergeSourceIDs: editState.mergeSourceIDs,
                newOrderID: newOrderID
            )
            return WriteResult(
                order: order.applyingPaymentMethodFlags(
                    flags: PaymentMethodFlags(
                        isCardless: editState.isSelectedPaymentMethodCardless,
                        isBankTransfer: editState.isSelectedPaymentMethodBankTransfer,
                        isCashOnDelivery: editState.isSelectedPaymentMethodCOD
                    )
                ),
                isNewOrder: false,
                writesPhotos: writesPhotos
            )
        } else {
            let mergePrimaryCustomer = editState.mergeSourceIDs.first
                .flatMap { primaryID in existingOrders.first { $0.id == primaryID }?.customer }
            let order = editState.draft.makeOrder(
                existingOrder: nil,
                mergePrimaryCustomer: mergePrimaryCustomer,
                draftPhotos: editState.draftPhotos,
                writesPhotos: true,
                mergeSourceIDs: editState.mergeSourceIDs,
                newOrderID: newOrderID
            )
            // 新建訂單走插入分支，因此一定寫入照片
            return WriteResult(
                order: order.applyingPaymentMethodFlags(
                    flags: PaymentMethodFlags(
                        isCardless: editState.isSelectedPaymentMethodCardless,
                        isBankTransfer: editState.isSelectedPaymentMethodBankTransfer,
                        isCashOnDelivery: editState.isSelectedPaymentMethodCOD
                    )
                ),
                isNewOrder: true,
                writesPhotos: true
            )
        }
    }
    
    /// 套用寫入結果到 state
    /// - Parameters:
    ///   - result: 寫入結果
    ///   - state: 將被修改的 ``OrdersFeature/State``
    static func applyWriteResult(
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
    
    /// 將編輯草稿套用到訂單清單
    /// - Parameters:
    ///   - editState: 編輯表單狀態
    ///   - state: 將被修改的 ``OrdersFeature/State``
    ///   - newOrderID: 新建列時使用的編號產生器
    /// - Returns: 套用後的訂單與是否為新建列
    @discardableResult
    static func applyEditDraft(
        _ editState: OrderEditFeature.State,
        to state: inout OrdersFeature.State,
        newOrderID: () -> String
    ) -> WriteResult? {
        guard let result = resolveWriteResult(
                editState, existingOrders: state.orders, newOrderID: newOrderID
        ) else {
            return nil
        }
        applyWriteResult((order: result.order, isNewOrder: result.isNewOrder), to: &state)
        return result
    }
}

// MARK: - Private Method

private extension OrderDraft {
    
    /// 依草稿與編輯情境建立訂單
    /// - Parameters:
    ///   - existingOrder: 正在編輯的既有訂單；`nil` 代表新建列
    ///   - mergePrimaryCustomer: 合併時沿用的主訂單客戶
    ///   - draftPhotos: 表單目前的照片草稿
    ///   - writesPhotos: 既有訂單是否寫入照片；新訂單一律帶入 `draftPhotos`
    ///   - mergeSourceIDs: 合併來源訂單編號
    ///   - newOrderID: 新訂單的編號產生器
    /// - Returns: 尚未套用付款方式旗標的訂單
    func makeOrder(
        existingOrder: LedgerOrder?,
        mergePrimaryCustomer: LedgerCustomer?,
        draftPhotos: [Data],
        writesPhotos: Bool,
        mergeSourceIDs: [LedgerOrder.ID],
        newOrderID: () -> String
    ) -> LedgerOrder {
        let trimmedName = customerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedOrderSource = orderSource.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedCategories = Self.normalizedNames(categories)
        let trimmedPaymentMethod = paymentMethod.trimmingCharacters(in: .whitespacesAndNewlines)
        // 備註只清除首尾空白，保留內部換行
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedCampaignNames = Self.normalizedNames(campaignNames)
        
        let normalizedAmount = max(0, chargedAmount)
        let normalizedItemCost = max(0, itemCost)
        let normalizedDom = max(0, domesticShipping)
        let normalizedIntl = max(0, internationalShipping)
        let normalizedForeignDom = max(0, foreignDomesticShipping)
        let normalizedCardFee = Self.clampRate(cardFeeRate)
        let normalizedPlatformFee = Self.clampRate(platformFeeRate)
        let normalizedPaymentFee = Self.clampRate(paymentFeeRate)
        
        if let existingOrder {
            let updatedCustomer = LedgerCustomer(
                name: trimmedName.isEmpty ? existingOrder.customer.name : trimmedName,
                initials: existingOrder.customer.initials,
                tier: existingOrder.customer.tier
            )
            
            // 未寫入照片時，in-memory 訂單維持空陣列
            return LedgerOrder(
                id: existingOrder.id,
                customer: updatedCustomer,
                status: status,
                currency: currency,
                date: date,
                items: items,
                itemCost: normalizedItemCost,
                domesticShipping: normalizedDom,
                internationalShipping: normalizedIntl,
                foreignDomesticShipping: normalizedForeignDom,
                cardFeeRate: normalizedCardFee,
                platformFeeRate: normalizedPlatformFee,
                paymentFeeRate: normalizedPaymentFee,
                chargedAmount: normalizedAmount,
                cardlessDeductionAmount: cardlessDeductionAmount,
                cardlessSupplementAmount: cardlessSupplementAmount,
                orderSource: trimmedOrderSource.isEmpty
                ? existingOrder.orderSource : trimmedOrderSource,
                categories: normalizedCategories.isEmpty
                ? existingOrder.categories : normalizedCategories,
                paymentMethod: trimmedPaymentMethod.isEmpty
                ? existingOrder.paymentMethod : trimmedPaymentMethod,
                notes: trimmedNotes,
                reconciliationStatus: reconciliationStatus,
                campaignNames: normalizedCampaignNames,
                paymentReceiptStatus: paymentReceiptStatus,
                isCashOnDelivery: false,
                photos: writesPhotos ? draftPhotos : [],
                mergedSourceIDs: existingOrder.mergedSourceIDs
            )
        } else {
            let resolvedName = trimmedName.isEmpty ? "未命名客戶" : trimmedName
            let resolvedOrderSource = trimmedOrderSource.isEmpty ? "未指定" : trimmedOrderSource
            let resolvedCategories = normalizedCategories.isEmpty ? ["未分類"] : normalizedCategories
            let initials = String(resolvedName.prefix(2)).uppercased()
            
            // 合併草稿沿用主訂單客戶，一般新訂單維持 .new。
            let resolvedCustomer =
            mergePrimaryCustomer.map {
                LedgerCustomer(name: resolvedName, initials: $0.initials, tier: $0.tier)
            } ?? LedgerCustomer(name: resolvedName, initials: initials, tier: .new)
            
            // 使用完整隨機識別碼；顯示短碼由 displayID 產生
            return LedgerOrder(
                id: "BL-DRAFT-\(newOrderID())",
                customer: resolvedCustomer,
                status: status,
                currency: currency,
                date: date,
                items: items,
                itemCost: normalizedItemCost,
                domesticShipping: normalizedDom,
                internationalShipping: normalizedIntl,
                foreignDomesticShipping: normalizedForeignDom,
                cardFeeRate: normalizedCardFee,
                platformFeeRate: normalizedPlatformFee,
                paymentFeeRate: normalizedPaymentFee,
                chargedAmount: normalizedAmount,
                cardlessDeductionAmount: cardlessDeductionAmount,
                cardlessSupplementAmount: cardlessSupplementAmount,
                orderSource: resolvedOrderSource,
                categories: resolvedCategories,
                paymentMethod: trimmedPaymentMethod,
                notes: trimmedNotes,
                reconciliationStatus: reconciliationStatus,
                campaignNames: normalizedCampaignNames,
                paymentReceiptStatus: paymentReceiptStatus,
                isCashOnDelivery: false,
                photos: draftPhotos,
                mergedSourceIDs: mergeSourceIDs
            )
        }
    }
    
    /// 將手續費比例 clamp 到 `[0, 1]` 區間，避免介面誤輸入造成損益失真
    /// - Parameter value: 待 clamp 的比例
    /// - Returns: clamp 後的比例
    static func clampRate(_ value: Decimal) -> Decimal {
        max(0, min(1, value))
    }
    
    /// 將草稿名稱陣列正規化：逐元素 trim、去除空字串與重複 (保序)
    /// - Parameter names: 草稿陣列 (類別或開團)
    /// - Returns: 正規化後的名稱陣列
    static func normalizedNames(_ names: [String]) -> [String] {
        var seen = Set<String>()
        return names
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && seen.insert($0).inserted }
    }
}
