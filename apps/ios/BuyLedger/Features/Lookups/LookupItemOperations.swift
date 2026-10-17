//
//  LookupItemOperations.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/24.
//

import ComposableArchitecture
import Foundation

/// 提供四種主檔的載入、新增、刪除與改名操作
struct LookupItemOperations: Sendable {

    // MARK: - Properties

    /// 主檔讀寫與改名清理操作入口
    let lookupService: LookupService
}

// MARK: - Internal Method

extension LookupItemOperations {

    /// 載入指定種類的主檔目錄
    ///
    /// - Parameter kind: 要載入的主檔種類
    /// - Returns: 把讀取結果送回畫面的工作
    func load(kind: LookupKind) -> Effect<LookupManagementFeature.Action> {
        .run { [self] send in
            do throws(PersistenceError) {
                let catalog = try await lookupService.fetchItems(kind)
                await send(.itemsResponse(.success(catalog)))
            } catch {
                await send(.itemsResponse(.failure(error)))
            }
        }
    }

    /// 寫入新增項目並送回結果
    ///
    /// - Parameters:
    ///   - addition: 要新增的名稱與旗標
    ///   - kind: 要新增的主檔種類
    /// - Returns: 把新增結果送回畫面的工作
    func add(
        _ addition: LookupItemAddition,
        kind: LookupKind
    ) -> Effect<LookupManagementFeature.Action> {
        .run { [self] send in
            do throws(PersistenceError) {
                try await lookupService.addItem(kind, addition)
                await send(.addResponse(.success(addition)))
            } catch {
                await send(.addResponse(.failure(error)))
            }
        }
    }

    /// 寫入刪除並送回結果
    ///
    /// - Parameters:
    ///   - name: 要刪除的主檔名稱
    ///   - kind: 要刪除的主檔種類
    /// - Returns: 把刪除結果送回畫面的工作
    func delete(name: String, kind: LookupKind) -> Effect<LookupManagementFeature.Action> {
        .run { [self] send in
            do throws(PersistenceError) {
                try await lookupService.removeItem(kind, name)
                await send(.deleteResponse(.success(name)))
            } catch {
                await send(.deleteResponse(.failure(error)))
            }
        }
    }

    /// 寫入主檔與訂單改名並送回結果
    ///
    /// - Parameters:
    ///   - rename: 要寫入的新舊名稱
    ///   - kind: 要改名的主檔種類
    /// - Returns: 把改名結果送回畫面的工作
    func rename(
        _ rename: LookupItemRename,
        kind: LookupKind
    ) -> Effect<LookupManagementFeature.Action> {
        .run { [self] send in
            do throws(PersistenceError) {
                try await lookupService.renameItem(kind, rename)
                await send(.renameResponse(.success(rename)))
            } catch {
                await send(.renameResponse(.failure(error)))
            }
        }
    }
}
