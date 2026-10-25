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

/// `OrderPercentConversion` 的單元測試，綁定測試以 `Store` 搭配 `@Bindable` 走與畫面相同的寫回路徑
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

    /// 驗證規格範例的百分比先四捨五入到小數點後兩位，再除以一百換算為費率
    ///
    /// - Parameter example: 規格範例與獨立的期望字面值
    /// - Throws: 範例字面值無法建立 `Decimal` 時丟出測試失敗
    @Test(arguments: Self.examples)
    func rate_範例百分比_捨入兩位小數後換算費率(example: ConversionExample) throws {
        // Given
        let entered = try #require(example.entered)
        let expectedRate = try #require(example.stored)

        // When
        let rate = OrderPercentConversion.rate(from: entered)

        // Then
        #expect(rate == expectedRate)
    }

    /// 驗證規格範例的儲存費率換算為百分比後，符合捨入到小數點後兩位的字面值
    ///
    /// - Parameter example: 規格範例與獨立的期望字面值
    /// - Throws: 範例字面值無法建立 `Decimal` 時丟出測試失敗
    @Test(arguments: Self.examples)
    func percentage_範例費率_換算回捨入後的百分比(example: ConversionExample) throws {
        // Given
        let storedRate = try #require(example.stored)
        let expectedPercentage = try #require(example.displayed)

        // When
        let percentage = OrderPercentConversion.percentage(from: storedRate)

        // Then
        #expect(percentage == expectedPercentage)
    }

    /// 驗證三種費率欄透過畫面綁定輸入規格範例時，草稿寫入捨入後的費率、讀回的百分比符合規格，且草稿標為已修改
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

    /// 驗證三種費率欄讀出顯示的百分比再原樣寫回時，不寫入費率欄，草稿內容不變且不標為已修改
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

    /// 驗證負數百分比的中點 (如 -4.565) 向遠離零的方向捨入成 -0.0457，範圍夾限仍由存檔流程處理
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

        /// 草稿中存放此費率的欄位 key path
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
