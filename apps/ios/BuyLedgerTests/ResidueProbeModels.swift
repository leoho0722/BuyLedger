//
//  ResidueProbeModels.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation
import SwiftData

@testable import BuyLedger

/// 建立交易隔離測試使用的暫存 store 與模型
enum ResidueProbeModels {

    // MARK: - Properties

    /// Fixture 與讀回資料庫共用的模型結構
    static let schema = Schema([
        OrderRecord.self,
        CategoryRecord.self,
        PaymentMethodRecord.self,
        CampaignRecord.self,
        CampaignReminderRecord.self,
        ResidueProbeParent.self,
        ResidueProbeChild.self,
    ])
}

// MARK: - Nested Types

extension ResidueProbeModels {

    /// 暫存磁碟資料庫與其目錄
    struct DiskFixture: Sendable {

        /// 測試用的 SwiftData 容器
        let container: ModelContainer

        /// 暫存 store 所在目錄
        let directoryURL: URL
    }

    /// 子項數量受限制的 parent
    @Model
    final class ResidueProbeParent {

        /// parent 名稱
        var name: String

        /// 最多只能關聯兩個子項
        @Relationship(
            deleteRule: .nullify,
            maximumModelCount: 2,
            inverse: \ResidueProbeChild.parent
        )
        var children: [ResidueProbeChild] = []

        /// 建立 parent
        ///
        /// - Parameter name: parent 名稱
        init(name: String) {
            self.name = name
        }
    }

    /// 可關聯至受限 parent 的子項
    @Model
    final class ResidueProbeChild {

        /// 子項名稱
        var name: String

        /// 所屬 parent
        var parent: ResidueProbeParent?

        /// 建立子項
        ///
        /// - Parameter name: 子項名稱
        init(name: String) {
            self.name = name
        }
    }
}

// MARK: - Internal Method

extension ResidueProbeModels {

    /// 建立包含有效既有資料的暫存磁碟 store
    ///
    /// - Parameters:
    ///   - orders: 要先寫入 store 的訂單
    ///   - categories: 要先寫入 store 的類別名稱
    /// - Returns: 含暫存容器與目錄的 fixture
    /// - Throws: 暫存目錄建立、`ModelContainer` 建立或初始 `ModelContext.save()` 失敗時丟出底層 API 錯誤
    static func makeDiskFixture(
        orders: [LedgerOrder] = [],
        categories: [String] = []
    ) throws -> DiskFixture {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("BuyLedgerResidueProbe-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let configuration = ModelConfiguration(
            url: storeURL(in: directoryURL),
            cloudKitDatabase: .none
        )
        let container = try TestContainerCreationLock.withLock {
            try ModelContainer(for: schema, configurations: [configuration])
        }
        let context = ModelContext(container)
        for name in categories {
            context.insert(CategoryRecord(name: name))
        }
        for order in orders {
            context.insert(OrderRecord(order: order))
        }
        let parent = ResidueProbeParent(name: "fixture-parent")
        context.insert(parent)
        let child = ResidueProbeChild(name: "fixture-child")
        context.insert(child)
        child.parent = parent
        try context.save()
        return DiskFixture(container: container, directoryURL: directoryURL)
    }

    /// 取得暫存 store 的固定檔案 URL
    ///
    /// - Parameter directoryURL: 暫存 store 所在目錄
    /// - Returns: `BuyLedger.store` 的 URL
    static func storeURL(in directoryURL: URL) -> URL {
        directoryURL.appendingPathComponent("BuyLedger.store")
    }
}
