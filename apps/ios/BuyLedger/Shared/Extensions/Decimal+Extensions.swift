//
//  Decimal+Extensions.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation

// MARK: - Internal Method

extension Decimal {

    /// 對 `Decimal` 套用無條件進位到整數
    func roundedUpToInteger() -> Decimal {
        var source = self
        var result = Decimal()
        NSDecimalRound(&result, &source, 0, .up)
        return result
    }
}
