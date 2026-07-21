//
//  OpenSettingsClient.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/21.
//

import ComposableArchitecture
import UIKit

/// 開啟本 App 系統設定頁的依賴介面
///
/// 以依賴反轉隔離 `UIApplication.open` 的系統呼叫，讓「權限被拒 → 前往設定」的流程
/// 可在 TestStore 中以替身驗證其被呼叫
struct OpenSettingsClient: Sendable {

    // MARK: - Dependency Properties

    /// 開啟本 App 的系統設定頁
    ///
    /// 無法開啟時靜默結束 (例如 URL 無法解析)；提示 alert 已由系統關閉，不阻塞使用者
    var open: @Sendable () async -> Void
}

// MARK: - Dependency Values

extension OpenSettingsClient: DependencyKey {

    /// App 執行時開啟系統設定的本 App 頁面
    nonisolated static let liveValue = OpenSettingsClient(
        open: {
            guard let url = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            await MainActor.run {
                UIApplication.shared.open(url)
            }
        }
    )

    /// 測試時的替身：不做任何事，由測試以自訂 closure 覆寫驗證呼叫
    nonisolated static let testValue = OpenSettingsClient(
        open: {}
    )
}
