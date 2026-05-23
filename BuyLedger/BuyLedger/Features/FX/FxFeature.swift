//
//  FxFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import Foundation

/// 匯率工具：選擇來源幣別與輸入金額，即時換算為 TWD。
///
/// 開啟後背景透過 ``ExchangeRateClient`` 讀取最新匯率快照；若 API key 缺失或 API 失敗，畫面顯示錯誤訊息並把所有匯率字串以「—」呈現，**不再退回到 hardcoded 對照表**——避免使用者誤以為看到的是即時匯率。
@Reducer
struct FxFeature {

    // MARK: - State

    /// 匯率工具狀態。
    @ObservableState
    struct State: Equatable, @unchecked Sendable {

        /// 目前選取的來源幣別。
        var fromCurrency: CurrencyCode

        /// 來源幣別的金額。
        var amount: Decimal

        /// 已從 API 取得的最新匯率快照；`nil` 代表尚未拉取或拉取失敗。
        var snapshot: FxRateSnapshot?

        /// 是否正在發 API 請求。
        var isLoading: Bool

        /// 最新匯率失敗時顯示給使用者的訊息；`nil` 表示沒有錯誤。
        var errorMessage: String?

        /// 可供選擇的幣別清單；由 ``CurrencyMetadataRepository`` 提供。
        var availableCurrencies: [CurrencyCode] = CurrencyCode.defaults

        // MARK: - Init

        /// 建立預設狀態。
        /// - Parameters:
        ///   - fromCurrency: 預設選取的來源幣別。
        ///   - amount: 預設輸入金額。
        ///   - snapshot: 預設最新匯率快照。
        ///   - isLoading: 是否正在載入。
        ///   - errorMessage: 最新匯率錯誤訊息。
        init(
            fromCurrency: CurrencyCode = .krw,
            amount: Decimal = 150_000,
            snapshot: FxRateSnapshot? = nil,
            isLoading: Bool = false,
            errorMessage: String? = nil
        ) {
            self.fromCurrency = fromCurrency
            self.amount = amount
            self.snapshot = snapshot
            self.isLoading = isLoading
            self.errorMessage = errorMessage
        }

        // MARK: - Computed Properties

        /// 來源幣別目前的匯率 (1 單位 = X TWD)；無 snapshot 時為 `nil`。
        var rate: Decimal? {
            displayRate(for: fromCurrency)
        }

        /// 換算後的 TWD 金額；無 snapshot 時為 `nil`。
        var convertedTwd: Decimal? {
            rate.map { amount * $0 }
        }

        /// 任意幣別目前對 TWD 的匯率 (1 單位 = X TWD)。
        ///
        /// 取值順序：(1) 查詢的幣別為 TWD 時直接回 `1`、(2) snapshot.base == .twd 時取 `1 / snapshot.rates[currency]`、(3) snapshot.base 與目標幣別一致時取 `snapshot.rates[.twd]`、(4) 以上都不符或無 snapshot 時回 `nil`，由 view 端顯示「—」。
        ///
        /// View 顯示「即時匯率列表」與「1 X = N TWD」字串時使用，確保 UI 永遠呈現 API 取得的真實匯率，避免使用者誤信過期或假資料。
        /// - Parameter currency: 要查詢的幣別。
        /// - Returns: 對應的 TWD 匯率。
        func displayRate(for currency: CurrencyCode) -> Decimal? {
            if currency == .twd { return 1 }
            guard let snapshot else {
                return nil
            }
            if snapshot.base == .twd, let inverse = snapshot.rates[currency], inverse > 0 {
                return Decimal(1) / inverse
            }
            if snapshot.base == currency, let twd = snapshot.rates[.twd] {
                return twd
            }
            return nil
        }
    }

    // MARK: - Action

    /// 匯率工具事件。
    @CasePathable
    enum Action: BindableAction, Equatable {

        /// SwiftUI 雙向繫結。
        case binding(BindingAction<State>)

        /// 使用者點擊預設金額按鈕。
        case quickAmountTapped(Decimal)

        /// 畫面 onAppear 觸發載入最新匯率。
        case task

        /// 最新匯率載入成功。
        case ratesLoaded(FxRateSnapshot)

        /// 最新匯率載入失敗。
        case ratesFailed(String)

        /// 從 ``CurrencyMetadataRepository`` 取回最新幣別主檔。
        case availableCurrenciesLoaded([CurrencyCode])
    }

    // MARK: - Dependency Properties

    /// 匯率 API client。
    @Dependency(ExchangeRateClient.self) private var client

    /// 幣別主檔資料來源；用於 task 從 cache 拉最新清單。
    @Dependency(CurrencyMetadataRepository.self) private var currencyMetadataRepository

    // MARK: - Reducer Body

    /// 匯率工具 reducer。
    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case let .quickAmountTapped(value):
                state.amount = value
                return .none

            case .task:
                let currencyMetadataRepository = currencyMetadataRepository
                let client = client
                let shouldFetchRates = !state.isLoading
                if shouldFetchRates {
                    state.isLoading = true
                    state.errorMessage = nil
                }

                return .run { send in
                    async let currenciesTask: Void = {
                        if let codes = try? await currencyMetadataRepository.fetchCodes(), !codes.isEmpty {
                            await send(.availableCurrenciesLoaded(codes))
                        }
                    }()

                    if shouldFetchRates {
                        do {
                            let snapshot = try await client.fetchLatest(.twd)
                            await send(.ratesLoaded(snapshot))
                        } catch let error as APIError {
                            await send(.ratesFailed(Self.userMessage(for: error)))
                        } catch {
                            await send(.ratesFailed("匯率載入失敗，請稍後再試。"))
                        }
                    }

                    _ = await currenciesTask
                }

            case let .ratesLoaded(snapshot):
                state.isLoading = false
                state.snapshot = snapshot
                state.errorMessage = nil
                return .none

            case let .ratesFailed(message):
                state.isLoading = false
                state.errorMessage = message
                return .none

            case let .availableCurrenciesLoaded(codes):
                var merged = Set(codes)
                merged.insert(state.fromCurrency)
                state.availableCurrencies = merged.sorted {
                    $0.rawValue.localizedStandardCompare($1.rawValue) == .orderedAscending
                }
                return .none
            }
        }
    }

    // MARK: - Private Method

    /// 把 ``APIError`` 轉成顯示給使用者的訊息。
    /// - Parameter error: API 錯誤。
    /// - Returns: 中文使用者訊息。
    private static func userMessage(for error: APIError) -> String {
        switch error {
        case .invalidKey:
            return "尚未設定 ExchangeRate-API 金鑰；無法顯示即時匯率。"
        case .quotaExceeded:
            return "本月匯率 API 配額已用完；無法顯示即時匯率。"
        case .transport:
            return "網路連線異常；無法顯示即時匯率，請稍後再試。"
        case let .http(statusCode):
            return "匯率 API 回應 HTTP \(statusCode)；無法顯示即時匯率。"
        case .decoding:
            return "匯率資料格式異常；無法顯示即時匯率。"
        case let .apiError(code):
            return "匯率 API 回應錯誤 (\(code))；無法顯示即時匯率。"
        }
    }
}
