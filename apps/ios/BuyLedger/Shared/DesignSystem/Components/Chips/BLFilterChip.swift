//
//  BLFilterChip.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/20.
//

import SwiftUI

/// 篩選膠囊：訂單列表的狀態、日期、類別與付款方式篩選共用
///
/// 抽成共用元件而非逐處修補——六處原本是彼此複製的產物，逐處補命中區會留下六份仍會再度分歧的
/// 程式碼，且下一個新增的膠囊仍會從既有的錯誤版本複製
struct BLFilterChip: View {

    // MARK: - View Properties

    /// 目前系統深淺色外觀
    @Environment(\.colorScheme) private var colorScheme

    /// 膠囊顯示的文字
    let title: LocalizedStringKey

    /// 是否為選取狀態
    let isSelected: Bool

    /// 選取態的語意配色
    var style: Style = .inverted

    /// 字級與水平內距的尺寸
    var size: Size = .standard

    /// 選用的前綴 SF Symbol 名稱
    var icon: String? = nil

    /// 選用的尾端 SF Symbol 名稱
    var trailingIcon: String? = nil

    /// 是否撐滿可用寬度並允許換行 (trigger 類膠囊使用)
    var isExpanded: Bool = false

    /// 點擊時的動作
    let action: () -> Void

    // MARK: - View Body

    /// 篩選膠囊的畫面內容
    var body: some View {
        let palette = BLPalette()

        Button(action: action) {
            label(palette: palette)
                // 命中區宣告在標籤內部才會擴大可點區域；形狀用 capsule 而非外接矩形，
                // 否則相鄰膠囊的命中區會在圓角處重疊
                .frame(minHeight: BLHitTarget.minimum)
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        // 選取態原本只以配色表達，補選取 trait 讓輔助技術與 UI 測試都讀得到、不必目視顏色
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Nested Types

extension BLFilterChip {

    /// 膠囊選取態的語意配色
    enum Style {

        // MARK: - Cases

        /// 以反白呈現選取 (狀態篩選)
        case inverted

        /// 以強調色呈現選取 (日期區間篩選)
        case accent

        /// 以輔助強調色呈現選取 (類別、付款方式與整合篩選)
        case purple
    }

    /// 膠囊的字級與水平內距
    ///
    /// 兩種尺寸源自 compact 與 regular 版面既有的差異，抽取時原樣保留——
    /// 統一字級會讓 compact 兩處縮小，混進本 change 不預期的視覺變化
    enum Size {

        // MARK: - Cases

        /// `.footnote` 加 12pt 水平內距 (regular 版面)
        case standard

        /// `.subheadline` 加 14pt 水平內距 (compact 版面)
        case large
    }
}

// MARK: - ViewBuilder

private extension BLFilterChip {

    /// 膠囊的可見內容：圖示、文字與選取態配色
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 膠囊標籤 view
    @ViewBuilder
    func label(palette: BLPalette) -> some View {
        HStack(alignment: isExpanded ? .firstTextBaseline : .center, spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(size.iconFont)
            }

            titleText

            if let trailingIcon {
                Image(systemName: trailingIcon)
                    .font(size.iconFont)
            }
        }
        .foregroundStyle(style.foreground(isSelected: isSelected, palette: palette))
        .padding(.vertical, 7)
        .padding(.horizontal, size.horizontalPadding)
        .background(style.background(isSelected: isSelected, palette: palette))
        .clipShape(Capsule())
    }

    /// 膠囊文字：撐滿型允許換行並靠左，其餘維持單行自然寬度
    @ViewBuilder
    var titleText: some View {
        if isExpanded {
            Text(title)
                .font(size.titleFont)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(title)
                .font(size.titleFont)
                .lineLimit(1)
        }
    }
}

// MARK: - Private Method

private extension BLFilterChip.Style {

    /// 回傳膠囊前景色
    /// - Parameters:
    ///   - isSelected: 是否為選取狀態
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: 文字與圖示使用的色彩
    func foreground(isSelected: Bool, palette: BLPalette) -> Color {
        guard isSelected else {
            return palette.secondaryLabel
        }
        switch self {
        case .inverted:
            return palette.background
        case .accent:
            return palette.accent
        case .purple:
            return palette.purple
        }
    }

    /// 回傳膠囊背景色
    /// - Parameters:
    ///   - isSelected: 是否為選取狀態
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: 膠囊底色
    func background(isSelected: Bool, palette: BLPalette) -> Color {
        guard isSelected else {
            return palette.fillTertiary
        }
        switch self {
        case .inverted:
            return palette.label
        case .accent:
            return palette.accent.opacity(0.18)
        case .purple:
            return palette.purple.opacity(0.18)
        }
    }
}

private extension BLFilterChip.Size {

    /// 膠囊文字字級
    var titleFont: Font {
        switch self {
        case .standard:
                .footnote.weight(.semibold)
        case .large:
                .subheadline.weight(.semibold)
        }
    }

    /// 膠囊圖示字級
    var iconFont: Font {
        switch self {
        case .standard:
                .caption2.weight(.semibold)
        case .large:
                .caption.weight(.semibold)
        }
    }

    /// 膠囊水平內距
    var horizontalPadding: CGFloat {
        switch self {
        case .standard:
            12
        case .large:
            14
        }
    }
}

// MARK: - Preview

#Preview("篩選膠囊") {
    VStack(alignment: .leading, spacing: BLSpacing.medium) {
        HStack(spacing: BLSpacing.small) {
            BLFilterChip(title: "全部", isSelected: true) {}
            BLFilterChip(title: "報價中", isSelected: false) {}
            BLFilterChip(title: "本月", isSelected: true, style: .accent, icon: "calendar") {}
        }

        BLFilterChip(
            title: "篩選: 全部",
            isSelected: false,
            style: .purple,
            size: .large,
            icon: "line.3.horizontal.decrease",
            trailingIcon: "chevron.down",
            isExpanded: true
        ) {}
    }
    .padding()
}
