//
//  OrderEditFeatureDirtyStateTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import PhotosUI
import SwiftUI
import Testing

@testable import BuyLedger

/// `OrderEditFeature` 的單元測試，涵蓋 `isDirty` 判定，選擇器路徑、焦點與照片載入不算修改
struct OrderEditFeatureDirtyStateTests {

    /// 驗證新訂單剛開啟、尚未改過任何欄位時，`isDirty` 為 `false`
    @Test
    func isDirty_新建訂單尚未編輯_回傳未修改() {
        // Given
        let state = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)

        // When
        let isDirty = state.isDirty

        // Then
        #expect(isDirty == false)
    }

    /// 驗證既有訂單開啟後尚未改動草稿時，`isDirty` 為 `false`
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

    /// 驗證既有訂單的欄位改掉後標記為已修改，改回原值後不再算未儲存變更
    ///
    /// - Throws: 改動後 `isDirty` 仍為 `false` 時由 `#require` 丟出
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

    /// 驗證只設定選擇器路徑、草稿內容未改時，`isDirty` 為 `false`
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

    /// 驗證新訂單改了顧客名稱後，`isDirty` 為 `true`
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

    /// 驗證新訂單改了備註後，`isDirty` 為 `true`
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

    /// 驗證新訂單草稿尚未改動、僅將 `photos.hasEditedPhotos` 設為 `true` 時，`isDirty` 即為 `true`
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

    /// 驗證只改焦點與照片選取、草稿內容未改時，`isDirty` 為 `false`
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

    /// 驗證既有訂單的照片載入完成後寫入草稿照片，但不算使用者編輯，`isDirty` 維持 `false`
    @Test
    @MainActor
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
