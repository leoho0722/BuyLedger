//
//  BLTypography.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import SwiftUI

/// BuyLedger 支援的文字層級
///
/// 文字樣式使用 SwiftUI 動態字級，讓內容可跟隨系統輔助使用設定縮放
enum BLTypographyStyle: String, CaseIterable, Identifiable {

    // MARK: - Cases

    /// 頁面最主要標題
    case largeTitle = "Large Title"

    /// 第一層標題
    case title1 = "Title 1"

    /// 第二層標題
    case title2 = "Title 2"

    /// 第三層標題
    case title3 = "Title 3"

    /// 列表或卡片中的強調標題
    case headline = "Headline"

    /// 主要內文
    case body = "Body"

    /// 次要內文或輔助說明
    case subhead = "Subhead"

    /// 補充說明文字
    case footnote = "Footnote"

    /// 標籤或圖說文字
    case caption = "Caption"

    /// 最小文字層級
    case caption2 = "Caption 2"

    // MARK: - Identifiable Properties

    /// 文字層級的穩定識別值
    var id: String { rawValue }

    // MARK: - Typography Properties

    /// 對應到 SwiftUI 動態字級的字型
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
