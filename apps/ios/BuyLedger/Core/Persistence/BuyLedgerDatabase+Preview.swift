//
//  BuyLedgerDatabase+Preview.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

#if DEBUG

import Foundation
import SwiftData

// MARK: - DependencyKey

extension BuyLedgerDatabaseKey {

    /// Preview 使用已載入範例訂單的記憶體資料庫
    static var previewValue: any BuyLedgerDatabaseProtocol {
        assert(
            RuntimeEnvironment.allowsPreviewStub,
            "BuyLedgerDatabaseKey.previewValue 只能在 Preview、UI Test 或單元測試中使用"
        )
        let modelContainer = PersistenceContainer.makeInMemory(for: .preview)
        let context = ModelContext(modelContainer)
        for order in LedgerOrder.sampleOrders {
            context.insert(OrderRecord(order: order))
        }
        do {
            try context.save()
        } catch {
            // 記憶體資料庫 seed 失敗是程式錯誤
            fatalError("Preview database seed failed: \(error.localizedDescription)")
        }
        return BuyLedgerDatabase(modelContainer: modelContainer, storeLocation: .inMemory)
    }
}

#endif
