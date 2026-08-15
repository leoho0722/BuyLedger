//
//  LookupManagementFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import ComposableArchitecture
import Foundation
import SwiftUI

/// 商品類別 / 付款方式主檔的獨立管理功能
@Reducer
struct LookupManagementFeature {
    
    // MARK: - State
    
    /// 主檔管理畫面狀態
    @ObservableState
    struct State: Equatable, Identifiable {
        
        /// 此狀態管理的主檔型別
        let kind: LookupKind
        
        /// 四種主檔共用的目錄
        @Shared(.lookupCatalog) var catalog: LookupCatalog
        
        /// 以主檔種類作為識別值，供根 feature 的 `IdentifiedArrayOf` 使用
        var id: LookupKind { kind }
        
        /// 目前的主檔項目 (已排序)，衍生自 ``catalog``
        var items: [String] { catalog.names(for: kind) }
        
        /// 付款方式的 isCardless 對應表
        var paymentMethodIsCardless: [String: Bool] {
            Dictionary(
                uniqueKeysWithValues: catalog.paymentMethods.map { ($0.name, $0.isCardless) }
            )
        }
        
        /// 付款方式的 isBankTransfer 對應表
        var paymentMethodIsBankTransfer: [String: Bool] {
            Dictionary(
                uniqueKeysWithValues: catalog.paymentMethods.map { ($0.name, $0.isBankTransfer) }
            )
        }
        
        /// 付款方式的 isCashOnDelivery 對應表
        var paymentMethodIsCashOnDelivery: [String: Bool] {
            Dictionary(
                uniqueKeysWithValues: catalog.paymentMethods.map { ($0.name, $0.isCashOnDelivery) }
            )
        }
        
        /// 載入失敗訊息
        var errorMessage: String?
        
        /// 是否已完成首次載入
        var hasLoaded = false
        
        /// 目前呈現中的改名或編輯付款方式流程；`nil` 表示未呈現
        @Presents var destination: Destination.State?
        
        /// 刪除主檔項目的二次確認；`nil` 代表未顯示
        @Presents var deletionConfirmation: AlertState<Action.Alert>?
        
        /// 待確認的付款方式更新；確認前不改動資料
        var pendingPaymentMethodEdit: PaymentMethodEditPlan?
        
        /// 付款方式更新的確認提示；沒有受影響訂單時不顯示
        @Presents var retroactiveConfirmation: AlertState<Action.Alert>?
        
        /// 一次性付款方式寫入失敗提示；關閉後即結束，不混入持續性的載入錯誤
        @Presents var writeFailureAlert: AlertState<Action.Alert>?
    }
    
    // MARK: - Action
    
    /// 主檔管理可處理的事件
    @CasePathable
    enum Action: BindableAction, Equatable {
        
        /// 畫面出現時觸發載入
        case task
        
        /// 訂單來源主檔載入成功
        case orderSourceItemsLoaded([String])
        
        /// 商品類別主檔載入成功
        case categoryItemsLoaded([String])
        
        /// 付款方式主檔載入成功 (含 `isCardless` 與 `isBankTransfer`)
        case paymentMethodInfosLoaded([PaymentMethodInfo])
        
        /// 對帳狀態主檔載入成功
        case reconciliationStatusItemsLoaded([String])
        
        /// 主檔載入失敗
        case loadFailed(String)
        
        /// 開啟新增主檔流程
        case addButtonTapped
        
        /// 確認新增主檔項目；付款方式另外保存三個旗標
        case addConfirmed(
            name: String,
            isCardless: Bool,
            isBankTransfer: Bool,
            isCashOnDelivery: Bool
        )
        
        /// 刪除確認 alert 的選項
        @CasePathable
        enum Alert: Equatable {
            
            /// 使用者確認刪除指定名稱的主檔項目
            case confirmDelete(String)
            
            /// 使用者確認重新計算付款方式旗標
            case confirmPaymentMethodEdit
        }
        
        /// 使用者點擊刪除；先以 ``State/deletionConfirmation`` 二次確認
        case deleteButtonTapped(String)
        
        /// 確認後實際執行刪除
        case deleteRequested(String)
        
        /// 刪除完成 (資料庫寫入成功後才更新狀態與各處記憶體副本)
        case deleteSucceeded(String)
        
        /// 刪除確認 alert 事件
        case deletionConfirmation(PresentationAction<Alert>)
        
        /// 開啟重新命名表單並帶入目前名稱
        case renameButtonTapped(name: String)
        
        /// 使用者要求把指定名稱改成新名稱；同時 cascade 到所有引用該名稱的訂單
        case renameRequested(from: String, to: String)
        
        /// 使用者點擊指定付款方式的「編輯」
        case editButtonTapped(name: String)
        
        /// 儲存付款方式的名稱與旗標
        case editConfirmed(
            originalName: String,
            name: String,
            isCardless: Bool,
            isBankTransfer: Bool,
            isCashOnDelivery: Bool
        )
        
        /// 已準備好的付款方式更新資料；有受影響訂單時顯示確認
        case paymentMethodEditPrepared(PaymentMethodEditPlan)
        
        /// 付款方式主檔與受影響訂單已在同一次持久化操作成功寫入
        case paymentMethodEditSucceeded(PaymentMethodEditPlan)
        
        /// 付款方式更新失敗；不改動主檔與訂單
        case paymentMethodEditFailed(String)
        
        /// 一次性付款方式寫入失敗提示事件
        case writeFailureAlert(PresentationAction<Alert>)
        
        /// 付款方式更新確認提示
        case retroactiveConfirmation(PresentationAction<Alert>)
        
        /// 改名 / 編輯付款方式呈現目的地事件
        case destination(PresentationAction<Destination.Action>)
        
        /// SwiftUI binding 更新 (新增流程的 alert / sheet 呈現狀態與草稿文字)
        case binding(BindingAction<State>)
    }
    
    // MARK: - Dependency Properties
    
    /// 訂單來源資料來源
    @Dependency(OrderSourceRepository.self) private var orderSourceRepository
    
    /// 商品類別資料來源
    @Dependency(CategoryRepository.self) private var categoryRepository
    
    /// 付款方式資料來源
    @Dependency(PaymentMethodRepository.self) private var paymentMethodRepository
    
    /// 對帳狀態資料來源
    @Dependency(ReconciliationStatusRepository.self) private var reconciliationStatusRepository
    
    /// 訂單資料來源；rename 時把 cascade 寫入訂單表
    @Dependency(OrderRepository.self) private var orderRepository
    
    // MARK: - Reducer Body
    
    /// 主檔管理 reducer
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce {
            state,
            action in
            switch action {
            case .task:
                guard !state.hasLoaded else {
                    return .none
                }
                return load(kind: state.kind)
                
            case let .orderSourceItemsLoaded(items):
                state.$catalog.withLock { $0.orderSources = items }
                state.hasLoaded = true
                state.errorMessage = nil
                return .none
                
            case let .categoryItemsLoaded(items):
                state.$catalog.withLock { $0.categories = items }
                state.hasLoaded = true
                state.errorMessage = nil
                return .none
                
            case let .paymentMethodInfosLoaded(infos):
                state.$catalog.withLock {
                    $0.paymentMethods = infos.sorted {
                        $0.name.localizedStandardCompare($1.name) == .orderedAscending
                    }
                }
                state.hasLoaded = true
                state.errorMessage = nil
                return .none
                
            case let .reconciliationStatusItemsLoaded(items):
                state.$catalog.withLock { $0.reconciliationStatuses = items }
                state.hasLoaded = true
                state.errorMessage = nil
                return .none
                
            case let .loadFailed(message):
                state.errorMessage = message
                return .none
                
            case .addButtonTapped:
                // 新增併入 destination：任一時刻只呈現一張 sheet，互斥由型別系統保證
                switch state.kind {
                case .orderSource,
                        .category,
                        .reconciliationStatus:
                    state.destination = .addNameOnly(Destination.AddNameOnlyFeature.State())
                case .paymentMethod:
                    state.destination = .addPaymentMethod(
                        Destination.AddPaymentMethodFeature.State())
                }
                return .none
                
            case let .addConfirmed(name, isCardless, isBankTransfer, isCashOnDelivery):
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    return .none
                }
                
                // 名稱型主檔不重複建立，付款方式則更新旗標
                state.$catalog.withLock {
                    $0.add(
                        name: trimmed,
                        kind: state.kind,
                        isCardless: isCardless,
                        isBankTransfer: isBankTransfer,
                        isCashOnDelivery: isCashOnDelivery
                    )
                }
                
                let kind = state.kind
                let orderSourceRepository = orderSourceRepository
                let categoryRepository = categoryRepository
                let paymentMethodRepository = paymentMethodRepository
                let reconciliationStatusRepository = reconciliationStatusRepository
                return .run { _ in
                    switch kind {
                    case .orderSource:
                        try await orderSourceRepository.addOrderSource(trimmed)
                    case .category:
                        try await categoryRepository.addCategory(trimmed)
                    case .paymentMethod:
                        try await paymentMethodRepository.addPaymentMethod(
                            trimmed, isCardless, isBankTransfer, isCashOnDelivery)
                    case .reconciliationStatus:
                        try await reconciliationStatusRepository.addReconciliationStatus(trimmed)
                    }
                } catch: { _, send in
                    await send(.loadFailed("新增失敗，請稍後再試。"))
                }
                
            case let .deleteButtonTapped(name):
                state.deletionConfirmation = AlertState {
                    TextState("刪除項目")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDelete(name)) {
                        TextState("刪除")
                    }
                    ButtonState(role: .cancel) {
                        TextState("取消")
                    }
                } message: {
                    TextState("刪除「\(name)」後，引用它的既有訂單會失去這個欄位值。此操作無法復原。")
                }
                return .none
                
            case let .deletionConfirmation(.presented(.confirmDelete(name))):
                return .send(.deleteRequested(name))
                
            case .deletionConfirmation:
                return .none
                
            case let .deleteRequested(name):
                // 先寫後改；刪除不是高頻操作，不需要樂觀更新。
                // 而寫入成功才更新狀態從根本消除了狀態與資料庫不一致的可能
                let kind = state.kind
                let orderSourceRepository = orderSourceRepository
                let categoryRepository = categoryRepository
                let paymentMethodRepository = paymentMethodRepository
                let reconciliationStatusRepository = reconciliationStatusRepository
                return .run { send in
                    switch kind {
                    case .orderSource:
                        try await orderSourceRepository.removeOrderSource(name)
                    case .category:
                        try await categoryRepository.removeCategory(name)
                    case .paymentMethod:
                        try await paymentMethodRepository.removePaymentMethod(name)
                    case .reconciliationStatus:
                        try await reconciliationStatusRepository.removeReconciliationStatus(name)
                    }
                    await send(.deleteSucceeded(name))
                } catch: { _, send in
                    await send(.loadFailed("刪除失敗，請稍後再試。"))
                }
                
            case let .deleteSucceeded(name):
                state.$catalog.withLock { $0.remove(name: name, kind: state.kind) }
                return .none
                
            case let .renameButtonTapped(name):
                state.destination = .rename(
                    Destination.RenameFeature.State(originalName: name, draft: name))
                return .none
                
            case let .renameRequested(from, to):
                let trimmedFrom = from.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedTo = to.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedFrom.isEmpty,
                      !trimmedTo.isEmpty,
                      trimmedFrom != trimmedTo else {
                    return .none
                }
                
                // 由 catalog.rename 統一合併付款方式旗標。
                state.$catalog.withLock {
                    $0.rename(from: trimmedFrom, to: trimmedTo, kind: state.kind)
                }
                
                let kind = state.kind
                let orderSourceRepository = orderSourceRepository
                let categoryRepository = categoryRepository
                let paymentMethodRepository = paymentMethodRepository
                let reconciliationStatusRepository = reconciliationStatusRepository
                let orderRepository = orderRepository
                return .run { _ in
                    switch kind {
                    case .orderSource:
                        try await orderSourceRepository.renameOrderSource(trimmedFrom, trimmedTo)
                        try await orderRepository.renameOrderSource(trimmedFrom, trimmedTo)
                    case .category:
                        try await categoryRepository.renameCategory(trimmedFrom, trimmedTo)
                        try await orderRepository.renameOrderCategory(trimmedFrom, trimmedTo)
                    case .paymentMethod:
                        try await paymentMethodRepository.renamePaymentMethod(
                            trimmedFrom, trimmedTo)
                        try await orderRepository.renameOrderPaymentMethod(trimmedFrom, trimmedTo)
                    case .reconciliationStatus:
                        try await reconciliationStatusRepository.renameReconciliationStatus(
                            trimmedFrom, trimmedTo)
                        try await orderRepository.renameOrderReconciliationStatus(
                            trimmedFrom, trimmedTo)
                    }
                } catch: { _, send in
                    await send(.loadFailed("重新命名失敗，請稍後再試。"))
                }
                
            case let .editButtonTapped(name):
                guard state.kind == .paymentMethod else {
                    return .none
                }
                state.destination = .editPaymentMethod(
                    Destination.EditPaymentMethodFeature.State(
                        originalName: name,
                        isCardless: state.paymentMethodIsCardless[name] ?? false,
                        isBankTransfer: state.paymentMethodIsBankTransfer[name] ?? false,
                        isCashOnDelivery: state.paymentMethodIsCashOnDelivery[name] ?? false
                    )
                )
                return .none
                
            case let .editConfirmed(
                originalName, rawName, isCardless, isBankTransfer, isCashOnDelivery):
                // 僅付款方式使用編輯流程；其他 kind 不會送此 action
                guard state.kind == .paymentMethod else {
                    return .none
                }
                let trimmedOriginal = originalName.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedNew = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedNew.isEmpty else {
                    return .none
                }
                
                let storedFlags = state.paymentMethodFlagSnapshot(for: trimmedOriginal)
                let requestedFlags = PaymentMethodFlagSnapshot(
                    isCardless: isCardless,
                    isBankTransfer: isBankTransfer,
                    isCashOnDelivery: isCashOnDelivery
                )
                let flagsChanged = storedFlags != requestedFlags
                
                let orderRepository = orderRepository
                return .run { send in
                    do {
                        // 確認文案與寫入資料共用同一個 plan。
                        let orders = try await orderRepository.fetchOrders()
                        let affectedOrders =
                        orders
                            .filter { $0.paymentMethod == trimmedOriginal }
                            .map {
                                $0
                                    .renamingPaymentMethod(to: trimmedNew)
                                    .applyingPaymentMethodFlags(
                                        isCardless: isCardless,
                                        isBankTransfer: isBankTransfer,
                                        isCashOnDelivery: isCashOnDelivery
                                    )
                            }
                        await send(
                            .paymentMethodEditPrepared(
                                PaymentMethodEditPlan(
                                    originalName: trimmedOriginal,
                                    newName: trimmedNew,
                                    isCardless: isCardless,
                                    isBankTransfer: isBankTransfer,
                                    isCashOnDelivery: isCashOnDelivery,
                                    flagsChanged: flagsChanged,
                                    affectedOrders: affectedOrders
                                )
                            )
                        )
                    } catch {
                        await send(.paymentMethodEditFailed("付款方式編輯失敗，請稍後再試。"))
                    }
                }
                
            case let .paymentMethodEditPrepared(plan):
                if plan.affectedOrders.isEmpty || !plan.flagsChanged {
                    // 沒有受影響訂單或只改名時，直接套用主檔旗標
                    return persistPaymentMethodEdit(plan)
                }
                
                state.pendingPaymentMethodEdit = plan
                let count = plan.affectedOrders.count
                let message: LocalizedStringKey =
                "確認後將重算 \(count) 筆既有訂單的付款旗標與獲利；折抵、補款或對帳狀態可能被清除。此操作無法復原。"
                state.retroactiveConfirmation = AlertState {
                    TextState("更正付款方式")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmPaymentMethodEdit) {
                        TextState("確認更正")
                    }
                    ButtonState(role: .cancel) {
                        TextState("取消")
                    }
                } message: {
                    TextState(message)
                }
                return .none
                
            case .retroactiveConfirmation(.presented(.confirmPaymentMethodEdit)):
                guard let plan = state.pendingPaymentMethodEdit else {
                    return .none
                }
                state.pendingPaymentMethodEdit = nil
                return persistPaymentMethodEdit(plan)
                
            case .retroactiveConfirmation(.dismiss):
                state.pendingPaymentMethodEdit = nil
                state.retroactiveConfirmation = nil
                return .none
                
            case .retroactiveConfirmation:
                return .none
                
            case let .paymentMethodEditSucceeded(plan):
                // 移除舊項目，再依新名稱與旗標寫入
                state.$catalog.withLock {
                    $0.remove(name: plan.originalName, kind: .paymentMethod)
                    $0.add(
                        name: plan.newName,
                        kind: .paymentMethod,
                        isCardless: plan.isCardless,
                        isBankTransfer: plan.isBankTransfer,
                        isCashOnDelivery: plan.isCashOnDelivery
                    )
                }
                state.pendingPaymentMethodEdit = nil
                state.retroactiveConfirmation = nil
                state.destination = nil
                state.errorMessage = nil
                return .none
                
            case let .paymentMethodEditFailed(message):
                state.pendingPaymentMethodEdit = nil
                state.retroactiveConfirmation = nil
                state.writeFailureAlert = makeWriteFailureAlert(LocalizedStringKey(message))
                return .none
                
            case .writeFailureAlert:
                return .none
                
            case let .destination(.presented(.addNameOnly(.saveButtonTapped(name)))):
                state.destination = nil
                return .send(
                    .addConfirmed(
                        name: name, isCardless: false, isBankTransfer: false,
                        isCashOnDelivery: false)
                )
                
            case let .destination(
                .presented(.addPaymentMethod(.saveButtonTapped(name, isCardless, isBankTransfer, isCashOnDelivery)))
            ):
                state.destination = nil
                return .send(
                    .addConfirmed(
                        name: name,
                        isCardless: isCardless,
                        isBankTransfer: isBankTransfer,
                        isCashOnDelivery: isCashOnDelivery
                    )
                )
                
            case .destination(.presented(.rename(.saveButtonTapped))):
                // 取出 rename 草稿後再關閉 destination
                guard let renameState = state.destination?.rename,
                      renameState.canSave else {
                    return .none
                }
                state.destination = nil
                return .send(.renameRequested(from: renameState.originalName, to: renameState.draft))
                
            case let .destination(
                .presented(.editPaymentMethod(.saveButtonTapped(name, isCardless, isBankTransfer, isCashOnDelivery)))
            ):
                guard let editState = state.destination?.editPaymentMethod else {
                    return .none
                }
                return .send(
                    .editConfirmed(
                        originalName: editState.originalName,
                        name: name,
                        isCardless: isCardless,
                        isBankTransfer: isBankTransfer,
                        isCashOnDelivery: isCashOnDelivery
                    )
                )
                
            case .destination:
                return .none
                
            case .binding:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        .ifLet(\.$deletionConfirmation, action: \.deletionConfirmation)
        .ifLet(\.$retroactiveConfirmation, action: \.retroactiveConfirmation)
        .ifLet(\.$writeFailureAlert, action: \.writeFailureAlert)
    }
}

// MARK: - Private Types

/// 付款方式編輯流程使用的三個旗標值快照
private struct PaymentMethodFlagSnapshot: Equatable, Sendable {

    // MARK: - Data Properties

    /// 是否屬於無卡類付款方式
    let isCardless: Bool

    /// 是否屬於銀行匯款類付款方式
    let isBankTransfer: Bool

    /// 是否屬於貨到付款類付款方式
    let isCashOnDelivery: Bool
}

// MARK: - Private Method

private extension LookupManagementFeature.State {

    /// 讀取指定付款方式的旗標快照；不存在的名稱各旗標皆視為 `false`
    /// - Parameter name: 付款方式名稱
    /// - Returns: 對應付款方式的三個旗標快照
    func paymentMethodFlagSnapshot(for name: String) -> PaymentMethodFlagSnapshot {
        PaymentMethodFlagSnapshot(
            isCardless: paymentMethodIsCardless[name] ?? false,
            isBankTransfer: paymentMethodIsBankTransfer[name] ?? false,
            isCashOnDelivery: paymentMethodIsCashOnDelivery[name] ?? false
        )
    }
}

// MARK: - Nested Types

extension LookupManagementFeature {
    
    /// 付款方式編輯操作的固定快照
    struct PaymentMethodEditPlan: Equatable, Sendable {
        
        /// 原付款方式名稱
        let originalName: String
        
        /// 新付款方式名稱
        let newName: String
        
        /// 使用者確認後要寫入的三個旗標
        let isCardless: Bool
        let isBankTransfer: Bool
        let isCashOnDelivery: Bool
        
        /// 旗標是否變更；只改名時不需確認
        let flagsChanged: Bool
        
        /// 已改名並依共用規則正規化的受影響訂單
        let affectedOrders: [LedgerOrder]
    }
}

// MARK: - Private Method

private extension LookupManagementFeature {
    
    /// 建立一次性付款方式寫入失敗提示
    /// - Parameter message: 要顯示的錯誤訊息
    /// - Returns: 一次性寫入失敗提示
    func makeWriteFailureAlert(_ message: LocalizedStringKey) -> AlertState<Action.Alert> {
        AlertState {
            TextState("操作失敗")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("知道了")
            }
        } message: {
            TextState(message)
        }
    }
    
    /// 在確認完成後執行主檔與訂單的單一原子寫入
    /// - Parameter plan: 已準備好的付款方式更新資料
    /// - Returns: 成功或失敗 action 的 effect
    func persistPaymentMethodEdit(_ plan: PaymentMethodEditPlan) -> Effect<Action> {
        let paymentMethodRepository = paymentMethodRepository
        return .run { send in
            do {
                try await paymentMethodRepository.applyPaymentMethodEdit(
                    plan.originalName,
                    plan.newName,
                    plan.isCardless,
                    plan.isBankTransfer,
                    plan.isCashOnDelivery,
                    plan.affectedOrders
                )
                await send(.paymentMethodEditSucceeded(plan))
            } catch {
                await send(.paymentMethodEditFailed("付款方式編輯失敗，請稍後再試。"))
            }
        }
    }
    
    /// 依 ``LookupKind`` 選擇對應 repository 觸發 fetch
    /// - Parameter kind: 要載入的主檔型別
    /// - Returns: 對應 effect
    func load(kind: LookupKind) -> Effect<Action> {
        let orderSourceRepository = orderSourceRepository
        let categoryRepository = categoryRepository
        let paymentMethodRepository = paymentMethodRepository
        let reconciliationStatusRepository = reconciliationStatusRepository
        return .run { send in
            do {
                switch kind {
                case .orderSource:
                    let items = try await orderSourceRepository.fetchOrderSources()
                    await send(.orderSourceItemsLoaded(items))
                case .category:
                    let items = try await categoryRepository.fetchCategories()
                    await send(.categoryItemsLoaded(items))
                case .paymentMethod:
                    let infos = try await paymentMethodRepository.fetchPaymentMethodInfos()
                    await send(.paymentMethodInfosLoaded(infos))
                case .reconciliationStatus:
                    let items =
                    try await reconciliationStatusRepository.fetchReconciliationStatuses()
                    await send(.reconciliationStatusItemsLoaded(items))
                }
            } catch {
                await send(.loadFailed("主檔載入失敗，請稍後再試。"))
            }
        }
    }
}
