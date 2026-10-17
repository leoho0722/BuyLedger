//
//  OrderEditFeatureTests+Photos.swift
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

    /// 照片已滿五張時再匯入，照片不增加，也不算改過照片
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

    /// 一次匯入的照片超過剩餘名額時，只依序收到名額用完為止
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

    /// 選好照片後匯入草稿，並清空選取，下次才能重新選
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

    /// 新一批照片匯入前應清除舊失敗張數，並保留本批失敗張數
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

    /// 兩張照片全部正規化失敗時，不應加入照片但應回報失敗張數
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

    /// 刪除中間那張照片後，其餘照片維持原本順序
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

    /// 索引超出照片範圍時，照片與編輯狀態都不變
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

    /// `.task` 載入既有訂單照片並放進草稿，不算使用者修改照片
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

    /// 關閉照片檢視器後，選擇器路徑會清空
    ///
    /// - Note: 此測試守住 `BindingReducer()` 的 `binding` 接線
    @Test
    func pickers_關閉照片檢視_清除照片檢視路徑() async {
        // Given
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.photos.draftPhotos = [Data([0x01]), Data([0x02]), Data([0x03])]
        initial.pickers.pickerRoute = .photoViewer(index: 2)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.pickers(.binding(.set(\.pickerRoute, nil)))) {
            $0.pickers.pickerRoute = nil
        }

        // Then
        #expect(store.state.pickers.pickerRoute == nil)
    }

    /// 點選第三張照片後，以推進方式開啟照片檢視器
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
