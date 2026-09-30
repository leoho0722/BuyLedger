//
//  FxFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import Foundation

/// 匯率工具：選擇來源幣別與輸入金額，即時換算為 TWD
@Reducer
struct FxFeature {

    // MARK: - State

    /// 匯率工具狀態
    @ObservableState
    struct State: Equatable, Sendable {

        /// 目前選取的來源幣別
        var fromCurrency: CurrencyCode = .krw

        /// 來源幣別的金額
        var amount: Decimal = 150_000

        /// 已從網路取得的最新匯率快照；`nil` 代表尚未取得或取得失敗
        var snapshot: FxRateSnapshot?

        /// 是否正在載入最新匯率
        var isLoading: Bool = false

        /// 最新匯率失敗時顯示給使用者的訊息；`nil` 表示沒有錯誤
        var errorMessage: LocalizedStringResource?

        /// 可供選擇的幣別清單；由 ``CurrencyMetadataService`` 提供
        var availableCurrencies: [CurrencyCode] = CurrencyCode.defaults

        /// 金額欄位是否取得鍵盤焦點
        var isAmountFieldFocused: Bool = false

        /// 目前呈現中的幣別選擇流程；`nil` 表示未呈現
        @Presents var destination: Destination.State?

        /// 來源幣別目前的匯率 (1 單位 = X TWD)；無 `snapshot` 時為 `nil`
        var rate: Decimal? {
            displayRate(for: fromCurrency)
        }

        /// 換算後的 TWD 金額；無 `snapshot` 時為 `nil`
        var convertedTWD: Decimal? {
            rate.map { amount * $0 }
        }

        /// 即時匯率列表要顯示的幣別，不包含新台幣
        var ratesListCurrencies: [CurrencyCode] {
            availableCurrencies.filter { $0 != .twd }
        }

        /// 任意幣別目前對 TWD 的匯率 (1 單位 = X TWD)
        ///
        /// - Parameter currency: 要查詢的幣別
        /// - Returns: 對應的 TWD 匯率；查無匯率時為 `nil`
        func displayRate(for currency: CurrencyCode) -> Decimal? {
            if currency == .twd {
                return 1
            }
            return snapshot?.twdRate(for: currency)
        }
    }

    // MARK: - Action

    /// 匯率工具事件
    @CasePathable
    enum Action: BindableAction {

        /// SwiftUI 雙向繫結
        ///
        /// - Parameter action: 要寫入匯率工具狀態的繫結變更
        case binding(BindingAction<State>)

        /// 使用者可直接操作的匯率工具事件
        ///
        /// - Parameter action: 使用者在匯率工具畫面執行的操作
        case view(View)

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

        /// 匯率工具畫面事件
        @CasePathable
        enum View {

            /// 畫面出現時載入匯率與幣別清單
            case task

            /// 使用者要求重新載入匯率與幣別清單
            case retryTapped

            /// 使用者點擊預設金額按鈕
            ///
            /// - Parameter amount: 要套用的預設金額
            case quickAmountTapped(Decimal)

            /// 使用者點擊來源幣別按鈕，開啟幣別選擇 sheet
            case currencyPickerTapped

            /// 使用者在幣別選擇 sheet 選定來源幣別
            ///
            /// - Parameter code: 使用者選定的 ISO code 字串
            case currencySelected(String)
        }
    }

    // MARK: - Dependencies

    /// 取得以新台幣計價的最新匯率；畫面出現與重新載入時使用
    @Dependency(\.exchangeRateService) private var exchangeRateService

    /// 幣別主檔資料來源；用於畫面出現與重新載入時取得最新清單
    @Dependency(\.currencyMetadataService) private var currencyMetadataService

    // MARK: - Body

    /// 組合雙向繫結、匯率工具自己的邏輯 (`core(state:action:)`) 與幣別選擇流程
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce(core)
            .ifLet(\.$destination, action: \.destination)
    }
}

// MARK: - Nested Types

extension FxFeature {

    /// 匯率工具的呈現目的地
    @Reducer
    enum Destination {

        /// 幣別選擇 sheet
        case currencyPicker
    }
}

// MARK: - Equatable

extension FxFeature.Destination.State: Equatable {}

// MARK: - Sendable

extension FxFeature.Destination.State: Sendable {}

// MARK: - Private Method

private extension FxFeature {

    /// 依收到的事件更新匯率工具狀態，並回傳要執行的 Effect
    ///
    /// - Parameters:
    ///   - state: 目前的匯率工具狀態，直接就地修改
    ///   - action: 這次收到的匯率工具事件
    /// - Returns: 接下來要執行的 Effect，沒有就回 `.none`
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .binding:
            return .none

        case .view(.task), .view(.retryTapped):
            guard !state.isLoading else {
                return .none
            }
            state.isLoading = true
            state.errorMessage = nil
            return loadRatesAndCurrencies()

        case .view(.quickAmountTapped(let amount)):
            state.amount = amount
            return .none

        case .view(.currencyPickerTapped):
            state.destination = .currencyPicker
            return .none

        case .view(.currencySelected(let code)):
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
            return "尚未設定 ExchangeRate-API 金鑰；無法顯示即時匯率。"

        case .quotaExceeded:
            return "本月匯率 API 配額已用完；無法顯示即時匯率。"

        case .transport:
            return "網路連線異常；無法顯示即時匯率，請稍後再試。"

        case .http(let statusCode):
            return "匯率 API 回應 HTTP \(statusCode)；無法顯示即時匯率。"

        case .decoding:
            return "匯率資料格式異常；無法顯示即時匯率。"

        case .apiError(let code):
            return "匯率 API 回應錯誤 (\(code))；無法顯示即時匯率。"
        }
    }

    /// 載入最新匯率與幣別主檔
    ///
    /// - Returns: 匯率與幣別主檔載入 effect
    func loadRatesAndCurrencies() -> Effect<Action> {
        let exchangeRateService = exchangeRateService
        let currencyMetadataService = currencyMetadataService
        return .run { send in
            do {
                let codes = try await currencyMetadataService.fetchCodes()
                await send(.currencyCodesResponse(.success(codes)))
            } catch {
                if let error = error as? CurrencyMetadataServiceError {
                    await send(.currencyCodesResponse(.failure(error)))
                }
            }

            do {
                let snapshot = try await exchangeRateService.fetchLatest(.twd)
                await send(.ratesResponse(.success(snapshot)))
            } catch {
                guard let error = error as? APIError else {
                    return
                }
                await send(.ratesResponse(.failure(error)))
            }
        }
    }
}
