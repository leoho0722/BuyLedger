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

    // MARK: - Properties

    /// 隨 Dynamic Type 文字大小縮放的圖示大小
    @ScaledMetric private var iconSize: CGFloat = 44

    /// 提供復原階段與失敗原因，並接收復原操作的 Store
    @Bindable var store: StoreOf<PersistenceFailureFeature>

    // MARK: - Body

    /// 持久層阻斷畫面的骨架：內容置中並限寬 520，背景鋪滿整個畫面，復原確認以 alert 呈現
    var body: some View {
        content
            .padding(32)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.blPlainBackground)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(BLAccessibilityID.PersistenceFailure.root)
            .alert($store.scope(state: \.destination, action: \.destination).alert)
    }
}

// MARK: - Private Views

private extension PersistenceFailureView {

    /// 阻斷畫面的內容：圖示、標題，以及依復原階段切換的說明
    @ViewBuilder
    var content: some View {
        VStack(spacing: 20) {
            Image(systemName: iconName)
                .font(.system(size: iconSize))
                .foregroundStyle(store.phase == .blocked ? .blRed : .blGreen)

            Text(
                store.phase == .blocked
                    ? "common.general.label.unableOpenData"
                    : "common.general.label.backupKept"
            )
            .blTextStyle(.title2)

            if store.phase == .blocked {
                blockedDetail
            } else {
                Text("common.general.message.closeReopenApp")
                    .multilineTextAlignment(.center)
            }
        }
    }

    /// 尚未復原時的說明、失敗原因與復原入口
    @ViewBuilder
    var blockedDetail: some View {
        Text("common.general.message.ledgerDataCannot")
            .multilineTextAlignment(.center)

        if let recoveryFailureReason = store.recoveryFailureReason {
            Text(recoveryFailureReason)
                .blTextStyle(.footnote)
                .foregroundStyle(.blRed)
                .multilineTextAlignment(.center)
        }

        Button("common.general.label.continueBlankDatabase", role: .destructive) {
            store.send(.view(.recoveryTapped))
        }
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier(BLAccessibilityID.PersistenceFailure.recoveryButton)
    }
}

// MARK: - Private Method

private extension PersistenceFailureView {

    /// 依復原階段顯示阻斷或備份完成的圖示
    var iconName: String {
        if store.phase == .blocked {
            return "externaldrive.badge.exclamationmark"
        }
        return "externaldrive.badge.checkmark"
    }
}

// MARK: - Preview

#Preview("common.general.label.unableOpenData") {
    PersistenceFailureView(
        store: Store(initialState: PersistenceFailureFeature.State()) {
            PersistenceFailureFeature()
        }
    )
}

#Preview("common.general.label.backupKept") {
    var state = PersistenceFailureFeature.State()
    state.phase = .relaunchRequired

    return PersistenceFailureView(
        store: Store(initialState: state) {
            PersistenceFailureFeature()
        }
    )
}

#Preview("復原失敗") {
    var state = PersistenceFailureFeature.State()
    state.recoveryFailureReason = "磁碟空間不足，無法搬移備份"

    return PersistenceFailureView(
        store: Store(initialState: state) {
            PersistenceFailureFeature()
        }
    )
}
