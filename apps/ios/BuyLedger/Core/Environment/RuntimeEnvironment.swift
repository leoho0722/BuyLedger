//
//  RuntimeEnvironment.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation

/// 判斷目前執行環境，供 Preview stub 的 assert 與 App 根部決定是否注入 stub 使用
enum RuntimeEnvironment {

}

// MARK: - Computed Properties

extension RuntimeEnvironment {

    /// 是否正在 Xcode Preview 中執行
    static var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    /// 是否由 UI Test 啟動，以 `-BLUITest` 旗標判斷
    static var isUITesting: Bool {
        CommandLine.arguments.contains("-BLUITest")
    }

    /// 是否正在跑單元測試：Xcode 會設定 XCTest 的環境變數，命令列的 `swift test` 不會，改看啟動參數
    ///
    /// - Note: 判斷條件參考 swift-issue-reporting 的 `isTesting`
    static var isUnitTesting: Bool {
        let environment = ProcessInfo.processInfo.environment
        let hasTestEnvironment = [
            "XCTestBundlePath",
            "XCTestBundleInjectPath",
            "XCTestConfigurationFilePath",
            "XCTestSessionIdentifier",
        ].contains { environment[$0] != nil }
        let hasTestArgument = CommandLine.arguments.contains { argument in
            let url = URL(fileURLWithPath: argument)
            return url.lastPathComponent == "swiftpm-testing-helper"
                || url.lastPathComponent == "xctest"
                || url.pathExtension == "xctest"
                || argument == "--testing-library"
        }
        return hasTestEnvironment || hasTestArgument
    }

    /// 是否允許使用 Preview stub：Preview、UI Test、單元測試三者任一成立即可
    static var allowsPreviewStub: Bool {
        isPreview || isUITesting || isUnitTesting
    }
}
