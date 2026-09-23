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

        /// 匯率與來源幣別，由 ``QuoteRateFeature`` 維護
        var rateSource = QuoteRateFeature.State()

        /// 來源幣別下的商品本金
        var itemPrice: Decimal = 0

        /// 來源幣別下的當地運費
        var domesticShipping: Decimal = 0

        /// 國際運費 (TWD)
        var internationalShippingTWD: Decimal = 0

        /// 刷卡手續費 %
        var cardFeePercent: Decimal = 0

        /// 金流手續費 %
        var paymentFeePercent: Decimal = 0

        /// 平台手續費 %
        var platformFeePercent: Decimal = 0

        /// 目標毛利 %
        var targetMarginPercent: Decimal = 0

        /// 金額欄位是否取得鍵盤焦點
        var isAmountFieldFocused: Bool = false

        /// 商品本金折合 TWD
        var itemTWD: Decimal {
            itemPrice * rateSource.rate
        }

        /// 當地運費折合 TWD
        var domesticTWD: Decimal {
            domesticShipping * rateSource.rate
        }

        /// 刷卡手續費 TWD
        var cardFeeTWD: Decimal {
            itemTWD * cardFeePercent / 100
        }

        /// 金流手續費 TWD
        var paymentFeeTWD: Decimal {
            itemTWD * paymentFeePercent / 100
        }

        /// 平台手續費 TWD
        var platformFeeTWD: Decimal {
            itemTWD * platformFeePercent / 100
        }

        /// 總成本 TWD
        var costTWD: Decimal {
            itemTWD
                + domesticTWD
                + internationalShippingTWD
                + cardFeeTWD
                + paymentFeeTWD
                + platformFeeTWD
        }

        /// 目標毛利是否低於 100%；只有低於 100% 才能計算售價
        var isTargetMarginBelowOneHundredPercent: Bool {
            targetMarginPercent < 100
        }

        /// 建議售價：成本除以 (1 − 目標毛利)，無條件進位到 10 元
        var suggestedTWD: Decimal? {
            guard isTargetMarginBelowOneHundredPercent else {
                return nil
            }
            let raw = costTWD / (1 - targetMarginPercent / 100)
            var rounded = Decimal()
            var source = raw / 10
            NSDecimalRound(&rounded, &source, 0, .up)
            return rounded * 10
        }

        /// 預估獲利；``suggestedTWD`` 為 `nil` 時一併為 `nil`
        var estimatedProfitTWD: Decimal? {
            guard let suggestedTWD else {
                return nil
            }
            return suggestedTWD - costTWD
        }

        /// 預估毛利率；無建議售價時為 `nil`
        var estimatedMarginPercent: Decimal? {
            guard let suggestedTWD, let estimatedProfitTWD, suggestedTWD != 0 else {
                return nil
            }
            return estimatedProfitTWD / suggestedTWD * 100
        }

        /// 預覽與畫面使用的建議售價；無可用匯率或無法計算時為 `nil`
        var displayedSuggestedTWD: Decimal? {
            guard rateSource.hasUsableRate else {
                return nil
            }
            return suggestedTWD
        }

        /// 建議售價 hero 卡下方要顯示的訊息種類
        var heroMessage: HeroMessage {
            guard rateSource.hasUsableRate else {
                return .rateUnavailable
            }
            guard let estimatedProfitTWD, let estimatedMarginPercent else {
                return .marginTooHigh
            }
            return .estimate(
                profitTWD: estimatedProfitTWD,
                marginPercent: estimatedMarginPercent
            )
        }
    }

    // MARK: - Action

    /// 報價試算事件
    @CasePathable
    enum Action: BindableAction {

        /// SwiftUI 雙向繫結
        ///
        /// - Parameter action: 要寫入報價試算狀態的繫結變更
        case binding(BindingAction<State>)

        /// 使用者可直接操作的報價試算事件
        ///
        /// - Parameter action: 使用者在報價試算畫面執行的操作
        case view(View)

        /// 匯率來源事件
        ///
        /// - Parameter action: ``QuoteRateFeature`` 的事件
        case rateSource(QuoteRateFeature.Action)

        /// 報價試算畫面事件
        @CasePathable
        enum View {

            /// 畫面出現時載入匯率與幣別清單
            case task

            /// 使用者要求重新載入匯率
            case retryTapped

            /// 使用者點擊來源幣別按鈕，開啟幣別選擇 sheet
            case currencyPickerTapped

            /// 使用者在幣別選擇 sheet 選定來源幣別
            ///
            /// - Parameter code: 使用者選定的 ISO code 字串
            case currencySelected(String)
        }
    }

    // MARK: - Body

    /// 報價 reducer
    var body: some Reducer<State, Action> {
        BindingReducer()

        Scope(state: \.rateSource, action: \.rateSource) {
            QuoteRateFeature()
        }

        Reduce(core)
    }
}

// MARK: - Nested Types

extension QuoteFeature {

    /// 報價試算畫面的 hero 提示種類
    enum HeroMessage: Equatable, Sendable {

        /// 沒有可用匯率資料，無法計算預估獲利
        case rateUnavailable

        /// 顯示預估獲利與預估毛利率
        ///
        /// - Parameters:
        ///   - profitTWD: 預估獲利
        ///   - marginPercent: 預估毛利率
        case estimate(profitTWD: Decimal, marginPercent: Decimal)

        /// 無法計算預估獲利，包含目標毛利過高或售價為零的情形
        case marginTooHigh
    }
}

// MARK: - Private Method

private extension QuoteFeature {

    /// 依收到的事件更新報價狀態，並回傳要執行的 Effect
    ///
    /// - Parameters:
    ///   - state: 目前的報價試算狀態，直接就地修改
    ///   - action: 這次收到的報價試算事件
    /// - Returns: 接下來要執行的 Effect，沒有就回 `.none`
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .binding:
            state.itemPrice = max(0, state.itemPrice)
            state.domesticShipping = max(0, state.domesticShipping)
            state.internationalShippingTWD = max(0, state.internationalShippingTWD)
            state.cardFeePercent = max(0, state.cardFeePercent)
            state.paymentFeePercent = max(0, state.paymentFeePercent)
            state.platformFeePercent = max(0, state.platformFeePercent)
            state.targetMarginPercent = max(0, state.targetMarginPercent)
            return .none

        case .view(.task):
            return .send(.rateSource(.task))

        case .view(.retryTapped):
            return .send(.rateSource(.refreshRequested))

        case .view(.currencyPickerTapped):
            return .send(.rateSource(.pickerTapped))

        case let .view(.currencySelected(code)):
            return .send(.rateSource(.currencySelected(code)))

        case .rateSource:
            return .none
        }
    }
}
