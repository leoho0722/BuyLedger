//
//  SnapshotTests+Tools.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/5.
//

import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import Testing

@testable import BuyLedger

extension SnapshotTests {

    /// 報價試算填入非零的商品價格與目標毛利時，建議售價卡片與成本拆解都顯示實際數字，不是破折號
    @Test
    func quoteView_非零試算輸入_顯示成本與建議售價() {
        TestDependencies.withFixedNow {
            // Given
            let state = QuoteFeature.State(
                rateSource: QuoteRateFeature.State(
                    fromCurrency: .krw,
                    snapshot: FxRateSnapshot.fallback
                ),
                itemPrice: 100_000,
                domesticShipping: 5_000,
                internationalShippingTWD: 180,
                cardFeePercent: 2.5,
                paymentFeePercent: 1,
                platformFeePercent: 1,
                targetMarginPercent: 25
            )

            let store = Store(initialState: state) {
                QuoteFeature()
            } withDependencies: {
                $0.currencyMetadataService.fetchCodes = { [] }
            }

            // When
            let view = QuoteView(store: store)
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)

            // Then
            assertSnapshot(of: view, as: .image)
        }
    }

    /// 匯率資料裡沒有所選幣別 (韓圓) 的匯率時，報價頁顯示錯誤狀態
    @Test
    func quoteView_沒有可用匯率_顯示錯誤狀態() {
        TestDependencies.withFixedNow {
            // Given
            let unavailableSnapshot = FxRateSnapshot(
                date: Date(timeIntervalSince1970: 0),
                base: .twd,
                rates: [.twd: 1]
            )
            let state = QuoteFeature.State(
                rateSource: QuoteRateFeature.State(
                    fromCurrency: .krw,
                    snapshot: unavailableSnapshot
                )
            )

            let store = Store(initialState: state) {
                QuoteFeature()
            } withDependencies: {
                $0.currencyMetadataService.fetchCodes = { [] }
            }

            // When
            let view = QuoteView(store: store)
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)

            // Then
            assertSnapshot(of: view, as: .image)
        }
    }

    /// 匯率工具已有匯率資料時顯示已連線狀態
    @Test
    func fxView_已載入匯率快照_顯示連線狀態() {
        TestDependencies.withFixedNow {
            // Given
            let state = FxFeature.State(snapshot: FxRateSnapshot.fallback)
            let store = Store<FxFeature.State, FxFeature.Action>(initialState: state) {
                EmptyReducer()
            }

            // When
            let view = FxView(store: store)
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)

            // Then
            assertSnapshot(of: view, as: .image)
        }
    }

    /// 匯率工具在載入失敗時顯示錯誤橫幅與重試鍵
    @Test
    func fxView_匯率載入失敗_顯示錯誤橫幅與重試鍵() {
        TestDependencies.withFixedNow {
            // Given
            let state = FxFeature.State(errorMessage: "fx.rates.message.networkErrorOccurred")
            let store = Store<FxFeature.State, FxFeature.Action>(initialState: state) {
                EmptyReducer()
            }

            // When
            let view = FxView(store: store)
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)

            // Then
            assertSnapshot(of: view, as: .image)
        }
    }
}
