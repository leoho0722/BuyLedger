//
//  OrderSelectableRow.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/31.
//

import ComposableArchitecture
import SwiftUI

/// 訂單清單多選模式下的可勾選列，供 compact 與 regular 版面共用
struct OrderSelectableRow: View {
    
    // MARK: - View Properties
    
    /// 要呈現的訂單
    let order: LedgerOrder
    
    /// 是否顯示訂購日期
    var showsDate: Bool = true
    
    /// 目前外觀使用的色盤
    let palette: BLPalette
    
    /// 訂單功能 store
    let store: StoreOf<OrdersFeature>
    
    // MARK: - View Body
    
    /// 可勾選的訂單列內容
    var body: some View {
        let isSelected = store.selectedOrderIDs.contains(order.id)
        
        Button {
            store.send(.orderSelectionToggled(order.id))
        } label: {
            HStack(spacing: BLSpacing.medium) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                // 保持圖示為一般字重。
                    .font(.title3)
                    .foregroundStyle(isSelected ? palette.accent : palette.tertiaryLabel)
                    .accessibilityHidden(true)
                
                OrderRowView(order: order, showsDate: showsDate)
                    .accessibilityIdentifier(BLAccessibilityID.Orders.row(orderID: order.id))
            }
            .padding(.horizontal, BLSpacing.large)
            .padding(.vertical, BLSpacing.extraSmall)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview("可勾選訂單列") {
    List {
        OrderSelectableRow(
            order: LedgerOrder.sampleOrders[0],
            palette: BLPalette(),
            store: Store(initialState: OrdersFeature.State()) {
                OrdersFeature()
            }
        )
    }
}
