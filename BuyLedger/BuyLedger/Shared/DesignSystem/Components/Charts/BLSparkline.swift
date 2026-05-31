//
//  BLSparkline.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import SwiftUI

/// 呈現小型走勢的折線圖。
struct BLSparkline: View {

    // MARK: - View Properties

    /// 目前系統深淺色外觀。
    @Environment(\.colorScheme) private var colorScheme

    /// 走勢圖要呈現的數值。
    let data: [Double]

    /// 可選的線條色彩；未提供時使用成功色。
    var tint: Color? = nil

    /// 走勢圖高度。
    var height: CGFloat = 40

    // MARK: - View Body

    /// 小型走勢圖的畫面內容。
    var body: some View {
        let palette = BLTheme.palette(for: colorScheme)
        let color = tint ?? palette.green

        GeometryReader { proxy in
            let points = points(in: proxy.size)

            ZStack {
                Path { path in
                    guard let first = points.first else { return }
                    path.move(to: CGPoint(x: first.x, y: proxy.size.height))
                    points.forEach { point in
                        path.addLine(to: point)
                    }
                    if let last = points.last {
                        path.addLine(to: CGPoint(x: last.x, y: proxy.size.height))
                    }
                    path.closeSubpath()
                }
                .fill(color.opacity(0.16))

                Path { path in
                    guard let first = points.first else { return }
                    path.move(to: first)
                    points.dropFirst().forEach { path.addLine(to: $0) }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(height: height)
    }
}

// MARK: - Private Method

private extension BLSparkline {

    /// 將資料轉換成繪製路徑使用的座標點。
    /// - Parameter size: 圖表可用繪製尺寸。
    /// - Returns: 對應到目前尺寸的座標點集合。
    func points(in size: CGSize) -> [CGPoint] {
        guard data.count > 1 else { return [] }

        let maxValue = data.max() ?? 1
        let minValue = data.min() ?? 0
        let range = max(maxValue - minValue, 1)

        return data.enumerated().map { index, value in
            let x = size.width * CGFloat(index) / CGFloat(data.count - 1)
            let normalized = CGFloat((value - minValue) / range)
            let y = size.height - normalized * (size.height - 4) - 2
            return CGPoint(x: x, y: y)
        }
    }
}

// MARK: - Preview

#Preview("走勢圖") {
    BLSparkline(data: [8, 12, 9, 15, 13, 18, 16, 22])
        .frame(width: 240)
        .padding()
}
