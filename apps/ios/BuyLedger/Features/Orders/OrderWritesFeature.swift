//
//  OrderWritesFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Foundation

/// 執行訂單寫入與交易後的調整，更新共用訂單，失敗交由容器呈現
@Reducer
struct OrderWritesFeature {

    // MARK: - State

    /// 與容器共用的訂單寫入狀態
    @ObservableState
    struct State: Equatable {

        /// 在成功回應或交易後的調整請求更新的訂單來源
        @Shared var orders: [LedgerOrder]

        /// 接收容器持有的訂單引用
        ///
        /// - Parameter orders: 共用訂單清單
        init(orders: Shared<[LedgerOrder]>) {
            self._orders = orders
        }
    }

    // MARK: - Action

    /// 父層請求、各操作的單一回應與交回容器的結果
    enum Action {

        /// 交回容器的呈現與選取意圖
        ///
        /// - Parameter action: 寫入結果
        case delegate(Delegate)

        /// 寫入已計算且有變更的批次訂單
        ///
        /// - Parameter orders: 批次狀態變更的訂單快照
        case batchStatusChangeRequested([LedgerOrder])

        /// 批次狀態寫入的唯一結果
        ///
        /// - Parameter result: 已寫入訂單清單或持久化失敗
        case batchStatusResponse(Result<[LedgerOrder], PersistenceError>)

        /// 套用開團或主檔交易完成後的訂單調整
        ///
        /// - Parameter request: 開團刪除、開團改名或主檔改名
        case cascadeRequested(OrdersCascadeOperations.Request)

        /// 刪除指定訂單
        ///
        /// - Parameter id: 訂單編號
        case deleteRequested(LedgerOrder.ID)

        /// 刪除寫入的唯一結果
        ///
        /// - Parameter result: 已刪除編號或持久化失敗
        case deleteResponse(Result<LedgerOrder.ID, PersistenceError>)

        /// 合併持久化的唯一結果，失敗時於 reducer 內回復快照
        ///
        /// - Parameters:
        ///   - plan: 合併結果與原訂單快照
        ///   - result: 合併交易成功或失敗
        case mergeResponse(plan: OrderMergeSavePlan, result: Result<Void, OrderError>)

        /// 套用主檔交易完成後的權威訂單快照，不重複落盤
        ///
        /// - Parameter orders: 已正規化的訂單
        case paymentMethodFlagsApplyRequested([LedgerOrder])

        /// 收款狀態寫入的唯一結果
        ///
        /// - Parameter result: 已寫入訂單或持久化失敗
        case receiptResponse(Result<LedgerOrder, PersistenceError>)

        /// 切換單筆收款狀態
        ///
        /// - Parameters:
        ///   - id: 訂單編號
        ///   - status: 目標收款狀態
        case receiptToggleRequested(id: LedgerOrder.ID, status: PaymentReceiptStatus)

        /// 依草稿解析出的建立、更新與照片意圖儲存
        ///
        /// - Parameter edit: 待寫入的表單快照，包含合併流程的來源編號與照片
        case saveRequested(OrderEditFeature.State)

        /// 草稿寫入的唯一結果
        ///
        /// - Parameter result: 寫入意圖與訂單，或持久化失敗
        case saveResponse(Result<OrderDraft.WriteResult, PersistenceError>)

        /// 改變單筆狀態，拒絕直接設為已合併
        ///
        /// - Parameters:
        ///   - id: 訂單編號
        ///   - status: 目標狀態
        case statusChangeRequested(id: LedgerOrder.ID, status: OrderStatus)

        /// 單筆狀態寫入的唯一結果
        ///
        /// - Parameter result: 已寫入訂單或持久化失敗
        case statusResponse(Result<LedgerOrder, PersistenceError>)

        /// 容器負責的寫入後續操作
        @CasePathable
        enum Delegate: Equatable {

            /// 請容器沿既有寫入失敗流程呈現
            ///
            /// - Parameter failure: 操作失敗或拒絕原因
            case failed(OrderWriteOperations.Failure)

            /// 儲存完成，請容器按建立意圖更新選取
            ///
            /// - Parameters:
            ///   - id: 已寫入訂單編號
            ///   - isNewOrder: 是否新建資料列
            case saved(id: LedgerOrder.ID, isNewOrder: Bool)

            /// 合併已樂觀更新，請容器同步詳情與選取
            ///
            /// - Parameter id: 新合併訂單編號
            case merged(id: LedgerOrder.ID)

            /// 刪除完成，請容器清理詳情與選取
            ///
            /// - Parameter id: 已刪除編號
            case deleted(LedgerOrder.ID)
        }
    }

    // MARK: - Dependencies

    /// 訂單持久化的寫入入口
    @Dependency(\.orderService) private var orderService

    /// 新訂單完整識別碼的來源
    @Dependency(\.uuid) private var uuid

    // MARK: - Body

    /// 組合寫入請求與回應處理
    var body: some ReducerOf<Self> {
        Reduce(core)
    }
}

// MARK: - Private Method

private extension OrderWritesFeature {

    /// 執行父層請求，在成功回應的同一次更新套用共用資料
    ///
    /// - Parameters:
    ///   - state: 共用訂單狀態
    ///   - action: 寫入請求、回應或委派
    /// - Returns: 持久化效果或交給容器的結果
    func core(state: inout State, action: Action) -> Effect<Action> {
        let operations = OrderWriteOperations(orderService: orderService)
        switch action {
        case .delegate:
            return .none

        case .batchStatusChangeRequested(let orders):
            return operations.writeBatchStatus(orders)

        case .batchStatusResponse(.success(let orders)):
            state.$orders.withLock {
                OrdersCascadeOperations.applyUpdates(orders, in: &$0)
            }
            return .none

        case .batchStatusResponse(.failure):
            return .send(.delegate(.failed(.batchStatus)))

        case .cascadeRequested(let request):
            state.$orders.withLock {
                OrdersCascadeOperations.apply(request, in: &$0)
            }
            return .none

        case .deleteRequested(let id):
            guard state.orders.contains(where: { $0.id == id }) else {
                return .none
            }
            return operations.write(
                id,
                operation: operations.orderService.removeOrder,
                response: Action.deleteResponse
            )

        case .deleteResponse(.success(let id)):
            guard let index = state.orders.firstIndex(where: { $0.id == id }) else {
                return .none
            }
            state.$orders.withLock {
                _ = $0.remove(at: index)
            }
            return .send(.delegate(.deleted(id)))

        case .deleteResponse(.failure):
            return .send(.delegate(.failed(.delete)))

        case .mergeResponse(_, .success):
            return .none

        case .mergeResponse(let plan, .failure):
            state.$orders.withLock { $0 = plan.previousOrders }
            return .send(.delegate(.failed(.merge)))

        case .paymentMethodFlagsApplyRequested(let orders):
            state.$orders.withLock {
                OrdersCascadeOperations.applyPaymentMethodFlags(orders, in: &$0)
            }
            return .none

        case .receiptResponse(.success(let order)):
            state.$orders.withLock {
                OrdersCascadeOperations.applyUpdates([order], in: &$0)
            }
            return .none

        case .receiptResponse(.failure):
            return .send(.delegate(.failed(.receipt)))

        case .receiptToggleRequested(let id, let status):
            guard let order = state.orders.first(where: { $0.id == id }),
                  order.paymentReceiptStatus != status else {
                return .none
            }
            return operations.write(
                order.withPaymentReceiptStatus(status),
                operation: operations.orderService.saveOrder,
                response: Action.receiptResponse
            )

        case .saveRequested(let edit):
            return saveDraft(edit, state: &state, operations: operations)

        case .saveResponse(.success(let result)):
            return applySavedDraft(result, state: &state)

        case .saveResponse(.failure):
            return .send(.delegate(.failed(.save)))

        case .statusChangeRequested(let id, let status):
            return operations.writeStatus(id, status: status, orders: state.orders)

        case .statusResponse(.success(let order)):
            state.$orders.withLock {
                OrdersCascadeOperations.applyUpdates([order], in: &$0)
            }
            return .none

        case .statusResponse(.failure):
            return .send(.delegate(.failed(.status)))
        }
    }

    /// 依草稿解析合併或儲存意圖並寫入；合併時先在共用訂單上套用結果再落盤
    ///
    /// - Parameters:
    ///   - edit: 待寫入的表單快照，包含合併流程的來源編號與照片
    ///   - state: 共用訂單狀態，合併時就地更新
    ///   - operations: 寫入操作入口
    /// - Returns: 寫入的 Effect；合併時先送出合併完成的委派
    func saveDraft(
        _ edit: OrderEditFeature.State,
        state: inout State,
        operations: OrderWriteOperations
    ) -> Effect<Action> {
        if !edit.mergeSourceIDs.isEmpty {
            let plan = OrderMergeSavePlan(edit: edit, orders: state.orders) {
                uuid().uuidString
            }
            state.$orders.withLock { $0 = plan.updatedOrders }
            return .concatenate(
                .send(.delegate(.merged(id: plan.order.id))),
                operations.merge(plan)
            )
        }
        let result = OrderDraft.resolveWriteResult(edit, existingOrders: state.orders) {
            uuid().uuidString
        }
        return operations.save(result)
    }

    /// 寫入成功後把結果套用到共用訂單，新建的訂單放在最前面
    ///
    /// - Parameters:
    ///   - result: 寫入意圖與已儲存的訂單
    ///   - state: 共用訂單狀態，就地更新
    /// - Returns: 交給容器的儲存完成委派
    func applySavedDraft(_ result: OrderDraft.WriteResult, state: inout State) -> Effect<Action> {
        state.$orders.withLock {
            if result.isNewOrder {
                $0.insert(result.order, at: 0)
            } else if let index = $0.firstIndex(
                where: {
                    $0.id == result.order.id
                }
            ) {
                $0[index] = result.order
            }
        }
        return .send(.delegate(.saved(id: result.order.id, isNewOrder: result.isNewOrder)))
    }
}
