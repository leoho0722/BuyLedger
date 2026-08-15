//
//  QuoteFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import Foundation

/// 報價試算工具狀態
@Reducer
struct QuoteFeature {
    
    // MARK: - State
    
    /// 報價試算狀態
    @ObservableState
    struct State: Equatable, Sendable {
        
        /// 來源幣別
        var fromCurrency: CurrencyCode = .krw
        
        /// 來源幣別下的商品本金
        var itemPrice: Decimal = 0
        
        /// 來源幣別下的當地運費
        var domesticShipping: Decimal = 0
        
        /// 國際運費 (TWD)
        var internationalShippingTwd: Decimal = 0
        
        /// 刷卡手續費 %
        var cardFeePercent: Decimal = 0
        
        /// 金流手續費 %
        var paymentFeePercent: Decimal = 0
        
        /// 平台手續費 %
        var platformFeePercent: Decimal = 0
        
        /// 目標毛利 %
        var targetMarginPercent: Decimal = 0
        
        /// 已從 API 取得的匯率快照；`nil` 代表尚未拉取或拉取失敗
        var snapshot: FxRateSnapshot?
        
        /// 是否正在載入匯率
        var isLoading: Bool = false
        
        /// 匯率載入失敗時顯示給使用者的訊息
        var errorMessage: LocalizedStringResource?
        
        /// 可供選擇的幣別清單；由 ``CurrencyMetadataRepository`` 提供
        var availableCurrencies: [CurrencyCode] = CurrencyCode.defaults
        
        /// 金額欄位是否取得鍵盤焦點
        var isAmountFieldFocused: Bool = false
        
        /// 是否顯示幣別選擇 sheet
        var showsCurrencySheet: Bool = false
        
        // MARK: - Computed Properties
        
        /// 來源幣別對 TWD 的匯率；無資料時為 `0`
        var rate: Decimal {
            if fromCurrency == .twd { return 1 }
            guard let snapshot else {
                return 0
            }
            if snapshot.base == .twd, let inverse = snapshot.rates[fromCurrency], inverse > 0 {
                return Decimal(1) / inverse
            }
            if snapshot.base == fromCurrency, let twd = snapshot.rates[.twd] {
                return twd
            }
            return 0
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
        
        /// 商品本金折合 TWD
        var itemTwd: Decimal { itemPrice * rate }
        
        /// 當地運費折合 TWD
        var domesticTwd: Decimal { domesticShipping * rate }
        
        /// 刷卡手續費 TWD
        var cardFeeTwd: Decimal { itemTwd * cardFeePercent / 100 }
        
        /// 金流手續費 TWD
        var paymentFeeTwd: Decimal { itemTwd * paymentFeePercent / 100 }
        
        /// 平台手續費 TWD
        var platformFeeTwd: Decimal { itemTwd * platformFeePercent / 100 }
        
        /// 總成本 TWD
        var costTwd: Decimal {
            itemTwd + domesticTwd + internationalShippingTwd + cardFeeTwd + paymentFeeTwd
            + platformFeeTwd
        }
        
        /// 目標毛利是否低於 100%；只有低於 100% 才能計算售價
        var isTargetMarginBelowOneHundredPercent: Bool {
            targetMarginPercent < 100
        }
        
        /// 建議售價：成本除以 (1 − 目標毛利)，無條件進位到 10 元
        var suggestedTwd: Decimal? {
            guard isTargetMarginBelowOneHundredPercent else {
                return nil
            }
            let raw = costTwd / (1 - targetMarginPercent / 100)
            var rounded = Decimal()
            var source = raw / 10
            NSDecimalRound(&rounded, &source, 0, .up)
            return rounded * 10
        }
        
        /// 預估獲利；``suggestedTwd`` 為 `nil` 時一併為 `nil`
        var estimatedProfitTwd: Decimal? {
            guard let suggestedTwd else {
                return nil
            }
            return suggestedTwd - costTwd
        }
        
        /// 預估毛利率；無建議售價時為 nil
        var estimatedMarginPercent: Decimal? {
            guard let suggestedTwd, let estimatedProfitTwd, suggestedTwd != 0 else {
                return nil
            }
            return estimatedProfitTwd / suggestedTwd * 100
        }
    }
    
    // MARK: - Action
    
    /// 報價試算事件
    @CasePathable
    enum Action: BindableAction, Equatable {
        
        /// SwiftUI 雙向繫結
        case binding(BindingAction<State>)
        
        /// 畫面 onAppear 觸發載入匯率
        case task
        
        /// 使用者在匯率載入失敗時要求重新載入
        case rateRefreshRequested
        
        /// 匯率載入成功
        case ratesLoaded(FxRateSnapshot)
        
        /// 匯率載入失敗
        case ratesFailed(LocalizedStringResource)
        
        /// 從 ``CurrencyMetadataRepository`` 取回最新幣別主檔
        case availableCurrenciesLoaded([CurrencyCode])
        
        /// 點擊來源幣別列，開啟幣別選擇 sheet
        case currencyPickerTapped
        
        /// 使用者於幣別選擇 sheet 選定來源幣別
        case fromCurrencySelected(String)
    }
    
    // MARK: - Dependency Properties
    
    /// 匯率 API client，與 FxFeature 共用
    @Dependency(ExchangeRateClient.self) private var client
    
    /// 幣別主檔資料來源；用於 task 從 cache 拉最新清單
    @Dependency(CurrencyMetadataRepository.self) private var currencyMetadataRepository
    
    // MARK: - Reducer Body
    
    /// 報價 reducer
    var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                // BindingReducer 後統一把數值限制為非負
                // 目標毛利僅保證非負、不設上限
                state.itemPrice = max(0, state.itemPrice)
                state.domesticShipping = max(0, state.domesticShipping)
                state.internationalShippingTwd = max(0, state.internationalShippingTwd)
                state.cardFeePercent = max(0, state.cardFeePercent)
                state.paymentFeePercent = max(0, state.paymentFeePercent)
                state.platformFeePercent = max(0, state.platformFeePercent)
                state.targetMarginPercent = max(0, state.targetMarginPercent)
                return .none
                
            case .task:
                let currencyMetadataRepository = currencyMetadataRepository
                let client = client
                let shouldFetchRates = !state.isLoading && state.snapshot == nil
                if shouldFetchRates {
                    state.isLoading = true
                    state.errorMessage = nil
                }
                
                return .run { send in
                    async let currenciesTask: Void = {
                        do {
                            let codes = try await currencyMetadataRepository.fetchCodes()
                            if !codes.isEmpty {
                                await send(.availableCurrenciesLoaded(codes))
                            }
                        } catch {
                            // 幣別主檔是輔助資料，載入失敗時保留目前清單
                        }
                    }()
                    
                    if shouldFetchRates {
                        await Self.loadRates(client: client, send: send)
                    }
                    
                    _ = await currenciesTask
                }
                
            case .rateRefreshRequested:
                guard !state.isLoading else { return .none }
                state.isLoading = true
                state.errorMessage = nil
                let client = client
                
                return .run { send in
                    await Self.loadRates(client: client, send: send)
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
                
            case .currencyPickerTapped:
                state.showsCurrencySheet = true
                return .none
                
            case let .fromCurrencySelected(code):
                state.fromCurrency = CurrencyCode(rawValue: code)
                return .none
            }
        }
    }
}

// MARK: - Private Method

private extension QuoteFeature {
    
    /// 載入匯率並處理成功或失敗結果
    /// - Parameters:
    ///   - client: 匯率 API client
    ///   - send: 目前 effect 的 send，用於派送載入結果
    static func loadRates(client: ExchangeRateClient, send: Send<Action>) async {
        do {
            let snapshot = try await client.fetchLatest(.twd)
            await send(.ratesLoaded(snapshot))
        } catch {
            await send(.ratesFailed(Self.userMessage(for: error)))
        }
    }
    
    /// 把 ``APIError`` 轉成顯示給使用者的訊息
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
