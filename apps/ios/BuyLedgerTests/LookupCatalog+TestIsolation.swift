//
//  LookupCatalog+TestIsolation.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/24.
//

import ComposableArchitecture

@testable import BuyLedger

// MARK: - Internal Method

extension LookupCatalog {

    /// 在獨立的記憶體儲存中執行主檔目錄測試
    ///
    /// - Parameter operation: 要在隔離儲存中執行的操作
    /// - Returns: 操作的結果
    /// - Throws: 操作拋出的錯誤
    @MainActor
    static func withIsolatedStorage<Output>(
        _ operation: () async throws(any Error) -> Output
    ) async rethrows -> Output {
        try await withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
        } operation: {
            try await operation()
        }
    }
}
