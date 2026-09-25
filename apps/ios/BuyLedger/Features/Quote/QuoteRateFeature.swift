//
//  QuoteRateFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/23.
//

import ComposableArchitecture
import Foundation

/// 報價試算的匯率來源：載入匯率與幣別主檔，並持有來源幣別選擇流程
@Reducer
struct QuoteRateFeature {

    // MARK: - State

    /// 匯率來源狀態
    @ObservableState
    struct State: Equatable, Sendable {

        /// 來源幣別
        var fromCurrency: CurrencyCode = .krw

        /// 已從 API 取得的匯率快照；`nil` 代表尚未拉取或拉取失敗
        var snapshot: FxRateSnapshot?

        /// 是否正在載入匯率
        var isLoading: Bool = false

        /// 匯率載入失敗時顯示給使用者的訊息
        var errorMessage: LocalizedStringResource?

        /// 可供選擇的幣別清單；由 ``CurrencyMetadataRepository`` 提供
        var availableCurrencies: [CurrencyCode] = CurrencyCode.defaults

        /// 目前呈現中的幣別選擇流程；`nil` 表示未呈現
        @Presents var destination: Destination.State?

        /// 來源幣別對 TWD 的匯率；無資料時為 `0`
        var rate: Decimal {
            fromCurrency == .twd ? 1 : snapshot?.twdRate(for: fromCurrency) ?? 0
        }

        /// 是否有可用匯率資料
        var hasUsableRate: Bool {
            rate > 0
        }

        /// 匯率不可用時顯示的原因
        var rateUnavailableReason: LocalizedStringResource? {
            guard !isLoading, !hasUsableRate else {
                return nil
            }
            return errorMessage ?? "尚無可用匯率資料，暫時無法試算。"
        }
    }

    // MARK: - Action

    /// 匯率來源事件
    ///
    /// 本 Feature 沒有自己的 View，事件一律由 ``QuoteFeature`` 轉送，因此不設 `view` 分組
    @CasePathable
    enum Action {

        /// 畫面出現時載入匯率與幣別清單
        case task

        /// 重新載入匯率
        case refreshRequested

        /// 開啟幣別選擇 sheet
        case pickerTapped

        /// 選定來源幣別
        ///
        /// - Parameter code: 使用者選定的 ISO code 字串
        case currencySelected(String)

        /// 幣別選擇流程事件
        ///
        /// - Parameter action: 目前呈現中的目的地事件
        case destination(PresentationAction<Destination.Action>)

        /// 幣別主檔載入結果
        ///
        /// - Parameter result: 幣別主檔載入成功或失敗的結果
        case currencyCodesResponse(Result<[CurrencyCode], CurrencyMetadataRepositoryError>)

        /// 匯率載入結果
        ///
        /// - Parameter result: 匯率載入成功或失敗的結果
        case ratesResponse(Result<FxRateSnapshot, APIError>)
    }

    // MARK: - Dependencies

    /// 匯率 API client，與 FxFeature 共用
    @Dependency(ExchangeRateClient.self) private var client

    /// 幣別主檔資料來源；用於畫面出現時載入最新清單
    @Dependency(CurrencyMetadataRepository.self) private var currencyMetadataRepository

    // MARK: - Body

    /// 匯率來源 reducer
    var body: some Reducer<State, Action> {
        Reduce(core)
            .ifLet(\.$destination, action: \.destination)
    }
}

// MARK: - Nested Types

extension QuoteRateFeature {

    /// 匯率來源的呈現目的地
    @Reducer
    enum Destination {

        /// 幣別選擇 sheet
        case currencyPicker
    }
}

// MARK: - Equatable

extension QuoteRateFeature.Destination.State: Equatable {}

// MARK: - Sendable

extension QuoteRateFeature.Destination.State: Sendable {}

// MARK: - Private Method

private extension QuoteRateFeature {

    /// 依收到的事件更新匯率來源狀態，並回傳要執行的 Effect
    ///
    /// - Parameters:
    ///   - state: 目前的匯率來源狀態，直接就地修改
    ///   - action: 這次收到的匯率來源事件
    /// - Returns: 接下來要執行的 Effect，沒有就回 `.none`
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .task:
            guard !state.isLoading else {
                return .none
            }
            let shouldLoadRates = state.snapshot == nil
            if shouldLoadRates {
                state.isLoading = true
                state.errorMessage = nil
            }
            let currencyEffect = loadCurrencyCodes()
            let ratesEffect = shouldLoadRates ? loadRates() : .none
            return .merge(currencyEffect, ratesEffect)

        case .refreshRequested:
            guard !state.isLoading else {
                return .none
            }
            state.isLoading = true
            state.errorMessage = nil
            return loadRates()

        case .pickerTapped:
            state.destination = .currencyPicker
            return .none

        case let .currencySelected(code):
            state.fromCurrency = CurrencyCode(rawValue: code)
            state.destination = nil
            return .none

        case .destination:
            return .none

        case let .currencyCodesResponse(.success(codes)):
            guard !codes.isEmpty else {
                return .none
            }
            var merged = Set(codes)
            merged.insert(state.fromCurrency)
            state.availableCurrencies = merged.sorted { lhs, rhs in
                lhs.rawValue.localizedStandardCompare(rhs.rawValue) == .orderedAscending
            }
            return .none

        case .currencyCodesResponse(.failure):
            return .none

        case let .ratesResponse(.success(snapshot)):
            state.isLoading = false
            state.snapshot = snapshot
            state.errorMessage = nil
            return .none

        case let .ratesResponse(.failure(error)):
            state.isLoading = false
            state.errorMessage = Self.userMessage(for: error)
            return .none
        }
    }

    /// 載入匯率並把成功或失敗合併成單一回應
    ///
    /// - Returns: 匯率載入 effect
    func loadRates() -> Effect<Action> {
        let client = client
        return .run { send in
            do {
                let snapshot = try await client.fetchLatest(.twd)
                await send(.ratesResponse(.success(snapshot)))
            } catch {
                guard let error = error as? APIError else {
                    return
                }
                await send(.ratesResponse(.failure(error)))
            }
        }
    }

    /// 載入幣別主檔並把成功或失敗合併成單一回應
    ///
    /// - Returns: 幣別主檔載入 effect
    func loadCurrencyCodes() -> Effect<Action> {
        let currencyMetadataRepository = currencyMetadataRepository
        return .run { send in
            do {
                let codes = try await currencyMetadataRepository.fetchCodes()
                await send(.currencyCodesResponse(.success(codes)))
            } catch {
                guard let error = error as? CurrencyMetadataRepositoryError else {
                    return
                }
                await send(.currencyCodesResponse(.failure(error)))
            }
        }
    }

    /// 把 ``APIError`` 轉成顯示給使用者的訊息
    ///
    /// - Parameter error: API 錯誤
    /// - Returns: 中文使用者訊息
    static func userMessage(for error: APIError) -> LocalizedStringResource {
        switch error {
        case .invalidKey:
            return "尚未設定 ExchangeRate-API 金鑰，目前無法計算建議售價。"

        case .quotaExceeded:
            return "本月匯率 API 配額已用完，目前無法計算建議售價。"

        case .transport:
            return "網路連線異常，目前無法計算建議售價。"

        case let .http(statusCode):
            return "匯率 API 回應 HTTP \(statusCode)，目前無法計算建議售價。"

        case .decoding:
            return "匯率資料格式異常，目前無法計算建議售價。"

        case let .apiError(code):
            return "匯率 API 回應錯誤 (\(code))，目前無法計算建議售價。"
        }
    }
}
