//
//  BLUITestHarness.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/24.
//

import Foundation
import SwiftData
import Dependencies

#if DEBUG

/// UI 測試模式的啟動 harness
///
/// 把「重置狀態 → 建 in-memory 資料庫 → 注入種子 → 覆寫依賴」收攏成單一進入點，
/// 由 ``AppLaunchConfigurator/prepareUITestHarnessIfNeeded()`` 在建立根 store 之前呼叫
///
/// - Important: 必須早於任何 `@Dependency` 首次解析。TCA 的依賴一旦被讀取就定型，晚一步注入不會生效
@MainActor
enum BLUITestHarness {

    // MARK: - Static Properties

    /// UI 測試模式使用的 in-memory container；正式執行為 `nil`
    private(set) static var modelContainer: ModelContainer?
}

// MARK: - Internal Method

@MainActor
extension BLUITestHarness {

    /// 帶 UI 測試啟動參數時完成全部前置注入，否則直接返回不影響正式路徑
    static func prepareIfNeeded() {
        let configuration = BLUITestConfiguration.current

        guard configuration.isEnabled else {
            return
        }

        resetPersistedState()

        guard let container = try? PersistenceContainer.make(inMemoryOnly: true) else {
            print("[BuyLedger][UITest] in-memory container 建立失敗，維持正式資料來源")
            return
        }

        BLUITestSeedData.seed(
            configuration.seedProfile,
            into: container,
            referenceDate: configuration.referenceDate
        )

        modelContainer = container

        prepareDependencies {
            $0.applyUITestOverrides(configuration, container: container)
        }
    }
}

// MARK: - Private Method

@MainActor
private extension BLUITestHarness {

    /// 清掉整個 App 的 `UserDefaults` 網域，避免上一輪測試留下的語言與設定影響這一輪
    static func resetPersistedState() {
        guard let domain = Bundle.main.bundleIdentifier else {
            print("[BuyLedger][UITest] 取不到 bundle identifier，跳過設定重置")
            return
        }

        UserDefaults.standard.removePersistentDomain(forName: domain)
    }
}

#endif
