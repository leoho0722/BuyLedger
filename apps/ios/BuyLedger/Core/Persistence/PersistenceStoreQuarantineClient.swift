//
//  PersistenceStoreQuarantineClient.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/26.
//

import ComposableArchitecture
import Foundation

/// 將無法開啟的 store 移至隔離備份目錄的可注入介面
struct PersistenceStoreQuarantineClient: Sendable {
    
    // MARK: - Dependency Properties
    
    /// 搬移目前 Application Support 目錄中的 store 檔
    /// - Throws: store 路徑解析或檔案搬移失敗時拋出 ``PersistenceRecoveryError``
    var quarantine: @Sendable () throws(PersistenceRecoveryError) -> Void
}

// MARK: - Dependency Values

extension PersistenceStoreQuarantineClient: DependencyKey {
    
    /// 正式環境只在使用者明確確認後才搬移 store 檔
    nonisolated static let liveValue = PersistenceStoreQuarantineClient(
        quarantine: { () throws(PersistenceRecoveryError) in
            let fileManager = FileManager.default
            let applicationSupportDirectory: URL
            do {
                applicationSupportDirectory = try fileManager.url(
                    for: .applicationSupportDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                )
            } catch {
                throw PersistenceRecoveryError.directoryResolutionFailed(
                    message: error.localizedDescription
                )
            }
            _ = try PersistenceStoreQuarantine.quarantine(
                storeDirectory: applicationSupportDirectory,
                backupDirectory: applicationSupportDirectory
            )
        }
    )
    
    /// 測試預設不碰檔案系統
    nonisolated static let testValue = PersistenceStoreQuarantineClient(quarantine: {})
    
    /// Preview 預設不碰檔案系統
    nonisolated static let previewValue = PersistenceStoreQuarantineClient(quarantine: {})
}
