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
        
        /// 雙方照片載入完成後，判斷是否進入照片挑選
        case candidatePhotosLoaded(
            secondary: LedgerOrder,
            primaryPhotos: [Data],
            secondaryPhotos: [Data]
        )
        
        /// 載入雙方照片失敗；顯示錯誤而非視為沒有照片
        case candidatePhotosLoadFailed
        
        /// 照片挑選步驟中 toggle 指定 index 照片的保留狀態
        case photoToggled(Int)
        
        /// 照片挑選步驟按下「繼續」，以目前勾選集合完成流程
        case photoStepConfirmTapped
        
        /// 照片挑選步驟按下 Back，返回候選選擇步驟重選副訂單
        case backToCandidatesTapped
        
        /// 照片載入失敗對話框的呈現／關閉
        case photoLoadFailureAlert(PresentationAction<Alert>)
        
        /// 對父層的回報事件
        case delegate(Delegate)
        
        /// 父層攔截的完成事件
        @CasePathable
        enum Delegate: Equatable {
            
            /// 合併資料選定完成：父層據此計算合併草稿並開啟預填的確認表單
            case completed(
                primary: LedgerOrder,
                secondary: LedgerOrder,
                keptPhotos: [Data]
            )
        }
        
        /// 照片載入失敗提示的操作
        enum Alert: Equatable {}
    }
    
    // MARK: - Dependency Properties
    
    /// 由父層注入的 dismiss effect
    @Dependency(\.dismiss) private var dismiss
    
    /// 依訂單編號載入合併雙方照片
    @Dependency(OrderRepository.self) private var orderRepository
    
    // MARK: - Reducer Body
    
    /// 合併流程 reducer
    var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce {
            state,
            action in
            switch action {
            case .binding:
                return .none
                
            case .cancelTapped:
                return .run { _ in await dismiss() }
                
            case let .candidateTapped(id):
                guard let secondary = state.candidates.first(where: { $0.id == id }) else {
                    return .none
                }
                
                // 清單不載入照片，進入挑選前先依編號讀取。
                let primaryID = state.primary.id
                let secondaryID = secondary.id
                let orderRepository = orderRepository
                return .run { send in
                    do {
                        async let primaryPhotosTask = orderRepository.fetchOrderPhotos(primaryID)
                        async let secondaryPhotosTask = orderRepository.fetchOrderPhotos(secondaryID)
                        let (primaryPhotos, secondaryPhotos) = try await (
                            primaryPhotosTask, secondaryPhotosTask
                        )
                        await send(
                            .candidatePhotosLoaded(
                                secondary: secondary,
                                primaryPhotos: primaryPhotos,
                                secondaryPhotos: secondaryPhotos
                            )
                        )
                    } catch {
                        // 任一方載入失敗都停止流程，避免遺漏照片。
                        await send(.candidatePhotosLoadFailed)
                    }
                }
                
            case .candidatePhotosLoadFailed:
                // 停留在候選步驟，使用者可重新選取候選訂單。
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
                
            case .photoLoadFailureAlert:
                return .none
                
            case let .candidatePhotosLoaded(secondary, primaryPhotos, secondaryPhotos):
                let combined = primaryPhotos + secondaryPhotos
                guard combined.count > LedgerOrder.maxPhotoCount else {
                    // 照片合計未超限：跳過挑選步驟，直接完成
                    return .send(
                        .delegate(
                            .completed(
                                primary: state.primary,
                                secondary: secondary,
                                keptPhotos: combined
                            )
                        )
                    )
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
                return .send(
                    .delegate(
                        .completed(
                            primary: state.primary,
                            secondary: secondary,
                            keptPhotos: kept
                        )
                    )
                )
                
            case .backToCandidatesTapped:
                // 返回候選選擇步驟並清掉照片步驟暫存，讓使用者改選其他副訂單
                state.step = .selectCandidate
                state.selectedSecondary = nil
                state.combinedPhotos = []
                state.selectedPhotoIndices = []
                return .none
                
            case .delegate:
                return .none
            }
        }
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
}

// MARK: - Internal Method

extension OrderMergeFeature.State {
    
    /// 依搜尋過濾後的候選清單，比照訂單列表以「日」分組為日期區段
    /// - Parameters:
    ///   - referenceDate: 判斷「今天／昨天」的基準時間
    ///   - calendar: 分組與標題使用的曆法
    ///   - locale: App 選定、用於日期區段標題的 locale
    /// - Returns: 依日期由新到舊排序的候選區段
    func candidateSections(
        referenceDate: Date,
        calendar: Calendar,
        locale: Locale
    ) -> [OrderDateSection] {
        OrderDateSection.group(
            filteredCandidates,
            referenceDate: referenceDate,
            calendar: calendar,
            locale: locale
        )
    }
    
    /// 依資格規則過濾可合併的候選訂單
    /// - Parameters:
    ///   - primary: 主訂單
    ///   - orders: 全部訂單
    /// - Returns: 符合資格的候選清單 (維持輸入順序)
    static func eligibleCandidates(
        for primary: LedgerOrder,
        in orders: [LedgerOrder]
    ) -> [LedgerOrder] {
        orders.filter { isEligibleCandidate($0, for: primary) }
    }

    /// 判斷單筆訂單是否符合合併候選資格
    /// - Parameters:
    ///   - candidate: 待檢查的候選訂單
    ///   - primary: 發起合併的主訂單
    /// - Returns: 候選訂單符合所有合併規則時為 `true`
    private static func isEligibleCandidate(
        _ candidate: LedgerOrder,
        for primary: LedgerOrder
    ) -> Bool {
        guard candidate.id != primary.id else {
            return false
        }
        guard candidate.status != .merged, candidate.status != .cancelled else {
            return false
        }
        guard candidate.currency == primary.currency else {
            return false
        }
        return candidate.customer.name == primary.customer.name
    }
}
