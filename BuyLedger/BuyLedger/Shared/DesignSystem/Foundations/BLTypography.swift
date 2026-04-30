//
//  BLTypography.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import SwiftUI

/// BuyLedger 支援的文字層級。
///
/// 文字樣式使用 SwiftUI 動態字級，讓內容可跟隨系統輔助使用設定縮放。
enum BLTypographyStyle: String, CaseIterable, Identifiable {

    // MARK: - Cases

    /// 頁面最主要標題。
    case largeTitle = "Large Title"

    /// 第一層標題。
    case title1 = "Title 1"

    /// 第二層標題。
    case title2 = "Title 2"

    /// 第三層標題。
    case title3 = "Title 3"

    /// 列表或卡片中的強調標題。
    case headline = "Headline"

    /// 主要內文。
    case body = "Body"

    /// 次要內文或輔助說明。
    case subhead = "Subhead"

    /// 補充說明文字。
    case footnote = "Footnote"

    /// 標籤或圖說文字。
    case caption = "Caption"

    /// 最小文字層級。
    case caption2 = "Caption 2"

    // MARK: - Identifiable Properties

    /// 文字層級的穩定識別值。
    var id: String { rawValue }

    // MARK: - Typography Properties

    /// 對應到 SwiftUI 動態字級的字型。
    var font: Font {
        switch self {
        case .largeTitle:
            .largeTitle.bold()
        case .title1:
            .title.bold()
        case .title2:
            .title2.bold()
        case .title3:
            .title3.weight(.semibold)
        case .headline:
            .headline
        case .body:
            .body
        case .subhead:
            .subheadline
        case .footnote:
            .footnote
        case .caption:
            .caption
        case .caption2:
            .caption2
        }
    }
}

/// 套用 BuyLedger 文字層級的 view modifier。
struct BLTypographyModifier: ViewModifier {

    // MARK: - View Properties

    /// 要套用的文字層級。
    let style: BLTypographyStyle

    // MARK: - View Body

    /// 回傳套用字型與字距後的內容。
    func body(content: Content) -> some View {
        content
            .font(style.font)
            .tracking(0)
    }
}

extension View {

    // MARK: - View Method

    /// 套用 BuyLedger 設計系統的文字樣式。
    /// - Parameter style: 要套用的文字層級。
    /// - Returns: 套用文字樣式後的 view。
    func blTextStyle(_ style: BLTypographyStyle) -> some View {
        modifier(BLTypographyModifier(style: style))
    }
}

// MARK: - Preview

#Preview("文字層級") {
    VStack(alignment: .leading, spacing: BLSpacing.medium) {
        ForEach(BLTypographyStyle.allCases) { style in
            Text(style.rawValue)
                .blTextStyle(style)
        }
    }
    .padding()
}
