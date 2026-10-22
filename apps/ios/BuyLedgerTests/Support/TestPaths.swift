//
//  TestPaths.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/23.
//

import Foundation

/// 測試讀取原始碼與設定檔時共用的目錄位置
enum TestPaths {}

// MARK: - Computed Properties

extension TestPaths {

    /// 測試 target 所在的 iOS 平台目錄 (`apps/ios`)
    ///
    /// - Note: 由本檔往上找到 `BuyLedgerTests` 資料夾後取其上層，測試檔放在哪一層子資料夾都能定位
    static var iosRoot: URL {
        var directory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        while directory.lastPathComponent != "BuyLedgerTests", directory.pathComponents.count > 1 {
            directory.deleteLastPathComponent()
        }
        return directory.deletingLastPathComponent()
    }
}
