//
//  Hlc.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/21.
//

import Foundation

/// 跨裝置同步的 Hybrid Logical Clock (HLC)
///
/// 演算法與後端 apps/backend/src/sync/hlc.ts 及 web apps/web/src/lib/sync/hlc.ts 完全一致
/// (規格與跨平台 conformance vectors 見 shared/sync-conformance/)。writerId 為每安裝穩定 id
/// (後端為 server)
struct Hlc: Equatable, Comparable, Sendable {

    // MARK: - Data Properties

    /// 物理毫秒 (epoch millis)
    let p: Int

    /// 邏輯計數器 (同一毫秒內的因果序)
    let c: Int

    /// 寫入者識別 (決勝最後一關)
    let w: String

    // MARK: - Init

    /// 以物理毫秒、邏輯計數器與寫入者識別建立時鐘
    /// - Parameters:
    ///   - p: 物理毫秒 (epoch millis)
    ///   - c: 邏輯計數器 (同一毫秒內的因果序)
    ///   - w: 寫入者識別 (決勝最後一關)
    init(p: Int, c: Int, w: String) {
        self.p = p
        self.c = c
        self.w = w
    }

    /// 反序列化 `p:c:w`；writerId 不含冒號。格式錯誤回 nil
    /// - Parameter encoded: 編碼後的 HLC 字串 `p:c:w`
    init?(encoded: String) {
        let parts = encoded.split(
            separator: ":",
            maxSplits: 2,
            omittingEmptySubsequences: false
        )
        guard parts.count == 3,
              let p = Int(parts[0]),
              let c = Int(parts[1]) else {
            return nil
        }
        self.p = p
        self.c = c
        self.w = String(parts[2])
    }
}

// MARK: - Computed Properties

extension Hlc {

    /// 序列化為可排序字串 `p(13):c(6):w`，使字典序等同因果序
    var encoded: String {
        "\(Self.pad(p, width: 13)):\(Self.pad(c, width: 6)):\(w)"
    }
}

// MARK: - Comparable

extension Hlc {

    /// 依 p → c → w 比較
    /// - Parameters:
    ///   - lhs: 左運算元
    ///   - rhs: 右運算元
    /// - Returns: `lhs` 因果早於 `rhs` 時為 `true`
    static func < (lhs: Hlc, rhs: Hlc) -> Bool {
        if lhs.p != rhs.p { return lhs.p < rhs.p }
        if lhs.c != rhs.c { return lhs.c < rhs.c }
        return lhs.w < rhs.w
    }
}

// MARK: - Private Method

private extension Hlc {

    /// 左補零至指定寬度；長度已達寬度則原樣回傳
    /// - Parameters:
    ///   - value: 要補零的整數
    ///   - width: 目標固定寬度
    /// - Returns: 左補零後的固定寬度字串
    static func pad(_ value: Int, width: Int) -> String {
        let string = String(value)
        return string.count >= width
            ? string
            : String(repeating: "0", count: width - string.count) + string
    }
}

// MARK: - HlcClock

/// HLC 的三個操作 (generate / receive / 容忍判定)，與後端、web 一致；純函式、不持有狀態
///
/// 物理時間由呼叫端 (sync 引擎) 經 @Dependency(\.date) 注入 nowMs，不在此直接讀系統時鐘
enum HlcClock {

    // MARK: - Static Properties

    /// 未來時鐘容忍度 (毫秒)；與後端一致
    static let skewToleranceMs = 5 * 60 * 1000
}

// MARK: - Operations

extension HlcClock {

    /// 本地寫入事件的下一個時鐘。lastIssued 為 nil 視為起點
    /// - Parameters:
    ///   - lastIssued: 本地最後一次發出的時鐘；nil 視為起點
    ///   - nowMs: 注入的當下物理毫秒
    ///   - writerId: 本機寫入者識別
    /// - Returns: 遞增後的新時鐘
    static func generate(lastIssued: Hlc?, nowMs: Int, writerId: String) -> Hlc {
        let lastP = lastIssued?.p ?? -1
        let p = max(nowMs, lastP)
        let c = (lastIssued != nil && p == lastIssued!.p) ? lastIssued!.c + 1 : 0
        return Hlc(p: p, c: c, w: writerId)
    }

    /// 觀察到遠端時鐘後推進本地 lastIssued (標準 HLC 合併規則)
    /// - Parameters:
    ///   - lastIssued: 本地最後一次發出的時鐘；nil 視為起點
    ///   - remote: 觀察到的遠端時鐘
    ///   - nowMs: 注入的當下物理毫秒
    ///   - writerId: 本機寫入者識別
    /// - Returns: 合併並推進後的新時鐘
    static func receive(lastIssued: Hlc?, remote: Hlc, nowMs: Int, writerId: String) -> Hlc {
        let lastP = lastIssued?.p ?? -1
        let p = max(lastP, remote.p, nowMs)
        let tieLast = lastIssued != nil && p == lastIssued!.p
        let tieRemote = p == remote.p

        let c: Int
        if tieLast && tieRemote {
            c = max(lastIssued!.c, remote.c) + 1
        } else if tieLast {
            c = lastIssued!.c + 1
        } else if tieRemote {
            c = remote.c + 1
        } else {
            c = 0
        }
        return Hlc(p: p, c: c, w: writerId)
    }

    /// 偏移容忍：incoming 物理時間不得超過 now 容忍界
    /// - Parameters:
    ///   - remoteP: 遠端時鐘的物理毫秒
    ///   - nowMs: 注入的當下物理毫秒
    ///   - toleranceMs: 未來時鐘容忍度 (毫秒，預設 ``skewToleranceMs``)
    /// - Returns: 在容忍界內為 `true`
    static func isWithinSkewTolerance(
        remoteP: Int,
        nowMs: Int,
        toleranceMs: Int = skewToleranceMs
    ) -> Bool {
        remoteP <= nowMs + toleranceMs
    }
}
