//
//  BLBarChartValue.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import Foundation

/// 長條圖使用的單筆資料
struct BLBarChartValue: Identifiable {

    // MARK: - Identifiable Properties

    /// 資料的穩定識別值
    var id: String { label }

    // MARK: - Data Properties

    /// X 軸顯示的標籤
    let label: String

    /// Y 軸使用的數值
    let value: Double

    /// 供輔助技術朗讀的數值描述
    ///
    /// 由呼叫端以其 locale 格式化後傳入——設計系統不認識金額或單位，
    /// 自行格式化會朗讀出沒有單位的裸數字
    let valueDescription: String
}
