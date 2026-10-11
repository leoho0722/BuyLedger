//
//  OrderWriteOperations.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture

/// 以 reducer 已解析的服務建立寫入效果，不持有或更新共用狀態
struct OrderWriteOperations: Sendable {

    // MARK: - Properties

    /// 訂單持久化入口
    let orderService: OrderService

    /// 訂單來源持久化入口
    let orderSourceService: OrderSourceService

    /// 商品類別持久化入口
    let categoryService: CategoryService

    /// 付款方式持久化入口
    let paymentMethodService: PaymentMethodService

    /// 對帳狀態持久化入口
    let reconciliationStatusService: ReconciliationStatusService
}

// MARK: - Nested Types

extension OrderWriteOperations {

    /// 各操作交給容器呈現的原因
    enum Failure: Equatable, Sendable {

        /// 草稿儲存失敗
        case save

        /// 單筆狀態寫入失敗
        case status

        /// 批次狀態寫入失敗
        case batchStatus

        /// 收款狀態寫入失敗
        case receipt

        /// 刪除訂單失敗
        case delete

        /// 合併寫入失敗，已於寫入子層回復快照
        case merge

        /// 新增主檔失敗
        ///
        /// - Parameter kind: 新增失敗的主檔種類
        case option(LookupKind)

        /// 已合併狀態只能由合併流程寫入
        case mergedStatusRejected

        /// 供容器呈現的既有本地化失敗訊息
        var message: String {
            switch self {
            case .save:
                return "orders.general.message.orderSavedTry"

            case .status, .mergedStatusRejected:
                return "orders.general.message.orderStatusUpdated"

            case .batchStatus:
                return "orders.general.message.batchStatusUpdate"

            case .receipt:
                return "orders.general.message.receiptStatusUpdated"

            case .delete:
                return "orders.general.message.orderDeletedTry"

            case .merge:
                return "orders.general.message.mergedOrderSaved"

            case .option(.orderSource):
                return "orders.general.message.orderSourceAdded"

            case .option(.category):
                return "orders.general.message.categoryAddedTry"

            case .option(.paymentMethod):
                return "orders.general.message.paymentMethodAdded"

            case .option(.reconciliationStatus):
                return "orders.general.message.reconciliationStatusAdded"
            }
        }
    }

    /// 執行指定值的持久化寫入
    typealias WriteOperation<Value: Sendable> = @Sendable (
        Value
    ) async throws(PersistenceError) -> Void
}

// MARK: - Internal Method

extension OrderWriteOperations {

    /// 寫入批次狀態變更；含已合併訂單時整批拒絕，沒有訂單時不寫入
    ///
    /// - Parameter orders: 批次狀態變更的訂單快照
    /// - Returns: 批次寫入的效果，或交給容器的拒絕結果
    func writeBatchStatus(_ orders: [LedgerOrder]) -> Effect<OrderWritesFeature.Action> {
        guard !orders.contains(where: { $0.status == .merged }) else {
            return .send(.delegate(.failed(.mergedStatusRejected)))
        }
        guard !orders.isEmpty else {
            return .none
        }
        return write(
            orders,
            operation: orderService.saveOrders,
            response: OrderWritesFeature.Action.batchStatusResponse
        )
    }

    /// 依主檔種類呼叫對應服務，成功與失敗都保留表單識別值
    ///
    /// - Parameter plan: 已整理名稱且保留付款方式旗標的新增請求
    /// - Returns: 保留原請求的單一回應
    func addOption(_ plan: OrderOptionWritePlan) -> Effect<OrderWritesFeature.Action> {
        .run { send in
            do throws(PersistenceError) {
                switch plan.kind {
                case .orderSource:
                    try await orderSourceService.addOrderSource(plan.name)

                case .category:
                    try await categoryService.addCategory(plan.name)

                case .paymentMethod:
                    try await paymentMethodService.addPaymentMethod(plan.name, plan.flags)

                case .reconciliationStatus:
                    try await reconciliationStatusService.addReconciliationStatus(plan.name)
                }
                await send(.optionResponse(plan: plan, result: .success(())))
            } catch {
                await send(.optionResponse(plan: plan, result: .failure(error)))
            }
        }
    }

    /// 一次寫入合併結果與來源狀態，快照原樣交回 reducer
    ///
    /// - Parameter plan: 合併結果與回滾快照
    /// - Returns: 保留合併計畫的單一回應
    func merge(_ plan: OrderMergeSavePlan) -> Effect<OrderWritesFeature.Action> {
        .run { send in
            do throws(OrderPersistenceError) {
                try await orderService.mergeOrders(plan.order, plan.sourceIDs)
                await send(.mergeResponse(plan: plan, result: .success(())))
            } catch {
                await send(.mergeResponse(plan: plan, result: .failure(error)))
            }
        }
    }

    /// 依建立、更新與照片意圖寫入訂單
    ///
    /// - Parameter result: reducer 解析後的寫入意圖
    /// - Returns: 一次存檔回應
    func save(_ result: OrderDraft.WriteResult) -> Effect<OrderWritesFeature.Action> {
        write(
            result,
            operation: { result throws(PersistenceError) in
                if result.isNewOrder {
                    do throws(OrderPersistenceError) {
                        try await orderService.createOrder(result.order)
                    } catch {
                        throw .saveFailed(underlying: error)
                    }
                } else if result.shouldWritePhotos {
                    try await orderService.saveOrderPersistingPhotos(result.order)
                } else {
                    try await orderService.saveOrder(result.order)
                }
            },
            response: OrderWritesFeature.Action.saveResponse
        )
    }

    /// 寫入單筆訂單的新狀態；拒絕直接設為已合併，狀態沒有變更時不寫入
    ///
    /// - Parameters:
    ///   - id: 訂單編號
    ///   - status: 目標狀態
    ///   - orders: 共用訂單快照，用來找出要寫入的訂單
    /// - Returns: 單筆寫入的效果，或交給容器的拒絕結果
    func writeStatus(
        _ id: LedgerOrder.ID,
        status: OrderStatus,
        orders: [LedgerOrder]
    ) -> Effect<OrderWritesFeature.Action> {
        guard status != .merged else {
            return .send(.delegate(.failed(.mergedStatusRejected)))
        }
        guard let order = orders.first(where: { $0.id == id }),
              order.status != status else {
            return .none
        }
        return write(
            order.withStatus(status),
            operation: orderService.saveOrder,
            response: OrderWritesFeature.Action.statusResponse
        )
    }

    /// 將每次持久化成功與失敗包成同一種回應
    ///
    /// - Parameters:
    ///   - value: 待寫入的快照或識別值
    ///   - operation: 此次持久化入口
    ///   - response: 操作專屬的結果事件
    /// - Returns: 只送出一次回應的寫入效果
    func write<Value: Sendable>(
        _ value: Value,
        operation: @escaping WriteOperation<Value>,
        response: @escaping @Sendable (Result<Value, PersistenceError>) -> OrderWritesFeature.Action
    ) -> Effect<OrderWritesFeature.Action> {
        .run { send in
            do throws(PersistenceError) {
                try await operation(value)
                await send(response(.success(value)))
            } catch {
                await send(response(.failure(error)))
            }
        }
    }
}
