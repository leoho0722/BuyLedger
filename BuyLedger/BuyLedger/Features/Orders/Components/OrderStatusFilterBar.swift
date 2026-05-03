//
//  OrderStatusFilterBar.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import SwiftUI

/// 訂單列表使用的狀態篩選列。
struct OrderStatusFilterBar: View {
    
    // MARK: - View Properties
    
    /// 目前系統深淺色外觀。
    @Environment(\.colorScheme) private var colorScheme
    
    /// 目前選取的篩選。
    let selection: OrderStatusFilter
    
    /// 可選擇的篩選清單。
    let filters: [OrderStatusFilter]
    
    /// 使用者選取篩選時呼叫的 closure。
    let onSelect: (OrderStatusFilter) -> Void
    
    // MARK: - View Body
    
    /// 篩選列的畫面內容。
    var body: some View {
        let palette = BLTheme.palette(for: colorScheme)
        
        ViewThatFits(in: .horizontal) {
            filterRow(palette: palette)
                .fixedSize(horizontal: true, vertical: false)
            
            filterGrid(palette: palette)
        }
    }
}

// MARK: - ViewBuilder

private extension OrderStatusFilterBar {
    
    /// 單列呈現所有篩選項目。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 單列篩選 view。
    func filterRow(palette: BLPalette) -> some View {
        HStack(spacing: BLSpacing.small) {
            ForEach(filters) { filter in
                filterButton(filter, palette: palette)
            }
        }
    }
    
    /// 空間不足時換行呈現所有篩選項目。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 換行篩選 view。
    func filterGrid(palette: BLPalette) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: 64), spacing: BLSpacing.small, alignment: .leading)
            ],
            alignment: .leading,
            spacing: BLSpacing.small
        ) {
            ForEach(filters) { filter in
                filterButton(filter, palette: palette)
            }
        }
    }
    
    /// 建立單一狀態篩選按鈕。
    /// - Parameters:
    ///   - filter: 要顯示的狀態篩選。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: 狀態篩選按鈕 view。
    func filterButton(_ filter: OrderStatusFilter, palette: BLPalette) -> some View {
        let isSelected = selection == filter
        
        return Button {
            onSelect(filter)
        } label: {
            Text(filter.title)
                .font(.footnote.weight(.semibold))
                .lineLimit(1)
                .foregroundStyle(isSelected ? palette.background : palette.secondaryLabel)
                .padding(.vertical, 7)
                .padding(.horizontal, 12)
                .background(isSelected ? palette.label : palette.fillTertiary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("訂單狀態篩選") {
    OrderStatusFilterBar(
        selection: .shipping,
        filters: OrderStatusFilter.orderBrowsingCases
    ) { _ in }
        .padding()
}
