//
//  OrderMergeFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/6.
//

import ComposableArchitecture
import Foundation

/// 合併訂單流程：候選選擇與照片挑選
@Reducer
struct OrderMergeFeature {

    // MARK: - State

    /// 合併流程狀態
    @ObservableState
    struct State: Equatable, Identifiable {

        /// 主訂單 (發起合併的那筆)
        let primary: LedgerOrder

        /// 通過合併資格檢查的候選訂單
        let candidates: [LedgerOrder]

        /// 開啟合併流程時的時間與行事曆，供候選日期分組使用
        let dateContext: OrderDateContext

        /// 候選搜尋輸入
        var searchText = ""

        /// 目前步驟
        var step: Step = .selectCandidate

        /// 已選定的副訂單；進入照片挑選步驟時設定
        var selectedSecondary: LedgerOrder?

        /// 兩筆訂單照片的串接 (主前副後)；照片挑選步驟的資料來源
        var combinedPhotos: [Data] = []

        /// 已選照片的 index；不可超過上限
        var selectedPhotoIndices: Set<Int> = []

        /// 載入雙方照片失敗時顯示一次性說明對話框
        @Presents var photoLoadFailureAlert: AlertState<Action.Alert>?

        /// sheet item 的穩定識別值
        let id: UUID

        /// 依搜尋字串過濾後的候選清單；比對客戶名稱、單號、類別與商品名稱
        private var filteredCandidates: [LedgerOrder] {
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !query.isEmpty else {
                return candidates
            }

            return candidates.filter {
                ([$0.id, $0.customer.name] + $0.categories + $0.items.map(\.name))
                    .joined(separator: " ")
                    .localizedStandardContains(query)
            }
        }

        /// 依主訂單與全部訂單建立合併流程狀態；候選清單在此一次過濾完成
        ///
        /// - Parameters:
        ///   - primary: 主訂單
        ///   - orders: 全部訂單 (通常為 ``OrdersFeature/State/orders``)
        ///   - dateContext: 容器提供的候選分組時間與行事曆
        init(primary: LedgerOrder, orders: [LedgerOrder], dateContext: OrderDateContext) {
            @Dependency(\.uuid) var uuid
            self.primary = primary
            self.dateContext = dateContext
            self.candidates = OrderMergeCandidates.eligible(for: primary, in: orders)
            self.id = uuid()
        }

        /// 依搜尋過濾後的候選清單，比照訂單列表以「日」分組為日期區段
        ///
        /// - Parameter locale: App 選定、用於日期區段標題的語系
        /// - Returns: 依日期由新到舊排序的候選區段
        func candidateSections(locale: Locale) -> [OrderDateSection] {
            OrderDateSection.group(
                filteredCandidates,
                referenceDate: dateContext.now,
                calendar: dateContext.calendar,
                locale: locale
            )
        }
    }

    // MARK: - Action

    /// 合併流程可處理的事件
    @CasePathable
    enum Action: BindableAction {

        /// `SwiftUI` 雙向繫結事件 (搜尋輸入)
        ///
        /// - Parameter action: 被修改的繫結欄位與新值
        case binding(BindingAction<State>)

        /// 合併畫面送出的使用者互動
        ///
        /// - Parameter action: 候選選取或照片挑選事件
        case view(View)

        /// 對父層的回報事件
        ///
        /// - Parameter action: 要回報給父層的結果
        case delegate(Delegate)

        /// 照片載入失敗對話框的呈現／關閉
        ///
        /// - Parameter action: 對話框的呈現或操作事件
        case photoLoadFailureAlert(PresentationAction<Alert>)

        /// 雙方照片的載入結果；失敗時停留在候選步驟，使用者可重新選取候選訂單
        ///
        /// - Parameter result: 成功帶回被選為副訂單的候選與串接照片，失敗帶回錯誤
        case candidatePhotosResponse(Result<CandidatePhotos, any Error>)

        /// 候選選擇與照片挑選畫面的操作
        @CasePathable
        enum View: Equatable {

            /// 按下取消，整個合併流程不留變更
            case cancelTapped

            /// 點選一筆候選訂單作為副訂單
            ///
            /// - Parameter id: 被點選的候選訂單編號
            case candidateTapped(LedgerOrder.ID)

            /// 切換照片的保留狀態
            ///
            /// - Parameter index: 照片在串接照片中的位置
            case photoToggled(Int)

            /// 按下繼續，以目前勾選集合完成流程
            case photoStepConfirmTapped

            /// 按下返回，回到候選選擇步驟
            case backToCandidatesTapped
        }

        /// 父層攔截的完成事件
        @CasePathable
        enum Delegate: Equatable {

            /// 合併資料選定完成：父層據此計算合併草稿並開啟預填的確認表單
            ///
            /// - Parameters:
            ///   - primary: 主訂單
            ///   - secondary: 副訂單
            ///   - keptPhotos: 合併後保留的照片
            case completed(primary: LedgerOrder, secondary: LedgerOrder, keptPhotos: [Data])
        }

        /// 照片載入失敗提示的操作
        enum Alert: Equatable {

        }
    }

    // MARK: - Dependencies

    /// 由父層注入的 dismiss effect
    @Dependency(\.dismiss) private var dismiss

    /// 依訂單編號載入合併雙方照片
    @Dependency(\.orderService) private var orderService

    // MARK: - Body

    /// 合併流程 reducer
    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce(core)
            .ifLet(\.$photoLoadFailureAlert, action: \.photoLoadFailureAlert)
    }
}

// MARK: - Nested Types

extension OrderMergeFeature {

    /// 合併流程的步驟
    enum Step: Hashable {

        /// 選擇要合併的第二筆訂單
        case selectCandidate

        /// 照片合計超過上限時的照片挑選
        case selectPhotos
    }

    /// 選定副訂單後載入的雙方照片，照片已依主前副後串接
    struct CandidatePhotos: Equatable, Sendable {

        /// 被選為副訂單的候選訂單
        let secondary: LedgerOrder

        /// 主訂單照片在前、副訂單照片在後的串接結果
        let photos: [Data]
    }
}

// MARK: - Private Method

private extension OrderMergeFeature {

    /// 處理候選選取、照片挑選與完成回報
    ///
    /// - Parameters:
    ///   - state: 合併流程的目前狀態
    ///   - action: 搜尋、選取或照片載入事件
    /// - Returns: 照片讀取、關閉流程或完成委派
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .binding:
            return .none

        case .view(.cancelTapped):
            return .run { _ in
                await dismiss()
            }

        case .view(.candidateTapped(let id)):
            return fetchCandidatePhotos(for: id, state: state)

        case .view(.photoToggled(let index)):
            return toggleSelectedPhoto(at: index, state: &state)

        case .view(.photoStepConfirmTapped):
            return confirmSelectedPhotos(in: state)

        case .view(.backToCandidatesTapped):
            // 返回候選選擇步驟並清掉照片步驟暫存，讓使用者改選其他副訂單
            state.step = .selectCandidate
            state.selectedSecondary = nil
            state.combinedPhotos = []
            state.selectedPhotoIndices = []
            return .none

        case .delegate:
            return .none

        case .photoLoadFailureAlert:
            return .none

        case .candidatePhotosResponse(.success(let loaded)):
            return completeOrSelectPhotos(loaded, state: &state)

        case .candidatePhotosResponse(.failure):
            state.photoLoadFailureAlert = AlertState {
                TextState("操作失敗")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("知道了")
                }
            } message: {
                TextState("無法讀取訂單照片，請稍後再試。")
            }
            return .none
        }
    }

    /// 依編號讀取主訂單與被點選候選的照片，結果以 `candidatePhotosResponse` 送回
    ///
    /// - Parameters:
    ///   - id: 被點選的候選訂單編號
    ///   - state: 合併流程的目前狀態
    /// - Returns: 讀取照片的 Effect；編號不在候選清單內時為 `.none`
    func fetchCandidatePhotos(for id: LedgerOrder.ID, state: State) -> Effect<Action> {
        guard let secondary = state.candidates.first(where: { $0.id == id }) else {
            return .none
        }

        // 清單不載入照片，進入挑選前先依編號讀取
        let primaryID = state.primary.id
        let secondaryID = secondary.id
        let orderService = orderService
        return .run { send in
            do {
                async let primaryPhotosTask = orderService.fetchOrderPhotos(primaryID)
                async let secondaryPhotosTask = orderService.fetchOrderPhotos(secondaryID)
                let (primaryPhotos, secondaryPhotos) = try await (
                    primaryPhotosTask,
                    secondaryPhotosTask
                )
                let photos = CandidatePhotos(
                    secondary: secondary,
                    photos: primaryPhotos + secondaryPhotos
                )
                await send(.candidatePhotosResponse(.success(photos)))
            } catch {
                // 任一方載入失敗都停止流程，避免遺漏照片
                await send(.candidatePhotosResponse(.failure(error)))
            }
        }
    }

    /// 切換照片的保留狀態；已達上限時不再新增勾選
    ///
    /// - Parameters:
    ///   - index: 照片在串接照片中的位置
    ///   - state: 合併流程的目前狀態，直接就地修改
    /// - Returns: 沒有後續 Effect，固定為 `.none`
    func toggleSelectedPhoto(at index: Int, state: inout State) -> Effect<Action> {
        guard state.combinedPhotos.indices.contains(index) else {
            return .none
        }

        if state.selectedPhotoIndices.contains(index) {
            state.selectedPhotoIndices.remove(index)
        } else if state.selectedPhotoIndices.count < LedgerOrder.maxPhotoCount {
            // 已達上限時忽略新增勾選，確保保留照片永不超過上限
            state.selectedPhotoIndices.insert(index)
        }
        return .none
    }

    /// 以目前勾選的照片完成合併，交給父層開啟確認表單
    ///
    /// - Parameter state: 合併流程的目前狀態
    /// - Returns: 完成委派；尚未選定副訂單時為 `.none`
    func confirmSelectedPhotos(in state: State) -> Effect<Action> {
        guard let secondary = state.selectedSecondary else {
            return .none
        }

        let kept = state.selectedPhotoIndices.sorted().map {
            state.combinedPhotos[$0]
        }
        return .send(
            .delegate(.completed(primary: state.primary, secondary: secondary, keptPhotos: kept))
        )
    }

    /// 雙方照片載入完成：合計未超過上限就直接完成，超過則進入照片挑選步驟
    ///
    /// - Parameters:
    ///   - loaded: 被選為副訂單的候選與串接後的照片
    ///   - state: 合併流程的目前狀態，直接就地修改
    /// - Returns: 完成委派；進入照片挑選步驟時為 `.none`
    func completeOrSelectPhotos(_ loaded: CandidatePhotos, state: inout State) -> Effect<Action> {
        guard loaded.photos.count > LedgerOrder.maxPhotoCount else {
            // 照片合計未超限：跳過挑選步驟，直接完成
            return .send(
                .delegate(
                    .completed(
                        primary: state.primary,
                        secondary: loaded.secondary,
                        keptPhotos: loaded.photos
                    )
                )
            )
        }

        // 超限：進入照片挑選步驟，預選前 `maxPhotoCount` 張 (主訂單照片在前)
        state.selectedSecondary = loaded.secondary
        state.combinedPhotos = loaded.photos
        state.selectedPhotoIndices = Set(0..<LedgerOrder.maxPhotoCount)
        state.step = .selectPhotos
        return .none
    }
}
