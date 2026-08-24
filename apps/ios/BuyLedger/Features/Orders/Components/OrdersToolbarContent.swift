//
//  OrdersToolbarContent.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/31.
//

import ComposableArchitecture
import SwiftUI

/// 訂單清單的多選工具列，供 compact 與 regular 版面共用
struct OrdersToolbarContent: ToolbarContent {
    
    // MARK: - View Properties
    
    /// 訂單功能 store
    let store: StoreOf<OrdersFeature>
    
    /// 目前外觀使用的色盤
    let palette: BLPalette
    
    /// 套用篩選後的訂單 ID，用於顯示筆數與判斷全選
    let filteredIDs: [LedgerOrder.ID]
    
    /// 目前是否已全選 `filteredIDs`；由呼叫端計算後傳入
    let allFilteredSelected: Bool
    
    // MARK: - Toolbar Content Body
    
    /// 顯示多選或一般模式的工具列
    var body: some ToolbarContent {
        if store.isSelecting {
            ToolbarItem(placement: .topBarLeading) {
                Button(LocalizedStringKey(allFilteredSelected ? "清除" : "全選")) {
                    store.send(allFilteredSelected ? .clearSelectionTapped : .selectAllTapped)
                }
            }
            
            // 批次操作放在頂部，避免可拖曳視窗遮住 bottomBar
            // 選取筆數由導覽標題顯示。
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    // 「已合併」僅能由合併流程寫入，批次目標清單一律排除
                    ForEach(OrderStatus.allCases.filter { $0 != .merged }) { status in
                        Button(LocalizedStringKey(status.title)) {
                            store.send(.batchStatusChanged(status))
                        }
                    }
                } label: {
                    Text("更改狀態")
                }
                .disabled(store.selectedOrderIDs.isEmpty)
                
                Button("完成") {
                    store.send(.selectionModeToggled)
                }
            }
        } else {
            ToolbarItem(placement: .topBarLeading) {
                Text("\(filteredIDs.count)")
                    .font(BLTypographyStyle.subhead.font.weight(.medium))
                    .monospacedDigit()
                    .foregroundStyle(palette.secondaryLabel)
            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    Button {
                        store.send(.aiSummaryTapped)
                    } label: {
                        Label("AI 總結", systemImage: "sparkles")
                    }
                    .disabled(filteredIDs.isEmpty)
                    .accessibilityIdentifier(BLAccessibilityID.Orders.aiSummaryButton)
                    
                    Button {
                        store.send(.selectionModeToggled)
                    } label: {
                        Label("選取訂單", systemImage: "checklist")
                    }
                    .disabled(store.orders.isEmpty)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("更多操作")
                .accessibilityIdentifier(BLAccessibilityID.Orders.batchMenuButton)
                
                Button {
                    store.send(.newOrderTapped)
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("新增訂單")
                .accessibilityIdentifier(BLAccessibilityID.Orders.addButton)
            }
        }
    }
}
