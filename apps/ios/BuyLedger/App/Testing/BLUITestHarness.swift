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
/// - Important: 必須早於第一次解析 `@Dependency`
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
        
        let container = PersistenceContainer.makeInMemory(for: .testing)
        
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
    
    /// 清除 App 的 UserDefaults 測試資料
    static func resetPersistedState() {
        guard let domain = Bundle.main.bundleIdentifier else {
            print("[BuyLedger][UITest] 取不到 bundle identifier，跳過設定重置")
            return
        }
        
        UserDefaults.standard.removePersistentDomain(forName: domain)
    }
}

#endif
