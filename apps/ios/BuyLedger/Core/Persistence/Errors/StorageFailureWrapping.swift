//
//  StorageFailureWrapping.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

/// 可將持久化錯誤轉為呼叫端錯誤型別
protocol StorageFailureWrapping: Error {

    /// 建立呼叫端的持久化錯誤
    ///
    /// - Parameter error: 寫入操作的持久化失敗
    /// - Returns: 呼叫端錯誤型別的持久化失敗
    static func storage(_ error: PersistenceError) -> Self
}
