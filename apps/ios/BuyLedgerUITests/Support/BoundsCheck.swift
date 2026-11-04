//
//  BoundsCheck.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/30.
//

import XCTest

/// 框線檢查：框線須完整落在容器內，且不與任何保留區相交
enum BoundsCheck {}

// MARK: - Internal Method

extension BoundsCheck {

    /// 確認框線位於容器內且避開系統保留區
    ///
    /// - Parameters:
    ///   - frame: 待檢查的元素框線
    ///   - container: 框線必須完整落在其中的容器範圍
    ///   - reservedRegions: 系統列或側邊欄等不可放置控制項的保留區
    ///   - tolerance: 允許的誤差 (point)，用於吸收像素取整與動畫收尾
    /// - Returns: 框線與容器皆有效、框線完整在容器內，且與保留區的重疊不超過誤差時為 `.passed`
    static func verify(
        frame: CGRect,
        container: CGRect,
        reservedRegions: [CGRect],
        tolerance: CGFloat = 1
    ) -> CheckOutcome {
        guard isValid(frame), isValid(container) else {
            return .failed("框線或容器無效 (框線：\(frame)，容器：\(container))")
        }
        let isInside = frame.minX >= container.minX - tolerance
            && frame.maxX <= container.maxX + tolerance
            && frame.minY >= container.minY - tolerance
            && frame.maxY <= container.maxY + tolerance
        guard isInside else {
            return .failed("框線越出容器 (框線：\(frame)，容器：\(container))")
        }
        for region in reservedRegions {
            let overlap = frame.intersection(region)
            if !overlap.isNull, overlap.width > tolerance, overlap.height > tolerance {
                return .failed("框線進入保留區 (框線：\(frame)，保留區：\(region))")
            }
        }
        return .passed
    }
}

// MARK: - Private Method

private extension BoundsCheck {

    /// 判斷框線是否為有限且非空的範圍
    ///
    /// - Parameter rect: 待判斷的框線
    /// - Returns: 位置與尺寸皆為有限值且寬高大於零時為 `true`
    static func isValid(_ rect: CGRect) -> Bool {
        rect.minX.isFinite
            && rect.minY.isFinite
            && rect.width.isFinite
            && rect.height.isFinite
            && rect.width > 0
            && rect.height > 0
    }
}
