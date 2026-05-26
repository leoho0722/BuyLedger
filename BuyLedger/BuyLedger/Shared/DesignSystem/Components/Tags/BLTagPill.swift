//
//  BLTagPill.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/26.
//

import SwiftUI

/// 以 neutral 灰底膠囊呈現標籤文字，並可在膠囊外側附加前導圖示。
///
/// 視覺沿用 ``BLStatusPill`` 的 neutral 外觀 (灰底、無狀態指示點)，常用於商品類別等分類標記。圖示置於膠囊外、與膠囊垂直置中對齊；膠囊文字維持單行、不提早換行。
struct BLTagPill: View {

    // MARK: - View Properties

    /// 膠囊內顯示的標籤文字。
    let text: String

    /// 膠囊左側 (膠囊外) 的前導 SF Symbol 名稱；為 nil 時不顯示圖示。
    let systemImage: String?

    // MARK: - Init

    /// 建立標籤膠囊。
    /// - Parameters:
    ///   - text: 膠囊內顯示的標籤文字。
    ///   - systemImage: 膠囊左側的前導 SF Symbol 名稱；預設為 nil (不顯示圖示)。
    init(_ text: String, systemImage: String? = nil) {
        self.text = text
        self.systemImage = systemImage
    }

    // MARK: - View Body

    /// 標籤膠囊的畫面內容。
    var body: some View {
        HStack(alignment: .center, spacing: BLSpacing.extraSmall) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption2)
                    .imageScale(.small)
                    .foregroundStyle(.secondary)
            }

            BLStatusPill(text, tone: .neutral, showsIndicator: false)
                .fixedSize(horizontal: true, vertical: false)
        }
    }
}

// MARK: - ViewBuilder

private extension BLTagPill {}

// MARK: - Preview

#Preview("標籤膠囊") {
    VStack(alignment: .leading, spacing: BLSpacing.medium) {
        BLTagPill("服飾", systemImage: "tag")
        BLTagPill("居家生活雜貨", systemImage: "tag")
        BLTagPill("無圖示")
    }
    .padding()
}
