//
//  BLProgressViewStyle.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/20.
//

import SwiftUI

/// 繪製水平進度條的軌道與填色
///
/// - Note: 經 `configuration.label` 轉交的標籤在整批 snapshot (畫面比對) 測試中偶爾漏畫，
///   因此標籤由 `BLProgressView` 自行繪製
struct BLProgressViewStyle {

    // MARK: - Properties

    /// 可選的進度列色彩；未提供時使用主強調色
    let tint: Color?

    /// 可選的軌道色彩；未提供時使用系統填色，適合一般淺色表面
    var track: Color? = nil
}

// MARK: - ProgressViewStyle

extension BLProgressViewStyle: ProgressViewStyle {

    /// 繪製固定高度的進度軌道，依完成比例填入色彩
    ///
    /// - Parameter configuration: 進度列目前的呈現狀態
    /// - Returns: 高度為 6pt 的進度條
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(track ?? palette.fillQuaternary)

                Capsule()
                    .fill(tint ?? palette.accent)
                    .frame(width: proxy.size.width * (configuration.fractionCompleted ?? 0))
            }
        }
        .frame(height: 6)
    }
}

// MARK: - Private Method

private extension BLProgressViewStyle {

    /// 目前外觀對應的色盤
    var palette: BLPalette {
        BLPalette()
    }
}
