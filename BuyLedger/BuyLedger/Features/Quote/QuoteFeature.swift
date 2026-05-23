//
//  QuoteFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import Foundation

/// 報價試算工具狀態。
///
/// 將商品本金、運費、刷卡手續費與目標毛利等可調項目集中為 state，view 端透過 slider/picker 即時更新並看到建議售價與獲利拆解。
///
/// 匯率資料透過 ``ExchangeRateClient`` 載入；尚未載入或載入失敗時 `rate` 為 `0`，所有衍生金額一併歸零，view 應顯示載入中或錯誤訊息提醒使用者目前的計算結果不可信任。
@Reducer
struct QuoteFeature {
    
    // MARK: - State
    
    /// 報價試算狀態。
    @ObservableState
    struct State: Equatable, @unchecked Sendable {

        /// 來源幣別。
        var fromCurrency: CurrencyCode
        
        /// 來源幣別下的商品本金。
        var itemPrice: Double
        
        /// 來源幣別下的當地運費。
        var domesticShipping: Double
        
        /// 國際運費 (TWD)。
        var internationalShippingTwd: Double
        
        /// 刷卡手續費 %。
        var cardFeePercent: Double

        /// 金流手續費 %。
        var paymentFeePercent: Double

        /// 平台手續費 %。
        var platformFeePercent: Double

        /// 目標毛利 %。
        var targetMarginPercent: Double
        
        /// 已從 API 取得的匯率快照；`nil` 代表尚未拉取或拉取失敗。
        var snapshot: FxRateSnapshot?
        
        /// 是否正在載入匯率。
        var isLoading: Bool
        
        /// 匯率載入失敗時顯示給使用者的訊息。
        var errorMessage: String?

        /// 可供選擇的幣別清單；由 ``CurrencyMetadataRepository`` 提供。
        var availableCurrencies: [CurrencyCode] = CurrencyCode.defaults
        
        // MARK: - Init
        
        /// 建立預設狀態。
        ///
        /// 所有數值欄位預設為 `0`：報價試算頁開啟時不預填任何示範金額或費率，避免使用者誤以為畫面上的「建議售價」是已存在的試算結果。實際數值由使用者拖動 slider / 輸入後即時運算。
        init(
            fromCurrency: CurrencyCode = .krw,
            itemPrice: Double = 0,
            domesticShipping: Double = 0,
            internationalShippingTwd: Double = 0,
            cardFeePercent: Double = 0,
            paymentFeePercent: Double = 0,
            platformFeePercent: Double = 0,
            targetMarginPercent: Double = 0,
            snapshot: FxRateSnapshot? = nil,
            isLoading: Bool = false,
            errorMessage: String? = nil
        ) {
            self.fromCurrency = fromCurrency
            self.itemPrice = itemPrice
            self.domesticShipping = domesticShipping
            self.internationalShippingTwd = internationalShippingTwd
            self.cardFeePercent = cardFeePercent
            self.paymentFeePercent = paymentFeePercent
            self.platformFeePercent = platformFeePercent
            self.targetMarginPercent = targetMarginPercent
            self.snapshot = snapshot
            self.isLoading = isLoading
            self.errorMessage = errorMessage
        }
        
        // MARK: - Computed Properties
        
        /// 來源幣別的匯率 (1 單位 = X TWD)；無 snapshot 時為 `0`，所有衍生金額會跟著歸零。
        var rate: Double {
            if fromCurrency == .twd { return 1 }
            guard let snapshot else {
                return 0
            }
            if snapshot.base == .twd, let inverse = snapshot.rates[fromCurrency], inverse > 0 {
                return NSDecimalNumber(decimal: Decimal(1) / inverse).doubleValue
            }
            if snapshot.base == fromCurrency, let twd = snapshot.rates[.twd] {
                return NSDecimalNumber(decimal: twd).doubleValue
            }
            return 0
        }
        
        /// 是否已具備可用的匯率資料；view 用此值決定是否顯示「正在載入」或「無法計算」提示。
        var hasUsableRate: Bool {
            rate > 0
        }
        
        /// 商品本金折合 TWD。
        var itemTwd: Double { itemPrice * rate }
        
        /// 當地運費折合 TWD。
        var domesticTwd: Double { domesticShipping * rate }
        
        /// 刷卡手續費 TWD。
        var cardFeeTwd: Double { itemTwd * cardFeePercent / 100 }

        /// 金流手續費 TWD。
        var paymentFeeTwd: Double { itemTwd * paymentFeePercent / 100 }

        /// 平台手續費 TWD。
        var platformFeeTwd: Double { itemTwd * platformFeePercent / 100 }

        /// 總成本 TWD。
        var costTwd: Double {
            itemTwd + domesticTwd + internationalShippingTwd + cardFeeTwd + paymentFeeTwd + platformFeeTwd
        }
        
        /// 建議售價 (無條件進位到 10 元)。
        var suggestedTwd: Double {
            let raw = costTwd * (1 + targetMarginPercent / 100)
            return (raw / 10).rounded(.up) * 10
        }
        
        /// 預估獲利。
        var estimatedProfitTwd: Double { suggestedTwd - costTwd }
        
        /// 預估毛利率 (profit / suggested)。
        var estimatedMarginPercent: Double {
            suggestedTwd == 0 ? 0 : estimatedProfitTwd / suggestedTwd * 100
        }
    }
    
    // MARK: - Action
    
    /// 報價試算事件。
    @CasePathable
    enum Action: BindableAction, Equatable {
        
        /// SwiftUI 雙向繫結。
        case binding(BindingAction<State>)
        
        /// 畫面 onAppear 觸發載入匯率。
        case task
        
        /// 匯率載入成功。
        case ratesLoaded(FxRateSnapshot)
        
        /// 匯率載入失敗。
        case ratesFailed(String)

        /// 從 ``CurrencyMetadataRepository`` 取回最新幣別主檔。
        case availableCurrenciesLoaded([CurrencyCode])
    }
    
    // MARK: - Dependency Properties
    
    /// 匯率 API client (與 ``FxFeature`` 共用同一個 dependency，方便未來改成共享 snapshot)。
    @Dependency(ExchangeRateClient.self) private var client

    /// 幣別主檔資料來源；用於 task 從 cache 拉最新清單。
    @Dependency(CurrencyMetadataRepository.self) private var currencyMetadataRepository
    
    // MARK: - Reducer Body
    
    /// 報價 reducer。
    var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
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
