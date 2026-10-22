//
//  InsightsCostSegment.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation

/// 成本結構的單一區塊
struct InsightsCostSegment: Equatable {

    // MARK: - Properties

    /// 顯示在圖例的標籤，為本地化 key
    let label: String

    /// 此區塊的金額
    let value: Decimal

    /// 畫面依此換算顏色的語意色調
    let tone: Tone
}

// MARK: - Nested Types

extension InsightsCostSegment {

    /// 成本區塊的語意色調，由畫面轉成色盤顏色
    enum Tone: Equatable, Sendable {

        /// 商品金額的強調色調
        case accent

        /// 國內運費的藍綠色色調
        case teal

        /// 國際運費的紫色色調
        case purple

        /// 手續費的橘色色調
        case orange
    }
}

// MARK: - Identifiable

extension InsightsCostSegment: Identifiable {

    /// 用標籤當識別值
    var id: String {
        label
    }
}
