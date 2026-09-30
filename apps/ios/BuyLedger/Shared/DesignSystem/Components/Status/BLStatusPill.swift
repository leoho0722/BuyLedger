//
//  BLStatusPill.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import SwiftUI

/// 以短文字與語意狀態呈現狀態
struct BLStatusPill: View {

    // MARK: - Properties

    /// 狀態膠囊垂直內距，隨字級縮放
    @ScaledMetric(relativeTo: .caption) private var verticalPadding: CGFloat = 3

    /// 狀態膠囊水平內距，隨字級縮放
    @ScaledMetric(relativeTo: .caption) private var horizontalPadding: CGFloat = 9

    /// 狀態點直徑，隨字級縮放
    @ScaledMetric(relativeTo: .caption) private var indicatorSize: CGFloat = 5

    /// 狀態膠囊顯示的文字
    let title: String

    /// 狀態膠囊使用的語意狀態
    let tone: BLTone

    /// 是否顯示左側狀態點
    let isIndicatorVisible: Bool

    // MARK: - Init

    /// 建立狀態膠囊
    ///
    /// - Parameters:
    ///   - title: 狀態膠囊顯示的文字
    ///   - tone: 狀態膠囊使用的語意狀態
    ///   - isIndicatorVisible: 是否顯示左側狀態點
    init(
        _ title: String,
        tone: BLTone = .neutral,
        showsIndicator isIndicatorVisible: Bool = true
    ) {
        self.title = title
        self.tone = tone
        self.isIndicatorVisible = isIndicatorVisible
    }

    // MARK: - Body

    /// 狀態膠囊的畫面內容
    var body: some View {
        statusContent
    }
}

// MARK: - Private Views

private extension BLStatusPill {

    /// 狀態膠囊的狀態點與文字內容
    var statusContent: some View {
        HStack(spacing: BLSpacing.extraSmall) {
            if isIndicatorVisible {
                Circle()
                    .fill(tone.indicator)
                    .frame(width: indicatorSize, height: indicatorSize)
                    .accessibilityHidden(true)
            }

            Text(LocalizedStringKey(title))
                .font(BLTypographyStyle.caption.font.weight(.semibold))
        }
        .padding(.vertical, verticalPadding)
        .padding(.horizontal, horizontalPadding)
        .foregroundStyle(tone.onSurface)
        .background(tone.background)
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
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
