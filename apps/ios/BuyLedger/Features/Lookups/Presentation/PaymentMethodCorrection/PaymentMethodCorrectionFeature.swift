//
//  PaymentMethodCorrectionFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/24.
//

import ComposableArchitecture

/// 查出引用原付款方式的訂單筆數、要求確認並在交易內寫入更正結果
@Reducer
struct PaymentMethodCorrectionFeature {

    // MARK: - State

    /// 付款方式更正流程的待確認資料
    @ObservableState
    struct State: Equatable {

        /// 四種主檔共用的目錄；用來查原付款方式目前的旗標
        @Shared(.lookupCatalog) var catalog: LookupCatalog

        /// 等待使用者確認的更正請求
        var pendingRequest: Request?
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

        /// 讀取使用原付款方式的訂單筆數後回傳的結果
        ///
        /// - Parameters:
        ///   - request: 發出查詢的更正請求
        ///   - result: 訂單筆數或讀取錯誤
        case countResponse(request: Request, result: Result<Int, PersistenceError>)

        /// 一起寫入付款方式與訂單的結果
        ///
        /// - Parameter result: 已寫入的更正資料或寫入錯誤
        case editResponse(Result<PaymentMethodEditPlan, PersistenceError>)

        /// 使用者送出付款方式更正資料
        ///
        /// - Parameters:
        ///   - originalName: 尚未更改的付款方式名稱
        ///   - newName: 使用者輸入的新名稱
        ///   - flags: 使用者選定的付款方式分類旗標
        case requested(originalName: String, newName: String, flags: PaymentMethodFlags)

        /// 交給主檔管理的更正結果
        @CasePathable
        enum Delegate: Equatable {

            /// 更正會影響既有訂單，需要顯示確認提示
            ///
            /// - Parameter affectedOrderCount: 需要重新計算的訂單筆數
            case confirmationRequired(affectedOrderCount: Int)

            /// 付款方式與受影響訂單已在交易內一起寫入
            ///
            /// - Parameter plan: 寫入完成的更正資料
            case edited(PaymentMethodEditPlan)

            /// 查詢引用原付款方式的訂單筆數或寫入更正時失敗
            case failed
        }
    }

    // MARK: - Dependencies

    /// 主檔與引用訂單的資料庫操作入口
    @Dependency(\.lookupService) private var lookupService

    // MARK: - Body

    /// 只組合 reducer，更正流程由 `core(state:action:)` 處理
    var body: some ReducerOf<Self> {
        Reduce(core)
    }
}

// MARK: - Nested Types

extension PaymentMethodCorrectionFeature {

    /// 付款方式更正的請求資料
    struct Request: Equatable, Sendable {

        /// 原付款方式名稱
        let originalName: String

        /// 新付款方式名稱
        let newName: String

        /// 使用者選定的分類旗標
        let flags: PaymentMethodFlags

        /// 旗標是否變更；只改名時不需確認
        let hasChangedFlags: Bool
    }
}

// MARK: - Private Method

private extension PaymentMethodCorrectionFeature {

    /// 處理更正流程事件，更新待確認資料並啟動相應操作
    ///
    /// - Parameters:
    ///   - state: 目前的更正流程狀態
    ///   - action: 這次收到的更正事件
    /// - Returns: 接續流程需要的操作，沒有時不再執行操作
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .delegate:
            return .none

        case .cancelled:
            state.pendingRequest = nil
            return .none

        case .confirmed:
            guard let request = state.pendingRequest else {
                return .none
            }
            state.pendingRequest = nil
            return write(request: request)

        case .countResponse(let request, .success(let count)):
            if count == 0 {
                return write(request: request)
            }
            state.pendingRequest = request
            return .send(.delegate(.confirmationRequired(affectedOrderCount: count)))

        case .countResponse(_, .failure):
            return .send(.delegate(.failed))

        case .editResponse(.success(let plan)):
            return .send(.delegate(.edited(plan)))

        case .editResponse(.failure):
            return .send(.delegate(.failed))

        case .requested(let originalName, let newName, let flags):
            let currentFlags = state.catalog.paymentMethodFlags(named: originalName)
            let hasChangedFlags = currentFlags != flags
            let request = Request(
                originalName: originalName,
                newName: newName,
                flags: flags,
                hasChangedFlags: hasChangedFlags
            )
            return startCorrection(request)
        }
    }

    /// 在交易內寫入付款方式與重算受影響訂單
    ///
    /// - Parameter request: 要寫入的更正請求
    /// - Returns: 寫入成功或失敗後送回結果
    func write(request: Request) -> Effect<Action> {
        let lookupService = lookupService
        return .run { send in
            do throws(PersistenceError) {
                let affectedOrders = try await lookupService.applyPaymentMethodEdit(
                    request.originalName,
                    request.newName,
                    request.flags
                )
                let plan = PaymentMethodEditPlan(
                    originalName: request.originalName,
                    newName: request.newName,
                    flags: request.flags,
                    hasChangedFlags: request.hasChangedFlags,
                    affectedOrders: affectedOrders
                )
                await send(.editResponse(.success(plan)))
            } catch {
                await send(.editResponse(.failure(error)))
            }
        }
    }

    /// 查出受影響的訂單筆數；旗標沒有變更時直接寫入
    ///
    /// - Parameter request: 使用者送出的更正請求
    /// - Returns: 查詢或寫入的 Effect，結果分別送回 `countResponse` 與 `editResponse`
    func startCorrection(_ request: Request) -> Effect<Action> {
        guard request.hasChangedFlags else {
            return write(request: request)
        }
        let lookupService = lookupService
        return .run { send in
            do throws(PersistenceError) {
                let count = try await lookupService.countOrders(request.originalName)
                await send(.countResponse(request: request, result: .success(count)))
            } catch {
                await send(.countResponse(request: request, result: .failure(error)))
            }
        }
    }
}
