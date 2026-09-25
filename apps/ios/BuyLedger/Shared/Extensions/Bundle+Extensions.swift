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

// MARK: - Computed Properties

extension Bundle {

    /// App 的短版號與建置號文字，格式為「短版號 (建置號)」；讀不到時以破折號替代
    static var appVersion: String {
        let infoDictionary = Bundle.main.infoDictionary
        let shortVersion = infoDictionary?["CFBundleShortVersionString"] as? String
        let buildVersion = infoDictionary?["CFBundleVersion"] as? String
        guard let shortVersion, let buildVersion else {
            return "—"
        }
        return "\(shortVersion) (\(buildVersion))"
    }
}
