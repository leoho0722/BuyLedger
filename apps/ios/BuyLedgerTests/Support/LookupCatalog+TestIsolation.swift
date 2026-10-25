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

    /// 以獨立的預設記憶體儲存執行 `operation`，讓具名共享的主檔目錄不跨測試外溢
    ///
    /// - Parameter operation: 要在隔離儲存中執行的操作
    /// - Returns: 操作的結果
    /// - Throws: 操作丟出的錯誤
    @MainActor
    static func withIsolatedStorage<Output>(
        _ operation: () async throws -> Output
    ) async rethrows -> Output {
        try await withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
        } operation: {
            try await operation()
        }
    }
}
