//
//  OrderDraftTests+Photos.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension OrderDraftTests {

    /// 既有訂單且使用者確實增刪過照片、照片已完整載入時，才顯式寫入照片
    @Test
    func resolveWriteResult_既有訂單照片已載入且已編輯_寫入照片() {
        // Given
        let existing = Self.makeOrder(id: "BL-001", customerName: "客戶")
        var editState = OrderEditFeature.State(
            original: existing,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        editState.photos.draftPhotos = [Data([1, 2, 3])]
        editState.photos.photoLoadPhase = .loaded
        editState.photos.hasEditedPhotos = true

        // When
        let editedResult = OrderDraft.resolveWriteResult(
            editState,
            existingOrders: [existing]
        ) { "unused" }

        // Then
        #expect(editedResult.order.photos == [Data([1, 2, 3])])
        #expect(editedResult.shouldWritePhotos == true)
    }

    /// 既有訂單的照片已載入但未編輯時不應顯式寫入照片
    @Test
    func resolveWriteResult_既有訂單照片已載入但未編輯_不寫入照片() {
        // Given
        let existing = Self.makeOrder(id: "BL-001", customerName: "客戶")
        var editState = OrderEditFeature.State(
            original: existing,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        editState.photos.draftPhotos = [Data([1, 2, 3])]
        editState.photos.photoLoadPhase = .loaded
        editState.photos.hasEditedPhotos = false

        // When
        let untouchedResult = OrderDraft.resolveWriteResult(
            editState,
            existingOrders: [existing]
        ) { "unused" }

        // Then
        #expect(untouchedResult.order.photos == [])
        #expect(untouchedResult.shouldWritePhotos == false)
    }

    /// 既有訂單的照片尚未載入時不應覆寫既有照片
    @Test
    func resolveWriteResult_既有訂單照片尚未載入_不寫入照片() {
        // Given
        let existing = Self.makeOrder(id: "BL-001", customerName: "客戶")
        var editState = OrderEditFeature.State(
            original: existing,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        editState.photos.draftPhotos = [Data([4, 5, 6])]
        editState.photos.photoLoadPhase = .notLoaded
        editState.photos.hasEditedPhotos = true

        // When
        let result = OrderDraft.resolveWriteResult(
            editState,
            existingOrders: [existing]
        ) { "unused" }

        // Then
        #expect(result.order.photos == [])
        #expect(result.shouldWritePhotos == false)
    }

    /// 新建訂單 (含合併草稿) 一律帶入照片，不受 `hasEditedPhotos` 影響
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
