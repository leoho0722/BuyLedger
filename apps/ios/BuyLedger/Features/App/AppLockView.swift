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

    // MARK: - Properties

    /// 提供辨識類型與驗證狀態，並接收重新驗證操作的 Store
    @Bindable var store: StoreOf<AppLockFeature>

    /// 隨 Dynamic Type 文字大小縮放的鎖頭圖示大小
    @ScaledMetric private var iconSize: CGFloat = 44

    // MARK: - Body

    /// 鎖定畫面的骨架：內容置中並限寬 520，背景鋪滿整個畫面
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
        Button(AppLockFormatters.unlockTitle(for: store.biometryType)) {
            store.send(.view(.retryUnlockTapped))
        }
        .buttonStyle(.borderedProminent)
        .disabled(store.isUnlocking)
        .accessibilityIdentifier(BLAccessibilityID.AppLock.retryButton)
    }
}

// MARK: - Preview

#Preview("Face ID 鎖定") {
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

#Preview("Touch ID 鎖定") {
    AppLockView(
        store: Store(
            initialState: AppLockFeature.State(
                isBiometricUnlockEnabled: true,
                isLocked: true,
                biometryType: .touchID
            )
        ) {
            AppLockFeature()
        }
    )
}

#Preview("裝置密碼鎖定") {
    AppLockView(
        store: Store(
            initialState: AppLockFeature.State(
                isBiometricUnlockEnabled: true,
                isLocked: true,
                biometryType: .unavailable
            )
        ) {
            AppLockFeature()
        }
    )
}

#Preview("驗證失敗") {
    AppLockView(
        store: Store(
            initialState: AppLockFeature.State(
                isBiometricUnlockEnabled: true,
                isLocked: true,
                unlockDidFail: true,
                biometryType: .faceID
            )
        ) {
            AppLockFeature()
        }
    )
}
