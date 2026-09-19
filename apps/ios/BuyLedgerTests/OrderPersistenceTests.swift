//
//  OrderPersistenceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/05/02.
//

import Foundation
import SwiftData
import Testing
@testable import BuyLedger

/// 驗證訂單持久化
@MainActor
struct OrderPersistenceTests {

    // MARK: - Tests

    /// 驗證訂單持久化在此情境下的資料結果
    @Test func fetchAllOnFreshContainerReturnsEmpty() async throws(any Error) {
        // Given

        let persistence = try makePersistence()

        // When

        let stored = try await persistence.fetchAll()
        // Then

        #expect(stored.isEmpty)
    }

    /// 驗證訂單持久化在此情境下的資料結果
    @Test func seedIfEmptyInsertsSamplesOnce() async throws(any Error) {
        // Given

        let persistence = try makePersistence()
        let samples = LedgerOrder.sampleOrders

        // When

        let firstSeeded = try await persistence.seedIfEmpty(with: samples)
        // Then

        #expect(firstSeeded == true)

        let afterFirst = try await persistence.fetchAll()
        #expect(afterFirst.count == samples.count)

        let secondSeeded = try await persistence.seedIfEmpty(with: samples)
        #expect(secondSeeded == false, "若資料表已非空，再次 seed 不應重複寫入")

        let afterSecond = try await persistence.fetchAll()
        #expect(afterSecond.count == samples.count)
    }

    /// 驗證訂單持久化在此情境下的資料結果
    @Test func fetchAllReturnsOrdersSortedByDateDescending() async throws(any Error) {
        // Given

        let persistence = try makePersistence()
        let samples = LedgerOrder.sampleOrders
        // When

        try await persistence.seedIfEmpty(with: samples)

        let fetched = try await persistence.fetchAll()

        let dates = fetched.map(\.date)
        let sorted = dates.sorted(by: >)
        // Then

        #expect(dates == sorted)
    }

    /// 驗證訂單持久化在此情境下的資料結果
    @Test func createInsertsNewOrderWhenIdNotPresent() async throws(any Error) {
        // Given

        let persistence = try makePersistence()

        let order = LedgerOrder(
            id: "BL-TEST-001",
            customer: LedgerCustomer(name: "測試客戶", initials: "TC", tier: .new),
            status: .quoting,
            currency: .twd,
            date: Date(timeIntervalSince1970: 1_700_000_000),
            items: [],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 0,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "蝦皮",
            categories: ["美妝"],
            paymentMethod: "",
            notes: "建立時的備註",
            reconciliationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )

        // When

        try await persistence.create(order)

        let stored = try await persistence.fetchAll()
        // Then

        #expect(stored.count == 1)
        #expect(stored.first?.id == "BL-TEST-001")
        #expect(stored.first?.customer.name == "測試客戶")
        #expect(stored.first?.notes == "建立時的備註", "備註應隨訂單一併持久化")
    }

    /// 驗證訂單持久化在此情境下的資料結果
    @Test
    func createFailsOnIdentifierCollisionAndLeavesExistingRowUnchanged() async throws(any Error) {
        // Given

        // 編號衝突時整批失敗，既有資料不得變更。
        let persistence = try makePersistence()
        let existing = Self.makeFullFieldOrder(variant: .original)
        // When

        try await persistence.create(existing)

        let colliding = Self.makeFullFieldOrder(variant: .updated)
        // Then

        #expect(colliding.id == existing.id, "測試前提：撞號的兩筆訂單必須同 id")

        do {
            try await persistence.create(colliding)
            Issue.record("預期為訂單編號衝突錯誤。")
        } catch {
            switch error {
            case let .identifierCollision(id):
                #expect(id == existing.id)
            case .storage:
                Issue.record("預期為訂單編號衝突錯誤，實際為持久化錯誤。")
            }
        }

        // fetchAll 不含照片，完整比對改用 fetch(id:)
        let stored = try await persistence.fetchAll()
        #expect(stored.count == 1, "撞號失敗後不應新增任何資料列")
        let storedWithPhotos = try await persistence.fetch(id: existing.id)
        #expect(
            storedWithPhotos.map(LedgerOrder.normalizingItemIdentifiers)
                == LedgerOrder.normalizingItemIdentifiers(existing),
            "撞號失敗後既有資料列必須逐欄未變 (含照片)"
        )
    }

    /// 驗證訂單持久化在此情境下的資料結果
    @Test func updateReplacesExistingRowAcrossEveryField() async throws(any Error) {
        // Given

        // 以整筆資料比對，確保所有欄位都被寫入
        let persistence = try makePersistence()
        let original = Self.makeFullFieldOrder(variant: .original)
        // When

        try await persistence.updatePersistingPhotos(original)

        let modified = Self.makeFullFieldOrder(variant: .updated)
        try await persistence.updatePersistingPhotos(modified)

        // fetchAll() 一律回傳空照片，整值比對改用 fetch(id:)
        let stored = try await persistence.fetchAll()
        // Then

        #expect(stored.count == 1, "update 不應因為 id 相同而新增重複資料")
        let storedWithPhotos = try await persistence.fetch(id: modified.id)
        // Codable round-trip 不含 LedgerOrderItem.id，比對前先移除
        #expect(
            storedWithPhotos.map(LedgerOrder.normalizingItemIdentifiers)
                == LedgerOrder.normalizingItemIdentifiers(modified),
            "更新後應與寫入值整體相等 (含照片)；映射漏寫任一欄會在此處被抓到"
        )
    }

    /// 驗證訂單持久化在此情境下的資料結果
    @Test func updatePersistsReconciliationStatusRoundTrip() async throws(any Error) {
        // Given

        let persistence = try makePersistence()

        let order = LedgerOrder(
            id: "BL-TEST-VS",
            customer: LedgerCustomer(name: "對帳測試", initials: "VS", tier: .regular),
            status: .confirmed,
            currency: .twd,
            date: Date(timeIntervalSince1970: 1_700_000_000),
            items: [],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 0,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "蝦皮",
            categories: ["美妝"],
            paymentMethod: "銀行匯款",
            notes: "",
            reconciliationStatus: "待對帳",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )

        // When

        try await persistence.update(order)

        let stored = try await persistence.fetchAll()
        // Then

        #expect(stored.first?.reconciliationStatus == "待對帳", "對帳狀態應隨訂單一併 round-trip")
    }

    /// `fetchAll()` 回傳的每筆訂單照片欄位皆為空陣列 (不代表該訂單沒有照片)
    ///
    /// - Throws: 測試容器建立或資料讀取失敗時拋出錯誤
    @Test func fetchAllReturnsOrdersWithoutPhotoBytes() async throws(any Error) {
        // Given

        let persistence = try makePersistence()
        let photo = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x01])
        let order = Self.makeStatusOrder(id: "BL-NO-PHOTO-BYTES", status: .confirmed)
        // When

        try await persistence.create(Self.withPhotos(order, photos: [photo]))

        let stored = try await persistence.fetchAll()

        // Then

        #expect(stored.count == 1)
        #expect(stored.first?.photos == [], "fetchAll() 不應帶入照片位元組")

        // 空陣列不代表沒有照片：fetch(id:) 仍能取回完整位元組
        let single = try await persistence.fetch(id: "BL-NO-PHOTO-BYTES")
        #expect(single?.photos == [photo], "fetch(id:) 應維持帶照片")
    }

    /// 驗證 fetchAll 回傳的訂單不含照片位元組
    @Test func fetchAllExcludesPhotoBytes() async throws(any Error) {
        // Given

        let persistence = try makePersistence()
        let order = Self.withPhotos(
            Self.makeStatusOrder(id: "BL-FETCH-ALL-PHOTOS", status: .confirmed),
            photos: [Data([0x01, 0x02])]
        )
        // When

        try await persistence.create(order)

        let stored = try await persistence.fetchAll()

        // Then

        #expect(stored.count == 1)
        #expect(stored.first?.photos.isEmpty == true, "fetchAll() 不應帶入照片位元組")
    }

    /// 依訂單編號讀取照片，回傳該訂單持久化順序的照片陣列
    ///
    /// - Throws: 測試容器建立或資料讀取失敗時拋出錯誤
    @Test func fetchPhotosReturnsStoredBytesInOrder() async throws(any Error) {
        // Given

        let persistence = try makePersistence()
        let photoA = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x01])
        let photoB = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x02])
        let order = Self.makeStatusOrder(id: "BL-FETCH-PHOTOS", status: .confirmed)
        // When

        try await persistence.create(Self.withPhotos(order, photos: [photoA, photoB]))

        let photos = try await persistence.fetchPhotos(id: "BL-FETCH-PHOTOS")

        // Then

        #expect(photos == [photoA, photoB], "應依持久化順序逐張取回，byte 級不變")
    }

    /// 依訂單編號讀取照片時，訂單不存在應回空陣列而非拋錯
    ///
    /// - Throws: 測試容器建立或資料讀取失敗時拋出錯誤
    @Test func fetchPhotosForUnknownIDReturnsEmpty() async throws(any Error) {
        // Given

        let persistence = try makePersistence()

        // When

        let photos = try await persistence.fetchPhotos(id: "BL-DOES-NOT-EXIST")

        // Then

        #expect(photos == [])
    }

    /// 新增訂單的插入分支維持寫入呼叫端提供的照片
    ///
    /// - Throws: 測試容器建立或資料寫入失敗時拋出錯誤
    @Test func insertingNewOrderPersistsItsPhotos() async throws(any Error) {
        // Given

        let persistence = try makePersistence()
        let photoA = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x01])
        let photoB = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x02])
        let order = Self.withPhotos(
            Self.makeStatusOrder(
                id: "BL-INSERT-PHOTOS",
                status: .confirmed
            ),
            photos: [photoA, photoB]
        )

        // 目標不存在時 update(_:) 也應插入並寫入照片。
        // When

        try await persistence.update(order)

        let stored = try await persistence.fetch(id: "BL-INSERT-PHOTOS")
        // Then

        #expect(stored?.photos == [photoA, photoB])
    }

    /// 不帶照片更新時，既有照片維持不變
    ///
    /// - Throws: 測試容器建立或資料寫入失敗時拋出錯誤
    @Test func upsertWithoutPhotosLeavesStoredPhotosIntact() async throws(any Error) {
        // Given

        let persistence = try makePersistence()
        let photoA = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x01])
        let photoB = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x02])
        let order = Self.withPhotos(
            Self.makeStatusOrder(
                id: "BL-KEEP-PHOTOS",
                status: .quoting
            ),
            photos: [photoA, photoB]
        )
        // When

        try await persistence.create(order)

        // 一般更新帶入不同照片時，既有照片仍應保留。
        let photoC = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x03])
        let updated = Self.withPhotos(
            Self.makeStatusOrder(
                id: "BL-KEEP-PHOTOS",
                status: .confirmed
            ),
            photos: [photoC]
        )
        try await persistence.update(updated)

        let stored = try await persistence.fetch(id: "BL-KEEP-PHOTOS")
        // Then

        #expect(stored?.status == .confirmed, "非照片欄位仍應正常更新")
        #expect(stored?.photos == [photoA, photoB], "既有照片必須維持不變，不受 order.photos 影響")
    }

    /// 帶照片寫入後，讀回照片等於傳入集合
    ///
    /// - Throws: 測試容器建立或資料寫入失敗時拋出錯誤
    @Test func writeWithPhotosReplacesStoredSet() async throws(any Error) {
        // Given

        let persistence = try makePersistence()
        let photoA = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x01])
        let order = Self.withPhotos(
            Self.makeStatusOrder(
                id: "BL-WRITE-PHOTOS",
                status: .confirmed
            ),
            photos: [photoA]
        )
        // When

        try await persistence.create(order)

        let photoB = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x02])
        let photoC = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x03])
        let updated = Self.withPhotos(
            Self.makeStatusOrder(
                id: "BL-WRITE-PHOTOS",
                status: .confirmed
            ),
            photos: [photoB, photoC]
        )
        try await persistence.updatePersistingPhotos(updated)

        let stored = try await persistence.fetch(id: "BL-WRITE-PHOTOS")
        // Then

        #expect(stored?.photos == [photoB, photoC], "顯式帶照片的寫入應覆寫既有照片集合")
    }

    /// 寫入三張較大照片後，確認讀回內容相同
    ///
    /// - Throws: 測試容器建立或資料寫入失敗時拋出錯誤
    @Test func upsertPersistsMultiplePhotosRoundTrip() async throws(any Error) {
        // Given

        let persistence = try makePersistence()

        /// 建立指定標記且符合 JPEG header 的測試照片
        ///
        /// - Parameter tag: 填入照片內容的標記 byte
        /// - Returns: 建立的測試照片資料
        func makeLargePhoto(tag: UInt8) -> Data {
            var bytes = [UInt8](repeating: tag, count: 300_000)
            bytes[0] = 0xFF
            bytes[1] = 0xD8
            bytes[2] = 0xFF
            return Data(bytes)
        }

        let photos = [
            makeLargePhoto(tag: 0xA1), makeLargePhoto(tag: 0xB2), makeLargePhoto(tag: 0xC3),
        ]
        let order = Self.withPhotos(
            Self.makeStatusOrder(
                id: "BL-LARGE-PHOTOS",
                status: .confirmed
            ),
            photos: photos
        )

        // When

        try await persistence.create(order)

        let stored = try await persistence.fetch(id: "BL-LARGE-PHOTOS")
        // Then

        #expect(stored?.photos == photos, "三張較大照片應逐張 byte 級相等")
    }

    /// 批次改狀態後，既有照片維持不變
    ///
    /// - Throws: 測試容器建立或資料寫入失敗時拋出錯誤
    @Test func photosSurviveBatchStatusChange() async throws(any Error) {
        // Given

        let persistence = try makePersistence()
        let photo = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x10])
        let target = Self.withPhotos(
            Self.makeStatusOrder(
                id: "BL-BATCH-PHOTO",
                status: .quoting
            ),
            photos: [photo]
        )
        let other = Self.makeStatusOrder(
            id: "BL-BATCH-OTHER",
            status: .quoting
        )
        // When

        try await persistence.create(target)
        try await persistence.create(other)

        // 批次資料不含照片，只更新狀態。
        let changedTarget = Self.makeStatusOrder(
            id: "BL-BATCH-PHOTO",
            status: .confirmed
        )
        let changedOther = Self.makeStatusOrder(
            id: "BL-BATCH-OTHER",
            status: .confirmed
        )
        try await persistence.upsertAll([changedTarget, changedOther])

        let stored = try await persistence.fetch(id: "BL-BATCH-PHOTO")
        // Then

        #expect(stored?.status == .confirmed, "狀態應正常更新")
        #expect(stored?.photos == [photo], "批次改狀態不應清空照片")
    }

    /// 主檔更名後訂單照片不變
    ///
    /// - Throws: 測試容器建立或資料寫入失敗時拋出錯誤
    @Test func photosSurviveEveryCascadeRename() async throws(any Error) {
        // Given

        let persistence = try makePersistence()
        let photo = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x20])

        // 依序更名四種主檔，確認照片不變。
        var order = Self.withPhotos(
            Self.makeArrayOrder(
                id: "BL-RENAME-ALL",
                categories: ["美妝"],
                campaignNames: ["春團"]
            ),
            photos: [photo]
        )
        order = Self.withReconciliationStatus(order, status: "待對帳")
        // When

        try await persistence.create(order)

        try await persistence.renameOrderSource(from: "蝦皮", to: "蝦皮 (新)")
        // Then

        #expect(
            try await persistence.fetch(id: "BL-RENAME-ALL")?.photos == [photo],
            "訂單來源更名後照片不應變動"
        )

        try await persistence.renameCategory(from: "美妝", to: "彩妝保養")
        #expect(
            try await persistence.fetch(id: "BL-RENAME-ALL")?.photos == [photo],
            "商品類別更名後照片不應變動"
        )

        try await persistence.renameReconciliationStatus(from: "待對帳", to: "對帳成功")
        #expect(
            try await persistence.fetch(id: "BL-RENAME-ALL")?.photos == [photo],
            "對帳狀態更名後照片不應變動"
        )

        try await persistence.renameCampaign(from: "春團", to: "春團 (補)")
        let stored = try await persistence.fetch(id: "BL-RENAME-ALL")
        #expect(stored?.photos == [photo], "開團更名後照片不應變動")
        // 逐項確認四種更名確實生效 (非誤判「沒動過所以沒變」)
        #expect(stored?.orderSource == "蝦皮 (新)")
        #expect(stored?.categories == ["彩妝保養"])
        #expect(stored?.reconciliationStatus == "對帳成功")
        #expect(stored?.campaignNames == ["春團 (補)"])
    }

    /// 驗證訂單持久化在此情境下的資料結果
    @Test func renameReconciliationStatusUpdatesMatchingOrders() async throws(any Error) {
        // Given

        let persistence = try makePersistence()
        let order = LedgerOrder(
            id: "BL-TEST-VS-RENAME",
            customer: LedgerCustomer(name: "對帳測試", initials: "VS", tier: .regular),
            status: .confirmed,
            currency: .twd,
            date: Date(timeIntervalSince1970: 1_700_000_000),
            items: [],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 0,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "蝦皮",
            categories: ["美妝"],
            paymentMethod: "銀行匯款",
            notes: "",
            reconciliationStatus: "待對帳",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
        // When

        try await persistence.update(order)

        try await persistence.renameReconciliationStatus(from: "待對帳", to: "對帳成功")

        let stored = try await persistence.fetchAll()
        // Then

        #expect(stored.first?.reconciliationStatus == "對帳成功", "cascade 更名應更新引用該對帳狀態的訂單")
    }

    /// 驗證訂單持久化在此情境下的資料結果
    @Test func deleteRemovesOrderById() async throws(any Error) {
        // Given

        let persistence = try makePersistence()
        let samples = LedgerOrder.sampleOrders
        // When

        try await persistence.seedIfEmpty(with: samples)

        let removeID = samples[0].id
        try await persistence.delete(id: removeID)

        let stored = try await persistence.fetchAll()
        // Then

        #expect(stored.count == samples.count - 1)
        #expect(!stored.contains(where: { $0.id == removeID }))
    }

    /// 驗證訂單持久化在此情境下的資料結果
    @Test func deleteUnknownIdIsNoOp() async throws(any Error) {
        // Given

        let persistence = try makePersistence()
        // When

        try await persistence.seedIfEmpty(with: LedgerOrder.sampleOrders)

        try await persistence.delete(id: "BL-DOES-NOT-EXIST")

        let stored = try await persistence.fetchAll()
        // Then

        #expect(stored.count == LedgerOrder.sampleOrders.count)
    }

    /// 驗證訂單持久化在此情境下的資料結果
    @Test func mergeOrdersInsertsNewAndMarksSourcesMergedInOneOperation() async throws(any Error) {
        // Given

        // 取兩筆同客戶同幣別的樣本作來源 (林書宇, KRW)
        let persistence = try makePersistence()
        let samples = LedgerOrder.sampleOrders
        // When

        try await persistence.seedIfEmpty(with: samples)

        let primaryID = "BL-2604-018"
        let secondaryID = "BL-2604-012"
        let primary = samples.first { $0.id == primaryID }!
        let secondary = samples.first { $0.id == secondaryID }!

        // 以純函式計算合併草稿後組出新訂單
        let draft = OrderMerge.makeDraft(
            primary: primary,
            secondary: secondary,
            now: Date(timeIntervalSince1970: 1_777_000_000),
            isCardless: { _ in false }
        )
        let merged = LedgerOrder(
            id: "BL-MERGED-001",
            customer: draft.customer,
            status: draft.status,
            currency: draft.currency,
            date: draft.date,
            items: draft.items,
            itemCost: draft.itemCost,
            domesticShipping: draft.domesticShipping,
            internationalShipping: draft.internationalShipping,
            foreignDomesticShipping: draft.foreignDomesticShipping,
            cardFeeRate: draft.cardFeeRate,
            platformFeeRate: draft.platformFeeRate,
            paymentFeeRate: draft.paymentFeeRate,
            chargedAmount: draft.chargedAmount,
            cardlessDeductionAmount: draft.cardlessDeductionAmount,
            cardlessSupplementAmount: draft.cardlessSupplementAmount,
            orderSource: draft.orderSource,
            categories: draft.categories,
            paymentMethod: draft.paymentMethod,
            notes: draft.notes,
            reconciliationStatus: draft.reconciliationStatus,
            campaignNames: draft.campaignNames,
            paymentReceiptStatus: draft.paymentReceiptStatus,
            isCashOnDelivery: draft.isCashOnDelivery,
            photos: draft.photos,
            mergedSourceIDs: draft.mergeSourceIDs
        )

        try await persistence.mergeOrders(newOrder: merged, consumedIDs: [primaryID, secondaryID])

        let stored = try await persistence.fetchAll()

        // 新訂單存在且記錄兩筆來源 id
        let storedMerged = stored.first { $0.id == "BL-MERGED-001" }
        // Then

        #expect(storedMerged != nil)
        #expect(storedMerged?.mergedSourceIDs == [primaryID, secondaryID])
        #expect(storedMerged?.categories == ["美妝", "服飾"])
        #expect(storedMerged?.chargedAmount == 17_480)

        // 兩筆來源訂單同一操作內轉「已合併」，其餘訂單不受影響
        #expect(stored.first { $0.id == primaryID }?.status == .merged)
        #expect(stored.first { $0.id == secondaryID }?.status == .merged)
        #expect(stored.count == samples.count + 1)
        let untouched = stored.filter {
            ![primaryID, secondaryID, "BL-MERGED-001"].contains($0.id)
        }
        #expect(untouched.allSatisfy { $0.status != .merged })
    }

    /// 驗證訂單持久化在此情境下的資料結果
    @Test
    func mergeOrdersFailsOnIdentifierCollisionAndLeavesEverythingUnchanged()
        async throws(any Error) {
        // Given

        // 撞號時整批不寫入，來源訂單也不變。
        let persistence = try makePersistence()
        let samples = LedgerOrder.sampleOrders
        // When

        try await persistence.seedIfEmpty(with: samples)

        let primaryID = "BL-2604-018"
        let secondaryID = "BL-2604-012"
        let collidingID = "BL-2604-011"
        let primary = samples.first { $0.id == primaryID }!
        let secondary = samples.first { $0.id == secondaryID }!
        let collidingExisting = samples.first { $0.id == collidingID }!

        let draft = OrderMerge.makeDraft(
            primary: primary,
            secondary: secondary,
            now: Date(timeIntervalSince1970: 1_777_000_000),
            isCardless: { _ in false }
        )
        let merged = LedgerOrder(
            id: collidingID,
            customer: draft.customer,
            status: draft.status,
            currency: draft.currency,
            date: draft.date,
            items: draft.items,
            itemCost: draft.itemCost,
            domesticShipping: draft.domesticShipping,
            internationalShipping: draft.internationalShipping,
            foreignDomesticShipping: draft.foreignDomesticShipping,
            cardFeeRate: draft.cardFeeRate,
            platformFeeRate: draft.platformFeeRate,
            paymentFeeRate: draft.paymentFeeRate,
            chargedAmount: draft.chargedAmount,
            cardlessDeductionAmount: draft.cardlessDeductionAmount,
            cardlessSupplementAmount: draft.cardlessSupplementAmount,
            orderSource: draft.orderSource,
            categories: draft.categories,
            paymentMethod: draft.paymentMethod,
            notes: draft.notes,
            reconciliationStatus: draft.reconciliationStatus,
            campaignNames: draft.campaignNames,
            paymentReceiptStatus: draft.paymentReceiptStatus,
            isCashOnDelivery: draft.isCashOnDelivery,
            photos: draft.photos,
            mergedSourceIDs: draft.mergeSourceIDs
        )

        do {
            try await persistence.mergeOrders(
                newOrder: merged,
                consumedIDs: [primaryID, secondaryID]
            )
            // Then

            Issue.record("預期為訂單編號衝突錯誤。")
        } catch {
            switch error {
            case let .identifierCollision(id):
                #expect(id == collidingID)
            case .storage:
                Issue.record("預期為訂單編號衝突錯誤，實際為持久化錯誤。")
            }
        }

        let stored = try await persistence.fetchAll()
        #expect(stored.count == samples.count, "撞號失敗後不應新增任何資料列")
        // Codable round-trip 不含 LedgerOrderItem.id，比對前先移除
        let collidingStored = stored.first { $0.id == collidingID }
        #expect(
            collidingStored.map(LedgerOrder.normalizingItemIdentifiers)
                == LedgerOrder.normalizingItemIdentifiers(collidingExisting),
            "撞號的既有訂單必須逐欄未變"
        )
        #expect(
            stored.first { $0.id == primaryID }?.status == primary.status,
            "來源訂單一狀態不應落地為已合併"
        )
        #expect(
            stored.first { $0.id == secondaryID }?.status == secondary.status,
            "來源訂單二狀態不應落地為已合併"
        )
    }

    /// 驗證訂單持久化在此情境下的資料結果
    @Test func renameCategoryRewritesElementsInsideArrays() async throws(any Error) {
        // Given

        // 多類別訂單僅目標元素改名 (保序)；未含目標的訂單不受影響
        let persistence = try makePersistence()
        // When

        try await persistence.update(
            Self.makeArrayOrder(
                id: "BL-CAT-1",
                categories: ["美妝", "服飾"]
            )
        )
        try await persistence.update(
            Self.makeArrayOrder(
                id: "BL-CAT-2",
                categories: ["服飾"]
            )
        )

        try await persistence.renameCategory(from: "美妝", to: "彩妝保養")

        let stored = try await persistence.fetchAll()
        // Then

        #expect(stored.first { $0.id == "BL-CAT-1" }?.categories == ["彩妝保養", "服飾"])
        #expect(stored.first { $0.id == "BL-CAT-2" }?.categories == ["服飾"])
    }

    /// 驗證訂單持久化在此情境下的資料結果
    @Test func renameCampaignRewritesElementsInsideArrays() async throws(any Error) {
        // Given

        // 多開團訂單僅目標元素改名 (保序)
        let persistence = try makePersistence()
        // When

        try await persistence.update(
            Self.makeArrayOrder(
                id: "BL-CAMP-1",
                categories: ["美妝"],
                campaignNames: ["三月日本團", "四月韓國團"]
            )
        )
        try await persistence.update(
            Self.makeArrayOrder(
                id: "BL-CAMP-2",
                categories: ["美妝"],
                campaignNames: []
            )
        )

        try await persistence.renameCampaign(from: "三月日本團", to: "三月日本團 (補)")

        let stored = try await persistence.fetchAll()
        // Then

        #expect(stored.first { $0.id == "BL-CAMP-1" }?.campaignNames == ["三月日本團 (補)", "四月韓國團"])
        #expect(stored.first { $0.id == "BL-CAMP-2" }?.campaignNames == [])
    }

    /// 驗證訂單持久化在此情境下的資料結果
    @Test func upsertAllInsertsAndUpdatesInOneBatch() async throws(any Error) {
        // Given

        // 批次同時更新既有與新增訂單時，儲存應保持原子性
        let persistence = try makePersistence()

        let existing1 = Self.makeStatusOrder(id: "BL-B-1", status: .shipping)
        let existing2 = Self.makeStatusOrder(id: "BL-B-2", status: .shipping)
        // When

        try await persistence.upsertAll([existing1, existing2])

        // 批次：更新兩筆既有狀態 + 插入一筆新訂單，單一操作落盤
        let updated1 = Self.makeStatusOrder(id: "BL-B-1", status: .arrived)
        let updated2 = Self.makeStatusOrder(id: "BL-B-2", status: .arrived)
        let inserted = Self.makeStatusOrder(id: "BL-B-3", status: .arrived)
        try await persistence.upsertAll([updated1, updated2, inserted])

        let stored = try await persistence.fetchAll()
        // Then

        #expect(stored.count == 3)
        #expect(stored.first { $0.id == "BL-B-1" }?.status == .arrived)
        #expect(stored.first { $0.id == "BL-B-2" }?.status == .arrived)
        #expect(stored.first { $0.id == "BL-B-3" }?.status == .arrived)
    }

    /// 驗證訂單持久化在此情境下的資料結果
    @Test func upsertAllWithEmptyArrayIsNoOp() async throws(any Error) {
        // Given

        let persistence = try makePersistence()
        // When

        try await persistence.upsertAll([])
        let stored = try await persistence.fetchAll()
        // Then

        #expect(stored.isEmpty)
    }

    /// 建立訂單儲存失敗時不應留下尚未落盤的資料列
    ///
    /// - Throws: 測試容器建立、寫入或讀取失敗時拋出錯誤
    @Test func createSaveFailureRemovesInsertedOrder() async throws(any Error) {
        // Given：儲存權限已撤回，且待建立的訂單尚不存在
        let persistence = try Self.makeUnsavablePersistence()
        let order = Self.makeStatusOrder(id: "BL-ROLLBACK-CREATE", status: .quoting)

        // When
        do {
            try await persistence.create(order)
            // Then

            Issue.record("預期 create 會拋出 storage(.saveFailed)。")
        } catch {
            switch error {
            case let .storage(storageError):
                switch storageError {
                case .saveFailed:
                    break
                case .fetchFailed, .containerCreationFailed:
                    Issue.record("預期 storage 內為 saveFailed。")
                }
            case .identifierCollision:
                Issue.record("預期為 storage(.saveFailed)，實際為 identifierCollision。")
            }
        }

        // Then
        let stored = try await persistence.fetchAll()
        #expect(
            stored.map(\.id) == ["BL-ROLLBACK-SEED"],
            "save 失敗後 rollback 應只保留 save 前已存在的資料列"
        )
    }

    /// 更新不存在的訂單儲存失敗時不應留下待寫入資料列
    ///
    /// - Throws: 測試容器建立、寫入或讀取失敗時拋出錯誤
    @Test func updateSaveFailureRemovesInsertedOrder() async throws(any Error) {
        // Given：儲存權限已撤回，且待更新的訂單尚不存在
        let persistence = try Self.makeUnsavablePersistence()
        let order = Self.makeStatusOrder(id: "BL-ROLLBACK-UPDATE", status: .quoting)

        // When
        await #expect(throws: PersistenceError.self) {
            try await persistence.update(order)
        }

        // Then
        let stored = try await persistence.fetchAll()
        #expect(
            stored.map(\.id) == ["BL-ROLLBACK-SEED"],
            "save 失敗後 rollback 應只保留 save 前已存在的資料列"
        )
    }

    /// 批次 upsert 儲存失敗時不應留下尚未落盤的資料列
    ///
    /// - Throws: 測試容器建立、寫入或讀取失敗時拋出錯誤
    @Test func upsertAllSaveFailureRemovesInsertedOrder() async throws(any Error) {
        // Given：儲存權限已撤回，且待 upsert 的訂單尚不存在
        let persistence = try Self.makeUnsavablePersistence()
        let order = Self.makeStatusOrder(id: "BL-ROLLBACK-UPSERT", status: .quoting)

        // When
        await #expect(throws: PersistenceError.self) {
            try await persistence.upsertAll([order])
        }

        // Then
        let stored = try await persistence.fetchAll()
        #expect(
            stored.map(\.id) == ["BL-ROLLBACK-SEED"],
            "save 失敗後 rollback 應只保留 save 前已存在的資料列"
        )
    }

    /// 合併訂單儲存失敗時不應留下尚未落盤的合併結果
    ///
    /// - Throws: 測試容器建立、寫入或讀取失敗時拋出錯誤
    @Test func mergeOrdersSaveFailureRemovesInsertedOrder() async throws(any Error) {
        // Given：儲存權限已撤回，且待合併的新訂單尚不存在
        let persistence = try Self.makeUnsavablePersistence()
        let merged = Self.makeStatusOrder(id: "BL-ROLLBACK-MERGE", status: .quoting)

        // When
        await #expect(throws: OrderPersistenceError.self) {
            try await persistence.mergeOrders(newOrder: merged, consumedIDs: [])
        }

        // Then
        let stored = try await persistence.fetchAll()
        #expect(
            stored.map(\.id) == ["BL-ROLLBACK-SEED"],
            "save 失敗後 rollback 應只保留 save 前已存在的資料列"
        )
    }

    /// 合併來源訂單讀取失敗時不應留下尚未落盤的合併結果
    ///
    /// - Throws: 測試容器建立、來源讀取或結果讀取失敗時拋出錯誤
    @Test
    func mergeOrdersSourceFetchFailureRemovesInsertedOrder() async throws(any Error) {
        // Given：來源訂單查詢會失敗，且待合併的新訂單尚不存在
        let persistence = OrderPersistence(
            modelContainer: PersistenceContainer.makeInMemory(for: .testing),
            consumedOrderFetcher: { _ in
                throw PersistenceError.fetchFailed(
                    underlying: TestDependencies.makeUnderlyingError(message: "來源查詢失敗")
                )
            }
        )
        let merged = Self.makeStatusOrder(id: "BL-ROLLBACK-SOURCE", status: .quoting)

        // When
        await #expect(throws: OrderPersistenceError.self) {
            try await persistence.mergeOrders(newOrder: merged, consumedIDs: ["BL-SOURCE-1"])
        }

        // Then
        let stored = try await persistence.fetchAll()
        #expect(stored.isEmpty, "來源讀取失敗後不應留下尚未落盤的合併結果")
    }

    /// 儲存含照片訂單失敗時移除尚未落盤的插入記錄
    ///
    /// - Throws: 測試容器建立或資料寫入失敗時拋出錯誤
    @Test
    func updatePersistingPhotosSaveFailureRemovesInsertedOrder() async throws(any Error) {
        // Given：儲存權限已撤回，且待寫入訂單含照片
        let persistence = try Self.makeUnsavablePersistence()
        let order = Self.withPhotos(
            Self.makeStatusOrder(id: "BL-ROLLBACK-PHOTOS", status: .quoting),
            photos: [Data([0x01, 0x02])]
        )

        // When
        await #expect(throws: PersistenceError.self) {
            try await persistence.updatePersistingPhotos(order)
        }

        // Then
        let stored = try await persistence.fetchAll()
        #expect(
            stored.map(\.id) == ["BL-ROLLBACK-SEED"],
            "save 失敗後 rollback 應只保留 save 前已存在的資料列"
        )
    }

    /// 初次 seed 儲存失敗時移除所有尚未落盤的插入記錄
    ///
    /// - Throws: 測試容器建立或資料寫入失敗時拋出錯誤
    @Test
    func seedIfEmptySaveFailureRemovesInsertedOrders() async throws(any Error) {
        // Given：空的儲存且儲存權限已撤回
        let persistence = try Self.makeUnsavablePersistence(shouldSeedExistingOrder: false)
        let samples = [
            Self.makeStatusOrder(id: "BL-ROLLBACK-SEED-1", status: .confirmed),
            Self.makeStatusOrder(id: "BL-ROLLBACK-SEED-2", status: .shipping),
        ]

        // When
        await #expect(throws: PersistenceError.self) {
            try await persistence.seedIfEmpty(with: samples)
        }

        // Then
        let stored = try await persistence.fetchAll()
        #expect(stored.isEmpty, "seed save 失敗後不應留下任何 pending 新訂單")
    }

    /// 驗證訂單持久化在此情境下的資料結果
    @Test func persistenceInstanceProviderReusesTheSameInstance() async throws(any Error) {
        // Given

        // 重複取用應回傳同一個實例，序列化同一實體的寫入。
        let container = PersistenceContainer.makeInMemory(for: .testing)
        let provider = OrderRepository.PersistenceInstanceProvider(container: container)

        // When

        let first = await provider.instance
        let second = await provider.instance

        // Then

        #expect(first === second)
    }

    /// 驗證訂單持久化在此情境下的資料結果
    @Test
    func concurrentCreateAttemptsAllHonorCreateIntentCollisionSemantics() async throws(any Error) {
        // Given

        // 驗證併發建立同編號訂單時會拒絕撞號
        // 併發呼叫用來重複驗證同編號建立會遵守撞號規則
        let container = PersistenceContainer.makeInMemory(for: .testing)
        let repository = OrderRepository.live(container: container)
        let order = Self.makeStatusOrder(id: "BL-CONCURRENT-1", status: .quoting)

        // When

        let results = await withTaskGroup(of: CreateResult.self) { group in
            for _ in 0..<20 {
                group.addTask { await Self.attemptCreate(order, via: repository) }
            }
            var collected: [CreateResult] = []
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        // Then

        #expect(results.filter { $0 == .created }.count == 1, "應恰好一筆並發建立成功")
        #expect(results.filter { $0 == .collided }.count == 19, "其餘應落在建立意圖的撞號路徑而非靜默插入")

        let stored = try await repository.fetchOrders()
        #expect(stored.filter { $0.id == order.id }.count == 1, "並發寫入後應只留下一列，不產生同編號重複資料")
    }

    /// 批次更新只影響指定訂單編號
    ///
    /// - Throws: 測試容器建立或資料寫入失敗時拋出錯誤
    @Test func upsertAllUpdatesOnlyGivenIDs() async throws(any Error) {
        // Given

        let persistence = try makePersistence()
        let target = Self.makeStatusOrder(id: "BL-PRED-TARGET", status: .quoting)
        let other = Self.makeStatusOrder(id: "BL-PRED-OTHER", status: .quoting)
        // When

        try await persistence.create(target)
        try await persistence.create(other)

        let changed = Self.makeStatusOrder(id: target.id, status: .confirmed)
        try await persistence.upsertAll([changed])

        // Then

        #expect(try await persistence.fetch(id: target.id)?.status == .confirmed)
        #expect(try await persistence.fetch(id: other.id)?.status == .quoting)
    }

    /// 批次更新只影響指定訂單
    ///
    /// - Throws: 測試容器建立或資料寫入失敗時拋出錯誤
    @Test func upsertAllLeavesUnrelatedOrdersUntouched() async throws(any Error) {
        // Given

        let persistence = try makePersistence()
        let photo = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x30])

        var seeded: [LedgerOrder] = []
        for index in 0..<500 {
            let order = Self.withPhotos(
                Self.makeStatusOrder(
                    id: String(format: "BL-BULK-%03d", index),
                    status: .quoting
                ),
                photos: [photo]
            )
            seeded.append(order)
        }
        // When

        try await persistence.upsertAll(seeded)

        let targetIDs = ["BL-BULK-010", "BL-BULK-250", "BL-BULK-499"]
        let changed = targetIDs.map { id in
            Self.withPhotos(
                Self.makeStatusOrder(
                    id: id,
                    status: .confirmed
                ),
                photos: [photo]
            )
        }
        try await persistence.upsertAll(changed)

        let all = try await persistence.fetchAll()
        // Then

        #expect(all.count == 500)

        for id in targetIDs {
            #expect(try await persistence.fetch(id: id)?.status == .confirmed, "\(id) 應已更新")
        }

        let untouchedIDs = seeded.map(\.id).filter { !targetIDs.contains($0) }
        #expect(untouchedIDs.count == 497)
        for id in untouchedIDs.shuffled().prefix(20) {
            let stored = try await persistence.fetch(id: id)
            #expect(stored?.status == .quoting, "\(id) 狀態不應被批次更新影響")
            #expect(stored?.photos == [photo], "\(id) 照片不應被批次更新影響")
        }
    }

    /// 合併只更新指定來源訂單
    ///
    /// - Throws: 測試容器建立或資料寫入失敗時拋出錯誤
    @Test func mergeOrdersLeavesUnrelatedOrdersUntouched() async throws(any Error) {
        // Given

        let persistence = try makePersistence()
        let photo = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x31])

        var seeded: [LedgerOrder] = []
        for index in 0..<50 {
            let order = Self.withPhotos(
                Self.makeStatusOrder(
                    id: String(format: "BL-MERGEBULK-%03d", index),
                    status: .quoting
                ),
                photos: [photo]
            )
            seeded.append(order)
        }
        // When

        try await persistence.upsertAll(seeded)

        let primaryID = "BL-MERGEBULK-005"
        let secondaryID = "BL-MERGEBULK-010"
        let merged = Self.withPhotos(
            Self.makeStatusOrder(
                id: "BL-MERGEBULK-NEW",
                status: .confirmed
            ),
            photos: [photo]
        )
        try await persistence.mergeOrders(newOrder: merged, consumedIDs: [primaryID, secondaryID])

        // Then

        #expect(try await persistence.fetch(id: primaryID)?.status == .merged)
        #expect(try await persistence.fetch(id: secondaryID)?.status == .merged)

        let untouchedIDs = seeded.map(\.id).filter { $0 != primaryID && $0 != secondaryID }
        #expect(untouchedIDs.count == 48)
        for id in untouchedIDs.shuffled().prefix(20) {
            let stored = try await persistence.fetch(id: id)
            #expect(stored?.status == .quoting, "\(id) 狀態不應被合併影響")
            #expect(stored?.photos == [photo], "\(id) 照片不應被合併影響")
        }
    }

    /// 大批訂單編號也能完整更新
    ///
    /// - Throws: 測試容器建立或資料寫入失敗時拋出錯誤
    @Test func upsertAllHandlesLargeIDBatch() async throws(any Error) {
        // Given

        let persistence = try makePersistence()

        var seeded: [LedgerOrder] = []
        for index in 0..<300 {
            seeded.append(
                Self.makeStatusOrder(
                    id: String(format: "BL-LARGEBATCH-%03d", index),
                    status: .quoting
                )
            )
        }
        // When

        try await persistence.upsertAll(seeded)

        let changed = (0..<300).map { index in
            Self.makeStatusOrder(
                id: String(format: "BL-LARGEBATCH-%03d", index),
                status: .confirmed
            )
        }
        try await persistence.upsertAll(changed)

        let all = try await persistence.fetchAll()
        // Then

        #expect(all.count == 300)
        #expect(all.allSatisfy { $0.status == .confirmed }, "300 筆訂單編號的批次應全數正確更新")
    }
}

// MARK: - Nested Types

private extension OrderPersistenceTests {

    /// 全欄位樣本的兩種變體：更新前／更新後，每一欄皆非預設值且逐欄相異
    enum FullFieldVariant {

        // MARK: - Cases

        /// 更新前寫入的初始值
        case original

        /// 更新後斷言相等的目標值
        case updated
    }

    /// 並發建立的結果分類
    enum CreateResult: Equatable {

        // MARK: - Cases

        /// 成功建立新資料列
        case created

        /// 撞號失敗
        case collided
    }
}

// MARK: - Private Method

private extension OrderPersistenceTests {

    /// 用 in-memory 的 ``ModelContainer`` 建立每個測試獨立的 ``OrderPersistence``
    ///
    /// - Returns: 建立的 OrderPersistence
    /// - Throws: 測試容器建立失敗時拋出錯誤
    func makePersistence() throws(any Error) -> OrderPersistence {
        let container = PersistenceContainer.makeInMemory(for: .testing)
        return OrderPersistence(modelContainer: container)
    }

    /// 建立寫入權限被撤回的磁碟 persistence，驗證 save 失敗可 rollback
    ///
    /// - Parameter shouldSeedExistingOrder: 是否先寫入一筆既有訂單
    /// - Returns: 使用不可寫入儲存的 OrderPersistence
    /// - Throws: 測試容器建立失敗時拋出錯誤
    static func makeUnsavablePersistence(
        shouldSeedExistingOrder: Bool = true
    ) throws(any Error) -> OrderPersistence {
        let schema = Schema(versionedSchema: BuyLedgerSchemaV17.self)
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("BuyLedgerRollbackTest-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        let storeURL = directoryURL.appendingPathComponent("BuyLedger.store")

        let writableConfiguration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        // 先釋放可寫入容器，讓後續讀取使用同一 store 的唯讀鎖
        do {
            let writableContainer = try ModelContainer(
                for: schema,
                migrationPlan: BuyLedgerMigrationPlan.self,
                configurations: writableConfiguration
            )
            let seedContext = ModelContext(writableContainer)
            if shouldSeedExistingOrder {
                seedContext.insert(
                    OrderRecord(
                        order: Self.makeStatusOrder(
                            id: "BL-ROLLBACK-SEED",
                            status: .confirmed
                        )
                    )
                )
                try seedContext.save()
            }
        }

        let readOnlyConfiguration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            allowsSave: false,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(
            for: schema,
            migrationPlan: BuyLedgerMigrationPlan.self,
            configurations: readOnlyConfiguration
        )
        return OrderPersistence(modelContainer: container)
    }

    /// 建立批次 upsert 測試用、可指定狀態的最小訂單
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - status: 訂單狀態
    /// - Returns: 建立的測試訂單
    static func makeStatusOrder(id: String, status: OrderStatus) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: "客戶", initials: "XX", tier: .new),
            status: status,
            currency: .twd,
            date: Date(timeIntervalSince1970: 1_770_000_000),
            items: [],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 0,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "蝦皮",
            categories: ["美妝"],
            paymentMethod: "信用卡",
            notes: "",
            reconciliationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }

    /// 回傳只改變照片的複本
    ///
    /// - Parameters:
    ///   - order: 原始訂單
    ///   - photos: 新的照片集合
    /// - Returns: 套用新照片後的訂單
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

    /// 回傳只改變對帳狀態的複本
    ///
    /// - Parameters:
    ///   - order: 原始訂單
    ///   - status: 新的對帳狀態
    /// - Returns: 套用新對帳狀態後的訂單
    static func withReconciliationStatus(_ order: LedgerOrder, status: String) -> LedgerOrder {
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
            reconciliationStatus: status,
            campaignNames: order.campaignNames,
            paymentReceiptStatus: order.paymentReceiptStatus,
            isCashOnDelivery: order.isCashOnDelivery,
            photos: order.photos,
            mergedSourceIDs: order.mergedSourceIDs
        )
    }

    /// 建立陣列 rename 測試用的最小訂單
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - categories: 商品類別
    ///   - campaignNames: 開團名稱
    /// - Returns: 建立的測試訂單
    static func makeArrayOrder(
        id: String,
        categories: [String],
        campaignNames: [String] = []
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: "客戶", initials: "XX", tier: .regular),
            status: .confirmed,
            currency: .twd,
            date: Date(timeIntervalSince1970: 1_770_000_000),
            items: [],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 0,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "蝦皮",
            categories: categories,
            paymentMethod: "信用卡",
            notes: "",
            reconciliationStatus: "",
            campaignNames: campaignNames,
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }

    /// 建立所有欄位都有值的整值相等測試樣本
    ///
    /// - Parameter variant: 測試樣本變體
    /// - Returns: 對應變體的完整訂單
    static func makeFullFieldOrder(variant: FullFieldVariant) -> LedgerOrder {
        switch variant {
        case .original:
            return LedgerOrder(
                id: "BL-FULLFIELD-001",
                customer: LedgerCustomer(name: "初始客戶", initials: "IN", tier: .regular),
                status: .quoting,
                currency: .usd,
                date: Date(timeIntervalSince1970: 1_700_000_000),
                items: [LedgerOrderItem(name: "商品A", quantity: 2, unitPrice: 150)],
                itemCost: 1_200,
                domesticShipping: 60,
                internationalShipping: 300,
                foreignDomesticShipping: 80,
                cardFeeRate: 0.02,
                platformFeeRate: 0.05,
                paymentFeeRate: 0.01,
                chargedAmount: 5_000,
                cardlessDeductionAmount: 100,
                cardlessSupplementAmount: 50,
                orderSource: "蝦皮",
                categories: ["美妝"],
                paymentMethod: "信用卡",
                notes: "初次備註",
                reconciliationStatus: "待對帳",
                campaignNames: ["春季團"],
                paymentReceiptStatus: .received,
                isCashOnDelivery: true,
                photos: [Data([0x01, 0x02])],
                mergedSourceIDs: ["BL-SRC-OLD"]
            )

        case .updated:
            return LedgerOrder(
                id: "BL-FULLFIELD-001",
                customer: LedgerCustomer(name: "更新後客戶", initials: "UD", tier: .vip),
                status: .delivered,
                currency: .jpy,
                date: Date(timeIntervalSince1970: 1_800_000_000),
                items: [LedgerOrderItem(name: "商品B", quantity: 5, unitPrice: 300)],
                itemCost: 2_400,
                domesticShipping: 120,
                internationalShipping: 450,
                foreignDomesticShipping: 160,
                cardFeeRate: 0.03,
                platformFeeRate: 0.08,
                paymentFeeRate: 0.02,
                chargedAmount: 8_000,
                cardlessDeductionAmount: 200,
                cardlessSupplementAmount: 75,
                orderSource: "露天",
                categories: ["3C"],
                paymentMethod: "銀行匯款",
                notes: "更新後備註",
                reconciliationStatus: "對帳完成",
                campaignNames: ["夏季團"],
                paymentReceiptStatus: .pending,
                isCashOnDelivery: false,
                photos: [Data([0x03, 0x04, 0x05])],
                mergedSourceIDs: ["BL-SRC-NEW-1", "BL-SRC-NEW-2"]
            )
        }
    }

    /// 建立訂單並將撞號轉為可比對結果
    ///
    /// - Parameters:
    ///   - order: 要建立的訂單
    ///   - repository: 要執行建立操作的 repository
    /// - Returns: 建立成功或發生編號衝突的結果
    static func attemptCreate(
        _ order: LedgerOrder,
        via repository: OrderRepository
    ) async -> CreateResult {
        do {
            try await repository.createOrder(order)
            return .created
        } catch OrderPersistenceError.identifierCollision {
            return .collided
        } catch {
            Issue.record("非預期的錯誤型別：\(error)")
            return .collided
        }
    }
}
