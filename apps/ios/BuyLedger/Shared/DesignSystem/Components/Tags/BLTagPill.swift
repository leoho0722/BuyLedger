//
//  BLTagPill.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/26.
//

import SwiftUI

/// 以 neutral 灰底膠囊呈現標籤文字，並可在膠囊外側附加前導圖示
///
/// 視覺沿用 ``BLStatusPill`` 的 neutral 外觀 (灰底、無狀態指示點)，常用於商品類別等分類標記。圖示置於膠囊外、與膠囊垂直置中對齊；膠囊文字過長時換行成多行、膠囊高度隨之增加 (不截斷、也不撐爆容器寬度)
struct BLTagPill: View {

    // MARK: - View Properties

    /// 膠囊內顯示的標籤文字
    let text: String

    /// 膠囊左側 (膠囊外) 的前導 SF Symbol 名稱；為 nil 時不顯示圖示
    let systemImage: String?

    // MARK: - Init

    /// 建立標籤膠囊
    /// - Parameters:
    ///   - text: 膠囊內顯示的標籤文字
    ///   - systemImage: 膠囊左側的前導 SF Symbol 名稱；預設為 nil (不顯示圖示)
    init(_ text: String, systemImage: String? = nil) {
        self.text = text
        self.systemImage = systemImage
    }

    // MARK: - View Body

    /// 標籤膠囊的畫面內容
    var body: some View {
        HStack(alignment: .center, spacing: BLSpacing.extraSmall) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption2)
                    .imageScale(.small)
                    .foregroundStyle(.secondary)
            }

            // 多行換行 + 垂直長高：不可用 `.fixedSize(horizontal:)`，否則膠囊會永遠採用文字理想寬度、不肯換行，
            // 長類別 (例如 "aespa Lemonade QQ 音樂限定禮包") 會把整列撐到比畫面還寬
            // `fixedSize(horizontal: false, vertical: true)` 表示「接受容器給的寬度、需要幾行就長多高」，
            // 膠囊底色隨多行文字一起增高，既不截斷也不溢出
            BLStatusPill(text, tone: .neutral, showsIndicator: false)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Preview

#Preview("標籤膠囊") {
    VStack(alignment: .leading, spacing: BLSpacing.medium) {
        BLTagPill("服飾", systemImage: "tag")
        BLTagPill("居家生活雜貨", systemImage: "tag")
        BLTagPill("無圖示")
    }
    .padding()
}
