//
//  OrderEditPhotosFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import PhotosUI
import SwiftUI

/// 管理訂單照片區段的選取、載入、匯入與刪除，檢視請求交由父層呈現
@Reducer
struct OrderEditPhotosFeature {

    // MARK: - State

    /// 照片區段的草稿與非同步載入狀態
    @ObservableState
    struct State: Equatable, Sendable {

        /// 需要讀取照片的既有訂單編號；新訂單為 `nil`
        let orderID: LedgerOrder.ID?

        /// 訂單照片草稿，最多 `LedgerOrder.maxPhotoCount` 張
        var draftPhotos: [Data]

        /// 照片載入階段；新訂單直接完成，既有訂單由區段畫面載入
        var photoLoadPhase: PhotoLoadPhase

        /// 使用者是否確實增刪過照片；載入與合併預填不會設為 `true`
        var hasEditedPhotos = false

        /// 最近一批照片匯入失敗的張數
        var photoImportFailureCount = 0

        /// `PhotosPicker` 的選取項目；匯入後清空
        var photoPickerSelection: [PhotosPickerItem] = []

        /// 還可加入的照片張數，供選取上限使用
        var remainingPhotoCapacity: Int {
            max(0, LedgerOrder.maxPhotoCount - draftPhotos.count)
        }

        /// 照片已載入且仍有容量時，允許加入照片
        var canAddMorePhotos: Bool {
            photoLoadPhase == .loaded && remainingPhotoCapacity > 0
        }

        /// 依既有訂單編號與合併保留照片建立區段狀態
        ///
        /// - Parameters:
        ///   - orderID: 要載入照片的訂單編號；新訂單為 `nil`
        ///   - draftPhotos: 合併時已保留的照片，不視為使用者編輯
        init(orderID: LedgerOrder.ID? = nil, draftPhotos: [Data] = []) {
            self.orderID = orderID
            self.draftPhotos = draftPhotos
            self.photoLoadPhase = orderID == nil ? .loaded : .notLoaded
        }

        /// 決定照片區段顯示載入進度、錯誤或照片內容的階段
        enum PhotoLoadPhase: Equatable, Sendable {

            /// 既有訂單尚未開始讀取照片
            case notLoaded

            /// 正在讀取照片
            case loading

            /// 草稿已包含讀取完成或合併保留的照片
            case loaded

            /// 讀取照片失敗，草稿維持原值
            case failed
        }
    }

    // MARK: - Action

    /// 照片區段的繫結、畫面事件、父層請求與服務回應
    enum Action: BindableAction {

        /// `SwiftUI` 更新照片選取的繫結值
        ///
        /// - Parameter action: 被修改的欄位與新值
        case binding(BindingAction<State>)

        /// 使用者在照片區段上的操作
        ///
        /// - Parameter action: 區段畫面送出的事件
        case view(View)

        /// 交給父層處理的檢視請求
        ///
        /// - Parameter action: 父層需要呈現的照片
        case delegate(Delegate)

        /// 選取項目載入與正規化完成
        ///
        /// - Parameter result: 成功匯入的照片與失敗張數
        case photoImportResponse(PhotoImportResult)

        /// 既有訂單照片讀取完成的單一結果
        ///
        /// - Parameter result: 已讀取的照片或原始持久化錯誤
        case photosLoadResponse(Result<[Data], PersistenceError>)

        /// 照片區段畫面能送出的事件
        @CasePathable
        enum View {

            /// 照片區段出現，讀取尚未載入的既有訂單照片
            case task

            /// 使用者刪除指定位置的照片
            ///
            /// - Parameter index: 要刪除的照片位置
            case deletePhotoTapped(Int)

            /// 使用者點擊照片縮圖
            ///
            /// - Parameter index: 要檢視的照片位置
            case photoTapped(Int)
        }

        /// 照片區段交給父層的請求
        @CasePathable
        enum Delegate: Equatable {

            /// 請父層以推進方式呈現照片檢視器
            ///
            /// - Parameter index: 檢視器的初始照片位置
            case photoViewerRequested(Int)
        }
    }

    // MARK: - Dependencies

    /// 載入並正規化使用者選取的照片
    @Dependency(\.photoService) private var photoService

    /// 只讀取既有訂單照片，不負責訂單寫入
    @Dependency(\.orderService) private var orderService

    // MARK: - Body

    /// 組合照片繫結與區段事件處理
    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce(core)
    }
}

// MARK: - Private Method

private extension OrderEditPhotosFeature {

    /// 依照片事件更新草稿與載入狀態
    ///
    /// - Parameters:
    ///   - state: 照片區段的目前狀態
    ///   - action: 繫結、操作或服務回應
    /// - Returns: 照片匯入、讀取或請父層呈現檢視器的效果
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .binding(\.photoPickerSelection):
            return importPhotos(state: &state)

        case .binding:
            return .none

        case .view(.task):
            guard let orderID = state.orderID, state.photoLoadPhase == .notLoaded else {
                return .none
            }
            state.photoLoadPhase = .loading
            return loadPhotos(orderID: orderID)

        case .view(.deletePhotoTapped(let index)):
            guard state.draftPhotos.indices.contains(index) else {
                return .none
            }
            state.draftPhotos.remove(at: index)
            state.hasEditedPhotos = true
            return .none

        case .view(.photoTapped(let index)):
            return .send(.delegate(.photoViewerRequested(index)))

        case .delegate:
            return .none

        case .photoImportResponse(let result):
            let appended = result.photos.prefix(state.remainingPhotoCapacity)
            state.draftPhotos.append(contentsOf: appended)
            state.photoImportFailureCount = result.failedCount
            state.photoPickerSelection = []
            if !appended.isEmpty {
                state.hasEditedPhotos = true
            }
            return .none

        case .photosLoadResponse(.success(let photos)):
            state.draftPhotos = photos
            state.photoLoadPhase = .loaded
            return .none

        case .photosLoadResponse(.failure):
            state.photoLoadPhase = .failed
            return .none
        }
    }

    /// 匯入目前選取的照片，開始前清除前一批失敗張數
    ///
    /// - Parameter state: 包含選取項目的照片區段狀態
    /// - Returns: 匯入完成後回報成功照片與失敗張數的效果
    func importPhotos(state: inout State) -> Effect<Action> {
        let items = state.photoPickerSelection
        guard !items.isEmpty else {
            return .none
        }
        state.photoImportFailureCount = 0
        let photoService = photoService
        return .run {
            await $0(.photoImportResponse(photoService.importPhotos(items)))
        }
    }

    /// 讀取既有訂單照片，將成功與失敗合併成同一回應
    ///
    /// - Parameter orderID: 要讀取照片的訂單編號
    /// - Returns: 讀取完成後回報照片或持久化錯誤的效果
    func loadPhotos(orderID: LedgerOrder.ID) -> Effect<Action> {
        let orderService = orderService
        return .run { send in
            do throws(PersistenceError) {
                let photos = try await orderService.fetchOrderPhotos(orderID)
                await send(.photosLoadResponse(.success(photos)))
            } catch {
                guard !Task.isCancelled else {
                    return
                }
                await send(.photosLoadResponse(.failure(error)))
            }
        }
    }
}
