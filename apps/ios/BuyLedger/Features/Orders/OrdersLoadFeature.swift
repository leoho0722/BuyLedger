//
//  OrdersLoadFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture

/// 只讀取訂單，提供容器與畫面共用的載入狀態
@Reducer
struct OrdersLoadFeature {

    // MARK: - State

    /// 訂單與載入狀態的共用來源
    @ObservableState
    struct State: Equatable {

        /// 與容器共用的訂單資料
        @Shared var orders: [LedgerOrder]

        /// 是否正在讀取訂單
        @Shared var isLoading: Bool

        /// 是否已成功讀取訂單
        @Shared var hasLoaded: Bool

        /// 持續顯示的訂單讀取失敗訊息
        @Shared var errorMessage: String?

        /// 建立訂單引用與獨立的載入狀態
        ///
        /// - Parameter orders: 容器持有的訂單引用
        init(orders: Shared<[LedgerOrder]>) {
            self._orders = orders
            self._isLoading = Shared(value: false)
            self._hasLoaded = Shared(value: false)
            self._errorMessage = Shared(value: nil)
        }
    }

    // MARK: - Action

    /// 父層的載入請求、完整讀取結果與失敗委派
    enum Action {

        /// 交給容器處理的讀取失敗
        ///
        /// - Parameter delegate: 載入流程的失敗結果
        case delegate(Delegate)

        /// 父層要求載入，載入中或已載入時略過
        case loadRequested

        /// 一次載入請求的訂單讀取結果
        ///
        /// - Parameter outcome: 訂單清單或讀取失敗
        case loadResponse(Outcome)

        /// 載入流程需要容器處理的結果
        @CasePathable
        enum Delegate: Equatable {

            /// 訂單載入失敗，共用狀態已保留失敗訊息
            case loadFailed
        }
    }

    // MARK: - Dependencies

    /// 訂單清單的讀取入口
    @Dependency(\.orderService) private var orderService

    // MARK: - Body

    /// 組合載入請求與讀取回應的處理
    var body: some ReducerOf<Self> {
        Reduce(core)
    }
}

// MARK: - Nested Types

extension OrdersLoadFeature {

    /// 一次訂單讀取的成功或失敗結果
    struct Outcome: Sendable {

        /// 訂單清單或讀取失敗
        let orders: Result<[LedgerOrder], PersistenceError>
    }
}

// MARK: - Private Method

private extension OrdersLoadFeature {

    /// 去重載入請求，並在 reducer 內套用讀取結果
    ///
    /// - Parameters:
    ///   - state: 訂單與載入狀態
    ///   - action: 父層請求或讀取結果
    /// - Returns: 讀取效果或交給容器的失敗委派
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .delegate:
            return .none

        case .loadRequested:
            guard !state.isLoading, !state.hasLoaded else {
                return .none
            }
            state.$isLoading.withLock {
                $0 = true
            }
            state.$errorMessage.withLock {
                $0 = nil
            }
            return load()

        case .loadResponse(let outcome):
            return apply(outcome, state: &state)
        }
    }

    /// 讀取訂單，完成後只送出一次成功或失敗回應
    ///
    /// - Returns: 帶有訂單讀取結果的載入效果
    func load() -> Effect<Action> {
        let orderService = orderService
        return .run { send in
            let orders: Result<[LedgerOrder], PersistenceError>
            do throws(PersistenceError) {
                orders = .success(try await orderService.fetchOrders())
            } catch {
                orders = .failure(error)
            }
            await send(.loadResponse(Outcome(orders: orders)))
        }
    }

    /// 套用訂單讀取結果，失敗時保留原訂單並允許下一次請求
    ///
    /// - Parameters:
    ///   - outcome: 訂單讀取結果
    ///   - state: 接收結果的共用資料與旗標
    /// - Returns: 訂單失敗時送出委派，成功時沒有後續效果
    func apply(_ outcome: Outcome, state: inout State) -> Effect<Action> {
        state.$isLoading.withLock {
            $0 = false
        }
        switch outcome.orders {
        case .success(let orders):
            state.$hasLoaded.withLock {
                $0 = true
            }
            state.$orders.withLock {
                $0 = orders
            }
            return .none

        case .failure:
            state.$hasLoaded.withLock {
                $0 = false
            }
            state.$errorMessage.withLock {
                $0 = "orders.general.message.ordersLoadedTry"
            }
            return .send(.delegate(.loadFailed))
        }
    }
}
