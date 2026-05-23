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
/// 以 ``LookupKind`` 切換要操作的 repository 與顯示文案，使同一份 reducer/view 可同時服務兩種主檔。
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

        /// 主檔載入成功。
        case itemsLoaded([String])

        /// 主檔載入失敗。
        case loadFailed(String)

        /// 使用者透過「新增」alert 確認新增一筆主檔項目。
        case addConfirmed(String)

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

            case let .itemsLoaded(items):
                state.items = items
                state.hasLoaded = true
                state.errorMessage = nil
                return .none

            case let .loadFailed(message):
                state.errorMessage = message
                return .none

            case let .addConfirmed(name):
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return .none }

                if !state.items.contains(trimmed) {
                    var updated = state.items
                    updated.append(trimmed)
                    state.items = updated.sorted {
                        $0.localizedStandardCompare($1) == .orderedAscending
                    }
                }

                let kind = state.kind
                let categoryRepository = categoryRepository
                let paymentMethodRepository = paymentMethodRepository
                return .run { _ in
                    switch kind {
                    case .category:
                        try? await categoryRepository.addCategory(trimmed)
                    case .paymentMethod:
                        try? await paymentMethodRepository.addPaymentMethod(trimmed)
                    }
                }

            case let .deleteRequested(name):
                state.items.removeAll { $0 == name }

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
                    await send(.itemsLoaded(items))
                case .paymentMethod:
                    let items = try await paymentMethodRepository.fetchPaymentMethods()
                    await send(.itemsLoaded(items))
                }
            } catch {
                await send(.loadFailed("主檔載入失敗，請稍後再試。"))
            }
        }
    }
}
