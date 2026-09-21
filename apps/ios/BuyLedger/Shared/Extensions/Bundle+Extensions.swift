//
//  Bundle+Extensions.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/20.
//

import Foundation

// MARK: - Properties

extension Bundle {

    /// 用來定位 App bundle 的識別型別
    private final class Token {}

    /// 存放 asset catalog 的 bundle
    static let assets = Bundle(for: Token.self)
}
