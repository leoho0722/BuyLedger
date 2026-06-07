//
//  PaymentMethodPersistence.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import Foundation
import SwiftData

/// SwiftData 上對付款方式主檔做 CRUD 的背景 actor。
@ModelActor
actor PaymentMethodPersistence {

    // MARK: - View Method

    /// 讀出全部付款方式名稱，依 locale 升冪排序。
    /// - Returns: 付款方式名稱陣列。
    func fetchAll() throws -> [String] {
        let descriptor = FetchDescriptor<PaymentMethodRecord>()
        let records = try modelContext.fetch(descriptor)
        return records
            .map { $0.name }
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    /// 讀出全部付款方式 (含 `isCardless` 旗標)，依 locale 升冪排序。
    ///
    /// 與 ``fetchAll()`` 的差別在於回傳 ``PaymentMethodInfo``，讓 caller 同時拿到名稱與「是否屬於無卡類或銀行匯款」的判定，避免在 view 端額外查詢主檔。
    /// - Returns: 付款方式資訊陣列。
    func fetchAllInfos() throws -> [PaymentMethodInfo] {
        let descriptor = FetchDescriptor<PaymentMethodRecord>()
        let records = try modelContext.fetch(descriptor)
        return records
            .map { PaymentMethodInfo(name: $0.name, isCardless: $0.isCardless, isBankTransfer: $0.isBankTransfer, isCashOnDelivery: $0.isCashOnDelivery) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// 寫入指定名稱的付款方式；若已存在則更新 `isCardless`、`isBankTransfer` 與 `isCashOnDelivery` 旗標 (讓使用者重新觸發新增時能更正先前忘記勾選的狀態)。
    /// - Parameters:
    ///   - name: 付款方式名稱 (呼叫前由 caller 完成 trim)。
    ///   - isCardless: 是否屬於無卡類付款方式。
    ///   - isBankTransfer: 是否屬於銀行匯款類付款方式。
    ///   - isCashOnDelivery: 是否屬於貨到付款類付款方式。
    func upsert(name: String, isCardless: Bool, isBankTransfer: Bool, isCashOnDelivery: Bool) throws {
        let descriptor = FetchDescriptor<PaymentMethodRecord>(
            predicate: #Predicate { $0.name == name }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            existing.isCardless = isCardless
            existing.isBankTransfer = isBankTransfer
            existing.isCashOnDelivery = isCashOnDelivery
        } else {
            modelContext.insert(PaymentMethodRecord(name: name, isCardless: isCardless, isBankTransfer: isBankTransfer, isCashOnDelivery: isCashOnDelivery))
        }
        try modelContext.save()
    }

    /// 刪除指定名稱的付款方式；不存在時視為 no-op。
    /// - Parameter name: 付款方式名稱。
    func delete(name: String) throws {
        let descriptor = FetchDescriptor<PaymentMethodRecord>(
            predicate: #Predicate { $0.name == name }
        )

        let records = try modelContext.fetch(descriptor)
        for record in records {
            modelContext.delete(record)
        }

        try modelContext.save()
    }

    /// 將指定付款方式更名；若新名稱已存在則合併 (刪除舊紀錄即可)，訂單端的 cascade 由 caller 另外處理。
    /// - Parameters:
    ///   - oldName: 原本的名稱。
    ///   - newName: 新的名稱 (由 caller 完成 trim)。
    func rename(from oldName: String, to newName: String) throws {
        let oldDescriptor = FetchDescriptor<PaymentMethodRecord>(
            predicate: #Predicate { $0.name == oldName }
        )
        let oldRecords = try modelContext.fetch(oldDescriptor)
        let preservedIsCardless = oldRecords.contains { $0.isCardless }
        let preservedIsBankTransfer = oldRecords.contains { $0.isBankTransfer }
        let preservedIsCashOnDelivery = oldRecords.contains { $0.isCashOnDelivery }
        for record in oldRecords {
            modelContext.delete(record)
        }

        let newDescriptor = FetchDescriptor<PaymentMethodRecord>(
            predicate: #Predicate { $0.name == newName }
        )
        if let existing = try modelContext.fetch(newDescriptor).first {
            // 合併時保留「任一邊曾標記為無卡／銀行匯款／貨到付款」的狀態，避免使用者改名後旗標莫名被清掉。
            if preservedIsCardless {
                existing.isCardless = true
            }
            if preservedIsBankTransfer {
                existing.isBankTransfer = true
            }
            if preservedIsCashOnDelivery {
                existing.isCashOnDelivery = true
            }
        } else {
            modelContext.insert(PaymentMethodRecord(name: newName, isCardless: preservedIsCardless, isBankTransfer: preservedIsBankTransfer, isCashOnDelivery: preservedIsCashOnDelivery))
        }

        try modelContext.save()
    }

    /// 設定指定付款方式的 `isCardless` 旗標；若該名稱不在主檔則先建立記錄。
    /// - Parameters:
    ///   - name: 付款方式名稱 (呼叫前由 caller 完成 trim)。
    ///   - isCardless: 是否屬於無卡類付款方式。
    func setIsCardless(name: String, isCardless: Bool) throws {
        let descriptor = FetchDescriptor<PaymentMethodRecord>(
            predicate: #Predicate { $0.name == name }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            existing.isCardless = isCardless
        } else {
            modelContext.insert(PaymentMethodRecord(name: name, isCardless: isCardless))
        }

        try modelContext.save()
    }
}
