//
//  CheckOutcome.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/30.
//

/// 純值版面檢查的結果
enum CheckOutcome: Equatable {

    /// 檢查通過
    case passed

    /// 檢查失敗，附上可直接放進診斷訊息的原因
    ///
    /// - Parameter string: 失敗原因，原樣放進 UI 診斷訊息
    case failed(String)
}

// MARK: - Computed Properties

extension CheckOutcome {

    /// 結果是否為失敗
    var isFailed: Bool {
        if case .failed = self {
            return true
        }
        return false
    }
}
