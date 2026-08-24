//
//  BLLoadFailureView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/20.
//

import SwiftUI

/// 資料載入失敗時的狀態畫面：失敗原因加上重試控制項
struct BLLoadFailureView: View {
    
    // MARK: - View Properties
    
    /// 描述失敗原因的訊息
    let message: String
    
    /// 重試鍵的 accessibility identifier
    /// `nil` 表示呼叫端不需單獨定位這顆按鈕
    var retryIdentifier: String? = nil
    
    /// 點擊重試時的 callback
    let onRetry: () -> Void
    
    // MARK: - View Body
    
    /// 失敗狀態的畫面內容
    var body: some View {
        ContentUnavailableView {
            Label("無法載入資料", systemImage: "exclamationmark.triangle")
        } description: {
            // 訊息是 reducer 給的固定中文詞，須經 catalog 解析、不可 verbatim
            Text(LocalizedStringKey(message))
        } actions: {
            retryButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // 保留重試鍵的 identifier，避免被外層容器合併。
        .accessibilityElement(children: .contain)
    }
}

// MARK: - ViewBuilder

private extension BLLoadFailureView {
    
    /// 重試按鈕；未指定時不掛 identifier
    @ViewBuilder
    var retryButton: some View {
        let button = Button("重試", action: onRetry)
            .buttonStyle(.borderedProminent)
        
        if let retryIdentifier {
            button.accessibilityIdentifier(retryIdentifier)
        } else {
            button
        }
    }
}

// MARK: - Preview

#Preview("載入失敗") {
    BLLoadFailureView(message: "訂單載入失敗，請稍後再試。") {}
}
