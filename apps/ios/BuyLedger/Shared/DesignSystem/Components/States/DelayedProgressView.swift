//
//  DelayedProgressView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/21.
//

import ComposableArchitecture
import SwiftUI

/// 延遲出現的轉圈
///
/// 骨架已承擔「載入中」的視覺回饋，轉圈只在載入逾一秒後才疊加——
/// 快速載入時不閃現，慢速載入時仍提供進行中的訊號
struct DelayedProgressView: View {

    // MARK: - View Properties

    /// 轉圈是否已可見
    @State private var isVisible = false

    /// 延遲用的時鐘；測試可注入 immediate clock 使行為可控
    @Dependency(\.continuousClock) private var clock

    /// 疊加轉圈前的延遲秒數
    var delay: Duration = .seconds(1)

    // MARK: - View Body

    /// 延遲轉圈的畫面內容
    var body: some View {
        ZStack {
            if isVisible {
                ProgressView()
                    .controlSize(.regular)
            }
        }
        .task {
            try? await clock.sleep(for: delay)
            isVisible = true
        }
    }
}

// MARK: - Preview

#Preview("延遲轉圈") {
    DelayedProgressView(delay: .seconds(1))
}
