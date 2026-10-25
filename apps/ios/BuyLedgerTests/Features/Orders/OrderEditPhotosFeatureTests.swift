//
//  OrderEditPhotosFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import PhotosUI
import SwiftUI
import Testing

@testable import BuyLedger

/// `OrderEditFeature` 與 `OrderEditPhotosFeature` 的單元測試，涵蓋照片讀取失敗時保留草稿與部分匯入失敗回報
@MainActor
struct OrderEditPhotosFeatureTests {

    /// 驗證既有訂單的照片讀取失敗時，只把載入階段改為失敗，草稿與原有照片保留，且不算修改
    @Test
    func photos_畫面出現且照片讀取失敗_保留草稿並標記失敗() async {
        // Given
        var initial = OrderEditFeature.State(
            original: LedgerOrder.fixture(id: "EXISTING"),
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        initial.photos.draftPhotos = [Data([0x01])]
        let initialDraft = initial.draft
        let failingFetch: OrderService.FetchOrderPhotos = { _ throws(PersistenceError) in
            throw .fetchFailed(underlying: TestDependencies.makeUnderlyingError(message: "照片讀取失敗"))
        }
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.orderService.fetchOrderPhotos = failingFetch
        }

        // When
        await store.send(.photos(.view(.task))) {
            $0.photos.photoLoadPhase = .loading
        }

        // Then
        await store.receive(\.photos.photosLoadResponse) {
            $0.photos.photoLoadPhase = .failed
        }
        #expect(store.state.draft == initialDraft)
        #expect(store.state.photos.draftPhotos == [Data([0x01])])
        #expect(store.state.photos.hasEditedPhotos == false)
        #expect(store.state.isDirty == false)
    }

    /// 驗證部分照片匯入失敗時，成功的照片加入草稿、選取清空，並回報本批失敗 1 張
    @Test
    func binding_匯入部分失敗_只加入成功照片並回報失敗張數() async {
        // Given
        var initial = OrderEditPhotosFeature.State(draftPhotos: [Data([0x01])])
        initial.photoImportFailureCount = 2
        let store = TestStore(initialState: initial) {
            OrderEditPhotosFeature()
        } withDependencies: {
            $0.photoService.importPhotos = { _ in
                PhotoImportResult(photos: [Data([0xAA]), Data([0xBB])], failedCount: 1)
            }
        }
        let items = [
            PhotosPickerItem(itemIdentifier: "partial-failure-1"),
            PhotosPickerItem(itemIdentifier: "partial-failure-2"),
            PhotosPickerItem(itemIdentifier: "partial-failure-3"),
        ]

        // When
        await store.send(\.binding.photoPickerSelection, items) {
            $0.photoPickerSelection = items
            $0.photoImportFailureCount = 0
        }

        // Then
        await store.receive(\.photoImportResponse) {
            $0.draftPhotos = [Data([0x01]), Data([0xAA]), Data([0xBB])]
            $0.photoPickerSelection = []
            $0.hasEditedPhotos = true
            $0.photoImportFailureCount = 1
        }
        #expect(store.state.draftPhotos.count == 3)
        #expect(store.state.photoImportFailureCount == 1)
    }
}
