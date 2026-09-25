//
//  LookupManagementFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import ComposableArchitecture
import Foundation

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

        /// 表單已送出並正在關閉
        var isFormSheetDismissing = false

        /// 表單關閉期間等待呈現的 alert
        var pendingAlert: Destination.State?

        /// 目前呈現中的表單或 alert
        @Presents var destination: Destination.State?

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

        /// 付款方式更正子 Feature 的事件
        ///
        /// - Parameter action: 付款方式更正流程的事件
        case correction(PaymentMethodCorrectionFeature.Action)

        /// 表單與 alert 目的地事件
        ///
        /// - Parameter action: 目前目的地的呈現事件
        case destination(PresentationAction<Destination.Action>)

        /// 新增寫入結果
        ///
        /// - Parameter result: 新增項目或持久化錯誤
        case addResponse(Result<LookupItemAddition, PersistenceError>)

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

    /// 商品類別主檔資料來源
    @Dependency(CategoryRepository.self) private var categoryRepository

    /// 訂單資料來源
    @Dependency(OrderRepository.self) private var orderRepository

    /// 訂單來源主檔資料來源
    @Dependency(OrderSourceRepository.self) private var orderSourceRepository

    /// 付款方式主檔資料來源
    @Dependency(PaymentMethodRepository.self) private var paymentMethodRepository

    /// 對帳狀態主檔資料來源
    @Dependency(ReconciliationStatusRepository.self) private var reconciliationStatusRepository

    // MARK: - Body

    /// 組合付款方式更正、核心邏輯與目的地 reducer
    var body: some Reducer<State, Action> {
        Scope(state: \.correction, action: \.correction) {
            PaymentMethodCorrectionFeature()
        }
        Reduce(core)
            .ifLet(\.$destination, action: \.destination)
    }
}

// MARK: - Private Method

private extension LookupManagementFeature {

    /// 依收到的事件更新主檔狀態並回傳後續效果
    ///
    /// - Parameters:
    ///   - state: 目前的主檔管理狀態
    ///   - action: 這次收到的主檔事件
    /// - Returns: 接下來要執行的效果，沒有就回傳 `.none`
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

        case let .view(.deleteButtonTapped(name: name)):
            state.destination = .deleteConfirmation(name: name)
            return .none

        case let .view(.editButtonTapped(name: name)):
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
            if let pendingAlert = state.pendingAlert {
                state.destination = pendingAlert
                state.pendingAlert = nil
            }
            return .none

        case let .view(.renameButtonTapped(name: name)):
            state.destination = .rename(
                LookupRenameFormFeature.State(originalName: name)
            )
            return .none

        case .delegate:
            return .none

        case let .correction(.delegate(.confirmationRequired(count))):
            presentAlertAfterFormSheetDismissal(
                .retroactiveConfirmation(affectedOrderCount: count),
                state: &state
            )
            return .none

        case let .correction(.delegate(.edited(plan))):
            state.$catalog.withLock { catalog in
                catalog.remove(name: plan.originalName, kind: .paymentMethod)
                catalog.add(name: plan.newName, kind: .paymentMethod, flags: plan.flags)
            }
            return .send(.delegate(.paymentMethodEdited(plan)))

        case .correction(.delegate(.failed)):
            presentAlertAfterFormSheetDismissal(.writeFailure(.paymentMethodEdit), state: &state)
            return .none

        case .correction:
            return .none

        case let .destination(.presented(.add(.delegate(.saved(name, flags))))):
            state.destination = nil
            state.isFormSheetDismissing = true
            return itemOperations().add(
                LookupItemAddition(name: name, flags: flags),
                kind: state.kind
            )

        case let .destination(.presented(.alert(.confirmDelete(name: name)))):
            return itemOperations().delete(name: name, kind: state.kind)

        case .destination(.presented(.alert(.confirmPaymentMethodEdit))):
            return .send(.correction(.confirmed))

        case .destination(.presented(.alert(.cancelPaymentMethodEdit))):
            return .send(.correction(.cancelled))

        case let .destination(
            .presented(.editPaymentMethod(.delegate(.saved(originalName, newName, flags))))
        ):
            state.destination = nil
            state.isFormSheetDismissing = true
            return .send(
                .correction(
                    .requested(originalName: originalName, newName: newName, flags: flags)
                )
            )

        case let .destination(.presented(.rename(.delegate(.saved(oldName, newName))))):
            state.destination = nil
            state.isFormSheetDismissing = true
            return itemOperations().rename(
                LookupItemRename(oldName: oldName, newName: newName),
                kind: state.kind
            )

        case .destination:
            return .none

        case let .addResponse(.success(addition)):
            state.$catalog.withLock { catalog in
                catalog.add(name: addition.name, kind: state.kind, flags: addition.flags)
            }
            return .none

        case .addResponse(.failure):
            presentAlertAfterFormSheetDismissal(.writeFailure(.add), state: &state)
            return .none

        case let .deleteResponse(.success(name)):
            state.$catalog.withLock { $0.remove(name: name, kind: state.kind) }
            return .none

        case .deleteResponse(.failure):
            state.destination = .writeFailure(.delete)
            return .none

        case let .itemsResponse(.success(catalog)):
            state.$catalog.withLock { $0.replaceItems(of: state.kind, from: catalog) }
            state.hasLoaded = true
            state.hasLoadFailed = false
            return .none

        case .itemsResponse(.failure):
            state.hasLoadFailed = true
            return .none

        case let .renameResponse(.success(rename)):
            state.$catalog.withLock { catalog in
                catalog.rename(from: rename.oldName, to: rename.newName, kind: state.kind)
            }
            return .send(.delegate(.itemRenamed(rename)))

        case .renameResponse(.failure):
            presentAlertAfterFormSheetDismissal(.writeFailure(.rename), state: &state)
            return .none
        }
    }

    /// 建立目前 reducer 使用的主檔操作分派器
    ///
    /// - Returns: 持有五個主檔 repository 的操作型別
    func itemOperations() -> LookupItemOperations {
        LookupItemOperations(
            categoryRepository: categoryRepository,
            orderRepository: orderRepository,
            orderSourceRepository: orderSourceRepository,
            paymentMethodRepository: paymentMethodRepository,
            reconciliationStatusRepository: reconciliationStatusRepository
        )
    }

    /// 表單關閉期間暫存提示，否則直接呈現
    ///
    /// - Parameters:
    ///   - alert: 要呈現的目的地狀態
    ///   - state: 要更新的主檔管理狀態
    func presentAlertAfterFormSheetDismissal(
        _ alert: Destination.State,
        state: inout State
    ) {
        if state.isFormSheetDismissing {
            state.pendingAlert = alert
        } else {
            state.destination = alert
        }
    }
}
