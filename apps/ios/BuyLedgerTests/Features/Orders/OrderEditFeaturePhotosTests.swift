//
//  OrderEditFeaturePhotosTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import PhotosUI
import SwiftUI
import Testing

@testable import BuyLedger

/// `OrderEditFeature` 的單元測試，涵蓋照片匯入上限、失敗回報、刪除、載入，以及檢視器推入與關閉
@MainActor
struct OrderEditFeaturePhotosTests {

    /// 驗證照片已滿五張時再匯入，草稿照片維持原樣，也不標記照片已編輯
    @Test
    func photos_匯入照片且照片已滿_不再追加() async {
        // Given
        let fullPhotos = (1...5).map { Data([UInt8($0)]) }
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.photos.draftPhotos = fullPhotos
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }
        let result = PhotoImportResult(photos: [Data([0x06])], failedCount: 0)

        // When
        await store.send(.photos(.photoImportResponse(result)))

        // Then
        #expect(store.state.photos.draftPhotos == fullPhotos)
        #expect(store.state.photos.hasEditedPhotos == false)
    }

    /// 驗證一次匯入超過剩餘名額的照片時，依序只收下到上限為止的張數，並標記為已編輯
    @Test
    func photos_匯入照片超過上限_截取至上限() async {
        // Given
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.photos.draftPhotos = [Data([0x01]), Data([0x02]), Data([0x03])]
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }
        let batch = [Data([0x04]), Data([0x05]), Data([0x06]), Data([0x07])]
        let expectedPhotos = [Data([0x01]), Data([0x02]), Data([0x03]), Data([0x04]), Data([0x05])]
        let result = PhotoImportResult(photos: batch, failedCount: 0)

        // When
        await store.send(.photos(.photoImportResponse(result))) {
            $0.photos.draftPhotos = expectedPhotos
            $0.photos.hasEditedPhotos = true
        }

        // Then
        #expect(store.state.photos.draftPhotos == expectedPhotos)
        #expect(store.state.photos.hasEditedPhotos)
    }

    /// 驗證選取照片後，匯入的照片加入草稿，選取清空以便重新選取，並標記為已編輯
    @Test
    func photos_選取照片_匯入並清空選取() async {
        // Given
        let imported = [Data([0xAA]), Data([0xBB]), Data([0xCC])]
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.photoService.importPhotos = { _ in
                PhotoImportResult(photos: imported, failedCount: 0)
            }
        }
        let items = [
            PhotosPickerItem(itemIdentifier: "test-item-1"),
            PhotosPickerItem(itemIdentifier: "test-item-2"),
            PhotosPickerItem(itemIdentifier: "test-item-3"),
        ]

        // When
        await store.send(.photos(.binding(.set(\.photoPickerSelection, items)))) {
            $0.photos.photoPickerSelection = items
        }

        // Then
        await store.receive(\.photos.photoImportResponse) {
            $0.photos.draftPhotos = imported
            $0.photos.photoPickerSelection = []
            $0.photos.hasEditedPhotos = true
        }
    }

    /// 驗證選取照片時先清除舊的失敗張數，本批有一張載入失敗則回報失敗數為 1
    @Test
    func photos_選取照片且一張載入失敗_回報失敗數() async {
        // Given
        let imported = [Data([0xAA]), Data([0xBB])]
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.photos.photoImportFailureCount = 2
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.photoService.importPhotos = { _ in
                PhotoImportResult(photos: imported, failedCount: 1)
            }
        }
        let items = [
            PhotosPickerItem(itemIdentifier: "load-failure-1"),
            PhotosPickerItem(itemIdentifier: "load-failure-2"),
            PhotosPickerItem(itemIdentifier: "load-failure-3"),
        ]

        // When
        await store.send(.photos(.binding(.set(\.photoPickerSelection, items)))) {
            $0.photos.photoPickerSelection = items
            $0.photos.photoImportFailureCount = 0
        }

        // Then
        await store.receive(\.photos.photoImportResponse) {
            $0.photos.draftPhotos = imported
            $0.photos.photoPickerSelection = []
            $0.photos.hasEditedPhotos = true
            $0.photos.photoImportFailureCount = 1
        }
    }

    /// 驗證選取的兩張照片全數正規化失敗時，草稿不加入照片，失敗數回報為 2
    @Test
    func photos_選取照片且正規化全數失敗_回報失敗數() async {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.photoService.importPhotos = { _ in
                PhotoImportResult(photos: [], failedCount: 2)
            }
        }
        let items = [
            PhotosPickerItem(itemIdentifier: "normalize-failure-1"),
            PhotosPickerItem(itemIdentifier: "normalize-failure-2"),
        ]

        // When
        await store.send(.photos(.binding(.set(\.photoPickerSelection, items)))) {
            $0.photos.photoPickerSelection = items
        }

        // Then
        await store.receive(\.photos.photoImportResponse) {
            $0.photos.photoPickerSelection = []
            $0.photos.photoImportFailureCount = 2
        }
    }

    /// 驗證照片選取經畫面綁定送達匯入服務，先清除舊失敗數，再加入成功照片並回報本批失敗數
    ///
    /// - Throws: 匯入請求或完成通知未收到時由 `#require` 丟出測試斷言錯誤
    /// - Note: 收到匯入請求後才註冊完成通知，避免選取本身的狀態變更提前通過等待
    @Test(.timeLimit(.minutes(1)))
    func photos_經畫面綁定選取照片_清除舊失敗數並觸發匯入() async throws {
        // Given
        let items = [
            PhotosPickerItem(itemIdentifier: "binding-selection-1"),
            PhotosPickerItem(itemIdentifier: "binding-selection-2"),
        ]
        let requests = AsyncStream<[PhotosPickerItem]>.makeStream()
        let release = AsyncStream<Void>.makeStream()
        let completion = AsyncStream<Void>.makeStream()
        var requestIterator = requests.stream.makeAsyncIterator()
        var completionIterator = completion.stream.makeAsyncIterator()
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.photos.draftPhotos = [Data([0x01])]
        initial.photos.photoImportFailureCount = 2
        let store = Store(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.photoService.importPhotos = { selectedItems in
                requests.continuation.yield(selectedItems)
                var iterator = release.stream.makeAsyncIterator()
                _ = await iterator.next()
                return PhotoImportResult(photos: [Data([0xAA])], failedCount: 1)
            }
        }
        @Bindable var photos = store.scope(state: \.photos, action: \.photos)

        // When
        $photos.photoPickerSelection.wrappedValue = items

        // Then
        defer {
            requests.continuation.finish()
            release.continuation.finish()
            completion.continuation.finish()
        }
        #expect(store.state.photos.photoPickerSelection == items)
        #expect(store.state.photos.photoImportFailureCount == 0)
        #expect(store.state.photos.draftPhotos == [Data([0x01])])
        #expect(store.state.photos.hasEditedPhotos == false)
        let receivedItems = try #require(await requestIterator.next())
        #expect(receivedItems == items)
        withObservationTracking {
            _ = photos.hasEditedPhotos
        } onChange: {
            completion.continuation.yield(())
            completion.continuation.finish()
        }
        release.continuation.finish()
        try #require(await completionIterator.next() != nil)
        #expect(store.state.photos.draftPhotos == [Data([0x01]), Data([0xAA])])
        #expect(store.state.photos.photoPickerSelection == [])
        #expect(store.state.photos.photoImportFailureCount == 1)
        #expect(store.state.photos.hasEditedPhotos)
    }

    /// 驗證刪除中間的照片時，只移除該張，其餘照片維持原順序，並標記為已編輯
    @Test
    func photos_刪除指定照片_保留其餘順序() async {
        // Given
        let photoA = Data([0x0A])
        let photoB = Data([0x0B])
        let photoC = Data([0x0C])
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.photos.draftPhotos = [photoA, photoB, photoC]
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.photos(.view(.deletePhotoTapped(1)))) {
            $0.photos.draftPhotos = [Data([0x0A]), Data([0x0C])]
            $0.photos.hasEditedPhotos = true
        }

        // Then
        #expect(store.state.photos.draftPhotos == [Data([0x0A]), Data([0x0C])])
        #expect(store.state.photos.hasEditedPhotos)
    }

    /// 驗證刪除索引超出照片張數的請求時，照片與已編輯標記都維持原樣
    @Test
    func photos_刪除照片且索引超出範圍_不變更照片() async {
        // Given
        let photoA = Data([0x0A])
        let photoB = Data([0x0B])
        let photoC = Data([0x0C])
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.photos.draftPhotos = [photoA, photoB, photoC]
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.photos(.view(.deletePhotoTapped(5))))

        // Then
        #expect(store.state.photos.draftPhotos == [photoA, photoB, photoC])
        #expect(store.state.photos.hasEditedPhotos == false)
    }

    /// 驗證編輯既有訂單的畫面出現時，向服務讀取該訂單照片並放進草稿，且不算使用者修改照片
    @Test
    func photos_畫面出現且編輯既有訂單_載入原始照片() async {
        // Given
        let original = LedgerOrder.sampleOrders[0]
        let photos = [Data([0x01]), Data([0x02])]
        let state = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        let fetchedPhotoOrderIDs = LockIsolated<[LedgerOrder.ID]>([])
        let store = TestStore(initialState: state) {
            OrderEditFeature()
        } withDependencies: {
            $0.orderService.fetchOrderPhotos = { id in
                fetchedPhotoOrderIDs.withValue {
                    $0.append(id)
                }
                return photos
            }
        }

        // When
        await store.send(.photos(.view(.task))) {
            $0.photos.photoLoadPhase = .loading
        }

        // Then
        await store.receive(\.photos.photosLoadResponse) {
            $0.photos.draftPhotos = photos
            $0.photos.photoLoadPhase = .loaded
        }
        #expect(fetchedPhotoOrderIDs.value == ["BL-2604-018"])
    }

    /// 驗證照片檢視器關閉時，經綁定把 `pickerRoute` 設為 `nil`，路徑清空
    ///
    /// - Note: 此測試守住 `BindingReducer()` 的 `binding` 接線
    @Test
    func pickers_關閉照片檢視_清除照片檢視路徑() {
        // Given
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.photos.draftPhotos = [Data([0x01]), Data([0x02]), Data([0x03])]
        initial.pickers.pickerRoute = .photoViewer(index: 2)
        let store = Store(initialState: initial) {
            OrderEditFeature()
        }
        @Bindable var pickers = store.scope(state: \.pickers, action: \.pickers)

        // When
        $pickers.pickerRoute.wrappedValue = nil

        // Then
        #expect(store.state.pickers.pickerRoute == nil)
    }

    /// 驗證點選第三張照片時，編輯表單把 `pickerRoute` 設為索引 2 的照片檢視，以開啟照片檢視器
    @Test
    func photos_點選第三張照片_推入照片檢視器() async {
        // Given
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.photos.draftPhotos = [Data([0x01]), Data([0x02]), Data([0x03])]
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.photos(.view(.photoTapped(2))))

        // Then
        await store.receive(\.photos.delegate.photoViewerRequested, 2) {
            $0.pickers.pickerRoute = .photoViewer(index: 2)
        }
        #expect(store.state.pickers.pickerRoute == .photoViewer(index: 2))
    }
}
