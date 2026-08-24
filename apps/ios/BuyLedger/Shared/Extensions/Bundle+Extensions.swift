//
//  Bundle+Extensions.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/20.
//

import Foundation

/// 用來定位 App bundle 的識別型別
private final class BundleToken {}

// MARK: - Static Properties

extension Bundle {
    
    /// 存放 asset catalog 的 bundle
    static let assets = Bundle(for: BundleToken.self)
}
