//
//  BLUITestPersistenceMode.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/3.
//

#if DEBUG

/// UI 測試資料庫的儲存方式
enum BLUITestPersistenceMode: String, CaseIterable, Sendable {

    /// 每次啟動建立新的記憶體資料庫
    case inMemory

    /// 使用可跨 App 重啟讀取的本機資料庫
    case persistent
}

#endif
