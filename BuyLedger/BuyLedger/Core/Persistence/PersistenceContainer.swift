//
//  PersistenceContainer.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/2.
//

import Foundation
import SwiftData

/// 建立 BuyLedger 用的 ``ModelContainer`` 的工廠。
///
/// App 預設以純本機方式運行 (``CloudKitOption/disabled``)。要切換成 CloudKit 同步時，把 `BuyLedgerApp` 中 ``makeForApp()`` 換成 ``make(cloudKit:inMemoryOnly:)``、傳入 `.privateContainer("iCloud.com.leoho.BuyLedger")`，並補上 iCloud 與 Background Modes capabilities 即可。
enum PersistenceContainer {

    // MARK: - Cases

    /// CloudKit 同步策略。
    enum CloudKitOption: Equatable, Sendable {

        /// 關閉 CloudKit 同步 (純本機儲存)。
        case disabled

        /// 由 SwiftData 自動從 entitlements 推斷 CloudKit container ID。
        case automatic

        /// 指定特定 CloudKit container ID 的私人資料庫 (例如 `"iCloud.com.leoho.BuyLedger"`)。
        case privateContainer(String)

        /// 對應到 ``ModelConfiguration/CloudKitDatabase`` 的設定值。
        nonisolated var modelConfigurationValue: ModelConfiguration.CloudKitDatabase {
            switch self {
            case .disabled:
                return .none
            case .automatic:
                return .automatic
            case let .privateContainer(identifier):
                return .private(identifier)
            }
        }
    }

    // MARK: - Static Method

    /// 為 App 執行時建立 ``ModelContainer``。
    ///
    /// 為了能夠從 nonisolated 的 dependency container (如 `OrderRepository.liveValue`) 中安全呼叫，整個函式採 `nonisolated`，並且明確帶入所有 `ModelConfiguration` 參數，避免 SDK 預設值 (例如 `groupContainer: .automatic`) 的 main-actor 隔離影響。
    /// - Parameters:
    ///   - cloudKit: CloudKit 同步策略，預設 ``CloudKitOption/disabled``。
    ///   - inMemoryOnly: 是否僅存於記憶體 (測試與 preview 用途)，預設 `false`。
    /// - Returns: 已套用設定的 ``ModelContainer``。
    nonisolated static func make(
        cloudKit: CloudKitOption = .disabled,
        inMemoryOnly: Bool = false
    ) throws -> ModelContainer {
        let schema = Schema(versionedSchema: BuyLedgerSchemaV5.self)

        let configuration = ModelConfiguration(
            "BuyLedger",
            schema: schema,
            isStoredInMemoryOnly: inMemoryOnly,
            allowsSave: true,
            groupContainer: .none,
            cloudKitDatabase: cloudKit.modelConfigurationValue
        )

        return try ModelContainer(
            for: schema,
            migrationPlan: BuyLedgerMigrationPlan.self,
            configurations: configuration
        )
    }

    /// 建立純本機、no-CloudKit 的 production container；當 ``ModelContainer`` 初始化失敗時 fall back 為 in-memory，避免 App 直接 crash。
    /// - Returns: production 用的 ``ModelContainer``。
    nonisolated static func makeForApp() -> ModelContainer {
        do {
            return try make(cloudKit: .disabled)
        } catch {
            // SwiftData 初始化失敗 — 通常是 schema 改動但缺自訂 migration plan。
            // 開發階段 App 尚未上架，把舊 store 整批清除後重建是最穩定的恢復策略；
            // 真的需要保留資料時應改寫 `SchemaMigrationPlan` 取代這段 fallback。
            print("[BuyLedger] SwiftData 初始化失敗，將清除舊 store 後重建：\(error)")

            resetStoreFiles()

            do {
                return try make(cloudKit: .disabled)
            } catch {
                print("[BuyLedger] 重建仍失敗，退回 in-memory：\(error)")
                // swiftlint:disable:next force_try
                return try! make(cloudKit: .disabled, inMemoryOnly: true)
            }
        }
    }

    /// 嘗試刪除 `Application Support` 內的 SwiftData store 與相關 sidecar 檔 (`-wal` / `-shm`)。
    nonisolated private static func resetStoreFiles() {
        let fileManager = FileManager.default
        guard let support = try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ) else {
            return
        }

        let candidates = [
            "BuyLedger.store",
            "BuyLedger.store-wal",
            "BuyLedger.store-shm",
            "default.store",
            "default.store-wal",
            "default.store-shm",
        ].map { support.appendingPathComponent($0) }

        for url in candidates where fileManager.fileExists(atPath: url.path) {
            try? fileManager.removeItem(at: url)
        }
    }

    // MARK: - Static Properties

    /// 整個 App 共用的 production container。
    ///
    /// 多個 repository (``OrderRepository`` / ``CategoryRepository`` / ``PaymentMethodRepository``) 若各自呼叫 ``makeForApp()`` 會各自建立 `ModelContainer` 物件；雖然底層 SQLite 檔同名，但兩個 container 在同一個 process 內並存可能造成 SwiftData 內部狀態錯亂。透過共享同一個 container 讓所有 repo 走同一條資料管線。
    nonisolated static let shared: ModelContainer = makeForApp()
}
