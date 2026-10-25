//
//  MockBuyLedgerDatabase.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture
import Foundation
import SwiftData

@testable import BuyLedger

/// 包裝 `BuyLedgerDatabase` 的替身，依 `mode` 注入讀寫失敗並記錄呼叫次數，供失敗情境的測試使用
final class MockBuyLedgerDatabase: Sendable {

    // MARK: - Properties

    /// 實際執行讀寫的 `BuyLedgerDatabase`
    private let database: BuyLedgerDatabase

    /// 目前的失敗模式，決定讀寫是否注入失敗
    private let modeState = LockIsolated(Mode.passthrough)

    /// 讀寫與隔離 store 的呼叫次數
    private let callCounts = LockIsolated(CallCounts())

    // MARK: - Init

    /// 建立初始為直通模式的資料庫替身
    ///
    /// - Parameter database: 要包裝的正式資料庫
    init(database: BuyLedgerDatabase) {
        self.database = database
    }
}

// MARK: - Nested Types

extension MockBuyLedgerDatabase {

    /// 讀寫替身的控制模式，決定是否注入失敗，讀取失敗時另指定第幾次呼叫注入
    enum Mode: Sendable {

        /// 讀寫皆直接交給正式資料庫執行，不注入失敗
        case passthrough

        /// 指定序號的讀取呼叫丟出注入的錯誤
        ///
        /// - Parameters:
        ///   - call: 要注入錯誤的讀取呼叫序號
        ///   - error: 要丟出的錯誤
        case readFailure(call: Int, error: any Error & Sendable)

        /// 交易主體執行後丟出指定錯誤
        ///
        /// - Parameter error: 要丟出的錯誤
        case writeFailureAfterBody(error: any Error & Sendable)

        /// 交易主體執行後插入違反子項上限的探測模型，使保存失敗
        ///
        /// - Note: 測試容器的 schema 必須同時包含 `ResidueProbeParent` 與 `ResidueProbeChild`
        case saveFailureAfterBody
    }

    /// 讀取、寫入與隔離 store 各自的呼叫次數
    private struct CallCounts: Sendable {

        /// 已呼叫的讀取次數
        var read = 0

        /// 已呼叫的寫入次數
        var write = 0

        /// 已呼叫的 store 隔離次數
        var quarantineStore = 0
    }
}

// MARK: - Computed Properties

extension MockBuyLedgerDatabase {

    /// 目前的失敗模式，測試中可切換
    var mode: Mode {
        get {
            modeState.withValue { $0 }
        }
        set {
            modeState.withValue { $0 = newValue }
        }
    }

    /// 讀取呼叫次數
    var readCallCount: Int {
        callCounts.withValue { $0.read }
    }

    /// 寫入呼叫次數
    var writeCallCount: Int {
        callCounts.withValue { $0.write }
    }

    /// store 隔離呼叫次數
    var quarantineStoreCallCount: Int {
        callCounts.withValue { $0.quarantineStore }
    }
}

// MARK: - BuyLedgerDatabaseProtocol

extension MockBuyLedgerDatabase: BuyLedgerDatabaseProtocol {

    /// 記錄讀取呼叫，依模式注入失敗或交給正式資料庫執行
    ///
    /// - Parameter body: 要在底層資料庫執行的讀取操作
    /// - Returns: 讀取操作的領域資料
    /// - Throws: 指定呼叫的注入錯誤或底層讀取主體定義的 `Failure`
    /// - Note: 注入錯誤與 `Failure` 型別不符代表測試設定錯誤，視為程式錯誤
    func read<Value: Sendable, Failure: Error>(
        _ body: @Sendable (ModelContext) throws(Failure) -> Value
    ) async throws(Failure) -> Value {
        let mode = modeState.withValue {
            $0
        }
        let call = callCounts.withValue {
            $0.read += 1
            return $0.read
        }
        if case .readFailure(let failureCall, let error) = mode, call == failureCall {
            guard let failure = error as? Failure else {
                // 注入的錯誤與 `Failure` 型別不符代表測試設定寫錯，無法照設定丟出
                preconditionFailure("MockBuyLedgerDatabase 的 read 錯誤型別不符")
            }
            throw failure
        }
        return try await database.read(body)
    }

    /// 記錄寫入呼叫，依模式注入失敗或交給正式資料庫執行
    ///
    /// - Parameter body: 要在底層資料庫執行的寫入操作
    /// - Returns: 寫入操作的領域資料
    /// - Throws: `.writeFailureAfterBody` 時丟出注入的錯誤；`body` 失敗時丟出其 `Failure`；
    ///   `.saveFailureAfterBody` 插入違規資料導致保存失敗時丟出
    ///   `Failure.storage(.saveFailed(underlying:))`
    ///
    /// - Note: 注入錯誤與 `Failure` 型別不符代表測試設定錯誤，視為程式錯誤
    func write<Value: Sendable, Failure: StorageFailureWrapping>(
        _ body: @Sendable (ModelContext) throws(Failure) -> Value
    ) async throws(Failure) -> Value {
        callCounts.withValue {
            $0.write += 1
        }
        let mode = modeState.withValue {
            $0
        }
        switch mode {
        case .passthrough, .readFailure:
            return try await database.write(body)

        case .writeFailureAfterBody(let error):
            return try await database.write { context throws(Failure) in
                _ = try body(context)
                guard let failure = error as? Failure else {
                    // 注入的錯誤與 `Failure` 型別不符代表測試設定寫錯，無法照設定丟出
                    preconditionFailure("MockBuyLedgerDatabase 的 write 錯誤型別不符")
                }
                throw failure
            }

        case .saveFailureAfterBody:
            return try await database.write { context throws(Failure) in
                let value = try body(context)
                let parent = ResidueProbeModels.ResidueProbeParent(name: "invalid-parent")
                context.insert(parent)
                for index in 1...3 {
                    let child = ResidueProbeModels.ResidueProbeChild(name: "invalid-child-\(index)")
                    context.insert(child)
                    child.parent = parent
                }
                return value
            }
        }
    }

    /// 記錄隔離呼叫，並交給正式資料庫隔離 store
    ///
    /// - Returns: 實際建立的備份目錄；`inMemory` 資料庫時為 `nil`
    /// - Throws: 路徑解析失敗時丟出 `.directoryResolutionFailed`；
    ///   隔離目錄建立失敗時丟出 `.directoryCreationFailed`，檔案搬移失敗時丟出 `.fileMoveFailed`
    func quarantineStore() async throws(PersistenceRecoveryError) -> URL? {
        callCounts.withValue { $0.quarantineStore += 1 }
        return try await database.quarantineStore()
    }
}
