//
//  BLDelayedProgressView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/21.
//

import ComposableArchitecture
import SwiftUI

/// 延遲出現的轉圈
struct BLDelayedProgressView: View {
    
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
            do {
                try await clock.sleep(for: delay)
                isVisible = true
            } catch is CancellationError {
                return
            } catch {
                return
            }
        }
    }
}

// MARK: - Preview

#Preview("延遲轉圈") {
    BLDelayedProgressView(delay: .seconds(1))
}
