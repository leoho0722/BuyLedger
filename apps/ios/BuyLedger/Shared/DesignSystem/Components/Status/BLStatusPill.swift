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

    /// 狀態膠囊水平內距，隨字級縮放
    @ScaledMetric(relativeTo: .caption) private var horizontalPadding: CGFloat = 9

    /// 狀態點直徑，隨字級縮放
    @ScaledMetric(relativeTo: .caption) private var indicatorSize: CGFloat = 5

    /// 狀態膠囊垂直內距，隨字級縮放
    @ScaledMetric(relativeTo: .caption) private var verticalPadding: CGFloat = 3

    /// 是否顯示左側狀態點
    private let isIndicatorVisible: Bool

    /// 狀態膠囊顯示的文字
    private let title: Title

    /// 狀態膠囊使用的語意狀態
    private let tone: BLTone

    // MARK: - Init

    /// 建立依畫面語言顯示文字的狀態膠囊
    ///
    /// - Parameters:
    ///   - title: 狀態膠囊顯示的本地化文字
    ///   - tone: 狀態膠囊使用的語意狀態
    ///   - isIndicatorVisible: 是否顯示左側狀態點
    init(
        _ title: LocalizedStringResource,
        tone: BLTone = .neutral,
        showsIndicator isIndicatorVisible: Bool = true
    ) {
        self.title = .localized(title)
        self.tone = tone
        self.isIndicatorVisible = isIndicatorVisible
    }

    /// 建立原樣顯示文字的狀態膠囊
    ///
    /// - Parameters:
    ///   - title: 不需本地化的狀態膠囊文字
    ///   - tone: 狀態膠囊使用的語意狀態
    ///   - isIndicatorVisible: 是否顯示左側狀態點
    init(
        verbatim title: String,
        tone: BLTone = .neutral,
        showsIndicator isIndicatorVisible: Bool = true
    ) {
        self.title = .verbatim(title)
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

            titleText
                .font(BLTypographyStyle.caption.font.weight(.semibold))
        }
        .padding(.vertical, verticalPadding)
        .padding(.horizontal, horizontalPadding)
        .foregroundStyle(tone.onSurface)
        .background(tone.background)
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
    }

    /// 依文字來源選擇本地化或原文顯示方式
    @ViewBuilder
    var titleText: some View {
        switch title {
        case .localized(let resource):
            Text(resource)

        case .verbatim(let text):
            Text(verbatim: text)
        }
    }
}

// MARK: - Nested Types

private extension BLStatusPill {

    /// 狀態膠囊文字的來源與顯示方式
    enum Title {

        /// 依畫面語言顯示的本地化文字
        ///
        /// - Parameter localizedStringResource: 要顯示的本地化文字
        case localized(LocalizedStringResource)

        /// 不進行本地化的原始文字
        ///
        /// - Parameter string: 要原樣顯示的文字
        case verbatim(String)
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
            ForEach(0..<3, id: \.self) {
                BLStatusPill(verbatim: samples[$0].0, tone: samples[$0].1)
            }
        }

        HStack(spacing: BLSpacing.small) {
            ForEach(3..<samples.count, id: \.self) {
                BLStatusPill(verbatim: samples[$0].0, tone: samples[$0].1)
            }
        }
    }
    .padding()
}
