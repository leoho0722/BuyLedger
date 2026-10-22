//
//  OrderPercentConversionTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/7.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

/// 驗證費率換算與畫面使用的百分比綁定，避免精度遺失或未編輯就寫回草稿
struct OrderPercentConversionTests {

    // MARK: - Properties

    /// 規格範例的輸入百分比、儲存費率與再次顯示的百分比
    private static let examples: [ConversionExample] = [
        ConversionExample(
            entered: Decimal(string: "4.56"),
            stored: Decimal(string: "0.0456"),
            displayed: Decimal(string: "4.56")
        ),
        ConversionExample(
            entered: Decimal(string: "1.5"),
            stored: Decimal(string: "0.015"),
            displayed: Decimal(string: "1.5")
        ),
        ConversionExample(
            entered: Decimal(string: "2.8"),
            stored: Decimal(string: "0.028"),
            displayed: Decimal(string: "2.8")
        ),
        ConversionExample(
            entered: Decimal(string: "4.567"),
            stored: Decimal(string: "0.0457"),
            displayed: Decimal(string: "4.57")
        ),
        ConversionExample(
            entered: Decimal(string: "4.565"),
            stored: Decimal(string: "0.0457"),
            displayed: Decimal(string: "4.57")
        ),
    ]

    /// 費率範例全程以十進位換算，超過兩位小數時先捨入百分比
    ///
    /// - Parameter example: 規格範例與獨立的期望字面值
    /// - Throws: 範例字面值無法建立 `Decimal` 時丟出測試失敗
    @Test(arguments: Self.examples)
    func rate_範例百分比_精確儲存並顯示捨入值(example: ConversionExample) throws {
        // Given
        let entered = try #require(example.entered)
        let expectedRate = try #require(example.stored)
        let expectedPercentage = try #require(example.displayed)

        // When
        let rate = OrderPercentConversion.rate(from: entered)
        let percentage = OrderPercentConversion.percentage(from: rate)

        // Then
        #expect(rate == expectedRate)
        #expect(percentage == expectedPercentage)
    }

    /// 三種費率欄都經畫面相同的綁定入口寫入，讀取時顯示規格指定的值
    ///
    /// - Parameters:
    ///   - example: 規格範例與獨立的期望字面值
    ///   - field: 要驗證的費率欄位
    /// - Throws: 範例字面值無法建立 `Decimal` 時丟出測試失敗
    @Test(arguments: Self.examples, RateField.allCases)
    @MainActor
    func percentageBinding_經畫面綁定輸入範例_精確寫回並顯示捨入值(
        example: ConversionExample,
        field: RateField
    ) throws {
        // Given
        let entered = try #require(example.entered)
        let expectedRate = try #require(example.stored)
        let expectedPercentage = try #require(example.displayed)
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = Store(initialState: initial) {
            OrderEditFeature()
        }
        @Bindable var bindable = store
        let rate = $bindable.draft[dynamicMember: field.keyPath]
        let percentage = OrderPercentConversion.percentageBinding(for: rate)

        // When
        percentage.wrappedValue = entered

        // Then
        #expect(store.draft[keyPath: field.keyPath] == expectedRate)
        #expect(percentage.wrappedValue == expectedPercentage)
        #expect(store.state.isDirty)
    }

    /// 只讀取並寫回目前顯示值時，不傳遞寫入也不讓草稿變成已修改
    ///
    /// - Parameter field: 要驗證的費率欄位
    /// - Throws: 費率字面值無法建立 `Decimal` 時丟出測試失敗
    @Test(arguments: RateField.allCases)
    @MainActor
    func percentageBinding_讀取後寫回目前顯示值_草稿不變且未修改(field: RateField) throws {
        // Given
        var draft = OrderDraft(original: nil, currentDate: TestDependencies.fixedNow)
        draft[keyPath: field.keyPath] = try #require(Decimal(string: "0.0456"))
        let initial = OrderEditFeature.State(
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            prefill: .init(draft: draft, mergeSourceIDs: [], keptPhotos: [])
        )
        let store = Store(initialState: initial) {
            OrderEditFeature()
        }
        @Bindable var bindable = store
        let rate = $bindable.draft[dynamicMember: field.keyPath]
        let writes = LockIsolated(0)
        let observedRate = Binding {
            rate.wrappedValue
        } set: { newValue in
            writes.withValue {
                $0 += 1
            }
            rate.wrappedValue = newValue
        }
        let percentage = OrderPercentConversion.percentageBinding(for: observedRate)

        // When
        percentage.wrappedValue = percentage.wrappedValue

        // Then
        #expect(percentage.wrappedValue == Decimal(string: "4.56"))
        #expect(writes.value == 0)
        #expect(store.draft == initial.draft)
        #expect(store.state.isDirty == false)
    }

    /// 負數百分比的中點同樣向遠離零的方向捨入，範圍夾限仍由存檔流程處理
    ///
    /// - Throws: 百分比字面值無法建立 `Decimal` 時丟出測試失敗
    @Test
    func rate_負百分比中點_捨入方向遠離零() throws {
        // Given
        let entered = try #require(Decimal(string: "-4.565"))

        // When
        let rate = OrderPercentConversion.rate(from: entered)

        // Then
        #expect(rate == Decimal(string: "-0.0457"))
    }
}

// MARK: - Nested Types

extension OrderPercentConversionTests {

    /// 單列規格範例，預期值由十進位字面值建立
    struct ConversionExample: Sendable {

        /// 使用者輸入的百分比
        let entered: Decimal?

        /// 規格要求儲存的比例值
        let stored: Decimal?

        /// 規格要求再次顯示的百分比
        let displayed: Decimal?
    }

    /// 共用百分比輸入欄的三種費率
    enum RateField: CaseIterable, Sendable {

        /// 刷卡手續費
        case cardFee

        /// 平台手續費
        case platformFee

        /// 收款手續費
        case paymentFee

        /// 對應畫面巢狀草稿綁定的費率欄位
        var keyPath: WritableKeyPath<OrderDraft, Decimal> {
            switch self {
            case .cardFee:
                \.cardFeeRate

            case .platformFee:
                \.platformFeeRate

            case .paymentFee:
                \.paymentFeeRate
            }
        }
    }
}
