//
//  NameLookupPersistenceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/08/01.
//

import Foundation
import SwiftData
import Testing
@testable import BuyLedger

/// 驗證名稱主檔持久化
@MainActor
struct NameLookupPersistenceTests {

    // MARK: - Tests (CategoryRecord)

    /// 驗證名稱主檔持久化在此情境下的資料結果
    @Test func categoryFetchAllSortsAscending() async throws(any Error) {
        // Given

        // When

        let names = try await fetchAllSortsAscending(CategoryRecord.self)

        // Then

        #expect(names == names.sorted { $0.localizedStandardCompare($1) == .orderedAscending })
        #expect(names.count == 3)
    }

    /// 驗證名稱主檔持久化在此情境下的資料結果
    @Test func categoryUpsertSameNameDoesNotDuplicate() async throws(any Error) {
        // Given

        // When

        let names = try await upsertSameNameDoesNotDuplicate(CategoryRecord.self)

        // Then

        #expect(names == ["重複項目"])
    }

    /// 驗證名稱主檔持久化在此情境下的資料結果
    @Test func categoryDeleteMissingNameIsNoOp() async throws(any Error) {
        // Given

        // When

        let names = try await deleteMissingNameIsNoOp(CategoryRecord.self)

        // Then

        #expect(names == ["既有項目"])
    }

    /// 驗證名稱主檔持久化在此情境下的資料結果
    @Test func categoryRenameToExistingNameMergesWithoutDuplicate() async throws(any Error) {
        // Given

        // When

        let names = try await renameToExistingNameMergesWithoutDuplicate(CategoryRecord.self)

        // Then

        #expect(names == ["新名"])
    }

    // MARK: - Tests (OrderSourceRecord)

    /// 驗證名稱主檔持久化在此情境下的資料結果
    @Test func orderSourceFetchAllSortsAscending() async throws(any Error) {
        // Given

        // When

        let names = try await fetchAllSortsAscending(OrderSourceRecord.self)

        // Then

        #expect(names == names.sorted { $0.localizedStandardCompare($1) == .orderedAscending })
        #expect(names.count == 3)
    }

    /// 驗證名稱主檔持久化在此情境下的資料結果
    @Test func orderSourceUpsertSameNameDoesNotDuplicate() async throws(any Error) {
        // Given

        // When

        let names = try await upsertSameNameDoesNotDuplicate(OrderSourceRecord.self)

        // Then

        #expect(names == ["重複項目"])
    }

    /// 驗證名稱主檔持久化在此情境下的資料結果
    @Test func orderSourceDeleteMissingNameIsNoOp() async throws(any Error) {
        // Given

        // When

        let names = try await deleteMissingNameIsNoOp(OrderSourceRecord.self)

        // Then

        #expect(names == ["既有項目"])
    }

    /// 驗證名稱主檔持久化在此情境下的資料結果
    @Test func orderSourceRenameToExistingNameMergesWithoutDuplicate() async throws(any Error) {
        // Given

        // When

        let names = try await renameToExistingNameMergesWithoutDuplicate(OrderSourceRecord.self)

        // Then

        #expect(names == ["新名"])
    }
}

// MARK: - Private Method

private extension NameLookupPersistenceTests {

    /// 讀出全部主檔名稱應依 locale 升冪排序
    /// - Parameter type: 要驗證的記錄型別
    /// - Throws: 測試容器建立或資料讀取失敗時拋出錯誤
    func fetchAllSortsAscending<Record: NameLookupRecordProtocol>(_ type: Record.Type)
        async throws(any Error) -> [String] {
        let persistence = try makePersistence(Record.self)
        try await persistence.upsert(name: "香蕉")
        try await persistence.upsert(name: "蘋果")
        try await persistence.upsert(name: "橘子")

        let names = try await persistence.fetchAll()

        return names
    }

    /// 同名重複寫入不應重複建立
    /// - Parameter type: 要驗證的記錄型別
    /// - Throws: 測試容器建立或資料寫入失敗時拋出錯誤
    func upsertSameNameDoesNotDuplicate<Record: NameLookupRecordProtocol>(_ type: Record.Type)
        async throws(any Error) -> [String] {
        let persistence = try makePersistence(Record.self)
        try await persistence.upsert(name: "重複項目")
        try await persistence.upsert(name: "重複項目")

        let names = try await persistence.fetchAll()

        return names
    }

    /// 刪除不存在的名稱應為無操作
    /// - Parameter type: 要驗證的記錄型別
    /// - Throws: 測試容器建立或資料寫入失敗時拋出錯誤
    func deleteMissingNameIsNoOp<Record: NameLookupRecordProtocol>(_ type: Record.Type)
        async throws(any Error) -> [String] {
        let persistence = try makePersistence(Record.self)
        try await persistence.upsert(name: "既有項目")

        try await persistence.delete(name: "不存在的項目")

        let names = try await persistence.fetchAll()
        return names
    }

    /// 更名到已存在的新名稱時，舊列應被刪除且不產生重複列
    /// - Parameter type: 要驗證的記錄型別
    /// - Throws: 測試容器建立或資料寫入失敗時拋出錯誤
    func renameToExistingNameMergesWithoutDuplicate<Record: NameLookupRecordProtocol>(
        _ type: Record.Type
    ) async throws(any Error) -> [String] {
        let persistence = try makePersistence(Record.self)
        try await persistence.upsert(name: "舊名")
        try await persistence.upsert(name: "新名")

        try await persistence.rename(from: "舊名", to: "新名")

        let names = try await persistence.fetchAll()
        return names
    }

    /// 用記憶體 ModelContainer 建立獨立 persistence
    /// - Parameter type: 要驗證的記錄型別
    /// - Returns: NameLookupPersistence
    /// - Throws: 測試容器建立失敗時拋出錯誤
    func makePersistence<Record: NameLookupRecordProtocol>(
        _ type: Record.Type
    ) throws(any Error) -> NameLookupPersistence<Record> {
        let container = PersistenceContainer.makeInMemory(for: .testing)
        return NameLookupPersistence<Record>(modelContainer: container)
    }
}
