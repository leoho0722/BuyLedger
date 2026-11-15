//
//  CGRect+Validity.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/14.
//

import CoreGraphics

// MARK: - 框線有效性

/// 提供判斷畫面框線是否可供量測的條件
extension CGRect {

    /// 座標與尺寸皆有限且寬高大於零時為可用框線
    var isUsableFrame: Bool {
        !isNull && !isInfinite && !isEmpty
            && origin.x.isFinite && origin.y.isFinite
            && width.isFinite && height.isFinite
            && minX.isFinite && minY.isFinite
            && maxX.isFinite && maxY.isFinite
    }

    /// 判斷此框線是否位於另一個框線上方
    ///
    /// - Parameter frame: 下方框線
    /// - Returns: 此框線底緣未超過下方框線頂緣時為 `true`
    func isAbove(_ frame: CGRect) -> Bool {
        maxY <= frame.minY
    }
}
