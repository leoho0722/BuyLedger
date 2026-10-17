//
//  RootLaunchOperations.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/7.
//

import ComposableArchitecture

/// 啟動時刷新幣別快取並監聽重大時間變更，結果交回啟動載入功能
struct RootLaunchOperations: Sendable {

    // MARK: - Properties

    /// 啟動載入功能注入的幣別快取操作入口
    let service: CurrencyMetadataService

    /// 啟動載入功能注入的重大時間變更監聽服務
    let timeChangeService: SignificantTimeChangeService
}

// MARK: - Internal Method

extension RootLaunchOperations {

    /// 同時啟動幣別載入與時間變更監聽兩個長效工作
    ///
    /// - Returns: 幣別讀取結果與時間變更委派共用的 Effect
    func start() -> Effect<RootLaunchFeature.Action> {
        .merge(loadCurrencyCodes(), observeSignificantTimeChanges())
    }
}

// MARK: - Private Method

private extension RootLaunchOperations {

    /// 以七天期限刷新幣別，再讀取一次快取並回報成功或失敗
    ///
    /// - Returns: 將幣別讀取結果送回啟動載入功能的工作
    func loadCurrencyCodes() -> Effect<RootLaunchFeature.Action> {
        .run { [service] send in
            _ = try? await service.refreshIfStale(604_800) // 失敗可忽略，因為仍可讀取既有快取
            let outcome: Result<[CurrencyCode], CurrencyMetadataServiceError>
            do throws(CurrencyMetadataServiceError) {
                outcome = .success(try await service.fetchCodes())
            } catch {
                outcome = .failure(error)
            }
            await send(.currencyCodesResponse(outcome))
        }
    }

    /// 監聽系統重大時間變更，每次變更都以委派交給啟動載入功能
    ///
    /// - Returns: 持續送出時間變更委派的工作
    func observeSignificantTimeChanges() -> Effect<RootLaunchFeature.Action> {
        .run { [timeChangeService] send in
            for await _ in timeChangeService.changes() {
                await send(.delegate(.significantTimeChanged))
            }
        }
    }
}
