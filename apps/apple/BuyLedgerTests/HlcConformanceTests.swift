//
//  HlcConformanceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/6/22.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// HLC 跨平台 conformance：直接讀取 `shared/sync-conformance/hlc-vectors.json` (非複製)，
/// 對 encode / compare / generate / receive / tolerance 五操作驗證 iOS 與後端 / web 行為一致
@MainActor
struct HlcConformanceTests {

    // MARK: - Encode

    @Test
    func encodeMatchesVectors() throws {
        let vectors = try Self.loadVectors()
        for entry in vectors.encode {
            let hlc = entry.hlc.hlc
            #expect(hlc.encoded == entry.expected)
            // round-trip：解碼回來等同原值
            #expect(Hlc(encoded: entry.expected) == hlc)
        }
    }

    // MARK: - Compare

    @Test
    func compareMatchesVectors() throws {
        let vectors = try Self.loadVectors()
        let client = HlcClient.testValue
        for entry in vectors.compare {
            let a = entry.a.hlc
            let b = entry.b.hlc
            #expect(client.compare(a, b) == entry.expected)
        }
    }

    // MARK: - Generate

    @Test
    func generateMatchesVectors() throws {
        let vectors = try Self.loadVectors()
        for entry in vectors.generate {
            let result = HlcClock.generate(
                lastIssued: entry.lastIssued?.hlc,
                nowMs: entry.nowMs,
                writerId: entry.writerId
            )
            #expect(result == entry.expected.hlc)
        }
    }

    // MARK: - Receive

    @Test
    func receiveMatchesVectors() throws {
        let vectors = try Self.loadVectors()
        for entry in vectors.receive {
            let result = HlcClock.receive(
                lastIssued: entry.lastIssued?.hlc,
                remote: entry.remote.hlc,
                nowMs: entry.nowMs,
                writerId: entry.writerId
            )
            #expect(result == entry.expected.hlc)
        }
    }

    // MARK: - Tolerance

    @Test
    func toleranceMatchesVectors() throws {
        let vectors = try Self.loadVectors()
        for entry in vectors.tolerance {
            let result = HlcClock.isWithinSkewTolerance(
                remoteP: entry.remoteP,
                nowMs: entry.nowMs,
                toleranceMs: entry.toleranceMs
            )
            #expect(result == entry.expected)
        }
    }

    // MARK: - Injected HlcClient determinism

    /// 固定 `\.date` 與穩定 writerId 下，
    /// `HlcClient.generate` 的物理段對齊注入時間、決定性決勝
    @Test
    func injectedClientSeedsFromInjectedDate() {
        let fixedMs = 1_700_000_123_000
        let fixedDate = Date(timeIntervalSince1970: TimeInterval(fixedMs) / 1000)
        withDependencies {
            $0.date = .constant(fixedDate)
        } operation: {
            let client = HlcClient.liveValue
            let first = client.generate(nil, "device-a")
            #expect(first.p == fixedMs)
            #expect(first.c == 0)
            #expect(first.w == "device-a")
            // 同毫秒重發決定性遞增 counter
            let second = client.generate(first, "device-a")
            #expect(second.p == fixedMs)
            #expect(second.c == 1)
        }
    }
}

// MARK: - Vector Loading

extension HlcConformanceTests {

    /// 自共用位置讀取 HLC vectors
    /// (以本測試檔路徑回推 repo 根，避免複製或 bundle 資源)
    /// - Returns: 解碼後的 vectors 集合
    static func loadVectors() throws -> HlcVectors {
        let url = sharedConformanceURL(file: "hlc-vectors.json")
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(HlcVectors.self, from: data)
    }

    /// 由 `#filePath` 上推 4 層 (BuyLedgerTests → apple → apps → repo root)
    /// 取得共用 conformance 檔的絕對 URL
    /// - Parameter file: 檔名
    /// - Returns: 共用 conformance 檔的 URL
    static func sharedConformanceURL(file: String) -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("shared")
            .appendingPathComponent("sync-conformance")
            .appendingPathComponent(file)
    }
}

// MARK: - Vector Models

extension HlcConformanceTests {

    /// HLC vectors 檔的解碼模型
    struct HlcVectors: Decodable {

        /// encode 案例
        let encode: [EncodeCase]

        /// compare 案例
        let compare: [CompareCase]

        /// generate 案例
        let generate: [GenerateCase]

        /// receive 案例
        let receive: [ReceiveCase]

        /// tolerance 案例
        let tolerance: [ToleranceCase]
    }

    /// 可解碼的 HLC 三元組 (轉領域 ``Hlc``)
    struct HlcLiteral: Decodable {

        /// 物理毫秒
        let p: Int

        /// 邏輯計數器
        let c: Int

        /// 寫入者識別
        let w: String

        /// 對應的領域 HLC
        var hlc: Hlc { Hlc(p: p, c: c, w: w) }
    }

    /// encode 案例
    struct EncodeCase: Decodable {

        let hlc: HlcLiteral
        let expected: String
    }

    /// compare 案例 (expected 為 -1/0/1)
    struct CompareCase: Decodable {

        let a: HlcLiteral
        let b: HlcLiteral
        let expected: Int
    }

    /// generate 案例
    struct GenerateCase: Decodable {

        let lastIssued: HlcLiteral?
        let nowMs: Int
        let writerId: String
        let expected: HlcLiteral
    }

    /// receive 案例
    struct ReceiveCase: Decodable {

        let lastIssued: HlcLiteral?
        let remote: HlcLiteral
        let nowMs: Int
        let writerId: String
        let expected: HlcLiteral
    }

    /// tolerance 案例
    struct ToleranceCase: Decodable {

        let remoteP: Int
        let nowMs: Int
        let toleranceMs: Int
        let expected: Bool
    }
}
