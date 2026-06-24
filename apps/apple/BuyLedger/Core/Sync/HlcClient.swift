//
//  HlcClient.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/22.
//

import ComposableArchitecture
import Foundation

/// HLC 三操作的可注入依賴 (generate / receive / compare)。物理時間 seed 自 ``Dependency``
/// 的 `\.date`、不直接讀系統時鐘；純函式核心委派 ``HlcClock``，writerId 與 lastIssued 由呼叫端
/// (同步引擎) 提供與持久化 (存 ``SyncMeta``)，使本依賴本身無狀態、易測
///
/// 與後端 `apps/backend/src/sync/hlc.ts`、web `apps/web/src/lib/sync/hlc.ts` 對同一組
/// `shared/sync-conformance/hlc-vectors.json` 全綠
struct HlcClient: Sendable {

    // MARK: - Dependency Properties

    /// 本地寫入事件的下一個時鐘 (注入當下毫秒)
    /// lastIssued 為 nil 視為起點
    var generate: @Sendable (_ lastIssued: Hlc?, _ writerId: String) -> Hlc

    /// 觀察到遠端時鐘後推進本地 lastIssued (標準 HLC 合併規則，注入當下毫秒)
    var receive: @Sendable (_ lastIssued: Hlc?, _ remote: Hlc, _ writerId: String) -> Hlc

    /// 依 p → c → w 比較兩時鐘 (-1 / 0 / 1)
    var compare: @Sendable (_ lhs: Hlc, _ rhs: Hlc) -> Int

    /// incoming 物理時間是否在 now 容忍界內
    /// (預設 ``HlcClock/skewToleranceMs``，注入當下毫秒)
    var isWithinSkewTolerance: @Sendable (_ remoteP: Int) -> Bool
}

// MARK: - DependencyKey

extension HlcClient: DependencyKey {

    // MARK: - Dependency Values

    /// 正式實作；物理毫秒一律經 `@Dependency(\.date)` 取得，
    /// 不直接讀系統時鐘
    nonisolated static var liveValue: HlcClient {
        HlcClient(
            generate: { lastIssued, writerId in
                @Dependency(\.date) var date
                let nowMs = Self.nowMs(date.now)
                return HlcClock.generate(lastIssued: lastIssued, nowMs: nowMs, writerId: writerId)
            },
            receive: { lastIssued, remote, writerId in
                @Dependency(\.date) var date
                let nowMs = Self.nowMs(date.now)
                return HlcClock.receive(
                    lastIssued: lastIssued,
                    remote: remote,
                    nowMs: nowMs,
                    writerId: writerId
                )
            },
            compare: { lhs, rhs in
                if lhs < rhs { return -1 }
                if rhs < lhs { return 1 }
                return 0
            },
            isWithinSkewTolerance: { remoteP in
                @Dependency(\.date) var date
                return HlcClock.isWithinSkewTolerance(remoteP: remoteP, nowMs: Self.nowMs(date.now))
            }
        )
    }

    /// 測試實作；沿用 ``liveValue`` 的純函式核心
    /// (HLC 行為平台中立、測試需確定性，故不拋錯)
    nonisolated static let testValue = liveValue
}

// MARK: - DependencyValues

extension DependencyValues {

    /// HLC 三操作的可注入依賴
    var hlcClient: HlcClient {
        get { self[HlcClient.self] }
        set { self[HlcClient.self] = newValue }
    }
}

// MARK: - Private Method

private extension HlcClient {

    /// 把注入的 `Date` 轉成 epoch 毫秒整數 (HLC 物理時間單位)
    /// - Parameter date: 注入的當下時間
    /// - Returns: epoch 毫秒整數
    static func nowMs(_ date: Date) -> Int {
        Int((date.timeIntervalSince1970 * 1000).rounded(.down))
    }
}
