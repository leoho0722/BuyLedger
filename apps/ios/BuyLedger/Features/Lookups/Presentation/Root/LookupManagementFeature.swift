//
//  LookupManagementFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import ComposableArchitecture

/// 管理單一種類的主檔項目
@Reducer
struct LookupManagementFeature {

    // MARK: - State

    /// 主檔管理畫面狀態
    @ObservableState
    struct State: Equatable, Identifiable {

        /// 此狀態管理的主檔種類
        let kind: LookupKind

        /// 四種主檔共用的目錄
        @Shared(.lookupCatalog) var catalog: LookupCatalog

        /// 是否已發生首次載入失敗
        var hasLoadFailed = false

        /// 是否已完成首次載入
        var hasLoaded = false

        /// 表單是否已送出並正在關閉
        var isFormSheetDismissing = false

        /// 表單關閉期間等待呈現的確認框
        var pendingAlert: Destination.State?

        /// 表單關閉期間等待呈現的寫入失敗通知
        var pendingNotice: Destination.WriteFailure?

        /// 目前呈現中的表單或確認框
        @Presents var destination: Destination.State?

        /// 目前呈現中的寫入失敗通知，與 `destination` 分開呈現
        @Presents var notice: AlertState<Destination.Alert>?

        /// 付款方式更正流程的狀態
        var correction = PaymentMethodCorrectionFeature.State()

        /// 以主檔種類作為根畫面的識別值
        var id: LookupKind {
            kind
        }

        /// 目前已排序的主檔項目
        var items: [String] {
            catalog.names(for: kind)
        }

        /// 此主檔是否包含付款方式分類
        var hasClassification: Bool {
            kind == .paymentMethod
        }

        /// 取得指定名稱的付款方式分類
        ///
        /// - Parameter name: 要查詢的主檔名稱
        /// - Returns: 付款方式旗標；非付款方式主檔回傳 `nil`
        func classification(for name: String) -> PaymentMethodFlags? {
            guard hasClassification else {
                return nil
            }
            return catalog.paymentMethodFlags(named: name)
        }
    }

    // MARK: - Action

    /// 主檔管理可處理的事件
    enum Action {

        /// 使用者可直接操作的事件
        ///
        /// - Parameter action: 主檔管理畫面上的操作
        case view(View)

        /// 交給根畫面處理的結果
        ///
        /// - Parameter action: 要轉送給根畫面的結果
        case delegate(Delegate)

        /// 表單與確認框的目的地事件
        ///
        /// - Parameter action: 目前目的地的呈現事件
        case destination(PresentationAction<Destination.Action>)

        /// 寫入失敗通知的呈現事件
        ///
        /// - Parameter action: 通知 alert 的呈現事件
        case notice(PresentationAction<Destination.Alert>)

        /// 新增寫入結果
        ///
        /// - Parameter result: 新增項目或持久化錯誤
        case addResponse(Result<LookupItemAddition, PersistenceError>)

        /// 付款方式更正子 Feature 的事件
        ///
        /// - Parameter action: 付款方式更正流程的事件
        case correction(PaymentMethodCorrectionFeature.Action)

        /// 刪除寫入結果
        ///
        /// - Parameter result: 刪除名稱或持久化錯誤
        case deleteResponse(Result<String, PersistenceError>)

        /// 主檔載入結果
        ///
        /// - Parameter result: 載入目錄或持久化錯誤
        case itemsResponse(Result<LookupCatalog, PersistenceError>)

        /// 改名寫入結果
        ///
        /// - Parameter result: 改名資料或持久化錯誤
        case renameResponse(Result<LookupItemRename, PersistenceError>)

        /// 主檔管理畫面的使用者操作
        @CasePathable
        enum View {

            /// 畫面出現時觸發載入
            case task

            /// 使用者點擊新增按鈕
            case addButtonTapped

            /// 使用者要求刪除項目
            ///
            /// - Parameter name: 要刪除的主檔名稱
            case deleteButtonTapped(name: String)

            /// 使用者要求編輯付款方式
            ///
            /// - Parameter name: 要編輯的付款方式名稱
            case editButtonTapped(name: String)

            /// 表單關閉動畫已完成
            case formSheetDismissed

            /// 使用者要求重新命名項目
            ///
            /// - Parameter name: 要重新命名的主檔名稱
            case renameButtonTapped(name: String)
        }

        /// 主檔管理交給根畫面的結果
        @CasePathable
        enum Delegate: Equatable {

            /// 主檔項目已成功改名
            ///
            /// - Parameter rename: 已寫入的新舊名稱
            case itemRenamed(LookupItemRename)

            /// 付款方式與訂單已一起更正
            ///
            /// - Parameter plan: 寫入完成的更正資料
            case paymentMethodEdited(PaymentMethodEditPlan)
        }
    }

    // MARK: - Dependencies

    /// 主檔讀寫與改名清理操作入口
    @Dependency(\.lookupService) private var lookupService

    // MARK: - Body

    /// 組合付款方式更正、核心邏輯、確認框與寫入失敗通知的 reducer
    var body: some ReducerOf<Self> {
        Scope(state: \.correction, action: \.correction) {
            PaymentMethodCorrectionFeature()
        }
        Reduce(core)
            .ifLet(\.$destination, action: \.destination)
        // 目的地清空後才沖出暫存的寫入失敗通知
        Reduce(releasePendingNotice)
            .ifLet(\.$notice, action: \.notice)
    }
}

// MARK: - Private Method

private extension LookupManagementFeature {

    /// 處理主檔畫面事件，更新狀態並啟動後續操作
    ///
    /// - Parameters:
    ///   - state: 目前的主檔管理狀態
    ///   - action: 這次收到的主檔事件
    /// - Returns: 接下來要執行的操作，沒有就回 `.none`
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .view(.task):
            guard !state.hasLoaded else {
                return .none
            }
            return itemOperations().load(kind: state.kind)

        case .view(.addButtonTapped):
            state.destination = .add(
                LookupAddFormFeature.State(hasClassification: state.hasClassification)
            )
            return .none

        case .view(.deleteButtonTapped(name: let name)):
            state.destination = .deleteConfirmation(name: name)
            return .none

        case .view(.editButtonTapped(name: let name)):
            guard state.hasClassification else {
                return .none
            }
            state.destination = .editPaymentMethod(
                PaymentMethodEditFormFeature.State(
                    originalName: name,
                    flags: state.catalog.paymentMethodFlags(named: name)
                )
            )
            return .none

        case .view(.formSheetDismissed):
            state.isFormSheetDismissing = false
            if let pendingNotice = state.pendingNotice {
                state.notice = .lookupWriteFailure(pendingNotice)
                state.pendingNotice = nil
            }
            if let pendingAlert = state.pendingAlert {
                state.destination = pendingAlert
                state.pendingAlert = nil
            }
            return .none

        case .view(.renameButtonTapped(name: let name)):
            state.destination = .rename(LookupRenameFormFeature.State(originalName: name))
            return .none

        case .delegate:
            return .none

        case .destination(.presented(.add(.delegate(.saved(let name, let flags))))):
            state.destination = nil
            state.isFormSheetDismissing = true
            return itemOperations().add(
                LookupItemAddition(name: name, flags: flags),
                kind: state.kind
            )

        case .destination(.presented(.alert(.confirmDelete(name: let name)))):
            return itemOperations().delete(name: name, kind: state.kind)

        case .destination(.presented(.alert(.confirmPaymentMethodEdit))):
            return .send(.correction(.confirmed))

        case .destination(.presented(.alert(.cancelPaymentMethodEdit))):
            return .send(.correction(.cancelled))

        case .destination(
            .presented(
                .editPaymentMethod(.delegate(.saved(let originalName, let newName, let flags)))
            )
        ):
            state.destination = nil
            state.isFormSheetDismissing = true
            return .send(
                .correction(.requested(originalName: originalName, newName: newName, flags: flags))
            )

        case .destination(.presented(.rename(.delegate(.saved(let oldName, let newName))))):
            state.destination = nil
            state.isFormSheetDismissing = true
            return itemOperations().rename(
                LookupItemRename(oldName: oldName, newName: newName),
                kind: state.kind
            )

        case .destination:
            return .none

        case .notice:
            return .none

        case .addResponse(.success(let addition)):
            state.$catalog.withLock {
                $0.add(name: addition.name, kind: state.kind, flags: addition.flags)
            }
            return .none

        case .addResponse(.failure):
            presentNotice(.add, state: &state)
            return .none

        case .correction(.delegate(.confirmationRequired(let count))):
            presentDestination(.retroactiveConfirmation(affectedOrderCount: count), state: &state)
            return .none

        case .correction(.delegate(.edited(let plan))):
            state.$catalog.withLock {
                $0.remove(name: plan.originalName, kind: .paymentMethod)
                $0.add(name: plan.newName, kind: .paymentMethod, flags: plan.flags)
            }
            return .send(.delegate(.paymentMethodEdited(plan)))

        case .correction(.delegate(.failed)):
            presentNotice(.paymentMethodEdit, state: &state)
            return .none

        case .correction:
            return .none

        case .deleteResponse(.success(let name)):
            state.$catalog.withLock { $0.remove(name: name, kind: state.kind) }
            return .none

        case .deleteResponse(.failure):
            presentNotice(.delete, state: &state)
            return .none

        case .itemsResponse(.success(let catalog)):
            state.$catalog.withLock { $0.replaceItems(of: state.kind, from: catalog) }
            state.hasLoaded = true
            state.hasLoadFailed = false
            return .none

        case .itemsResponse(.failure):
            state.hasLoadFailed = true
            return .none

        case .renameResponse(.success(let rename)):
            state.$catalog.withLock {
                $0.rename(from: rename.oldName, to: rename.newName, kind: state.kind)
            }
            return .send(.delegate(.itemRenamed(rename)))

        case .renameResponse(.failure):
            presentNotice(.rename, state: &state)
            return .none
        }
    }

    /// 用本畫面取得的 Service 組出主檔操作物件
    ///
    /// - Returns: 可載入、變更與改名主檔的操作物件
    func itemOperations() -> LookupItemOperations {
        LookupItemOperations(lookupService: lookupService)
    }

    /// 目的地呈現中或表單正在關閉時先暫存寫入失敗通知，否則直接放進通知狀態
    ///
    /// - Parameters:
    ///   - failure: 失敗的主檔操作
    ///   - state: 要更新的主檔管理狀態
    func presentNotice(_ failure: Destination.WriteFailure, state: inout State) {
        if state.isFormSheetDismissing || state.destination != nil {
            state.pendingNotice = failure
        } else {
            state.notice = .lookupWriteFailure(failure)
        }
    }

    /// 表單正在關閉時先暫存確認框，否則直接放進目的地
    ///
    /// - Parameters:
    ///   - destination: 要呈現的目的地狀態
    ///   - state: 要更新的主檔管理狀態
    func presentDestination(_ destination: Destination.State, state: inout State) {
        if state.isFormSheetDismissing {
            state.pendingAlert = destination
        } else {
            state.destination = destination
        }
    }

    /// 目的地已清空且表單不在關閉中時，把暫存的寫入失敗通知放進通知狀態
    ///
    /// - Parameters:
    ///   - state: 要更新的主檔管理狀態
    ///   - action: 這次收到的主檔事件，此處只檢查目的地處理後的狀態
    /// - Returns: 沒有後續操作，固定回 `.none`
    func releasePendingNotice(state: inout State, action: Action) -> Effect<Action> {
        guard state.destination == nil,
              !state.isFormSheetDismissing,
              let pendingNotice = state.pendingNotice else {
            return .none
        }
        state.notice = .lookupWriteFailure(pendingNotice)
        state.pendingNotice = nil
        return .none
    }
}
