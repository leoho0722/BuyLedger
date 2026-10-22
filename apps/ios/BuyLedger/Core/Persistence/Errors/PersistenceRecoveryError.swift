//
//  PersistenceRecoveryError.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation

/// 復原搬移資料庫檔案時發生的錯誤
enum PersistenceRecoveryError: Error, Sendable {

    /// 解析 Application Support 目錄失敗
    ///
    /// - Parameter underlying: 解析目錄時原本拋出的錯誤
    case directoryResolutionFailed(underlying: any Error & Sendable)

    /// 建立復原目錄失敗
    ///
    /// - Parameter underlying: 建立目錄時原本拋出的錯誤
    case directoryCreationFailed(underlying: any Error & Sendable)

    /// 搬移資料庫檔案失敗
    ///
    /// - Parameters:
    ///   - fileName: 無法搬移的檔案名稱
    ///   - underlying: 搬移檔案時原本拋出的錯誤
    case fileMoveFailed(fileName: String, underlying: any Error & Sendable)
}

// MARK: - LocalizedError

extension PersistenceRecoveryError: LocalizedError {

    /// 顯示各種 store 復原失敗的底層診斷訊息
    var errorDescription: String? {
        switch self {
        case .directoryResolutionFailed(let underlying), .directoryCreationFailed(let underlying):
            underlying.localizedDescription

        case .fileMoveFailed(let fileName, let underlying):
            "\(fileName): \(underlying.localizedDescription)"
        }
    }
}
