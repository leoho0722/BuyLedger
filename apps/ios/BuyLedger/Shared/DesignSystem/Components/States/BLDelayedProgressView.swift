//
//  BLDelayedProgressView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/21.
//

import SwiftUI

/// 延遲出現的轉圈
struct BLDelayedProgressView: View {

    // MARK: - Properties

    /// 轉圈是否已可見
    @State private var isVisible = false

    /// 疊加轉圈前的延遲秒數
    var delay: Duration = .seconds(1)

    // MARK: - Body

    /// 延遲轉圈的畫面內容
    var body: some View {
        progressContent
            .task {
                // 睡眠被取消或失敗時不顯示轉圈
                try? await Task.sleep(for: delay)
                guard !Task.isCancelled else { return }
                isVisible = true
            }
    }
}

// MARK: - Private Views

private extension BLDelayedProgressView {

    /// 延遲顯示進度指示器的內容
    var progressContent: some View {
        ZStack {
            if isVisible {
                ProgressView()
                    .controlSize(.regular)
            }
        }
    }
}

// MARK: - Preview

#Preview("延遲轉圈") {
    BLDelayedProgressView(delay: .seconds(1))
}
