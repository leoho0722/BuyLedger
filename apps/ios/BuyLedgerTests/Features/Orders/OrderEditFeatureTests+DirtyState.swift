//
//  OrderEditFeatureTests+DirtyState.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import PhotosUI
import SwiftUI
import Testing

@testable import BuyLedger

extension OrderEditFeatureTests {

    /// 剛開啟、還沒改過任何欄位的新訂單，不算有未儲存的變更
    @Test
    func isDirty_新建訂單尚未編輯_回傳未修改() {
        // Given
        let state = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)

        // When
        let isDirty = state.isDirty

        // Then
        #expect(isDirty == false)
    }

    /// 開啟既有訂單後尚未改動草稿，不算有未儲存的變更
    @Test
    func isDirty_既有訂單尚未編輯_回傳未修改() {
        // Given
        let state = OrderEditFeature.State(
            original: LedgerOrder.sampleOrders[0],
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )

        // When
        let isDirty = state.isDirty

        // Then
        #expect(isDirty == false)
    }

    /// 既有訂單的欄位改掉又改回原值時，不算有未儲存的變更
    ///
    /// - Throws: 草稿欄位變更後若未標記為修改，測試即失敗
    @Test
    func isDirty_既有訂單編輯後還原_回傳未修改() throws {
        // Given
        var state = OrderEditFeature.State(
            original: LedgerOrder.sampleOrders[0],
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        state.draft.chargedAmount = 11_801
        try #require(state.isDirty)
        state.draft.chargedAmount = 11_800

        // When
        let isDirty = state.isDirty

        // Then
        #expect(isDirty == false)
    }

    /// 只打開選項選擇器、沒改草稿內容時，不算有未儲存的變更
    ///
    /// - Note: 選擇器路徑是暫時的呈現狀態，不屬於訂單草稿
    @Test
    func isDirty_只改選擇器路徑_不標記修改() {
        // Given
        var state = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        state.pickers.pickerRoute = .category

        // When
        let isDirty = state.isDirty

        // Then
        #expect(isDirty == false)
    }

    /// 新訂單的顧客名稱變更會標記為未儲存
    @Test
    func isDirty_新建訂單改顧客名稱_回傳已修改() {
        // Given
        var state = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        state.draft.customerName = "小明"

        // When
        let isDirty = state.isDirty

        // Then
        #expect(isDirty)
    }

    /// 新訂單的備註變更會標記為未儲存
    @Test
    func isDirty_新建訂單改備註_回傳已修改() {
        // Given
        var state = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        state.draft.notes = "新備註"

        // When
        let isDirty = state.isDirty

        // Then
        #expect(isDirty)
    }

    /// 新訂單增刪照片後會標記為未儲存
    @Test
    func isDirty_新建訂單增刪過照片_回傳已修改() {
        // Given
        var state = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        state.photos.hasEditedPhotos = true

        // When
        let isDirty = state.isDirty

        // Then
        #expect(isDirty)
    }

    /// 只改焦點與照片選取時，不算有未儲存的變更
    @Test
    func isDirty_只改焦點與照片選取_不標記修改() {
        // Given
        var state = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        state.focusedField = .customerName
        state.photos.photoPickerSelection = [PhotosPickerItem(itemIdentifier: "test-item")]

        // When
        let isDirty = state.isDirty

        // Then
        #expect(isDirty == false)
    }

    /// 既有訂單照片載入完成時，不算使用者編輯過照片
    @Test
    func photos_既有訂單照片載入完成_不算未儲存變更() async {
        // Given
        var initial = OrderEditFeature.State(
            original: LedgerOrder.sampleOrders[0],
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        initial.photos.photoLoadPhase = .loading
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }
        let photos = [Data([0x01]), Data([0x02])]

        // When
        await store.send(.photos(.photosLoadResponse(.success(photos)))) {
            $0.photos.draftPhotos = photos
            $0.photos.photoLoadPhase = .loaded
        }

        // Then
        #expect(store.state.isDirty == false)
    }
}
