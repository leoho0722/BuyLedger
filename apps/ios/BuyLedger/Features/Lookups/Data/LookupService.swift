//
//  LookupService.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/16.
//

import ComposableArchitecture
import Foundation
import SwiftData

/// 四種主檔與引用訂單的操作入口；
/// 正式實作在 `liveValue`、Preview 在 `previewValue`、測試預設值在 `testValue`
struct LookupService: Sendable {

    // MARK: - Properties

    /// 讀取指定種類的主檔，其他種類保持空白
    ///
    /// - Parameter kind: 要讀取的主檔種類
    /// - Returns: 只包含指定種類的目錄
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    var fetchItems: FetchItems

    /// 新增主檔，付款方式同名時覆寫旗標
    ///
    /// - Parameters:
    ///   - kind: 要新增的主檔種類
    ///   - addition: 名稱與付款方式旗標
    /// - Throws: 查詢或儲存失敗時丟出 `PersistenceError`
    var addItem: AddItem

    /// 刪除指定名稱的主檔，不存在時保留原資料
    ///
    /// - Parameters:
    ///   - kind: 要刪除的主檔種類
    ///   - name: 要刪除的名稱
    /// - Throws: 查詢或儲存失敗時丟出 `PersistenceError`
    var removeItem: RemoveItem

    /// 在同一次寫入內改名主檔與引用訂單，任一步失敗就全部不套用；付款方式撞名時合併旗標
    ///
    /// - Parameters:
    ///   - kind: 要改名的主檔種類
    ///   - rename: 原名稱與尚未去除前後空白的新名稱
    /// - Throws: 查詢或儲存失敗時丟出 `PersistenceError`
    var renameItem: RenameItem

    /// 計算目前使用指定付款方式的訂單筆數
    ///
    /// - Parameter paymentMethod: 要查詢的付款方式名稱
    /// - Returns: 資料庫內符合名稱的訂單筆數
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    var countOrders: CountOrders

    /// 在同一次寫入內編輯付款方式，並重算當下引用原名稱的訂單，任一步失敗就全部不套用
    ///
    /// - Parameters:
    ///   - originalName: 原付款方式名稱
    ///   - newName: 尚未去除前後空白的新名稱
    ///   - flags: 要覆寫的付款方式旗標
    /// - Returns: 寫回的訂單，不包含照片；空白新名稱回傳空陣列
    /// - Throws: 查詢、訂單轉換或儲存失敗時丟出 `PersistenceError`
    var applyPaymentMethodEdit: ApplyPaymentMethodEdit
}

// MARK: - Nested Types

extension LookupService {

    /// `fetchItems` 的函式型別
    typealias FetchItems = @Sendable (
        _ kind: LookupKind
    ) async throws(PersistenceError) -> LookupCatalog

    /// `addItem` 的函式型別
    typealias AddItem = @Sendable (
        _ kind: LookupKind,
        _ addition: LookupItemAddition
    ) async throws(PersistenceError) -> Void

    /// `removeItem` 的函式型別
    typealias RemoveItem = @Sendable (
        _ kind: LookupKind,
        _ name: String
    ) async throws(PersistenceError) -> Void

    /// `renameItem` 的函式型別
    typealias RenameItem = @Sendable (
        _ kind: LookupKind,
        _ rename: LookupItemRename
    ) async throws(PersistenceError) -> Void

    /// `countOrders` 的函式型別
    typealias CountOrders = @Sendable (
        _ paymentMethod: String
    ) async throws(PersistenceError) -> Int

    /// `applyPaymentMethodEdit` 的函式型別
    typealias ApplyPaymentMethodEdit = @Sendable (
        _ originalName: String,
        _ newName: String,
        _ flags: PaymentMethodFlags
    ) async throws(PersistenceError) -> [LedgerOrder]
}

// MARK: - DependencyKey

extension LookupService: DependencyKey {

    /// 正式 App 使用的主檔操作，資料庫由依賴系統取得
    static var liveValue: Self {
        // 以 computed property 每次重新解析依賴，測試才能用 `withDependencies` 替換資料庫
        @Dependency(\.buyLedgerDatabase) var database
        return Self(
            fetchItems: { kind throws(PersistenceError) in
                try await database.read { context throws(PersistenceError) in
                    try Self.fetchItems(kind, in: context)
                }
            },
            addItem: { kind, addition throws(PersistenceError) in
                try await database.write { context throws(PersistenceError) in
                    try Self.addItem(kind, addition: addition, in: context)
                }
            },
            removeItem: { kind, name throws(PersistenceError) in
                try await database.write { context throws(PersistenceError) in
                    try Self.removeItem(kind, name: name, in: context)
                }
            },
            renameItem: { kind, rename throws(PersistenceError) in
                guard let newName = Self.normalizedRenameTarget(
                    oldName: rename.oldName,
                    newName: rename.newName
                ) else {
                    return
                }
                try await database.write { context throws(PersistenceError) in
                    try Self.renameItem(
                        kind,
                        from: rename.oldName,
                        to: newName,
                        in: context
                    )
                }
            },
            countOrders: { paymentMethod throws(PersistenceError) in
                try await database.read { context throws(PersistenceError) in
                    try Self.countOrders(paymentMethod: paymentMethod, in: context)
                }
            },
            applyPaymentMethodEdit: { originalName, newName, flags throws(PersistenceError) in
                let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedName.isEmpty else {
                    return []
                }
                return try await database.write { context throws(PersistenceError) in
                    try Self.applyPaymentMethodEdit(
                        from: originalName,
                        to: trimmedName,
                        flags: flags,
                        in: context
                    )
                }
            }
        )
    }

    #if DEBUG

    /// Preview 使用各 Service 共用、只存在記憶體的資料庫執行主檔操作
    static var previewValue: Self {
        assert(
            RuntimeEnvironment.allowsPreviewStub,
            "LookupService.previewValue 只能在 Preview、UI Test 或單元測試中使用"
        )
        return liveValue
    }

    #endif

    /// 每個操作都必須由測試明確覆寫，未覆寫的呼叫會回報失敗
    static var testValue: Self {
        Self(
            fetchItems: unimplemented("LookupService.fetchItems", placeholder: LookupCatalog()),
            addItem: unimplemented("LookupService.addItem"),
            removeItem: unimplemented("LookupService.removeItem"),
            renameItem: unimplemented("LookupService.renameItem"),
            countOrders: unimplemented("LookupService.countOrders", placeholder: 0),
            applyPaymentMethodEdit: unimplemented(
                "LookupService.applyPaymentMethodEdit",
                placeholder: []
            )
        )
    }
}

// MARK: - Private Method

private extension LookupService {

    /// 讀取指定種類的主檔名稱與旗標，依使用者語言的排序規則排列
    ///
    /// - Parameters:
    ///   - kind: 要讀取的主檔種類
    ///   - context: 本次讀取使用的資料庫 `context`
    /// - Returns: 只填入指定種類的主檔目錄
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func fetchItems(
        _ kind: LookupKind,
        in context: ModelContext
    ) throws(PersistenceError) -> LookupCatalog {
        switch kind {
        case .orderSource:
            LookupCatalog(orderSources: try fetchNames(OrderSourceRecord.self, in: context))

        case .category:
            LookupCatalog(categories: try fetchNames(CategoryRecord.self, in: context))

        case .paymentMethod:
            LookupCatalog(paymentMethods: try fetchPaymentMethodInfos(in: context))

        case .reconciliationStatus:
            LookupCatalog(
                reconciliationStatuses: try fetchNames(ReconciliationStatusRecord.self, in: context)
            )
        }
    }

    /// 讀出名稱主檔並依使用者語言排序
    ///
    /// - Parameters:
    ///   - recordType: 要讀取的名稱主檔型別
    ///   - context: 本次讀取使用的資料庫 `context`
    /// - Returns: 名稱陣列，沒有資料時為空陣列
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func fetchNames<Record: NameLookupRecordProtocol>(
        _ recordType: Record.Type,
        in context: ModelContext
    ) throws(PersistenceError) -> [String] {
        let records = try PersistenceError.mapFetch {
            try context.fetch(FetchDescriptor<Record>())
        }
        return records.map(\.name).sorted { lhs, rhs in
            lhs.localizedStandardCompare(rhs) == .orderedAscending
        }
    }

    /// 讀出全部付款方式資訊並依使用者語言排序
    ///
    /// - Parameter context: 本次讀取使用的資料庫 `context`
    /// - Returns: 付款方式資訊陣列，沒有資料時為空陣列
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func fetchPaymentMethodInfos(
        in context: ModelContext
    ) throws(PersistenceError) -> [PaymentMethodInfo] {
        let records = try PersistenceError.mapFetch {
            try context.fetch(FetchDescriptor<PaymentMethodRecord>())
        }
        return records
            .map {
                PaymentMethodInfo(
                    name: $0.name,
                    flags: PaymentMethodFlags(
                        isCardless: $0.isCardless,
                        isBankTransfer: $0.isBankTransfer,
                        isCashOnDelivery: $0.isCashOnDelivery
                    )
                )
            }
            .sorted { lhs, rhs in
                lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
    }

    /// 依主檔種類新增名稱，付款方式使用指定旗標
    ///
    /// - Parameters:
    ///   - kind: 要新增的主檔種類
    ///   - addition: 名稱與付款方式旗標
    ///   - context: 本次寫入使用的資料庫 `context`
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func addItem(
        _ kind: LookupKind,
        addition: LookupItemAddition,
        in context: ModelContext
    ) throws(PersistenceError) {
        switch kind {
        case .orderSource:
            try addName(OrderSourceRecord.self, rawName: addition.name, in: context)

        case .category:
            try addName(CategoryRecord.self, rawName: addition.name, in: context)

        case .paymentMethod:
            try addPaymentMethod(rawName: addition.name, flags: addition.flags, in: context)

        case .reconciliationStatus:
            try addName(ReconciliationStatusRecord.self, rawName: addition.name, in: context)
        }
    }

    /// 去除前後空白後新增主檔名稱，空白或已存在時不新增
    ///
    /// - Parameters:
    ///   - recordType: 要新增的名稱主檔型別
    ///   - rawName: 尚未去除前後空白的名稱
    ///   - context: 本次寫入使用的資料庫 `context`
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func addName<Record: NameLookupRecordProtocol>(
        _ recordType: Record.Type,
        rawName: String,
        in context: ModelContext
    ) throws(PersistenceError) {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            return
        }
        let descriptor = FetchDescriptor<Record>(predicate: Record.matchingName(name))
        let existing = try PersistenceError.mapFetch {
            try context.fetch(descriptor).first
        }
        if existing == nil {
            context.insert(Record(name: name))
        }
    }

    /// 寫入或更新付款方式，覆寫同名記錄的全部旗標
    ///
    /// - Parameters:
    ///   - rawName: 尚未去除前後空白的名稱
    ///   - flags: 付款方式分類旗標
    ///   - context: 本次寫入使用的資料庫 `context`
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func addPaymentMethod(
        rawName: String,
        flags: PaymentMethodFlags,
        in context: ModelContext
    ) throws(PersistenceError) {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            return
        }
        try upsert(name: name, flags: flags, in: context)
    }

    /// 依指定旗標新增付款方式，或更新同名記錄
    ///
    /// - Parameters:
    ///   - name: 已去除前後空白的付款方式名稱
    ///   - flags: 要寫入的付款方式旗標
    ///   - context: 本次寫入使用的資料庫 `context`
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func upsert(
        name: String,
        flags: PaymentMethodFlags,
        in context: ModelContext
    ) throws(PersistenceError) {
        let descriptor = FetchDescriptor<PaymentMethodRecord>(
            predicate: #Predicate { $0.name == name }
        )
        let existing = try PersistenceError.mapFetch {
            try context.fetch(descriptor).first
        }
        if let existing {
            existing.isCardless = flags.isCardless
            existing.isBankTransfer = flags.isBankTransfer
            existing.isCashOnDelivery = flags.isCashOnDelivery
        } else {
            context.insert(
                PaymentMethodRecord(
                    name: name,
                    isCardless: flags.isCardless,
                    isBankTransfer: flags.isBankTransfer,
                    isCashOnDelivery: flags.isCashOnDelivery
                )
            )
        }
    }

    /// 依主檔種類移除符合名稱的全部記錄
    ///
    /// - Parameters:
    ///   - kind: 要刪除的主檔種類
    ///   - name: 要刪除的名稱
    ///   - context: 本次寫入使用的資料庫 `context`
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func removeItem(
        _ kind: LookupKind,
        name: String,
        in context: ModelContext
    ) throws(PersistenceError) {
        switch kind {
        case .orderSource:
            try removeName(OrderSourceRecord.self, name: name, in: context)

        case .category:
            try removeName(CategoryRecord.self, name: name, in: context)

        case .paymentMethod:
            try removePaymentMethod(name: name, in: context)

        case .reconciliationStatus:
            try removeName(ReconciliationStatusRecord.self, name: name, in: context)
        }
    }

    /// 移除名稱相符的全部主檔記錄
    ///
    /// - Parameters:
    ///   - recordType: 要刪除的名稱主檔型別
    ///   - name: 要刪除的名稱
    ///   - context: 本次寫入使用的資料庫 `context`
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func removeName<Record: NameLookupRecordProtocol>(
        _ recordType: Record.Type,
        name: String,
        in context: ModelContext
    ) throws(PersistenceError) {
        let descriptor = FetchDescriptor<Record>(predicate: Record.matchingName(name))
        let records = try PersistenceError.mapFetch {
            try context.fetch(descriptor)
        }
        for record in records {
            context.delete(record)
        }
    }

    /// 刪除符合名稱的全部付款方式記錄
    ///
    /// - Parameters:
    ///   - name: 要刪除的名稱
    ///   - context: 本次寫入使用的資料庫 `context`
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func removePaymentMethod(
        name: String,
        in context: ModelContext
    ) throws(PersistenceError) {
        let descriptor = FetchDescriptor<PaymentMethodRecord>(
            predicate: #Predicate { $0.name == name }
        )
        let records = try PersistenceError.mapFetch {
            try context.fetch(descriptor)
        }
        for record in records {
            context.delete(record)
        }
    }

    /// 去除新名稱前後空白，並判斷這次改名需不需要執行
    ///
    /// - Parameters:
    ///   - oldName: 原本的名稱
    ///   - newName: 尚未去除前後空白的新名稱
    /// - Returns: 去除空白後的新名稱；新名稱為空白或與 `oldName` 相同時為 `nil`
    static func normalizedRenameTarget(oldName: String, newName: String) -> String? {
        let normalizedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedName.isEmpty, normalizedName != oldName else {
            return nil
        }
        return normalizedName
    }

    /// 依種類在同一次寫入內改名主檔與引用訂單
    ///
    /// - Parameters:
    ///   - kind: 要改名的主檔種類
    ///   - oldName: 原本的名稱
    ///   - newName: 已去除前後空白的新名稱
    ///   - context: 本次寫入使用的資料庫 `context`
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func renameItem(
        _ kind: LookupKind,
        from oldName: String,
        to newName: String,
        in context: ModelContext
    ) throws(PersistenceError) {
        switch kind {
        case .orderSource:
            try renameOrderSource(from: oldName, to: newName, in: context)

        case .category:
            try renameCategory(from: oldName, to: newName, in: context)

        case .paymentMethod:
            try renamePaymentMethod(from: oldName, to: newName, in: context)

        case .reconciliationStatus:
            try renameReconciliationStatus(from: oldName, to: newName, in: context)
        }
    }

    /// 在同一次寫入內改名訂單來源主檔與引用它的訂單
    ///
    /// - Parameters:
    ///   - oldName: 原本的名稱
    ///   - newName: 已去除前後空白的新名稱
    ///   - context: 本次寫入使用的資料庫 `context`
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func renameOrderSource(
        from oldName: String,
        to newName: String,
        in context: ModelContext
    ) throws(PersistenceError) {
        try renameLookup(
            OrderSourceRecord.self,
            from: oldName,
            to: newName,
            in: context
        )
        let descriptor = FetchDescriptor<OrderRecord>(
            predicate: #Predicate { $0.orderSource == oldName }
        )
        let records = try PersistenceError.mapFetch {
            try context.fetch(descriptor)
        }
        for record in records {
            record.orderSource = newName
        }
    }

    /// 改名只有名稱的主檔，目標已存在時只移除來源記錄
    ///
    /// - Parameters:
    ///   - recordType: 要改名的主檔記錄型別
    ///   - oldName: 原本的名稱
    ///   - newName: 新名稱
    ///   - context: 本次寫入使用的資料庫 `context`
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func renameLookup<Record: NameLookupRecordProtocol>(
        _ recordType: Record.Type,
        from oldName: String,
        to newName: String,
        in context: ModelContext
    ) throws(PersistenceError) {
        let oldDescriptor = FetchDescriptor<Record>(predicate: Record.matchingName(oldName))
        let oldRecords = try PersistenceError.mapFetch {
            try context.fetch(oldDescriptor)
        }
        for record in oldRecords {
            context.delete(record)
        }

        let newDescriptor = FetchDescriptor<Record>(predicate: Record.matchingName(newName))
        let existing = try PersistenceError.mapFetch {
            try context.fetch(newDescriptor).first
        }
        guard existing == nil else {
            return
        }
        context.insert(Record(name: newName))
    }

    /// 在同一次寫入內改名類別主檔與所有訂單中的類別值
    ///
    /// - Parameters:
    ///   - oldName: 原本的名稱
    ///   - newName: 已去除前後空白的新名稱
    ///   - context: 本次寫入使用的資料庫 `context`
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func renameCategory(
        from oldName: String,
        to newName: String,
        in context: ModelContext
    ) throws(PersistenceError) {
        try renameLookup(
            CategoryRecord.self,
            from: oldName,
            to: newName,
            in: context
        )
        let records = try PersistenceError.mapFetch {
            try context.fetch(FetchDescriptor<OrderRecord>())
        }
        for record in records where record.categories.contains(oldName) {
            record.categories = record.categories.map { $0 == oldName ? newName : $0 }
        }
    }

    /// 在同一次寫入內改名付款方式並合併主檔旗標
    ///
    /// - Parameters:
    ///   - oldName: 原本的名稱
    ///   - newName: 已去除前後空白的新名稱
    ///   - context: 本次寫入使用的資料庫 `context`
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func renamePaymentMethod(
        from oldName: String,
        to newName: String,
        in context: ModelContext
    ) throws(PersistenceError) {
        let oldDescriptor = FetchDescriptor<PaymentMethodRecord>(
            predicate: #Predicate { $0.name == oldName }
        )
        let oldRecords = try PersistenceError.mapFetch {
            try context.fetch(oldDescriptor)
        }
        let mergedFlags = PaymentMethodFlags(
            isCardless: oldRecords.contains(where: \.isCardless),
            isBankTransfer: oldRecords.contains(where: \.isBankTransfer),
            isCashOnDelivery: oldRecords.contains(where: \.isCashOnDelivery)
        )
        for record in oldRecords {
            context.delete(record)
        }

        let newDescriptor = FetchDescriptor<PaymentMethodRecord>(
            predicate: #Predicate { $0.name == newName }
        )
        let existing = try PersistenceError.mapFetch {
            try context.fetch(newDescriptor).first
        }
        if let existing {
            existing.isCardless = existing.isCardless || mergedFlags.isCardless
            existing.isBankTransfer = existing.isBankTransfer || mergedFlags.isBankTransfer
            existing.isCashOnDelivery = existing.isCashOnDelivery || mergedFlags.isCashOnDelivery
        } else {
            context.insert(
                PaymentMethodRecord(
                    name: newName,
                    isCardless: mergedFlags.isCardless,
                    isBankTransfer: mergedFlags.isBankTransfer,
                    isCashOnDelivery: mergedFlags.isCashOnDelivery
                )
            )
        }

        let orderDescriptor = FetchDescriptor<OrderRecord>(
            predicate: #Predicate { $0.paymentMethod == oldName }
        )
        let orderRecords = try PersistenceError.mapFetch {
            try context.fetch(orderDescriptor)
        }
        for record in orderRecords {
            record.paymentMethod = newName
        }
    }

    /// 在同一次寫入內改名對帳狀態主檔與訂單欄位
    ///
    /// - Parameters:
    ///   - oldName: 原本的名稱
    ///   - newName: 已去除前後空白的新名稱
    ///   - context: 本次寫入使用的資料庫 `context`
    /// - Throws: 查詢失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func renameReconciliationStatus(
        from oldName: String,
        to newName: String,
        in context: ModelContext
    ) throws(PersistenceError) {
        try renameLookup(
            ReconciliationStatusRecord.self,
            from: oldName,
            to: newName,
            in: context
        )
        let descriptor = FetchDescriptor<OrderRecord>(
            predicate: #Predicate { $0.reconciliationStatus == oldName }
        )
        let records = try PersistenceError.mapFetch {
            try context.fetch(descriptor)
        }
        for record in records {
            record.reconciliationStatus = newName
        }
    }

    /// 計算資料庫內使用指定付款方式的訂單數量
    ///
    /// - Parameters:
    ///   - paymentMethod: 要查詢的付款方式名稱
    ///   - context: 本次讀取使用的資料庫 `context`
    /// - Returns: 名稱相符的訂單筆數
    /// - Throws: 讀取失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func countOrders(
        paymentMethod: String,
        in context: ModelContext
    ) throws(PersistenceError) -> Int {
        let descriptor = FetchDescriptor<OrderRecord>(
            predicate: #Predicate { $0.paymentMethod == paymentMethod }
        )
        return try PersistenceError.mapFetch {
            try context.fetchCount(descriptor)
        }
    }

    /// 在同一次寫入內覆寫付款方式主檔，重算當下引用原名稱的訂單
    ///
    /// - Parameters:
    ///   - oldName: 原付款方式名稱
    ///   - newName: 已去除前後空白的新名稱
    ///   - flags: 要覆寫的付款方式旗標
    ///   - context: 本次寫入使用的資料庫 `context`
    /// - Returns: 寫回的訂單，不包含照片
    /// - Throws: 查詢或訂單轉換失敗時丟出 `PersistenceError.fetchFailed(underlying:)`
    static func applyPaymentMethodEdit(
        from oldName: String,
        to newName: String,
        flags: PaymentMethodFlags,
        in context: ModelContext
    ) throws(PersistenceError) -> [LedgerOrder] {
        guard !newName.isEmpty else {
            return []
        }
        if oldName != newName {
            try removePaymentMethod(name: oldName, in: context)
        }
        try upsert(name: newName, flags: flags, in: context)

        let descriptor = FetchDescriptor<OrderRecord>(
            predicate: #Predicate { $0.paymentMethod == oldName }
        )
        let records = try PersistenceError.mapFetch {
            try context.fetch(descriptor)
        }
        var updatedOrders: [LedgerOrder] = []
        for record in records {
            let order = try record.toDomain(includingPhotos: false)
                .renamingPaymentMethod(to: newName)
                .applyingPaymentMethodFlags(flags)
            record.apply(order)
            updatedOrders.append(order)
        }
        return updatedOrders
    }
}

// MARK: - DependencyValues

extension DependencyValues {

    /// 供 Feature 以 `@Dependency(\.lookupService)` 取得的主檔 Service
    var lookupService: LookupService {
        get { self[LookupService.self] }
        set { self[LookupService.self] = newValue }
    }
}
