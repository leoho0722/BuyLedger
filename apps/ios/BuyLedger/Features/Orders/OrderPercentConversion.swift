//
//  OrderPercentConversion.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/7.
//

import Foundation

/// 以十進位計算訂單費率與輸入百分比，保留使用者輸入的精度
enum OrderPercentConversion {

}

// MARK: - Internal Method

extension OrderPercentConversion {

    /// 將儲存的費率轉成畫面顯示的百分比
    ///
    /// - Parameter rate: 儲存的比例值
    /// - Returns: 比例值乘以一百的百分比
    static func percentage(from rate: Decimal) -> Decimal {
        rate * 100
    }

    /// 將輸入百分比先四捨五入到兩位小數，再轉成儲存費率
    ///
    /// - Parameter percentage: 使用者輸入的百分比
    /// - Returns: 百分比捨入後除以一百的比例值
    /// - Note: 正負數的中點皆向遠離零的方向捨入
    /// - Note: 有效範圍由存檔流程限制
    static func rate(from percentage: Decimal) -> Decimal {
        var value = percentage
        var rounded = Decimal()
        NSDecimalRound(
            &rounded,
            &value,
            2,
            .plain
        )
        return rounded / 100
    }
}
