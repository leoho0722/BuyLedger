//
//  OrderDraftPhotosTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrderDraft.resolveWriteResult` 的單元測試，涵蓋新建與編輯訂單時的照片寫入條件
struct OrderDraftPhotosTests {

    /// 驗證既有訂單的照片已完整載入、使用者確實增刪過照片時，結果帶出照片並標記要寫入
    @Test
    func resolveWriteResult_既有訂單照片已載入且已編輯_寫入照片() {
        // Given
        let existing = OrderDraftTestSupport.makeOrder(id: "BL-001", customerName: "客戶")
        var editState = OrderEditFeature.State(
            original: existing,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        editState.photos.draftPhotos = [Data([1, 2, 3])]
        editState.photos.photoLoadPhase = .loaded
        editState.photos.hasEditedPhotos = true

        // When
        let editedResult = OrderDraft.resolveWriteResult(editState, existingOrders: [existing]) {
            "unused"
        }

        // Then
        #expect(editedResult.order.photos == [Data([1, 2, 3])])
        #expect(editedResult.shouldWritePhotos == true)
    }

    /// 驗證既有訂單的照片已載入但使用者未編輯時，結果不帶出草稿照片，也不標記要寫入
    @Test
    func resolveWriteResult_既有訂單照片已載入但未編輯_不寫入照片() {
        // Given
        let existing = OrderDraftTestSupport.makeOrder(id: "BL-001", customerName: "客戶")
        var editState = OrderEditFeature.State(
            original: existing,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        editState.photos.draftPhotos = [Data([1, 2, 3])]
        editState.photos.photoLoadPhase = .loaded
        editState.photos.hasEditedPhotos = false

        // When
        let untouchedResult = OrderDraft.resolveWriteResult(editState, existingOrders: [existing]) {
            "unused"
        }

        // Then
        #expect(untouchedResult.order.photos == [])
        #expect(untouchedResult.shouldWritePhotos == false)
    }

    /// 驗證既有訂單的照片尚未載入時，即使草稿有編輯，結果也不帶出照片，避免覆寫既有照片
    @Test
    func resolveWriteResult_既有訂單照片尚未載入_不寫入照片() {
        // Given
        let existing = OrderDraftTestSupport.makeOrder(id: "BL-001", customerName: "客戶")
        var editState = OrderEditFeature.State(
            original: existing,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        editState.photos.draftPhotos = [Data([4, 5, 6])]
        editState.photos.photoLoadPhase = .notLoaded
        editState.photos.hasEditedPhotos = true

        // When
        let result = OrderDraft.resolveWriteResult(editState, existingOrders: [existing]) {
            "unused"
        }

        // Then
        #expect(result.order.photos == [])
        #expect(result.shouldWritePhotos == false)
    }

    /// 驗證新建訂單時，草稿照片一律帶入並標記要寫入，不受是否編輯照片影響
    @Test
    func resolveWriteResult_新建訂單_一律寫入照片() {
        // Given
        var editState = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        editState.photos.draftPhotos = [Data([9, 9, 9])]
        editState.photos.hasEditedPhotos = false

        // When
        let result = OrderDraft.resolveWriteResult(editState, existingOrders: []) { "GENID" }

        // Then
        #expect(result.order.photos == [Data([9, 9, 9])])
        #expect(result.shouldWritePhotos == true)
        #expect(result.isNewOrder == true)
    }
}
