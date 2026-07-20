//
//  BLDonutSegment.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import SwiftUI

/// 圈狀圖使用的單一區段
struct BLDonutSegment: Identifiable {

    // MARK: - Identifiable Properties

    /// 區段的穩定識別值
    var id: String { label }

    // MARK: - Data Properties

    /// 區段名稱
    let label: String

    /// 區段數值
    let value: Double

    /// 區段色彩
    let color: Color

    /// 供輔助技術朗讀的數值描述
    ///
    /// 由呼叫端以其 locale 格式化後傳入——設計系統不認識金額或單位，
    /// 自行格式化會朗讀出沒有單位的裸數字
    let valueDescription: String
}
