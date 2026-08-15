//
//  BLHeatmapDepth.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/20.
//

import SwiftUI

/// 熱力圖的離散深度級數
enum BLHeatmapDepth: Int, CaseIterable {
    
    // MARK: - Cases
    
    /// 最淺的密度級數
    case level1 = 1
    
    /// 偏淺的密度級數
    case level2
    
    /// 中間的密度級數
    case level3
    
    /// 偏深的密度級數
    case level4
    
    /// 最深的密度級數
    case level5
}

// MARK: - Display Properties

extension BLHeatmapDepth {
    
    /// 此級數的格子底色
    var background: Color {
        Color("BLHeatmapLevel\(rawValue)Background", bundle: .assets)
    }
    
    /// 與 ``background`` 成對定義、經驗證達標的數字色
    var numeral: Color {
        Color("BLHeatmapLevel\(rawValue)Numeral", bundle: .assets)
    }
}

// MARK: - Internal Method

extension BLHeatmapDepth {
    
    /// 依格子的計數與整張圖的最大值決定深度級數
    /// - Parameters:
    ///   - count: 該格子的計數
    ///   - maxCount: 整張熱力圖的最大計數
    /// - Returns: 對應的深度級數；計數為零時回傳 `nil` 表示空格
    static func depth(for count: Int, maxCount: Int) -> BLHeatmapDepth? {
        guard count > 0 else {
            return nil
        }
        guard maxCount > 1 else {
            return .level5
        }
        
        let allCases = BLHeatmapDepth.allCases
        let ratio = Double(count - 1) / Double(maxCount - 1)
        let index = Int((ratio * Double(allCases.count - 1)).rounded())
        return allCases[min(max(index, 0), allCases.count - 1)]
    }
}
