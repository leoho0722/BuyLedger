//
//  BLUITestSettingsStore.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

#if DEBUG

import Synchronization

/// 以記憶體保存設定快照的容器
final class BLUITestSettingsStore: Sendable {

    // MARK: - Properties

    /// 目前的設定快照
    ///
    /// - Note: ``SettingsService/load`` 是同步介面，因此以 `Mutex` 保護快照
    private let snapshot: Mutex<SettingsSnapshot>

    // MARK: - Init

    /// 以初始快照建立容器
    ///
    /// - Parameter initial: 套用啟動參數後的初始設定
    private init(initial: SettingsSnapshot) {
        snapshot = Mutex(initial)
    }
}

// MARK: - Internal Method

extension BLUITestSettingsStore {

    /// 以記憶體保存指定的初始設定快照
    ///
    /// - Parameter initial: 套用啟動參數後的初始設定
    /// - Returns: 可讀寫該快照的設定服務
    static func makeSettingsService(initial: SettingsSnapshot) -> SettingsService {
        let store = Self(initial: initial)
        return SettingsService(
            load: { store.load() },
            save: { store.save($0) }
        )
    }
}

// MARK: - Private Method

private extension BLUITestSettingsStore {

    /// 讀出目前設定
    ///
    /// - Returns: 目前的設定快照
    func load() -> SettingsSnapshot {
        snapshot.withLock { $0 }
    }

    /// 覆寫目前設定
    ///
    /// - Parameter newSnapshot: 要寫入的設定快照
    func save(_ newSnapshot: SettingsSnapshot) {
        snapshot.withLock { $0 = newSnapshot }
    }
}

#endif
