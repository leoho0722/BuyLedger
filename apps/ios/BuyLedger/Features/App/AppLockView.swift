//
//  AppLockView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/31.
//

import ComposableArchitecture
import SwiftUI

/// App 鎖定時顯示的阻斷畫面
struct AppLockView: View {

    // MARK: - View Properties

    /// AppLockFeature 的 Store
    @Bindable var store: StoreOf<AppLockFeature>

    /// 依據螢幕尺寸縮放的圖示大小
    @ScaledMetric private var iconSize: CGFloat = 44

    // MARK: - View Body

    /// App 鎖定畫面的 view body
    var body: some View {
        content
            .padding(32)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(BLPalette().plainBackground)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(BLAccessibilityID.AppLock.root)
    }
}

// MARK: - Private Views

private extension AppLockView {

    /// App 鎖定畫面的內容
    @ViewBuilder
    var content: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: iconSize))
                .foregroundStyle(Color.blSecondaryLabel)

            Text("App 已鎖定")
                .blTextStyle(.title2)

            Text("請完成身份驗證以繼續使用。")
                .multilineTextAlignment(.center)

            if store.unlockDidFail {
                failedMessage
            }

            retryButton
        }
    }

    /// 驗證失敗時顯示的訊息
    var failedMessage: some View {
        Text("驗證未完成，請再試一次。")
            .blTextStyle(.footnote)
            .foregroundStyle(BLTone.destructive.onSurface)
            .multilineTextAlignment(.center)
            .accessibilityIdentifier(BLAccessibilityID.AppLock.failedMessage)
    }

    /// 重新驗證按鈕
    var retryButton: some View {
        Button(store.unlockButtonTitleKey) {
            store.send(.retryUnlockTapped)
        }
        .buttonStyle(.borderedProminent)
        .disabled(store.isUnlocking)
        .accessibilityIdentifier(BLAccessibilityID.AppLock.retryButton)
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
