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
/// 以 ``LookupKind`` 切換要操作的 repository 與顯示文案，使同一份 reducer/view 可同時服務兩種主檔。付款方式主檔額外維護 ``State/paymentMethodIsCardless`` 對應表，供 view 端在 List 中顯示「無卡」標籤；`isCardless` 的設定發生在使用者新增付款方式的當下（``Action/addConfirmed(name:isCardless:)``），不再於 List row 提供切換 toggle，以避免 UX 上不易理解。
@Reducer
struct LookupManagementFeature {

    // MARK: - State

    /// 主檔管理畫面狀態。
    @ObservableState
    struct State: Equatable {

        /// 此狀態管理的主檔型別。
        let kind: LookupKind

        /// 目前的主檔項目（已排序）。
        var items: [String] = []

        /// 付款方式主檔的 `isCardless` 對應表；只有 `kind == .paymentMethod` 時有意義。
        ///
        /// 以名稱為 key 的 dictionary，缺值視為 `false`。View 對 paymentMethod kind 會在 row 上顯示「無卡」標籤，但不再提供切換 toggle；要更新此旗標只能透過刪除後重新新增。
        var paymentMethodIsCardless: [String: Bool] = [:]

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

        /// 商品類別主檔載入成功。
        case categoryItemsLoaded([String])

        /// 付款方式主檔載入成功（含 `isCardless`）。
        case paymentMethodInfosLoaded([PaymentMethodInfo])

        /// 主檔載入失敗。
        case loadFailed(String)

        /// 使用者透過「新增」流程確認新增一筆主檔項目；對商品類別 kind，`isCardless` 永遠為 `false` 並被忽略。
        case addConfirmed(name: String, isCardless: Bool)

        /// 使用者要求刪除指定名稱的主檔項目。
        case deleteRequested(String)

        /// 使用者要求把指定名稱改成新名稱；同時 cascade 到所有引用該名稱的訂單。
        case renameRequested(from: String, to: String)
    }

    // MARK: - Dependency Properties

    /// 商品類別資料來源。
    @Dependency(CategoryRepository.self) private var categoryRepository

    /// 付款方式資料來源。
    @Dependency(PaymentMethodRepository.self) private var paymentMethodRepository

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

            case let .categoryItemsLoaded(items):
                state.items = items
                state.hasLoaded = true
                state.errorMessage = nil
                return .none

            case let .paymentMethodInfosLoaded(infos):
                state.items = infos.map(\.name)
                    .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
                var map: [String: Bool] = [:]
                for info in infos {
                    map[info.name] = info.isCardless
                }
                state.paymentMethodIsCardless = map
                state.hasLoaded = true
                state.errorMessage = nil
                return .none

            case let .loadFailed(message):
                state.errorMessage = message
                return .none

            case let .addConfirmed(name, isCardless):
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
                    // 重新觸發同名新增等同於「重新套用 isCardless」，方便使用者上次忘了勾選無卡時更正。
                    state.paymentMethodIsCardless[trimmed] = isCardless
                }

                let kind = state.kind
                let categoryRepository = categoryRepository
                let paymentMethodRepository = paymentMethodRepository
                return .run { _ in
                    switch kind {
                    case .category:
                        try? await categoryRepository.addCategory(trimmed)
                    case .paymentMethod:
                        try? await paymentMethodRepository.addPaymentMethod(trimmed, isCardless)
                    }
                }

            case let .deleteRequested(name):
                state.items.removeAll { $0 == name }
                state.paymentMethodIsCardless.removeValue(forKey: name)

                let kind = state.kind
                let categoryRepository = categoryRepository
                let paymentMethodRepository = paymentMethodRepository
                return .run { _ in
                    switch kind {
                    case .category:
                        try? await categoryRepository.removeCategory(name)
                    case .paymentMethod:
                        try? await paymentMethodRepository.removePaymentMethod(name)
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

                if state.kind == .paymentMethod,
                   let oldFlag = state.paymentMethodIsCardless.removeValue(forKey: trimmedFrom) {
                    // 合併：任一邊曾標記為無卡就維持無卡。
                    let mergedFlag = oldFlag || (state.paymentMethodIsCardless[trimmedTo] ?? false)
                    state.paymentMethodIsCardless[trimmedTo] = mergedFlag
                }

                let kind = state.kind
                let categoryRepository = categoryRepository
                let paymentMethodRepository = paymentMethodRepository
                let orderRepository = orderRepository
                return .run { _ in
                    switch kind {
                    case .category:
                        try? await categoryRepository.renameCategory(trimmedFrom, trimmedTo)
                        try? await orderRepository.renameOrderCategory(trimmedFrom, trimmedTo)
                    case .paymentMethod:
                        try? await paymentMethodRepository.renamePaymentMethod(trimmedFrom, trimmedTo)
                        try? await orderRepository.renameOrderPaymentMethod(trimmedFrom, trimmedTo)
                    }
                }
            }
        }
    }

    // MARK: - Private Method

    /// 依 ``LookupKind`` 選擇對應 repository 觸發 fetch。
    /// - Parameter kind: 要載入的主檔型別。
    /// - Returns: 對應 effect。
    private func load(kind: LookupKind) -> Effect<Action> {
        let categoryRepository = categoryRepository
        let paymentMethodRepository = paymentMethodRepository
        return .run { send in
            do {
                switch kind {
                case .category:
                    let items = try await categoryRepository.fetchCategories()
                    await send(.categoryItemsLoaded(items))
                case .paymentMethod:
                    let infos = try await paymentMethodRepository.fetchPaymentMethodInfos()
                    await send(.paymentMethodInfosLoaded(infos))
                }
            } catch {
                await send(.loadFailed("主檔載入失敗，請稍後再試。"))
            }
        }
    }
}
