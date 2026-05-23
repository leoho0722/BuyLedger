//
//  OrderEditFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import Foundation

/// 編輯或新增訂單表單的功能。
///
/// 本切片僅建立 sheet 流程骨架：state 持有原始訂單（`nil` 視為新訂單）與草稿欄位，`saveTapped` 與 `cancelTapped` 都僅觸發 dismiss，不寫回資料。實際的儲存邏輯會在後續切片補上。
@Reducer
struct OrderEditFeature {
    
    // MARK: - State
    
    /// 編輯/新增訂單表單的狀態。
    @ObservableState
    struct State: Equatable, Identifiable, @unchecked Sendable {
        
        /// 原始訂單；`nil` 代表「新訂單」流程。
        let original: LedgerOrder?
        
        /// 客戶名稱草稿。
        var draftCustomerName: String
        
        /// 商品類別草稿。
        var draftCategory: String
        
        /// 訂單狀態草稿。
        var draftStatus: OrderStatus
        
        /// 商品幣別草稿。
        var draftCurrency: CurrencyCode
        
        /// 客戶收款金額草稿（新台幣）。
        var draftChargedAmount: Decimal
        
        /// 商品折合 TWD 後的成本草稿。
        var draftItemCost: Decimal
        
        /// 國內運費草稿（TWD）。
        var draftDomesticShipping: Decimal
        
        /// 國際集運草稿（TWD）。
        var draftInternationalShipping: Decimal
        
        /// 刷卡手續費比例草稿（0–1，例如 0.015 = 1.5%）。
        var draftCardFeeRate: Decimal
        
        /// 平台手續費比例草稿（0–1，例如 0.03 = 3%）。
        var draftPlatformFeeRate: Decimal
        
        /// 商品明細草稿；可在編輯表單內新增、刪除、修改。
        var draftItems: [LedgerOrderItem]

        /// 可供選擇的商品類別清單；由父層 reducer 從現有訂單聚合後注入，並在使用者新增類別時即時擴充。
        var availableCategories: [String]

        // MARK: - Identifiable Properties

        /// 表單 instance 的穩定識別值，供 SwiftUI sheet item 使用。
        let id: UUID

        // MARK: - Init

        /// 依原始訂單建立草稿狀態。
        /// - Parameters:
        ///   - original: 要編輯的訂單；`nil` 表示新訂單。
        ///   - availableCategories: 表單可選用的既有類別；不含原訂單類別時會在初始化時補上。
        init(original: LedgerOrder? = nil, availableCategories: [String] = []) {
            self.original = original
            self.draftCustomerName = original?.customer.name ?? ""
            self.draftCategory = original?.category ?? ""
            self.draftStatus = original?.status ?? .quoting
            self.draftCurrency = original?.currency ?? .twd
            self.draftChargedAmount = original?.chargedAmount ?? 0
            self.draftItemCost = original?.itemCost ?? 0
            self.draftDomesticShipping = original?.domesticShipping ?? 0
            self.draftInternationalShipping = original?.internationalShipping ?? 0
            self.draftCardFeeRate = original?.cardFeeRate ?? 0
            self.draftPlatformFeeRate = original?.platformFeeRate ?? 0
            self.draftItems = original?.items ?? []

            var categories = availableCategories
            let originalCategory = original?.category.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !originalCategory.isEmpty, !categories.contains(originalCategory) {
                categories.append(originalCategory)
            }
            self.availableCategories = categories.sorted { $0.localizedStandardCompare($1) == .orderedAscending }

            self.id = UUID()
        }
    }
    
    // MARK: - Action
    
    /// 表單可處理的事件。
    @CasePathable
    enum Action: BindableAction, Equatable {
        
        /// SwiftUI 雙向繫結事件。
        case binding(BindingAction<State>)
        
        /// 使用者按下取消。
        case cancelTapped

        /// 使用者按下儲存。
        case saveTapped

        /// 使用者透過「新增類別」彈窗確認新增一筆類別名稱。
        case addCategoryTapped(String)
    }
    
    // MARK: - Dependency Properties
    
    /// 由父層注入的 dismiss effect。
    @Dependency(\.dismiss) private var dismiss
    
    // MARK: - Reducer Body
    
    /// 表單 reducer。
    var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .cancelTapped, .saveTapped:
                return .run { _ in await dismiss() }

            case let .addCategoryTapped(rawName):
                let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return .none }

                if !state.availableCategories.contains(trimmed) {
                    var updated = state.availableCategories
                    updated.append(trimmed)
                    state.availableCategories = updated.sorted {
                        $0.localizedStandardCompare($1) == .orderedAscending
                    }
                }
                state.draftCategory = trimmed
                return .none
            }
        }
    }
}
