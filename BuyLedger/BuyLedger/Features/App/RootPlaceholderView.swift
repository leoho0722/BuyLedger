//
//  RootPlaceholderView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import SwiftUI

/// 尚未進入實作切片的分頁佔位畫面。
struct RootPlaceholderView: View {

    // MARK: - View Properties

    /// 佔位畫面對應的分頁。
    let tab: RootTab

    // MARK: - View Body

    /// 佔位畫面的內容。
    var body: some View {
        ContentUnavailableView(
            "\(tab.title)尚未建立",
            systemImage: tab.systemImage,
            description: Text("目前切片先完成訂單瀏覽，後續會逐步補上此功能。")
        )
        .navigationTitle(tab.title)
    }
}

// MARK: - ViewBuilder

private extension RootPlaceholderView {}

// MARK: - Preview

#Preview("佔位畫面") {
    RootPlaceholderView(tab: .dashboard)
}
