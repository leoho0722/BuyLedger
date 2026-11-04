//
//  BLCardRowPosition.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/29.
//

import SwiftUI

/// 卡片列在共用卡片中的位置，決定列的圓角、分隔線與外緣留白
enum BLCardRowPosition: Equatable, Sendable {

    /// 組內只有一列，四個角都是卡片外緣
    case single

    /// 組內第一列，上緣為卡片外緣
    case first

    /// 組內中間的列，上下皆為列間界線
    case middle

    /// 組內最後一列，下緣為卡片外緣
    case last

    // MARK: - Init

    /// 依列的索引與組內總數決定位置
    ///
    /// - Parameters:
    ///   - index: 列在組內的索引，從 0 起算
    ///   - count: 組內的列數
    init(index: Int, count: Int) {
        if count <= 1 {
            self = .single
        } else if index == 0 {
            self = .first
        } else if index == count - 1 {
            self = .last
        } else {
            self = .middle
        }
    }
}

// MARK: - Computed Properties

extension BLCardRowPosition {

    /// 上緣是否為卡片外緣，是時轉為圓角並保留陰影空間
    var hasTopEdge: Bool {
        self == .single || self == .first
    }

    /// 下緣是否為卡片外緣，是時轉為圓角並保留陰影空間
    var hasBottomEdge: Bool {
        self == .single || self == .last
    }

    /// 下方是否需要卡片內分隔線
    var hasDivider: Bool {
        !hasBottomEdge
    }

    /// 上緣為外緣時保留給陰影的高度
    var topRoom: CGFloat {
        hasTopEdge ? BLCardRowMetrics.edgeRoom : 0
    }

    /// 下緣為外緣時保留給陰影的高度
    var bottomRoom: CGFloat {
        hasBottomEdge ? BLCardRowMetrics.edgeRoom : 0
    }
}

// MARK: - Internal Method

extension BLCardRowPosition {

    /// 計算卡片列的列內距：外緣保留陰影空間，有分隔線時底部保留分隔線的高度
    ///
    /// - Parameters:
    ///   - dividerHeight: 分隔線的高度，呼叫端以環境的 `pixelLength` 傳入
    ///   - horizontalInset: 卡片與列左右邊緣的距離，預設為 `BLCardRowMetrics.horizontalInset`
    /// - Returns: 列內距
    func cardRowInsets(
        dividerHeight: CGFloat,
        horizontalInset: CGFloat = BLCardRowMetrics.horizontalInset
    ) -> EdgeInsets {
        EdgeInsets(
            top: topRoom,
            leading: horizontalInset,
            bottom: bottomRoom + (hasDivider ? dividerHeight : 0),
            trailing: horizontalInset
        )
    }
}
