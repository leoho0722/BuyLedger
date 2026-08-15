//
//  PersistenceFailureView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/26.
//

import ComposableArchitecture
import SwiftUI

/// 持久層失敗時顯示的阻斷畫面
struct PersistenceFailureView: View {
    
    // MARK: - View Properties
    
    /// PersistenceFailureFeature 的 Store
    @Bindable var store: StoreOf<PersistenceFailureFeature>
    
    /// 依據螢幕尺寸縮放的圖示大小
    @ScaledMetric private var iconSize: CGFloat = 44
    
    /// 根據 phase 顯示對應圖示
    private var iconName: String {
        store.phase == .blocked ? "externaldrive.badge.exclamationmark" : "externaldrive.badge.checkmark"
    }
    
    // MARK: - View Body
    
    var body: some View {
        let palette = BLPalette()
        
        VStack(spacing: 20) {
            Image(systemName: iconName)
            .font(.system(size: iconSize))
            .foregroundStyle(store.phase == .blocked ? palette.red : palette.green)
            
            Text(store.phase == .blocked ? "資料無法開啟" : "備份已保留")
                .blTextStyle(.title2)
            
            if store.phase == .blocked {
                Text("帳本資料目前無法開啟。原始資料仍完整保留在這台裝置上。請勿新增或修改資料，以免資料只留在暫存記憶體中。")
                    .multilineTextAlignment(.center)
                
                if let recoveryFailureReason = store.recoveryFailureReason {
                    Text(recoveryFailureReason)
                        .blTextStyle(.footnote)
                        .foregroundStyle(palette.red)
                        .multilineTextAlignment(.center)
                }
                
                Button("改用空白資料庫繼續", role: .destructive) {
                    store.send(.recoveryTapped)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier(BLAccessibilityID.PersistenceFailure.recoveryButton)
            } else {
                Text("請關閉 App 後重新開啟。App 會建立一個空白資料庫供你繼續使用。")
                    .multilineTextAlignment(.center)
            }
        }
        .padding(32)
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.plainBackground)
        .alert($store.scope(state: \.confirmation, action: \.confirmation))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(BLAccessibilityID.PersistenceFailure.root)
    }
}

// MARK: - Preview

#Preview {
    PersistenceFailureView(
        store: Store(initialState: PersistenceFailureFeature.State()) {
            PersistenceFailureFeature()
        }
    )
}
