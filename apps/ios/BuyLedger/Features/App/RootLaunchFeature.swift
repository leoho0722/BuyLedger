//
//  RootLaunchFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import OSLog

/// 啟動時載入共用幣別清單，並把系統重大時間變更交給根功能
@Reducer
struct RootLaunchFeature {

    // MARK: - State

    /// 啟動載入功能狀態
    @ObservableState
    struct State: Equatable {

        /// 啟動時從快取載入的記憶體內共用幣別清單
        @Shared(.currencyCodes) var currencyCodes: [CurrencyCode]
    }

    // MARK: - Action

    /// 啟動載入功能可處理的事件
    enum Action {

        /// 交給根功能處理的結果
        ///
        /// - Parameter delegate: 需要根功能處理的事件
        case delegate(Delegate)

        /// 啟動時讀取幣別快取的結果
        ///
        /// - Parameter outcome: 快取中的幣別清單或讀取失敗原因
        case currencyCodesResponse(Result<[CurrencyCode], CurrencyMetadataServiceError>)

        /// 根功能於 `view(.task)` 時送出，開始載入幣別並監聽時間變更
        case loadRequested

        /// 需要根功能處理的事件
        @CasePathable
        enum Delegate: Equatable {

            /// 系統回報重大時間變更，根功能需重寫日期脈絡
            case significantTimeChanged
        }
    }

    // MARK: - Dependencies

    /// 幣別清單的來源；App 啟動時向 ExchangeRate-API 的 `/codes` 下載，保存 7 天
    @Dependency(\.currencyMetadataService) private var currencyMetadataService

    /// 監聽系統重大時間變更，以刷新開團日期標題
    @Dependency(\.significantTimeChangeService) private var significantTimeChangeService

    // MARK: - Body

    /// 只負責組合 reducer，本功能自己的邏輯在 `core(state:action:)`
    var body: some ReducerOf<Self> {
        Reduce(core)
    }
}

// MARK: - Private Method

private extension RootLaunchFeature {

    /// 依收到的事件更新啟動狀態，並回傳要執行的 Effect
    ///
    /// - Parameters:
    ///   - state: 目前的啟動狀態，直接就地修改
    ///   - action: 這次收到的事件
    /// - Returns: 接下來要執行的 Effect，沒有就回 `.none`
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .delegate:
            return .none

        case .currencyCodesResponse(.success(let codes)) where !codes.isEmpty:
            state.$currencyCodes.withLock {
                $0 = codes
            }
            return .none

        case .currencyCodesResponse:
            AppLogger.persistence.warning("幣別快取讀取失敗或沒有資料，保留共用清單")
            return .none

        case .loadRequested:
            return RootLaunchOperations(
                service: currencyMetadataService,
                timeChangeService: significantTimeChangeService
            )
            .start()
        }
    }
}
