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

    /// 提供復原階段與失敗原因，並接收復原操作的 Store
    @Bindable var store: StoreOf<PersistenceFailureFeature>

    /// 隨 Dynamic Type 文字大小縮放的圖示大小
    @ScaledMetric private var iconSize: CGFloat = 44

    // MARK: - Body

    /// 持久層阻斷畫面的骨架：內容置中並限寬 520，背景鋪滿整個畫面，復原確認以 alert 呈現
    var body: some View {
        content
            .padding(32)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(palette.plainBackground)
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
                .foregroundStyle(store.phase == .blocked ? palette.red : palette.green)

            Text(store.phase == .blocked ? "資料無法開啟" : "備份已保留")
                .blTextStyle(.title2)

            if store.phase == .blocked {
                blockedDetail
            } else {
                Text("請關閉 App 後重新開啟。App 會建立一個空白資料庫供你繼續使用。")
                    .multilineTextAlignment(.center)
            }
        }
    }

    /// 尚未復原時的說明、失敗原因與復原入口
    @ViewBuilder
    var blockedDetail: some View {
        Text("帳本資料目前無法開啟。原始資料仍完整保留在這台裝置上。請勿新增或修改資料，以免資料只留在暫存記憶體中。")
            .multilineTextAlignment(.center)

        if let recoveryFailureReason = store.recoveryFailureReason {
            Text(recoveryFailureReason)
                .blTextStyle(.footnote)
                .foregroundStyle(palette.red)
                .multilineTextAlignment(.center)
        }

        Button("改用空白資料庫繼續", role: .destructive) {
            store.send(.view(.recoveryTapped))
        }
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier(BLAccessibilityID.PersistenceFailure.recoveryButton)
    }
}

// MARK: - Private Method

private extension PersistenceFailureView {

    /// 目前外觀使用的色盤
    var palette: BLPalette {
        BLPalette()
    }

    /// 依復原階段顯示阻斷或備份完成的圖示
    var iconName: String {
        if store.phase == .blocked {
            return "externaldrive.badge.exclamationmark"
        }
        return "externaldrive.badge.checkmark"
    }
}

// MARK: - Preview

#Preview("資料無法開啟") {
    PersistenceFailureView(
        store: Store(initialState: PersistenceFailureFeature.State()) {
            PersistenceFailureFeature()
        }
    )
}

#Preview("備份已保留") {
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
