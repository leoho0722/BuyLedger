//
//  PaymentMethodCorrectionFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/24.
//

import ComposableArchitecture
import Foundation

/// 找出引用原付款方式的訂單、要求確認並一起寫入更正結果 (全部成功或全部不動)
@Reducer
struct PaymentMethodCorrectionFeature {

    // MARK: - State

    /// 付款方式更正流程的待確認資料
    @ObservableState
    struct State: Equatable {

        /// 目前共用的付款方式目錄
        @Shared(.lookupCatalog) var catalog: LookupCatalog

        /// 等待使用者確認的更正資料
        var pendingPlan: PaymentMethodEditPlan?
    }

    // MARK: - Action

    /// 付款方式更正流程可處理的事件
    enum Action {

        /// 交給主檔管理的更正結果
        ///
        /// - Parameter delegate: 需要確認、已完成或失敗
        case delegate(Delegate)

        /// 使用者取消回溯更正
        case cancelled

        /// 使用者確認回溯更正
        case confirmed

        /// 一起寫入付款方式與訂單的結果 (全部成功或全部不動)
        ///
        /// - Parameter result: 已寫入的更正資料或寫入錯誤
        case editResponse(Result<PaymentMethodEditPlan, PaymentMethodPersistenceError>)

        /// 找出引用原付款方式的訂單後回傳的結果
        ///
        /// - Parameter result: 更正資料或讀取錯誤
        case planResponse(Result<PaymentMethodEditPlan, PersistenceError>)

        /// 使用者送出付款方式更正資料
        ///
        /// - Parameters:
        ///   - originalName: 尚未更改的付款方式名稱
        ///   - newName: 使用者輸入的新名稱
        ///   - flags: 使用者選定的付款方式分類旗標
        case requested(
            originalName: String,
            newName: String,
            flags: PaymentMethodFlags
        )

        /// 交給主檔管理的更正結果
        @CasePathable
        enum Delegate: Equatable {

            /// 更正會影響既有訂單，需要顯示確認提示
            ///
            /// - Parameter affectedOrderCount: 需要重新計算的訂單筆數
            case confirmationRequired(affectedOrderCount: Int)

            /// 付款方式與受影響訂單已一起寫入 (全部成功或全部不動)
            ///
            /// - Parameter plan: 寫入完成的更正資料
            case edited(PaymentMethodEditPlan)

            /// 找出引用原付款方式的訂單或一起寫入時失敗
            case failed
        }
    }

    // MARK: - Dependencies

    /// 讀取目前訂單以建立更正資料
    @Dependency(OrderRepository.self) private var orderRepository

    /// 一次寫入付款方式與受影響訂單
    @Dependency(PaymentMethodRepository.self) private var paymentMethodRepository

    // MARK: - Body

    /// 只組合 reducer，更正流程由 `core(state:action:)` 處理
    var body: some Reducer<State, Action> {
        Reduce(core)
    }
}

// MARK: - Private Method

private extension PaymentMethodCorrectionFeature {

    /// 依收到的事件更新更正流程狀態並回傳後續效果
    ///
    /// - Parameters:
    ///   - state: 目前的更正流程狀態
    ///   - action: 這次收到的更正事件
    /// - Returns: 接下來要執行的效果，沒有就回傳 `.none`
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .delegate:
            return .none

        case .cancelled:
            state.pendingPlan = nil
            return .none

        case .confirmed:
            guard let plan = state.pendingPlan else {
                return .none
            }
            state.pendingPlan = nil
            return write(plan: plan)

        case let .editResponse(.success(plan)):
            return .send(.delegate(.edited(plan)))

        case .editResponse(.failure):
            return .send(.delegate(.failed))

        case let .planResponse(.success(plan)):
            if plan.affectedOrders.isEmpty || !plan.hasChangedFlags {
                return write(plan: plan)
            }
            state.pendingPlan = plan
            return .send(
                .delegate(
                    .confirmationRequired(affectedOrderCount: plan.affectedOrders.count)
                )
            )

        case .planResponse(.failure):
            return .send(.delegate(.failed))

        case let .requested(originalName, newName, flags):
            let currentFlags = state.catalog.paymentMethodFlags(named: originalName)
            let hasChangedFlags = currentFlags != flags
            return preparePlan(
                originalName: originalName,
                newName: newName,
                flags: flags,
                hasChangedFlags: hasChangedFlags
            )
        }
    }

    /// 一起寫入付款方式與已正規化的受影響訂單 (全部成功或全部不動)
    ///
    /// - Parameter plan: 付款方式與訂單的固定更正資料
    /// - Returns: 寫入完成後送回結果的效果
    func write(plan: PaymentMethodEditPlan) -> Effect<Action> {
        let paymentMethodRepository = paymentMethodRepository
        return .run { send in
            do throws(PaymentMethodPersistenceError) {
                try await paymentMethodRepository.applyPaymentMethodEdit(
                    plan.originalName,
                    plan.newName,
                    plan.flags,
                    plan.affectedOrders
                )
                await send(.editResponse(.success(plan)))
            } catch {
                await send(.editResponse(.failure(error)))
            }
        }
    }

    /// 找出引用原付款方式的訂單並正規化
    ///
    /// - Parameters:
    ///   - originalName: 尚未更改的付款方式名稱
    ///   - newName: 使用者輸入的新名稱
    ///   - flags: 使用者選定的付款方式分類旗標
    ///   - hasChangedFlags: 付款方式分類旗標是否與目錄不同
    /// - Returns: 找出相關訂單後送回更正資料或讀取錯誤的效果
    func preparePlan(
        originalName: String,
        newName: String,
        flags: PaymentMethodFlags,
        hasChangedFlags: Bool
    ) -> Effect<Action> {
        let orderRepository = orderRepository
        return .run { send in
            do throws(PersistenceError) {
                let orders = try await orderRepository.fetchOrders()
                let affectedOrders = orders
                    .filter { order in order.paymentMethod == originalName }
                    .map { order in
                        order
                            .renamingPaymentMethod(to: newName)
                            .applyingPaymentMethodFlags(flags)
                    }
                let plan = PaymentMethodEditPlan(
                    originalName: originalName,
                    newName: newName,
                    flags: flags,
                    hasChangedFlags: hasChangedFlags,
                    affectedOrders: affectedOrders
                )
                await send(.planResponse(.success(plan)))
            } catch {
                await send(.planResponse(.failure(error)))
            }
        }
    }
}
