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

/// `OrderPercentConversion` 的單元測試，綁定測試以 `TestStore` 送出畫面費率欄寫回草稿的 binding action
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

    /// 驗證三種費率欄輸入規格範例時，換算後的費率經整份草稿的 binding action 寫入，
    /// 草稿寫入捨入後的費率、讀回的百分比符合規格，且草稿標為已修改
    ///
    /// - Parameters:
    ///   - example: 規格範例與獨立的期望字面值
    ///   - field: 要驗證的費率欄位
    /// - Throws: 範例字面值無法建立 `Decimal` 時丟出測試失敗
    /// - Note: 畫面把 `$store.draft.<費率欄>` 交給 `percentageBinding(for:)`，巢狀欄位送出的是整個 `draft`；
    ///   測試以記錄寫入的 `Binding` 取得換算結果，再送出相同的 action
    @Test(arguments: Self.examples, RateField.allCases)
    @MainActor
    func percentageBinding_輸入範例百分比_送出捨入後的費率並顯示捨入值(
        example: ConversionExample,
        field: RateField
    ) async throws {
        // Given
        let entered = try #require(example.entered)
        let expectedRate = try #require(example.stored)
        let expectedPercentage = try #require(example.displayed)
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }
        let writtenDraft = LockIsolated(initial.draft)
        let rate = Binding {
            writtenDraft.value[keyPath: field.keyPath]
        } set: { newValue in
            writtenDraft.withValue {
                $0[keyPath: field.keyPath] = newValue
            }
        }
        let percentage = OrderPercentConversion.percentageBinding(for: rate)

        // When
        percentage.wrappedValue = entered
        await store.send(\.binding.draft, writtenDraft.value) {
            $0.draft[keyPath: field.keyPath] = expectedRate
        }

        // Then
        #expect(percentage.wrappedValue == expectedPercentage)
        #expect(store.state.isDirty)
    }

    /// 驗證三種費率欄讀出顯示的百分比再原樣寫回時，不寫入費率欄，草稿內容不變
    ///
    /// - Parameter field: 要驗證的費率欄位
    /// - Throws: 費率字面值無法建立 `Decimal` 時丟出測試失敗
    /// - Note: 沒有寫入就不會送出 binding action，草稿維持開啟時的內容而不標為已修改
    @Test(arguments: RateField.allCases)
    func percentageBinding_讀取後寫回目前顯示值_不寫入費率欄(field: RateField) throws {
        // Given
        var preparedDraft = OrderDraft(original: nil, currentDate: TestDependencies.fixedNow)
        preparedDraft[keyPath: field.keyPath] = try #require(Decimal(string: "0.0456"))
        let draft = preparedDraft
        let currentDraft = LockIsolated(draft)
        let writes = LockIsolated(0)
        let rate = Binding {
            currentDraft.value[keyPath: field.keyPath]
        } set: { newValue in
            writes.withValue {
                $0 += 1
            }
            currentDraft.withValue {
                $0[keyPath: field.keyPath] = newValue
            }
        }
        let percentage = OrderPercentConversion.percentageBinding(for: rate)

        // When
        percentage.wrappedValue = percentage.wrappedValue

        // Then
        #expect(percentage.wrappedValue == Decimal(string: "4.56"))
        #expect(writes.value == 0)
        #expect(currentDraft.value == draft)
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
