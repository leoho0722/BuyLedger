//
//  LayerBoundaryFileScan.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import Foundation
import Testing

/// 格式化分層守門的違規位置，供測試失敗訊息使用
enum LayerBoundaryFileScan {}

// MARK: - Internal Method

extension LayerBoundaryFileScan {

    /// 把違規清單格式化為附帶檔名與行號的說明
    ///
    /// - Parameter violations: 掃描命中的違規位置
    /// - Returns: 以頓號分隔的違規說明
    static func describe(_ violations: [LayerBoundaryScanner.Violation]) -> String {
        violations.map { "\($0.file):\($0.line) (\($0.typeName))" }.joined(separator: "、")
    }
}
