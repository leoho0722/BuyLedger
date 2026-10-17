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

        /// 目前選取的來源幣別
        var fromCurrency: CurrencyCode = .krw

        /// 已從網路取得的匯率快照；`nil` 代表尚未取得或取得失敗
        var snapshot: FxRateSnapshot?

        /// 是否正在載入匯率
        var isLoading: Bool = false

        /// 匯率載入失敗時顯示給使用者的訊息
        var errorMessage: LocalizedStringResource?

        /// 可供選擇的幣別清單；由 ``CurrencyMetadataService`` 提供
        var availableCurrencies: [CurrencyCode] = CurrencyCode.defaults

        /// 目前呈現中的幣別選擇流程；`nil` 表示未呈現
        @Presents var destination: Destination.State?

        /// 來源幣別對 TWD 的匯率；無資料時為 `0`
        var rate: Decimal {
            fromCurrency == .twd ? 1 : snapshot?.twdRate(for: fromCurrency) ?? 0
        }

        /// 匯率大於 `0` 才算可用，決定能不能算出建議售價
        var hasUsableRate: Bool {
            rate > 0
        }

        /// 匯率不可用時顯示的原因
        var rateUnavailableReason: LocalizedStringResource? {
            guard !isLoading, !hasUsableRate else {
                return nil
            }
            return errorMessage ?? "quote.calculator.message.exchangeRateAvailable"
        }

        /// 幣別選擇清單使用的 ISO code 字串，順序與 ``availableCurrencies`` 相同
        var availableCurrencyCodes: [String] {
            availableCurrencies.map(\.rawValue)
        }
    }

    // MARK: - Action

    /// 匯率來源事件
    ///
    /// - Note: 本 Feature 沒有自己的 View，事件一律由 ``QuoteFeature`` 轉送，因此不設 `view` 分組
    @CasePathable
    enum Action {

        /// 畫面出現時載入幣別清單；尚無匯率快照時一併載入匯率
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
        /// - Parameter result: 成功帶回幣別清單，失敗帶回錯誤
        case currencyCodesResponse(Result<[CurrencyCode], CurrencyMetadataServiceError>)

        /// 匯率載入結果
        ///
        /// - Parameter result: 成功帶回匯率快照，失敗帶回錯誤
        case ratesResponse(Result<FxRateSnapshot, APIError>)
    }

    // MARK: - Dependencies

    /// 取得以新台幣計價的最新匯率，與 `FxFeature` 共用；畫面出現時尚無匯率快照、或要求重新載入時使用
    @Dependency(\.exchangeRateService) private var exchangeRateService

    /// 幣別主檔資料來源；用於畫面出現時載入最新清單
    @Dependency(\.currencyMetadataService) private var currencyMetadataService

    // MARK: - Body

    /// 只負責組合 reducer：匯率來源自己的邏輯在 `core(state:action:)`，另接上幣別選擇流程
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

extension QuoteRateFeature.Destination.State: Equatable {

}

// MARK: - Sendable

extension QuoteRateFeature.Destination.State: Sendable {

}

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
            return loadOnAppear(state: &state)

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

        case .currencySelected(let code):
            state.fromCurrency = CurrencyCode(rawValue: code)
            state.destination = nil
            return .none

        case .destination:
            return .none

        case .currencyCodesResponse(.success(let codes)):
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

        case .ratesResponse(.success(let snapshot)):
            state.isLoading = false
            state.snapshot = snapshot
            state.errorMessage = nil
            return .none

        case .ratesResponse(.failure(let error)):
            state.isLoading = false
            state.errorMessage = Self.userMessage(for: error)
            return .none
        }
    }

    /// 把 ``APIError`` 轉成顯示給使用者的訊息
    ///
    /// - Parameter error: 載入匯率時的失敗原因
    /// - Returns: 依 App 語言顯示給使用者的錯誤訊息
    static func userMessage(for error: APIError) -> LocalizedStringResource {
        switch error {
        case .invalidKey:
            return "quote.calculator.message.exchangeRateApiKeyMissing"

        case .quotaExceeded:
            return "quote.calculator.message.monthsExchangerateApi"

        case .transport:
            return "quote.calculator.message.networkErrorOccurred"

        case .http(let statusCode):
            return LocalizedStringResource(
                "quote.calculator.message.httpErrorCode",
                defaultValue: "\(statusCode)"
            )

        case .decoding:
            return "quote.calculator.message.exchangerateDataInvalid"

        case .apiError(let code):
            return LocalizedStringResource(
                "quote.calculator.message.apiErrorCode",
                defaultValue: "\(code)"
            )
        }
    }

    /// 畫面出現時載入幣別清單，尚無匯率快照時一併載入匯率
    ///
    /// - Parameter state: 要更新的匯率來源狀態；尚無快照時改為載入中並清除舊的失敗訊息
    /// - Returns: 幣別清單與匯率的合併 Effect；正在載入中時為 `.none`
    func loadOnAppear(state: inout State) -> Effect<Action> {
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
    }

    /// 載入幣別主檔並把成功或失敗合併成單一回應
    ///
    /// - Returns: 幣別主檔載入 effect
    func loadCurrencyCodes() -> Effect<Action> {
        let currencyMetadataService = currencyMetadataService
        return .run { send in
            do throws(CurrencyMetadataServiceError) {
                let codes = try await currencyMetadataService.fetchCodes()
                await send(.currencyCodesResponse(.success(codes)))
            } catch {
                await send(.currencyCodesResponse(.failure(error)))
            }
        }
    }

    /// 載入匯率並把成功或失敗合併成單一回應
    ///
    /// - Returns: 匯率載入 effect
    func loadRates() -> Effect<Action> {
        let exchangeRateService = exchangeRateService
        return .run { send in
            do throws(APIError) {
                let snapshot = try await exchangeRateService.fetchLatest(.twd)
                await send(.ratesResponse(.success(snapshot)))
            } catch {
                await send(.ratesResponse(.failure(error)))
            }
        }
    }
}
