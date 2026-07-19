//
//  LookupManagementFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import ComposableArchitecture
import Foundation

/// 商品類別 / 付款方式主檔的獨立管理功能
///
/// 以 ``LookupKind`` 切換要操作的 repository 與顯示文案，使同一份 reducer/view 可同時服務多種主檔
///
/// 付款方式主檔額外維護 ``State/paymentMethodIsCardless``、``State/paymentMethodIsBankTransfer`` 與 ``State/paymentMethodIsCashOnDelivery`` 三個對應表，供 view 端在 List 中顯示「無卡」「銀行匯款」「貨到付款」標籤
///
/// 旗標的設定發生在使用者新增或編輯付款方式的當下，不再於 List row 提供切換 toggle，以避免 UX 上不易理解
@Reducer
struct LookupManagementFeature {

    // MARK: - State

    /// 主檔管理畫面狀態
    @ObservableState
    struct State: Equatable {

        /// 此狀態管理的主檔型別
        let kind: LookupKind

        /// 目前的主檔項目 (已排序)
        var items: [String] = []

        /// 付款方式主檔的 `isCardless` 對應表；只有 `kind == .paymentMethod` 時有意義
        ///
        /// 以名稱為 key 的 dictionary，缺值視為 `false`。View 對 paymentMethod kind 會在 row 上顯示「無卡」標籤，但不再提供切換 toggle；要更新此旗標只能透過刪除後重新新增
        var paymentMethodIsCardless: [String: Bool] = [:]

        /// 付款方式主檔的 `isBankTransfer` 對應表；只有 `kind == .paymentMethod` 時有意義
        ///
        /// 以名稱為 key 的 dictionary，缺值視為 `false`。View 對 paymentMethod kind 會在 row 上顯示「銀行匯款」標籤；設定方式與 ``paymentMethodIsCardless`` 相同 (新增當下決定)
        var paymentMethodIsBankTransfer: [String: Bool] = [:]

        /// 付款方式主檔的 `isCashOnDelivery` 對應表；只有 `kind == .paymentMethod` 時有意義
        ///
        /// 以名稱為 key 的 dictionary，缺值視為 `false`。View 對 paymentMethod kind 會在 row 上顯示「貨到付款」標籤；設定方式與 ``paymentMethodIsCardless`` 相同 (新增當下決定)
        var paymentMethodIsCashOnDelivery: [String: Bool] = [:]

        /// 載入失敗訊息
        var errorMessage: String?

        /// 是否已完成首次載入
        var hasLoaded = false

        /// 是否顯示「新增」alert (訂單來源 / 商品類別 / 對帳狀態等純名稱 kind 使用)
        var showsAddNameOnlyAlert = false

        /// 是否顯示「新增付款方式」sheet (僅付款方式 kind 使用；alert 在實機驗證會 silently 丟掉 Toggle，所以付款方式入口改走 sheet)
        var showsAddPaymentMethodSheet = false

        /// 新增 alert / sheet 的名稱輸入草稿
        var addDraft = ""

        /// 目前呈現中的改名或編輯付款方式流程；`nil` 表示未呈現
        @Presents var destination: Destination.State?
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

        /// 使用者點擊 toolbar「新增」；reducer 依 ``State/kind`` 重置草稿並開啟對應的新增 alert (訂單來源 / 商品類別) 或 sheet (付款方式 / 對帳狀態)，取代 view 端直接分支寫入呈現狀態
        case addButtonTapped

        /// 使用者透過「新增」流程確認新增一筆主檔項目；對付款方式以外的 kind，`isCardless`、`isBankTransfer` 與 `isCashOnDelivery` 永遠為 `false` 並被忽略
        case addConfirmed(name: String, isCardless: Bool, isBankTransfer: Bool, isCashOnDelivery: Bool)

        /// 新增 alert 的「新增」/「取消」按完後清空名稱輸入草稿
        case addDraftCleared

        /// 使用者要求刪除指定名稱的主檔項目
        case deleteRequested(String)

        /// 使用者點擊指定項目的「重新命名」；由 reducer 以該名稱為初值呈現 ``Destination/rename(_:)``，取代 view 端直接組裝表單初值
        case renameButtonTapped(name: String)

        /// 使用者要求把指定名稱改成新名稱；同時 cascade 到所有引用該名稱的訂單
        case renameRequested(from: String, to: String)

        /// 使用者點擊指定付款方式的「編輯」
        ///
        /// 由 reducer 自 ``State/paymentMethodIsCardless`` 等主檔字典快照旗標，呈現 ``Destination/editPaymentMethod(_:)``，取代 view 端直接索引字典組裝表單初值
        case editButtonTapped(name: String)

        /// 使用者透過「編輯」sheet 確認修改一筆付款方式 (名稱 + 旗標)；僅 `kind == .paymentMethod` 使用
        ///
        /// 與 ``renameRequested`` + ``addConfirmed`` 分開送的差別：編輯為「權威設定」，名稱變更後會以使用者實際勾選的旗標覆寫，允許取消勾選
        ///
        /// (`renameRequested` 的合併規則會把任一邊為 `true` 的旗標保留，無法取消)
        case editConfirmed(originalName: String, name: String, isCardless: Bool, isBankTransfer: Bool, isCashOnDelivery: Bool)

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
        Reduce { state, action in
            switch action {
            case .task:
                guard !state.hasLoaded else {
                    return .none
                }
                return load(kind: state.kind)

            case let .orderSourceItemsLoaded(items):
                state.items = items
                state.hasLoaded = true
                state.errorMessage = nil
                return .none

            case let .categoryItemsLoaded(items):
                state.items = items
                state.hasLoaded = true
                state.errorMessage = nil
                return .none

            case let .paymentMethodInfosLoaded(infos):
                state.items = infos.map(\.name)
                    .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
                var cardlessMap: [String: Bool] = [:]
                var bankTransferMap: [String: Bool] = [:]
                var cashOnDeliveryMap: [String: Bool] = [:]
                for info in infos {
                    cardlessMap[info.name] = info.isCardless
                    bankTransferMap[info.name] = info.isBankTransfer
                    cashOnDeliveryMap[info.name] = info.isCashOnDelivery
                }
                state.paymentMethodIsCardless = cardlessMap
                state.paymentMethodIsBankTransfer = bankTransferMap
                state.paymentMethodIsCashOnDelivery = cashOnDeliveryMap
                state.hasLoaded = true
                state.errorMessage = nil
                return .none

            case let .reconciliationStatusItemsLoaded(items):
                state.items = items
                state.hasLoaded = true
                state.errorMessage = nil
                return .none

            case let .loadFailed(message):
                state.errorMessage = message
                return .none

            case .addButtonTapped:
                switch state.kind {
                case .orderSource, .category, .reconciliationStatus:
                    state.addDraft = ""
                    state.showsAddNameOnlyAlert = true
                case .paymentMethod:
                    state.showsAddPaymentMethodSheet = true
                }
                return .none

            case let .addConfirmed(name, isCardless, isBankTransfer, isCashOnDelivery):
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    return .none
                }

                if !state.items.contains(trimmed) {
                    var updated = state.items
                    updated.append(trimmed)
                    state.items = updated.sorted {
                        $0.localizedStandardCompare($1) == .orderedAscending
                    }
                }

                if state.kind == .paymentMethod {
                    // 重新觸發同名新增等同於「重新套用 isCardless / isBankTransfer / isCashOnDelivery」，方便使用者上次忘了勾選時更正
                    state.paymentMethodIsCardless[trimmed] = isCardless
                    state.paymentMethodIsBankTransfer[trimmed] = isBankTransfer
                    state.paymentMethodIsCashOnDelivery[trimmed] = isCashOnDelivery
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
                        try await paymentMethodRepository.addPaymentMethod(trimmed, isCardless, isBankTransfer, isCashOnDelivery)
                    case .reconciliationStatus:
                        try await reconciliationStatusRepository.addReconciliationStatus(trimmed)
                    }
                } catch: { _, send in
                    await send(.loadFailed("新增失敗，請稍後再試。"))
                }

            case .addDraftCleared:
                state.addDraft = ""
                return .none

            case let .deleteRequested(name):
                state.items.removeAll { $0 == name }
                state.paymentMethodIsCardless.removeValue(forKey: name)
                state.paymentMethodIsBankTransfer.removeValue(forKey: name)
                state.paymentMethodIsCashOnDelivery.removeValue(forKey: name)

                let kind = state.kind
                let orderSourceRepository = orderSourceRepository
                let categoryRepository = categoryRepository
                let paymentMethodRepository = paymentMethodRepository
                let reconciliationStatusRepository = reconciliationStatusRepository
                return .run { _ in
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
                } catch: { _, send in
                    await send(.loadFailed("刪除失敗，請稍後再試。"))
                }

            case let .renameButtonTapped(name):
                state.destination = .rename(Destination.RenameFeature.State(originalName: name, draft: name))
                return .none

            case let .renameRequested(from, to):
                let trimmedFrom = from.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedTo = to.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedFrom.isEmpty,
                      !trimmedTo.isEmpty,
                      trimmedFrom != trimmedTo else {
                    return .none
                }

                // 本地 state 同步更新：把舊名稱替換、去重後排序
                var renamed = state.items.map { $0 == trimmedFrom ? trimmedTo : $0 }
                renamed = Array(Set(renamed))
                state.items = renamed.sorted {
                    $0.localizedStandardCompare($1) == .orderedAscending
                }

                if state.kind == .paymentMethod {
                    if let oldFlag = state.paymentMethodIsCardless.removeValue(forKey: trimmedFrom) {
                        // 合併：任一邊曾標記為無卡就維持無卡
                        state.paymentMethodIsCardless[trimmedTo] = oldFlag || (state.paymentMethodIsCardless[trimmedTo] ?? false)
                    }
                    if let oldFlag = state.paymentMethodIsBankTransfer.removeValue(forKey: trimmedFrom) {
                        // 合併：任一邊曾標記為銀行匯款就維持銀行匯款
                        state.paymentMethodIsBankTransfer[trimmedTo] = oldFlag || (state.paymentMethodIsBankTransfer[trimmedTo] ?? false)
                    }
                    if let oldFlag = state.paymentMethodIsCashOnDelivery.removeValue(forKey: trimmedFrom) {
                        // 合併：任一邊曾標記為貨到付款就維持貨到付款
                        state.paymentMethodIsCashOnDelivery[trimmedTo] = oldFlag || (state.paymentMethodIsCashOnDelivery[trimmedTo] ?? false)
                    }
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
                        try await paymentMethodRepository.renamePaymentMethod(trimmedFrom, trimmedTo)
                        try await orderRepository.renameOrderPaymentMethod(trimmedFrom, trimmedTo)
                    case .reconciliationStatus:
                        try await reconciliationStatusRepository.renameReconciliationStatus(trimmedFrom, trimmedTo)
                        try await orderRepository.renameOrderReconciliationStatus(trimmedFrom, trimmedTo)
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

            case let .editConfirmed(originalName, rawName, isCardless, isBankTransfer, isCashOnDelivery):
                // 僅付款方式使用編輯流程；其他 kind 不會送此 action
                guard state.kind == .paymentMethod else {
                    return .none
                }
                let trimmedOriginal = originalName.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedNew = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedNew.isEmpty else {
                    return .none
                }

                let didRename = trimmedNew != trimmedOriginal
                if didRename {
                    // 名稱變更：把舊名稱替換、去重後排序，並清掉舊名稱的旗標對應
                    var renamed = state.items.map { $0 == trimmedOriginal ? trimmedNew : $0 }
                    renamed = Array(Set(renamed))
                    state.items = renamed.sorted {
                        $0.localizedStandardCompare($1) == .orderedAscending
                    }
                    state.paymentMethodIsCardless.removeValue(forKey: trimmedOriginal)
                    state.paymentMethodIsBankTransfer.removeValue(forKey: trimmedOriginal)
                    state.paymentMethodIsCashOnDelivery.removeValue(forKey: trimmedOriginal)
                } else if !state.items.contains(trimmedNew) {
                    var updated = state.items
                    updated.append(trimmedNew)
                    state.items = updated.sorted {
                        $0.localizedStandardCompare($1) == .orderedAscending
                    }
                }
                // 編輯為權威設定：直接以使用者實際勾選覆寫旗標 (允許取消勾選)
                state.paymentMethodIsCardless[trimmedNew] = isCardless
                state.paymentMethodIsBankTransfer[trimmedNew] = isBankTransfer
                state.paymentMethodIsCashOnDelivery[trimmedNew] = isCashOnDelivery

                let paymentMethodRepository = paymentMethodRepository
                let orderRepository = orderRepository
                return .run { _ in
                    if didRename {
                        try await paymentMethodRepository.renamePaymentMethod(trimmedOriginal, trimmedNew)
                        try await orderRepository.renameOrderPaymentMethod(trimmedOriginal, trimmedNew)
                    }
                    // rename 會合併保留舊旗標；最後以使用者選擇權威覆寫，確保可取消勾選。必須在 rename 之後執行
                    try await paymentMethodRepository.addPaymentMethod(trimmedNew, isCardless, isBankTransfer, isCashOnDelivery)
                } catch: { _, send in
                    await send(.loadFailed("編輯失敗，請稍後再試。"))
                }

            case .destination(.presented(.rename(.saveButtonTapped))):
                // ifLet 已先跑過 rename 子 reducer，此刻 destination 仍持有草稿，取出後才 dismiss
                guard let renameState = state.destination?.rename, renameState.canSave else {
                    return .none
                }
                state.destination = nil
                return .send(.renameRequested(from: renameState.originalName, to: renameState.draft))

            case let .destination(.presented(.editPaymentMethod(.saveButtonTapped(name, isCardless, isBankTransfer, isCashOnDelivery)))):
                guard let editState = state.destination?.editPaymentMethod else {
                    return .none
                }
                state.destination = nil
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
    }
}

// MARK: - Private Method

private extension LookupManagementFeature {

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
                    let items = try await reconciliationStatusRepository.fetchReconciliationStatuses()
                    await send(.reconciliationStatusItemsLoaded(items))
                }
            } catch {
                await send(.loadFailed("主檔載入失敗，請稍後再試。"))
            }
        }
    }
}
