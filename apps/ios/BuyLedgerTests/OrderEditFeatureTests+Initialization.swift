//
//  OrderEditFeatureTests+Initialization.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension OrderEditFeatureTests {

    /// 新訂單的標題沿用「新訂單」本地化鍵
    @Test
    func navigationTitleKey_新訂單_提供新訂單標題() {
        // Given
        let state = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)

        // When
        let title = state.navigationTitleKey

        // Then
        #expect(title == "orders.list.label.newOrder")
    }

    /// 編輯既有訂單的標題沿用「編輯訂單」本地化鍵
    @Test
    func navigationTitleKey_既有訂單_提供編輯訂單標題() {
        // Given
        let state = OrderEditFeature.State(
            original: LedgerOrder.sampleOrders[0],
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )

        // When
        let title = state.navigationTitleKey

        // Then
        #expect(title == "orders.detail.label.editOrder")
    }

    /// 合併預填沒有原始訂單時，標題仍沿用「新訂單」本地化鍵
    @Test
    func navigationTitleKey_合併預填無原始訂單_提供新訂單標題() {
        // Given
        let state = OrderEditFeature.State(
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            prefill: OrderEditFeature.State.Prefill(
                draft: OrderDraft(original: nil, currentDate: TestDependencies.fixedNow),
                mergeSourceIDs: ["BL-FIRST", "BL-SECOND"],
                keptPhotos: []
            )
        )

        // When
        let title = state.navigationTitleKey

        // Then
        #expect(title == "orders.list.label.newOrder")
    }

    /// 編輯既有訂單時，草稿帶入原有欄位內容
    @Test
    func init_編輯既有訂單_草稿帶入原始欄位() {
        // Given
        let original = LedgerOrder.sampleOrders[0]

        // When
        let state = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        let draft = state.draft

        // Then
        #expect(draft.customerName == "林書宇")
        #expect(draft.categories == ["美妝"])
        #expect(draft.status == .shipping)
        #expect(draft.currency == .krw)
        #expect(draft.chargedAmount == 11_800)
        #expect(draft.itemCost == 8_892)
        #expect(draft.domesticShipping == 80)
        #expect(draft.internationalShipping == 320)
        #expect(draft.cardFeeRate == 0.015)
        #expect(draft.notes == "客戶指定到貨後先拍照確認，再安排出貨。")
    }

    /// 編輯既有訂單時，表單一開始不帶入訂單上的照片，等載入完成才放進草稿
    @Test
    func init_既有訂單照片尚未載入_不帶入原照片() {
        // Given
        let photos = [Data([0x01]), Data([0x02])]
        let sample = LedgerOrder.sampleOrders[0]
        let original = LedgerOrder(
            id: sample.id,
            customer: sample.customer,
            status: sample.status,
            currency: sample.currency,
            date: sample.date,
            items: sample.items,
            itemCost: sample.itemCost,
            domesticShipping: sample.domesticShipping,
            internationalShipping: sample.internationalShipping,
            foreignDomesticShipping: sample.foreignDomesticShipping,
            cardFeeRate: sample.cardFeeRate,
            platformFeeRate: sample.platformFeeRate,
            paymentFeeRate: sample.paymentFeeRate,
            chargedAmount: sample.chargedAmount,
            cardlessDeductionAmount: sample.cardlessDeductionAmount,
            cardlessSupplementAmount: sample.cardlessSupplementAmount,
            orderSource: sample.orderSource,
            categories: sample.categories,
            paymentMethod: sample.paymentMethod,
            notes: sample.notes,
            reconciliationStatus: sample.reconciliationStatus,
            campaignNames: sample.campaignNames,
            paymentReceiptStatus: sample.paymentReceiptStatus,
            isCashOnDelivery: sample.isCashOnDelivery,
            photos: photos,
            mergedSourceIDs: []
        )

        // When
        let state = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )

        // Then
        #expect(state.photos.draftPhotos.isEmpty)
        #expect(state.photos.photoLoadPhase == .notLoaded)
    }

    /// 新訂單一開啟照片就算載入完成，可以直接加入照片
    @Test
    func init_新建訂單_照片直接視為已載入() {
        // Given

        // When
        let state = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)

        // Then
        #expect(state.photos.photoLoadPhase == .loaded)
        #expect(state.photos.canAddMorePhotos == true)
    }

    /// 新訂單的草稿欄位以空白與預設值起始
    @Test
    func init_新訂單_草稿帶入預設值() {
        // Given

        // When
        let state = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)

        // Then
        #expect(state.draft.customerName.isEmpty)
        #expect(state.draft.categories.isEmpty)
        #expect(state.draft.status == .quoting)
        #expect(state.draft.currency == .twd)
        #expect(state.draft.date == TestDependencies.fixedNow)
        #expect(state.draft.chargedAmount == 0)
        #expect(state.draft.cardlessDeductionAmount == 0)
        #expect(state.draft.cardlessSupplementAmount == 0)
        #expect(state.draft.itemCost == 0)
        #expect(state.draft.domesticShipping == 0)
        #expect(state.draft.internationalShipping == 0)
        #expect(state.draft.cardFeeRate == 0)
        #expect(state.draft.platformFeeRate == 0)
        #expect(state.draft.notes.isEmpty)
    }
}
