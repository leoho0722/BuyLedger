//
//  NameLookupPersistenceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/8/1.
//

import Foundation
import SwiftData
import Testing
@testable import BuyLedger

/// 驗證名稱主檔持久化
@MainActor
struct NameLookupPersistenceTests {
    
    // MARK: - Tests (CategoryRecord)
    
    @Test func categoryFetchAllSortsAscending() async throws(any Error) {
        try await verifyFetchAllSortsAscending(CategoryRecord.self)
    }
    
    @Test func categoryUpsertSameNameDoesNotDuplicate() async throws(any Error) {
        try await verifyUpsertSameNameDoesNotDuplicate(CategoryRecord.self)
    }
    
    @Test func categoryDeleteMissingNameIsNoOp() async throws(any Error) {
        try await verifyDeleteMissingNameIsNoOp(CategoryRecord.self)
    }
    
    @Test func categoryRenameToExistingNameMergesWithoutDuplicate() async throws(any Error) {
        try await verifyRenameToExistingNameMergesWithoutDuplicate(CategoryRecord.self)
    }
    
    // MARK: - Tests (OrderSourceRecord)
    
    @Test func orderSourceFetchAllSortsAscending() async throws(any Error) {
        try await verifyFetchAllSortsAscending(OrderSourceRecord.self)
    }
    
    @Test func orderSourceUpsertSameNameDoesNotDuplicate() async throws(any Error) {
        try await verifyUpsertSameNameDoesNotDuplicate(OrderSourceRecord.self)
    }
    
    @Test func orderSourceDeleteMissingNameIsNoOp() async throws(any Error) {
        try await verifyDeleteMissingNameIsNoOp(OrderSourceRecord.self)
    }
    
    @Test func orderSourceRenameToExistingNameMergesWithoutDuplicate() async throws(any Error) {
        try await verifyRenameToExistingNameMergesWithoutDuplicate(OrderSourceRecord.self)
    }
}

// MARK: - Private Method

private extension NameLookupPersistenceTests {
    
    /// 讀出全部主檔名稱應依 locale 升冪排序
    /// - Parameter type: 要驗證的記錄型別
    /// - Throws: 測試容器建立或資料讀取失敗時拋出錯誤
    func verifyFetchAllSortsAscending<Record: NameLookupRecord>(_ type: Record.Type) async throws(any Error) {
        let persistence = try makePersistence(Record.self)
        try await persistence.upsert(name: "香蕉")
        try await persistence.upsert(name: "蘋果")
        try await persistence.upsert(name: "橘子")
        
        let names = try await persistence.fetchAll()
        
        #expect(names == names.sorted { $0.localizedStandardCompare($1) == .orderedAscending })
        #expect(names.count == 3)
    }
    
    /// 同名重複寫入不應重複建立
    /// - Parameter type: 要驗證的記錄型別
    /// - Throws: 測試容器建立或資料寫入失敗時拋出錯誤
    func verifyUpsertSameNameDoesNotDuplicate<Record: NameLookupRecord>(_ type: Record.Type) async throws(any Error) {
        let persistence = try makePersistence(Record.self)
        try await persistence.upsert(name: "重複項目")
        try await persistence.upsert(name: "重複項目")
        
        let names = try await persistence.fetchAll()
        
        #expect(names == ["重複項目"])
    }
    
    /// 刪除不存在的名稱應為無操作
    /// - Parameter type: 要驗證的記錄型別
    /// - Throws: 測試容器建立或資料寫入失敗時拋出錯誤
    func verifyDeleteMissingNameIsNoOp<Record: NameLookupRecord>(_ type: Record.Type) async throws(any Error) {
        let persistence = try makePersistence(Record.self)
        try await persistence.upsert(name: "既有項目")
        
        try await persistence.delete(name: "不存在的項目")
        
        let names = try await persistence.fetchAll()
        #expect(names == ["既有項目"])
    }
    
    /// 更名到已存在的新名稱時，舊列應被刪除且不產生重複列
    /// - Parameter type: 要驗證的記錄型別
    /// - Throws: 測試容器建立或資料寫入失敗時拋出錯誤
    func verifyRenameToExistingNameMergesWithoutDuplicate<Record: NameLookupRecord>(
        _ type: Record.Type
    ) async throws(any Error) {
        let persistence = try makePersistence(Record.self)
        try await persistence.upsert(name: "舊名")
        try await persistence.upsert(name: "新名")
        
        try await persistence.rename(from: "舊名", to: "新名")
        
        let names = try await persistence.fetchAll()
        #expect(names == ["新名"])
    }
    
    /// 用記憶體 ModelContainer 建立獨立 persistence
    /// - Parameter type: 要驗證的記錄型別
    /// - Returns: NameLookupPersistence
    /// - Throws: 測試容器建立失敗時拋出錯誤
    func makePersistence<Record: NameLookupRecord>(
        _ type: Record.Type
    ) throws(any Error) -> NameLookupPersistence<Record> {
        let container = PersistenceContainer.makeInMemory(for: .testing)
        return NameLookupPersistence<Record>(modelContainer: container)
    }
}
