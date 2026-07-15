//
//  OrderMergeFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/6.
//

import ComposableArchitecture
import Foundation

/// 「合併訂單」流程的兩步驟狀態機：候選選擇 → (照片合計超過上限時) 照片挑選
///
/// 由 ``OrdersFeature`` 以 optional 子 state + `.sheet(item:)` 呈現。流程完成時以 ``OrderMergeFeature/Action/Delegate/completed(primary:secondary:keptPhotos:)`` 回報父層，由父層計算合併草稿並開啟預填的合併確認表單；本 feature 不做任何持久化
@Reducer
struct OrderMergeFeature {

    // MARK: - State

    /// 合併流程狀態
    @ObservableState
    struct State: Equatable, Identifiable {

        /// 主訂單 (發起合併的那筆)
        let primary: LedgerOrder

        /// 可合併的候選訂單；已依資格規則過濾 (排除自身、已合併、已取消，限同幣別、同客戶名稱)
        let candidates: [LedgerOrder]

        /// 候選搜尋輸入
        var searchText = ""

        /// 目前步驟
        var step: Step = .selectCandidate

        /// 已選定的副訂單；進入照片挑選步驟時設定
        var selectedSecondary: LedgerOrder?

        /// 兩筆訂單照片的串接 (主前副後)；照片挑選步驟的資料來源
        var combinedPhotos: [Data] = []

        /// 照片挑選步驟目前勾選的照片 index 集合 (相對 ``combinedPhotos``)；上限 ``LedgerOrder/maxPhotoCount``，由 reducer 守門
        var selectedPhotoIndices: Set<Int> = []

        // MARK: - Identifiable Properties

        /// sheet item 的穩定識別值
        let id: UUID

        // MARK: - Init

        /// 依主訂單與全部訂單建立合併流程狀態；候選清單在此一次過濾完成
        /// - Parameters:
        ///   - primary: 主訂單
        ///   - orders: 全部訂單 (通常為 ``OrdersFeature/State/orders``)
        init(primary: LedgerOrder, orders: [LedgerOrder]) {
            @Dependency(\.uuid) var uuid
            self.primary = primary
            self.candidates = Self.eligibleCandidates(for: primary, in: orders)
            self.id = uuid()
        }

        // MARK: - Computed Properties

        /// 依搜尋字串過濾後的候選清單；比對客戶名稱、單號、類別與商品名稱
        var filteredCandidates: [LedgerOrder] {
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !query.isEmpty else {
                return candidates
            }

            return candidates.filter { order in
                ([order.id, order.customer.name] + order.categories + order.items.map(\.name))
                    .joined(separator: " ")
                    .localizedStandardContains(query)
            }
        }
    }

    // MARK: - Action

    /// 合併流程可處理的事件
    @CasePathable
    enum Action: BindableAction, Equatable {

        /// SwiftUI 雙向繫結事件 (搜尋輸入)
        case binding(BindingAction<State>)

        /// 使用者按下取消，整個合併流程不留任何變更
        case cancelTapped

        /// 使用者點選一筆候選訂單作為副訂單
        case candidateTapped(LedgerOrder.ID)

        /// 照片挑選步驟中 toggle 指定 index 照片的保留狀態
        case photoToggled(Int)

        /// 照片挑選步驟按下「繼續」，以目前勾選集合完成流程
        case photoStepConfirmTapped

        /// 對父層的回報事件
        case delegate(Delegate)

        /// 父層攔截的完成事件
        @CasePathable
        enum Delegate: Equatable {

            /// 合併資料選定完成：父層據此計算合併草稿並開啟預填的確認表單
            case completed(primary: LedgerOrder, secondary: LedgerOrder, keptPhotos: [Data])
        }
    }

    // MARK: - Dependency Properties

    /// 由父層注入的 dismiss effect
    @Dependency(\.dismiss) private var dismiss

    // MARK: - Reducer Body

    /// 合併流程 reducer
    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .cancelTapped:
                return .run { _ in await dismiss() }

            case let .candidateTapped(id):
                guard let secondary = state.candidates.first(where: { $0.id == id }) else {
                    return .none
                }

                let combined = state.primary.photos + secondary.photos
                guard combined.count > LedgerOrder.maxPhotoCount else {
                    // 照片合計未超限：跳過挑選步驟，直接完成
                    return .send(.delegate(.completed(primary: state.primary, secondary: secondary, keptPhotos: combined)))
                }

                // 超限：進入照片挑選步驟，預選前 maxPhotoCount 張 (主訂單照片在前)
                state.selectedSecondary = secondary
                state.combinedPhotos = combined
                state.selectedPhotoIndices = Set(0..<LedgerOrder.maxPhotoCount)
                state.step = .selectPhotos
                return .none

            case let .photoToggled(index):
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

            case .photoStepConfirmTapped:
                guard let secondary = state.selectedSecondary else {
                    return .none
                }

                let kept = state.selectedPhotoIndices.sorted().map { state.combinedPhotos[$0] }
                return .send(.delegate(.completed(primary: state.primary, secondary: secondary, keptPhotos: kept)))

            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - Nested Types

extension OrderMergeFeature {

    /// 合併流程的步驟
    enum Step: Equatable {

        /// 選擇要合併的第二筆訂單
        case selectCandidate

        /// 照片合計超過上限時的照片挑選
        case selectPhotos
    }
}

// MARK: - Internal Method

extension OrderMergeFeature.State {

    /// 依搜尋過濾後的候選清單，比照訂單列表以「日」分組為日期區段
    ///
    /// 區段與段內皆由新到舊排序，標題同訂單頁 (今天/昨天/格式化日期)；候選列因此不再於列內重複顯示日期
    /// - Parameters:
    ///   - referenceDate: 判斷「今天／昨天」的基準時間
    ///   - calendar: 分組與標題使用的曆法
    /// - Returns: 依日期由新到舊排序的候選區段
    func candidateSections(referenceDate: Date, calendar: Calendar) -> [OrderDateSection] {
        OrderDateSection.group(filteredCandidates, referenceDate: referenceDate, calendar: calendar)
    }

    /// 依資格規則過濾可合併的候選訂單
    ///
    /// 候選資格：非主訂單自身、狀態非「已合併」與「已取消」、與主訂單同幣別、與主訂單同客戶名稱 (不支援跨客戶合併)
    /// - Parameters:
    ///   - primary: 主訂單
    ///   - orders: 全部訂單
    /// - Returns: 符合資格的候選清單 (維持輸入順序)
    static func eligibleCandidates(for primary: LedgerOrder, in orders: [LedgerOrder]) -> [LedgerOrder] {
        orders.filter { candidate in
            candidate.id != primary.id
                && candidate.status != .merged
                && candidate.status != .cancelled
                && candidate.currency == primary.currency
                && candidate.customer.name == primary.customer.name
        }
    }
}
