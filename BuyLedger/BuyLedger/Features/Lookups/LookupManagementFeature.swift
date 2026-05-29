//
//  LookupManagementFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import ComposableArchitecture
import Foundation

/// 商品類別 / 付款方式主檔的獨立管理功能。
///
/// 以 ``LookupKind`` 切換要操作的 repository 與顯示文案，使同一份 reducer/view 可同時服務兩種主檔。付款方式主檔額外維護 ``State/paymentMethodIsCardless`` 對應表，供 view 端在 List 中顯示「無卡」標籤；`isCardless` 的設定發生在使用者新增付款方式的當下 (``Action/addConfirmed(name:isCardless:)``)，不再於 List row 提供切換 toggle，以避免 UX 上不易理解。
@Reducer
struct LookupManagementFeature {

    // MARK: - State

    /// 主檔管理畫面狀態。
    @ObservableState
    struct State: Equatable {

        /// 此狀態管理的主檔型別。
        let kind: LookupKind

        /// 目前的主檔項目 (已排序)。
        var items: [String] = []

        /// 付款方式主檔的 `isCardless` 對應表；只有 `kind == .paymentMethod` 時有意義。
        ///
        /// 以名稱為 key 的 dictionary，缺值視為 `false`。View 對 paymentMethod kind 會在 row 上顯示「無卡」標籤，但不再提供切換 toggle；要更新此旗標只能透過刪除後重新新增。
        var paymentMethodIsCardless: [String: Bool] = [:]

        /// 付款方式主檔的 `isBankTransfer` 對應表；只有 `kind == .paymentMethod` 時有意義。
        ///
        /// 以名稱為 key 的 dictionary，缺值視為 `false`。View 對 paymentMethod kind 會在 row 上顯示「銀行匯款」標籤；設定方式與 ``paymentMethodIsCardless`` 相同 (新增當下決定)。
        var paymentMethodIsBankTransfer: [String: Bool] = [:]

        /// 載入失敗訊息。
        var errorMessage: String?

        /// 是否已完成首次載入。
        var hasLoaded = false
    }

    // MARK: - Action

    /// 主檔管理可處理的事件。
    @CasePathable
    enum Action: Equatable {

        /// 畫面出現時觸發載入。
        case task

        /// 訂單來源主檔載入成功。
        case orderSourceItemsLoaded([String])

        /// 商品類別主檔載入成功。
        case categoryItemsLoaded([String])

        /// 付款方式主檔載入成功 (含 `isCardless` 與 `isBankTransfer`)。
        case paymentMethodInfosLoaded([PaymentMethodInfo])

        /// 對帳狀態主檔載入成功。
        case verificationStatusItemsLoaded([String])

        /// 主檔載入失敗。
        case loadFailed(String)

        /// 使用者透過「新增」流程確認新增一筆主檔項目；對付款方式以外的 kind，`isCardless` 與 `isBankTransfer` 永遠為 `false` 並被忽略。
        case addConfirmed(name: String, isCardless: Bool, isBankTransfer: Bool)

        /// 使用者要求刪除指定名稱的主檔項目。
        case deleteRequested(String)

        /// 使用者要求把指定名稱改成新名稱；同時 cascade 到所有引用該名稱的訂單。
        case renameRequested(from: String, to: String)

        /// 使用者透過「編輯」sheet 確認修改一筆付款方式 (名稱 + 旗標)；僅 `kind == .paymentMethod` 使用。
        ///
        /// 與 ``renameRequested`` + ``addConfirmed`` 分開送的差別：編輯為「權威設定」，名稱變更後會以使用者實際勾選的旗標覆寫，允許取消勾選 (`renameRequested` 的合併規則會把任一邊為 `true` 的旗標保留，無法取消)。
        case editConfirmed(originalName: String, name: String, isCardless: Bool, isBankTransfer: Bool)
    }

    // MARK: - Dependency Properties

    /// 訂單來源資料來源。
    @Dependency(OrderSourceRepository.self) private var orderSourceRepository

    /// 商品類別資料來源。
    @Dependency(CategoryRepository.self) private var categoryRepository

    /// 付款方式資料來源。
    @Dependency(PaymentMethodRepository.self) private var paymentMethodRepository

    /// 對帳狀態資料來源。
    @Dependency(VerificationStatusRepository.self) private var verificationStatusRepository

    /// 訂單資料來源；rename 時把 cascade 寫入訂單表。
    @Dependency(OrderRepository.self) private var orderRepository

    // MARK: - Reducer Body

    /// 主檔管理 reducer。
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                guard !state.hasLoaded else { return .none }
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
                for info in infos {
                    cardlessMap[info.name] = info.isCardless
                    bankTransferMap[info.name] = info.isBankTransfer
                }
                state.paymentMethodIsCardless = cardlessMap
                state.paymentMethodIsBankTransfer = bankTransferMap
                state.hasLoaded = true
                state.errorMessage = nil
                return .none

            case let .verificationStatusItemsLoaded(items):
                state.items = items
                state.hasLoaded = true
                state.errorMessage = nil
                return .none

            case let .loadFailed(message):
                state.errorMessage = message
                return .none

            case let .addConfirmed(name, isCardless, isBankTransfer):
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return .none }

                if !state.items.contains(trimmed) {
                    var updated = state.items
                    updated.append(trimmed)
                    state.items = updated.sorted {
                        $0.localizedStandardCompare($1) == .orderedAscending
                    }
                }

                if state.kind == .paymentMethod {
                    // 重新觸發同名新增等同於「重新套用 isCardless / isBankTransfer」，方便使用者上次忘了勾選時更正。
                    state.paymentMethodIsCardless[trimmed] = isCardless
                    state.paymentMethodIsBankTransfer[trimmed] = isBankTransfer
                }

                let kind = state.kind
                let orderSourceRepository = orderSourceRepository
                let categoryRepository = categoryRepository
                let paymentMethodRepository = paymentMethodRepository
                let verificationStatusRepository = verificationStatusRepository
                return .run { _ in
                    switch kind {
                    case .orderSource:
                        try? await orderSourceRepository.addOrderSource(trimmed)
                    case .category:
                        try? await categoryRepository.addCategory(trimmed)
                    case .paymentMethod:
                        try? await paymentMethodRepository.addPaymentMethod(trimmed, isCardless, isBankTransfer)
                    case .verificationStatus:
                        try? await verificationStatusRepository.addVerificationStatus(trimmed)
                    }
                }

            case let .deleteRequested(name):
                state.items.removeAll { $0 == name }
                state.paymentMethodIsCardless.removeValue(forKey: name)
                state.paymentMethodIsBankTransfer.removeValue(forKey: name)

                let kind = state.kind
                let orderSourceRepository = orderSourceRepository
                let categoryRepository = categoryRepository
                let paymentMethodRepository = paymentMethodRepository
                let verificationStatusRepository = verificationStatusRepository
                return .run { _ in
                    switch kind {
                    case .orderSource:
                        try? await orderSourceRepository.removeOrderSource(name)
                    case .category:
                        try? await categoryRepository.removeCategory(name)
                    case .paymentMethod:
                        try? await paymentMethodRepository.removePaymentMethod(name)
                    case .verificationStatus:
                        try? await verificationStatusRepository.removeVerificationStatus(name)
                    }
                }

            case let .renameRequested(from, to):
                let trimmedFrom = from.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedTo = to.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedFrom.isEmpty,
                      !trimmedTo.isEmpty,
                      trimmedFrom != trimmedTo else {
                    return .none
                }

                // 本地 state 同步更新：把舊名稱替換、去重後排序。
                var renamed = state.items.map { $0 == trimmedFrom ? trimmedTo : $0 }
                renamed = Array(Set(renamed))
                state.items = renamed.sorted {
                    $0.localizedStandardCompare($1) == .orderedAscending
                }

                if state.kind == .paymentMethod {
                    if let oldFlag = state.paymentMethodIsCardless.removeValue(forKey: trimmedFrom) {
                        // 合併：任一邊曾標記為無卡就維持無卡。
                        state.paymentMethodIsCardless[trimmedTo] = oldFlag || (state.paymentMethodIsCardless[trimmedTo] ?? false)
                    }
                    if let oldFlag = state.paymentMethodIsBankTransfer.removeValue(forKey: trimmedFrom) {
                        // 合併：任一邊曾標記為銀行匯款就維持銀行匯款。
                        state.paymentMethodIsBankTransfer[trimmedTo] = oldFlag || (state.paymentMethodIsBankTransfer[trimmedTo] ?? false)
                    }
                }

                let kind = state.kind
                let orderSourceRepository = orderSourceRepository
                let categoryRepository = categoryRepository
                let paymentMethodRepository = paymentMethodRepository
                let verificationStatusRepository = verificationStatusRepository
                let orderRepository = orderRepository
                return .run { _ in
                    switch kind {
                    case .orderSource:
                        try? await orderSourceRepository.renameOrderSource(trimmedFrom, trimmedTo)
                        try? await orderRepository.renameOrderSource(trimmedFrom, trimmedTo)
                    case .category:
                        try? await categoryRepository.renameCategory(trimmedFrom, trimmedTo)
                        try? await orderRepository.renameOrderCategory(trimmedFrom, trimmedTo)
                    case .paymentMethod:
                        try? await paymentMethodRepository.renamePaymentMethod(trimmedFrom, trimmedTo)
                        try? await orderRepository.renameOrderPaymentMethod(trimmedFrom, trimmedTo)
                    case .verificationStatus:
                        try? await verificationStatusRepository.renameVerificationStatus(trimmedFrom, trimmedTo)
                        try? await orderRepository.renameOrderVerificationStatus(trimmedFrom, trimmedTo)
                    }
                }

            case let .editConfirmed(originalName, rawName, isCardless, isBankTransfer):
                // 僅付款方式使用編輯流程；其他 kind 不會送此 action。
                guard state.kind == .paymentMethod else { return .none }
                let trimmedOriginal = originalName.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedNew = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedNew.isEmpty else { return .none }

                let didRename = trimmedNew != trimmedOriginal
                if didRename {
                    // 名稱變更：把舊名稱替換、去重後排序，並清掉舊名稱的旗標對應。
                    var renamed = state.items.map { $0 == trimmedOriginal ? trimmedNew : $0 }
                    renamed = Array(Set(renamed))
                    state.items = renamed.sorted {
                        $0.localizedStandardCompare($1) == .orderedAscending
                    }
                    state.paymentMethodIsCardless.removeValue(forKey: trimmedOriginal)
                    state.paymentMethodIsBankTransfer.removeValue(forKey: trimmedOriginal)
                } else if !state.items.contains(trimmedNew) {
                    var updated = state.items
                    updated.append(trimmedNew)
                    state.items = updated.sorted {
                        $0.localizedStandardCompare($1) == .orderedAscending
                    }
                }
                // 編輯為權威設定：直接以使用者實際勾選覆寫旗標 (允許取消勾選)。
                state.paymentMethodIsCardless[trimmedNew] = isCardless
                state.paymentMethodIsBankTransfer[trimmedNew] = isBankTransfer

                let paymentMethodRepository = paymentMethodRepository
                let orderRepository = orderRepository
                return .run { _ in
                    if didRename {
                        try? await paymentMethodRepository.renamePaymentMethod(trimmedOriginal, trimmedNew)
                        try? await orderRepository.renameOrderPaymentMethod(trimmedOriginal, trimmedNew)
                    }
                    // rename 會合併保留舊旗標；最後以使用者選擇權威覆寫，確保可取消勾選。必須在 rename 之後執行。
                    try? await paymentMethodRepository.addPaymentMethod(trimmedNew, isCardless, isBankTransfer)
                }
            }
        }
    }

    // MARK: - Private Method

    /// 依 ``LookupKind`` 選擇對應 repository 觸發 fetch。
    /// - Parameter kind: 要載入的主檔型別。
    /// - Returns: 對應 effect。
    private func load(kind: LookupKind) -> Effect<Action> {
        let orderSourceRepository = orderSourceRepository
        let categoryRepository = categoryRepository
        let paymentMethodRepository = paymentMethodRepository
        let verificationStatusRepository = verificationStatusRepository
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
                case .verificationStatus:
                    let items = try await verificationStatusRepository.fetchVerificationStatuses()
                    await send(.verificationStatusItemsLoaded(items))
                }
            } catch {
                await send(.loadFailed("主檔載入失敗，請稍後再試。"))
            }
        }
    }
}
