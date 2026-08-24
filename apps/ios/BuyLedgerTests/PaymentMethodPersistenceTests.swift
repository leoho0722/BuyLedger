//
//  PaymentMethodPersistenceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/29.
//

import Foundation
import SwiftData
import Testing
@testable import BuyLedger

/// 驗證付款方式更新的持久化
@MainActor
struct PaymentMethodPersistenceTests {
    
    // MARK: - Tests
    
    @Test func upsertPersistsBothFlagsRoundTrip() async throws(any Error) {
        let persistence = try makePersistence()
        
        try await persistence.upsert(
            name: "銀行匯款",
            flags: PaymentMethodFlags(
                isCardless: false,
                isBankTransfer: true,
                isCashOnDelivery: false
            )
        )
        try await persistence.upsert(
            name: "無卡存款",
            flags: PaymentMethodFlags(
                isCardless: true,
                isBankTransfer: false,
                isCashOnDelivery: false
            )
        )
        
        let infos = try await persistence.fetchAllInfos()
        let bankTransfer = infos.first { $0.name == "銀行匯款" }
        let cardless = infos.first { $0.name == "無卡存款" }
        
        #expect(bankTransfer?.isBankTransfer == true)
        #expect(bankTransfer?.isCardless == false)
        #expect(cardless?.isCardless == true)
        #expect(cardless?.isBankTransfer == false)
    }
    
    @Test func upsertSameNameOverwritesFlags() async throws(any Error) {
        let persistence = try makePersistence()
        
        try await persistence.upsert(
            name: "綠界",
            flags: .none
        )
        // 二次新增同名：以新旗標覆寫 (使用者上次忘了勾選銀行匯款，這次更正)
        try await persistence.upsert(
            name: "綠界",
            flags: PaymentMethodFlags(
                isCardless: false,
                isBankTransfer: true,
                isCashOnDelivery: false
            )
        )
        
        let infos = try await persistence.fetchAllInfos()
        #expect(infos.count == 1)
        #expect(infos.first?.isBankTransfer == true)
    }
    
    @Test func renamePreservesBankTransferFlag() async throws(any Error) {
        let persistence = try makePersistence()
        try await persistence.upsert(
            name: "匯款",
            flags: PaymentMethodFlags(
                isCardless: false,
                isBankTransfer: true,
                isCashOnDelivery: false
            )
        )
        
        try await persistence.rename(from: "匯款", to: "銀行匯款")
        
        let infos = try await persistence.fetchAllInfos()
        let renamed = infos.first { $0.name == "銀行匯款" }
        #expect(infos.contains { $0.name == "匯款" } == false)
        #expect(renamed?.isBankTransfer == true, "更名應保留 isBankTransfer 旗標")
    }
    
    @Test func upsertAndRenamePreserveCashOnDeliveryFlag() async throws(any Error) {
        let persistence = try makePersistence()
        
        try await persistence.upsert(
            name: "貨到付款",
            flags: PaymentMethodFlags(
                isCardless: false,
                isBankTransfer: false,
                isCashOnDelivery: true
            )
        )
        
        let info = try await persistence.fetchAllInfos().first { $0.name == "貨到付款" }
        #expect(info?.isCashOnDelivery == true)
        #expect(info?.isCardless == false)
        #expect(info?.isBankTransfer == false)
        
        // 更名應保留 isCashOnDelivery 旗標
        try await persistence.rename(from: "貨到付款", to: "超商取貨付款")
        let renamed = try await persistence.fetchAllInfos().first { $0.name == "超商取貨付款" }
        #expect(renamed?.isCashOnDelivery == true, "更名應保留 isCashOnDelivery 旗標")
    }
    
    @Test func applyEditPersistsMasterAndNormalizedOrdersTogether() async throws(any Error) {
        let storeURL = Self.makeStoreURL()
        let original = Self.makePaymentOrder(id: "PM-PERSIST", paymentMethod: "匯款")
        let corrected =
            original
            .renamingPaymentMethod(to: "銀行匯款")
            .applyingPaymentMethodFlags(flags: .none)
        
        #expect(original.cardlessDeductionAmount != 0)
        #expect(original.cardlessSupplementAmount != 0)
        #expect(!original.reconciliationStatus.isEmpty)
        #expect(original.isCashOnDelivery)
        
        do {
            let bootstrap = PersistenceContainer.makeBootstrapForTesting(storeURL: storeURL)
            guard case .healthy = bootstrap.status else {
                Issue.record("Expected a healthy disk-backed bootstrap before applying the edit.")
                return
            }
            
            let paymentPersistence = PaymentMethodPersistence(modelContainer: bootstrap.container)
            let orderRepository = OrderRepository.live(container: bootstrap.container)
            
            try await paymentPersistence.upsert(
                name: "匯款",
                flags: PaymentMethodFlags(
                    isCardless: true,
                    isBankTransfer: true,
                    isCashOnDelivery: true
                )
            )
            try await orderRepository.createOrder(original)
            
            // 先由長命 OrderPersistence 讀取一次，釘住 A3 的 stale-context 風險
            let warmedOrders = try await orderRepository.fetchOrders()
            #expect(warmedOrders.first?.id == original.id)
            
            try await paymentPersistence.applyEdit(
                from: "匯款",
                to: "銀行匯款",
                flags: .none,
                orders: [corrected]
            )
            
            // 同一個長命 OrderPersistence context 也必須讀到另一個 context 的新值
            let storedOrder = try await orderRepository.fetchOrders().first
            #expect(
                storedOrder.map(Self.normalizingItemIdentifiers)
                    == Self.normalizingItemIdentifiers(corrected))
        }
        
        // 丟棄第一個 container 後以同一個 URL 重建，模擬重啟後重新讀取
        let rebooted = PersistenceContainer.makeBootstrapForTesting(storeURL: storeURL)
        guard case .healthy = rebooted.status else {
            Issue.record("Expected the corrected store to reopen successfully.")
            return
        }
        let rebootedPaymentPersistence = PaymentMethodPersistence(
            modelContainer: rebooted.container)
        let rebootedOrderRepository = OrderRepository.live(container: rebooted.container)
        let infos = try await rebootedPaymentPersistence.fetchAllInfos()
        let storedOrder = try await rebootedOrderRepository.fetchOrders().first
        
        #expect(
            infos == [
                PaymentMethodInfo(
                    name: "銀行匯款", isCardless: false, isBankTransfer: false, isCashOnDelivery: false)
            ])
        #expect(
            storedOrder.map(Self.normalizingItemIdentifiers)
                == Self.normalizingItemIdentifiers(corrected))
        #expect(storedOrder?.cardlessDeductionAmount == 0)
        #expect(storedOrder?.cardlessSupplementAmount == 0)
        #expect(storedOrder?.reconciliationStatus == "")
        #expect(storedOrder?.isCashOnDelivery == false)
        #expect(storedOrder?.summary.profit == corrected.summary.profit)
    }
    
    /// 驗證付款方式改名時保留照片
    /// - Throws: 測試容器建立或資料寫入失敗時拋出錯誤
    @Test func applyEditPreservesExistingOrderPhotos() async throws(any Error) {
        let container = PersistenceContainer.makeInMemory(for: .testing)
        let orderPersistence = OrderPersistence(modelContainer: container)
        let paymentPersistence = PaymentMethodPersistence(modelContainer: container)
        
        let photo = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x40])
        let original = Self.makePaymentOrder(id: "PM-PHOTO", paymentMethod: "匯款")
        try await orderPersistence.create(Self.withPhotos(original, photos: [photo]))
        
        // 清單讀取不含照片，因此更正時應保持空照片
        let corrected =
            original
            .renamingPaymentMethod(to: "銀行匯款")
            .applyingPaymentMethodFlags(flags: .none)
        #expect(corrected.photos.isEmpty, "本測試前提：affected order 快照的照片欄位須為空，才能驗證 apply(_:) 不依賴它")
        
        try await paymentPersistence.applyEdit(
            from: "匯款",
            to: "銀行匯款",
            flags: .none,
            orders: [corrected]
        )
        
        let stored = try await orderPersistence.fetch(id: "PM-PHOTO")
        #expect(stored?.paymentMethod == "銀行匯款", "付款方式應正常更新")
        #expect(stored?.photos == [photo], "已存照片不應被回溯更正清空")
    }
    
    @Test func applyEditRollsBackWhenOrderSnapshotContainsMissingID() async throws(any Error) {
        let container = PersistenceContainer.makeInMemory(for: .testing)
        let paymentPersistence = PaymentMethodPersistence(modelContainer: container)
        let orderPersistence = OrderPersistence(modelContainer: container)
        let original = Self.makePaymentOrder(id: "PM-ATOMIC", paymentMethod: "匯款")
        let corrected =
            original
            .renamingPaymentMethod(to: "銀行匯款")
            .applyingPaymentMethodFlags(flags: .none)
        let missing = Self.makePaymentOrder(id: "PM-MISSING", paymentMethod: "匯款")
            .renamingPaymentMethod(to: "銀行匯款")
            .applyingPaymentMethodFlags(flags: .none)
        let originalInfo = PaymentMethodInfo(
            name: "匯款", isCardless: true, isBankTransfer: true, isCashOnDelivery: true)
        
        try await paymentPersistence.upsert(
            name: originalInfo.name,
            flags: originalInfo.currentFlags
        )
        try await orderPersistence.create(original)
        
        await #expect(throws: PaymentMethodPersistenceError.orderNotFound(id: missing.id)) {
            try await paymentPersistence.applyEdit(
                from: "匯款",
                to: "銀行匯款",
                flags: .none,
                orders: [corrected, missing]
            )
        }
        
        #expect(try await paymentPersistence.fetchAllInfos() == [originalInfo])
        let stored = try await orderPersistence.fetch(id: original.id)
        #expect(
            stored.map(Self.normalizingItemIdentifiers) == Self.normalizingItemIdentifiers(original)
        )
        #expect(try await orderPersistence.fetch(id: missing.id) == nil)
    }
    
    @Test func applyEditRollsBackMasterAndOrdersWhenSaveFails() async throws(any Error) {
        let storeURL = Self.makeStoreURL()
        let original = Self.makePaymentOrder(id: "PM-SAVE-FAIL", paymentMethod: "匯款")
        let corrected =
            original
            .renamingPaymentMethod(to: "銀行匯款")
            .applyingPaymentMethodFlags(flags: .none)
        let originalInfo = PaymentMethodInfo(
            name: "匯款", isCardless: true, isBankTransfer: true, isCashOnDelivery: true)
        
        do {
            let bootstrap = PersistenceContainer.makeBootstrapForTesting(storeURL: storeURL)
            guard case .healthy = bootstrap.status else {
                Issue.record(
                    "Expected a healthy disk-backed bootstrap before seeding the save-failure test."
                )
                return
            }
            let paymentPersistence = PaymentMethodPersistence(modelContainer: bootstrap.container)
            let orderPersistence = OrderPersistence(modelContainer: bootstrap.container)
            try await paymentPersistence.upsert(
                name: originalInfo.name,
                flags: originalInfo.currentFlags
            )
            try await orderPersistence.create(original)
        }
        
        do {
            let readOnlyContainer = try Self.makeReadOnlyContainer(at: storeURL)
            let paymentPersistence = PaymentMethodPersistence(modelContainer: readOnlyContainer)
            
            await #expect(throws: PaymentMethodPersistenceError.self) {
                try await paymentPersistence.applyEdit(
                    from: "匯款",
                    to: "銀行匯款",
                    flags: .none,
                    orders: [corrected]
                )
            }
        }
        
        // 以新 context 讀取 store，確認失敗後沒有殘留資料
        let restored = PersistenceContainer.makeBootstrapForTesting(storeURL: storeURL)
        guard case .healthy = restored.status else {
            Issue.record("Expected the original store to remain reopenable after a failed save.")
            return
        }
        let restoredPaymentPersistence = PaymentMethodPersistence(
            modelContainer: restored.container)
        let restoredOrderPersistence = OrderPersistence(modelContainer: restored.container)
        #expect(try await restoredPaymentPersistence.fetchAllInfos() == [originalInfo])
        let stored = try await restoredOrderPersistence.fetch(id: original.id)
        #expect(
            stored.map(Self.normalizingItemIdentifiers) == Self.normalizingItemIdentifiers(original)
        )
    }
}

// MARK: - Private Method

private extension PaymentMethodPersistenceTests {
    
    /// 建立帶有四個非預設付款旗標受管欄位的訂單
    /// - Returns: 建立的訂單
    static func makePaymentOrder(id: String, paymentMethod: String) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: "付款測試", initials: "PM", tier: .regular),
            status: .delivered,
            currency: .twd,
            date: TestDependencies.fixedNow,
            items: [LedgerOrderItem(name: "商品", quantity: 1, unitPrice: 5_000)],
            itemCost: 3_000,
            domesticShipping: 125,
            internationalShipping: 275,
            foreignDomesticShipping: 425,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 5_000,
            cardlessDeductionAmount: 750,
            cardlessSupplementAmount: 250,
            orderSource: "來源",
            categories: ["測試"],
            paymentMethod: paymentMethod,
            notes: "",
            reconciliationStatus: "待對帳",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: true,
            photos: [],
            mergedSourceIDs: []
        )
    }
    
    /// 回傳只改變照片的複本
    /// - Returns: 加入照片後的訂單
    static func withPhotos(_ order: LedgerOrder, photos: [Data]) -> LedgerOrder {
        LedgerOrder(
            id: order.id,
            customer: order.customer,
            status: order.status,
            currency: order.currency,
            date: order.date,
            items: order.items,
            itemCost: order.itemCost,
            domesticShipping: order.domesticShipping,
            internationalShipping: order.internationalShipping,
            foreignDomesticShipping: order.foreignDomesticShipping,
            cardFeeRate: order.cardFeeRate,
            platformFeeRate: order.platformFeeRate,
            paymentFeeRate: order.paymentFeeRate,
            chargedAmount: order.chargedAmount,
            cardlessDeductionAmount: order.cardlessDeductionAmount,
            cardlessSupplementAmount: order.cardlessSupplementAmount,
            orderSource: order.orderSource,
            categories: order.categories,
            paymentMethod: order.paymentMethod,
            notes: order.notes,
            reconciliationStatus: order.reconciliationStatus,
            campaignNames: order.campaignNames,
            paymentReceiptStatus: order.paymentReceiptStatus,
            isCashOnDelivery: order.isCashOnDelivery,
            photos: photos,
            mergedSourceIDs: order.mergedSourceIDs
        )
    }
    
    /// 建立每次測試獨立的 disk-backed store 路徑
    /// - Returns: 測試 store 路徑
    static func makeStoreURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("BuyLedgerPaymentMethodTest-\(UUID().uuidString).store")
    }
    
    /// 建立禁止 save 的 disk-backed container，供驗證原子回滾
    /// - Parameter storeURL: 資料庫路徑
    /// - Returns: 唯讀 ModelContainer
    /// - Throws: 測試容器建立失敗時拋出錯誤
    static func makeReadOnlyContainer(at storeURL: URL) throws(any Error) -> ModelContainer {
        let schema = Schema(versionedSchema: BuyLedgerSchemaV17.self)
        let configuration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            allowsSave: false,
            cloudKitDatabase: .none
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: BuyLedgerMigrationPlan.self,
            configurations: configuration
        )
    }
    
    /// 忽略 `LedgerOrderItem.id` 後比較整筆訂單
    /// - Returns: 正規化後的訂單
    static func normalizingItemIdentifiers(_ order: LedgerOrder) -> LedgerOrder {
        let placeholderID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        return LedgerOrder(
            id: order.id,
            customer: order.customer,
            status: order.status,
            currency: order.currency,
            date: order.date,
            items: order.items.map {
                LedgerOrderItem(
                    id: placeholderID, name: $0.name, quantity: $0.quantity, unitPrice: $0.unitPrice
                )
            },
            itemCost: order.itemCost,
            domesticShipping: order.domesticShipping,
            internationalShipping: order.internationalShipping,
            foreignDomesticShipping: order.foreignDomesticShipping,
            cardFeeRate: order.cardFeeRate,
            platformFeeRate: order.platformFeeRate,
            paymentFeeRate: order.paymentFeeRate,
            chargedAmount: order.chargedAmount,
            cardlessDeductionAmount: order.cardlessDeductionAmount,
            cardlessSupplementAmount: order.cardlessSupplementAmount,
            orderSource: order.orderSource,
            categories: order.categories,
            paymentMethod: order.paymentMethod,
            notes: order.notes,
            reconciliationStatus: order.reconciliationStatus,
            campaignNames: order.campaignNames,
            paymentReceiptStatus: order.paymentReceiptStatus,
            isCashOnDelivery: order.isCashOnDelivery,
            photos: order.photos,
            mergedSourceIDs: order.mergedSourceIDs
        )
    }
    
    /// 用記憶體 ModelContainer 建立獨立 persistence
    /// - Returns: PaymentMethodPersistence
    /// - Throws: 測試容器建立失敗時拋出錯誤
    func makePersistence() throws(any Error) -> PaymentMethodPersistence {
        let container = PersistenceContainer.makeInMemory(for: .testing)
        return PaymentMethodPersistence(modelContainer: container)
    }
}
