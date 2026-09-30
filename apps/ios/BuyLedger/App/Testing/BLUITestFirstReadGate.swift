//
//  BLUITestFirstReadGate.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

#if DEBUG

import Synchronization

/// UI 測試模擬「第一次讀取失敗、重試後成功」時使用，只有第一次讀取會被判為失敗
final class BLUITestFirstReadGate: Sendable {

    // MARK: - Properties

    /// 是否尚未觸發第一次讀取失敗
    ///
    /// - Note: 以 `Mutex` 保護旗標，確保並行讀取只會失敗一次
    private let isFailurePending = Mutex(true)
}

// MARK: - Internal Method

extension BLUITestFirstReadGate {

    /// 消耗一次失敗額度
    ///
    /// - Returns: 首次呼叫回 `true` (該次應失敗)，之後一律回 `false`
    func consumeFailure() -> Bool {
        isFailurePending.withLock {
            let shouldFail = $0
            $0 = false
            return shouldFail
        }
    }
}

#endif
