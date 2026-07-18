//
//  BLStatusPill.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import SwiftUI

/// 以短文字與語意狀態呈現狀態
struct BLStatusPill: View {

    // MARK: - View Properties

    /// 目前系統深淺色外觀
    @Environment(\.colorScheme) private var colorScheme

    /// 狀態膠囊顯示的文字
    let title: String

    /// 狀態膠囊使用的語意狀態
    let tone: BLTone

    /// 指示是否顯示左側狀態點
    let showsIndicator: Bool

    // MARK: - Init

    /// 建立狀態膠囊
    /// - Parameters:
    ///   - title: 狀態膠囊顯示的文字
    ///   - tone: 狀態膠囊使用的語意狀態
    ///   - showsIndicator: 指示是否顯示左側狀態點
    init(_ title: String, tone: BLTone = .neutral, showsIndicator: Bool = true) {
        self.title = title
        self.tone = tone
        self.showsIndicator = showsIndicator
    }

    // MARK: - View Body

    /// 狀態膠囊的畫面內容
    var body: some View {
        let palette = BLTheme.palette(for: colorScheme)
        let foreground = tone.foreground(in: palette)

        HStack(spacing: 4) {
            if showsIndicator {
                Circle()
                    .fill(foreground)
                    .frame(width: 5, height: 5)
            }

            Text(LocalizedStringKey(title))
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(foreground)
        .padding(.vertical, 3)
        .padding(.horizontal, 9)
        .background(tone.background(in: palette))
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview("狀態膠囊") {
    let samples: [(String, BLTone)] = [
        ("中性", .neutral),
        ("主要", .accent),
        ("成功", .success),
        ("警示", .warning),
        ("錯誤", .destructive),
        ("資訊", .informative),
    ]

    VStack(alignment: .leading, spacing: BLSpacing.small) {
        HStack(spacing: BLSpacing.small) {
            ForEach(0..<3, id: \.self) { index in
                BLStatusPill(samples[index].0, tone: samples[index].1)
            }
        }

        HStack(spacing: BLSpacing.small) {
            ForEach(3..<samples.count, id: \.self) { index in
                BLStatusPill(samples[index].0, tone: samples[index].1)
            }
        }
    }
    .padding()
}
