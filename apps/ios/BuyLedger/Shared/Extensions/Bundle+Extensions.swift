//
//  Bundle+Extensions.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/20.
//

import Foundation

/// 用來定位 App bundle 的識別型別
///
/// 只作為 ``Bundle/assets`` 的查找依據，本身不持有任何行為
private final class BundleToken {}

// MARK: - Static Properties

extension Bundle {

    /// 存放 asset catalog 的 bundle
    ///
    /// 不直接用 ``Bundle/main``：單元測試在測試執行器的行程中載入時，`main` 會指向執行器而非 App，
    /// 使具名色彩靜默回退為系統預設色
    static let assets = Bundle(for: BundleToken.self)
}
