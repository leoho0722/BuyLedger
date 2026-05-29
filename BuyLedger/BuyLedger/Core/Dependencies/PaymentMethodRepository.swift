//
//  PaymentMethodRepository.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import ComposableArchitecture
import Foundation
import SwiftData

/// 付款方式主檔的依賴介面。
struct PaymentMethodRepository: Sendable {

    // MARK: - Dependency Properties

    /// 讀取目前所有付款方式名稱 (已排序)。
    var fetchPaymentMethods: @Sendable () async throws -> [String]

    /// 讀取目前所有付款方式 (含 `isCardless` 旗標，已依名稱排序)。
    ///
    /// 給訂單編輯與付款方式管理頁使用，避免上層只拿到名稱字串卻得另查「該方式是否屬於無卡類」。
    var fetchPaymentMethodInfos: @Sendable () async throws -> [PaymentMethodInfo]

    /// 加入新付款方式；trim 後若空字串視為 no-op。
    ///
    /// 參數依序為 (名稱, isCardless, isBankTransfer)。若名稱已存在，會以新傳入的旗標覆寫 (用來在使用者第二次新增同名項目時修正先前勾選)。
    var addPaymentMethod: @Sendable (String, Bool, Bool) async throws -> Void

    /// 刪除指定名稱的付款方式；不存在視為 no-op。
    var removePaymentMethod: @Sendable (String) async throws -> Void

    /// 把指定付款方式更名 (舊名 → 新名)。caller 負責把訂單表的 cascade 一併處理；本方法只更新主檔。
    var renamePaymentMethod: @Sendable (String, String) async throws -> Void

    /// 設定指定付款方式的 `isCardless` 旗標；若該名稱尚未在主檔則建立記錄。
    var setPaymentMethodIsCardless: @Sendable (String, Bool) async throws -> Void
}

extension PaymentMethodRepository {

    // MARK: - Static Method

    /// 以指定的 SwiftData ``ModelContainer`` 建立 repository。
    /// - Parameter container: 用於建立背景 actor 的 SwiftData container。
    /// - Returns: 對應的 ``PaymentMethodRepository`` 實例。
    nonisolated static func live(container: ModelContainer) -> PaymentMethodRepository {
        PaymentMethodRepository(
            fetchPaymentMethods: {
                let persistence = await Self.makePersistence(container: container)
                return try await persistence.fetchAll()
            },
            fetchPaymentMethodInfos: {
                let persistence = await Self.makePersistence(container: container)
                return try await persistence.fetchAllInfos()
            },
            addPaymentMethod: { rawName, isCardless, isBankTransfer in
                let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                let persistence = await Self.makePersistence(container: container)
                try await persistence.upsert(name: trimmed, isCardless: isCardless, isBankTransfer: isBankTransfer)
            },
            removePaymentMethod: { name in
                let persistence = await Self.makePersistence(container: container)
                try await persistence.delete(name: name)
            },
            renamePaymentMethod: { oldName, newName in
                let trimmedNew = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedNew.isEmpty, trimmedNew != oldName else { return }
                let persistence = await Self.makePersistence(container: container)
                try await persistence.rename(from: oldName, to: trimmedNew)
            },
            setPaymentMethodIsCardless: { rawName, isCardless in
                let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                let persistence = await Self.makePersistence(container: container)
                try await persistence.setIsCardless(name: trimmed, isCardless: isCardless)
            }
        )
    }

    /// 在 main actor 上實例化 ``PaymentMethodPersistence`` (`@ModelActor` 的 init 帶有 main-actor 隔離)。
    /// - Parameter container: 共用的 ``ModelContainer``。
    /// - Returns: 對應 container 的 ``PaymentMethodPersistence`` 實例。
    private static func makePersistence(container: ModelContainer) async -> PaymentMethodPersistence {
        await MainActor.run {
            PaymentMethodPersistence(modelContainer: container)
        }
    }
}

extension PaymentMethodRepository: DependencyKey {

    // MARK: - Dependency Values

    /// App 執行時使用共用 SwiftData container。
    nonisolated static let liveValue: PaymentMethodRepository = PaymentMethodRepository.live(
        container: PersistenceContainer.shared
    )

    /// SwiftUI Preview 使用 in-memory container。
    nonisolated static let previewValue: PaymentMethodRepository = {
        let container = (try? PersistenceContainer.make(inMemoryOnly: true)) ?? PersistenceContainer.shared
        return PaymentMethodRepository.live(container: container)
    }()

    /// 測試預設使用空資料來源；TestStore 可透過 `withDependencies` 覆寫。
    nonisolated static let testValue = PaymentMethodRepository(
        fetchPaymentMethods: { [] },
        fetchPaymentMethodInfos: { [] },
        addPaymentMethod: { _, _, _ in },
        removePaymentMethod: { _ in },
        renamePaymentMethod: { _, _ in },
        setPaymentMethodIsCardless: { _, _ in }
    )
}
