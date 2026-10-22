//
//  InsightsCategory.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation

/// 類別排行的單列資料
struct InsightsCategory: Equatable {

    // MARK: - Properties

    /// 類別名稱
    let name: String

    /// 該類別累計獲利
    let profit: Decimal

    /// 相對第一名類別獲利的比例，介於 0 與 1 之間，供進度條使用
    let ratio: Double
}

// MARK: - Identifiable

extension InsightsCategory: Identifiable {

    /// 用類別名稱當識別值
    var id: String {
        name
    }
}
