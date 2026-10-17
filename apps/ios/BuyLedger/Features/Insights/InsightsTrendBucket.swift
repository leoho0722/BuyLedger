//
//  InsightsTrendBucket.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation

/// 走勢圖單一期間的標籤與淨獲利
struct InsightsTrendBucket: Equatable {

    // MARK: - Properties

    /// 圖表上顯示的期間標籤，依行事曆與時區格式化的 verbatim 字串
    let label: String

    /// 該期間的淨獲利，以 `Decimal` 保留精確值供彙總
    let profit: Decimal
}
