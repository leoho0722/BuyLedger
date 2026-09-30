//
//  TestContainerCreationLock.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import Synchronization

/// 將測試中的 SwiftData 容器建立動作依序執行
enum TestContainerCreationLock {

    // MARK: - Properties

    /// 所有測試共用的容器建立鎖
    private static let lock = Mutex(())
}

// MARK: - Internal Method

extension TestContainerCreationLock {

    /// 在共用互斥鎖內執行同步容器建立
    ///
    /// - Parameter operation: 建立容器的同步操作
    /// - Returns: 建立操作的結果
    /// - Throws: 重新丟出 `operation` 拋出的 `Failure`
    /// - Note: 不使用 `LockIsolated`，因為它要求 closure 與回傳值符合 `Sendable`
    static func withLock<Value, Failure: Error>(
        _ operation: () throws(Failure) -> Value
    ) throws(Failure) -> Value {
        try lock.withLock { _ throws(Failure) in
            try operation()
        }
    }
}
