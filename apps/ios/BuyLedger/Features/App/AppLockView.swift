//
//  AppLockView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/31.
//

import ComposableArchitecture
import SwiftUI

/// 帳本鎖定時顯示的阻斷畫面
struct AppLockView: View {
    
    // MARK: - View Properties
    
    /// AppLockFeature 的 Store
    @Bindable var store: StoreOf<AppLockFeature>
    
    /// 依據螢幕尺寸縮放的圖示大小
    @ScaledMetric private var iconSize: CGFloat = 44
    
    // MARK: - View Body
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: iconSize))
                .foregroundStyle(Color.blSecondaryLabel)
            
            Text("帳本已鎖定")
                .blTextStyle(.title2)
            
            Text("請完成身份驗證以檢視內容。")
                .multilineTextAlignment(.center)
            
            if store.unlockDidFail {
                Text("驗證未完成，請再試一次。")
                    .blTextStyle(.footnote)
                    .foregroundStyle(BLTone.destructive.onSurface)
                    .multilineTextAlignment(.center)
            }
            
            Button(store.unlockButtonTitleKey) {
                store.send(.retryUnlockTapped)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier(BLAccessibilityID.AppLock.retryButton)
        }
        .padding(32)
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BLPalette().plainBackground)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(BLAccessibilityID.AppLock.root)
    }
}

// MARK: - Preview

#Preview {
    AppLockView(
        store: Store(
            initialState: AppLockFeature.State(
                isBiometricUnlockEnabled: true,
                isLocked: true,
                biometryType: .faceID
            )
        ) {
            AppLockFeature()
        }
    )
}
