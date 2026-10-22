//
//  BuyLedgerDatabase+Dependency.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture
import Foundation

// MARK: - DependencyKey

/// 把 `BuyLedgerDatabaseProtocol` 註冊進 TCA 依賴系統：正式 App 用正式實作，Preview 用 seed 過的記憶體資料庫；
/// 不宣告測試值，測 Service 時漏了以 `withDependencies` 注入 mock 就會直接失敗
enum BuyLedgerDatabaseKey: DependencyKey {

    /// 正式環境使用啟動時建立的 `ModelContainer`，並在依賴註冊處注入 Application Support 目錄解析
    static var liveValue: any BuyLedgerDatabaseProtocol {
        BuyLedgerDatabase(
            modelContainer: PersistenceContainer.bootstrap.container,
            storeLocation: .applicationSupport(
                resolveDirectory: {
                    try FileManager.default.url(
                        for: .applicationSupportDirectory,
                        in: .userDomainMask,
                        appropriateFor: nil,
                        create: true
                    )
                }
            )
        )
    }
}

// MARK: - DependencyValues

extension DependencyValues {

    /// 取得隔離持久層操作的資料庫
    var buyLedgerDatabase: any BuyLedgerDatabaseProtocol {
        get { self[BuyLedgerDatabaseKey.self] }
        set { self[BuyLedgerDatabaseKey.self] = newValue }
    }
}
