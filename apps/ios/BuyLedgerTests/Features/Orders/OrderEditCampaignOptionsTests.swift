//
//  OrderEditCampaignOptionsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/7.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// 驗證既有訂單與合併確認入口的開團選項，保留已選的收單開團
@MainActor
struct OrderEditCampaignOptionsTests {

    /// 編輯入口只帶入進行中開團，並保留既有訂單的已收單歸屬
    ///
    /// - Parameter testCase: 編輯開團選項案例
    @Test(arguments: Self.campaignOptionCases)
    func list_進行中與已收單開團_保留進行中與既有歸屬(testCase: CampaignOptionCase) async {
        // Given
        let initial = withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
        } operation: {
            OrdersFeature.State()
        }
        let order = LedgerOrder.fixture(id: "ORDER", campaignNames: testCase.assigned)
        initial.$orders.withLock {
            $0 = [order]
        }
        initial.$campaigns.withLock {
            $0 = [
                Campaign.fixture(id: "MAY", name: "May-JP"),
                Campaign.fixture(id: "APRIL", name: "April-KR", status: .closed),
            ]
        }
        if testCase.hasJuneCampaign {
            initial.$campaigns.withLock {
                $0.append(Campaign.fixture(id: "JUNE", name: "June-US"))
            }
        }
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .constant(UUID(0))
        }
        let options = OrderEditOptions(
            orderSources: ["測試來源"],
            paymentMethods: [
                PaymentMethodInfo(
                    name: "測試付款方式",
                    isCardless: false,
                    isBankTransfer: false,
                    isCashOnDelivery: false
                ),
            ],
            campaigns: testCase.expected,
            calendar: TestDependencies.fixedCalendar
        )

        // When
        await store.send(.list(.delegate(.requested(.edit("ORDER"))))) {
            $0.presentation.destination = .edit(
                OrderEditFeature.State(
                    original: order,
                    id: UUID(0),
                    options: options,
                    currentDate: TestDependencies.fixedNow
                )
            )
        }

        // Then
        await store.finish()
        let editor = store.state.presentation.destination?.edit
        #expect(editor?.pickers.options.campaigns == testCase.expected)
        #expect(editor?.draft.campaignNames == testCase.assigned)
        #expect(editor?.isMergeContext == false)
    }

    /// 合併確認保留來源訂單的已收單開團與快取沒有的幣別，排除無關已收單開團
    ///
    /// - Throws: 合併確認表單未建立時由 `#require` 丟出
    @Test
    func presentation_合併確認到期且來源含已收單開團與舊幣別_保留歸屬並提供多選() async throws {
        // Given
        let initial = withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
        } operation: {
            @Shared(.currencyCodes) var currencyCodes: [CurrencyCode]
            $currencyCodes.withLock {
                $0 = [.twd, .jpy, CurrencyCode(rawValue: "EUR")]
            }
            return OrdersFeature.State()
        }
        let primary = LedgerOrder.fixture(
            id: "PRIMARY",
            currency: .krw,
            campaignNames: ["April-KR"]
        )
        let secondary = LedgerOrder.fixture(
            id: "SECONDARY",
            currency: .krw,
            campaignNames: ["May-JP"]
        )
        initial.$orders.withLock {
            $0 = [primary, secondary]
        }
        initial.$campaigns.withLock {
            $0 = [
                Campaign.fixture(id: "MAY", name: "May-JP"),
                Campaign.fixture(id: "APRIL", name: "April-KR", status: .closed),
                Campaign.fixture(id: "MARCH", name: "March-TW", status: .closed),
            ]
        }
        let draft = OrderMerge.makeDraft(
            primary: primary,
            secondary: secondary,
            now: TestDependencies.fixedNow
        ) { _ in false }
        let options = OrderEditOptions(
            orderSources: ["測試來源"],
            paymentMethods: [
                PaymentMethodInfo(
                    name: "測試付款方式",
                    isCardless: false,
                    isBankTransfer: false,
                    isCashOnDelivery: false
                ),
            ],
            campaigns: ["April-KR", "May-JP"],
            currencyCodes: [.twd, .jpy, CurrencyCode(rawValue: "EUR"), .krw],
            calendar: TestDependencies.fixedCalendar
        )
        var prefillDraft = OrderDraft(
            original: nil,
            currentDate: TestDependencies.fixedNow,
            defaultCurrency: .twd
        )
        prefillDraft.customerName = "測試客戶"
        prefillDraft.orderSource = "測試來源"
        prefillDraft.status = .confirmed
        prefillDraft.currency = .krw
        prefillDraft.paymentMethod = "測試付款方式"
        prefillDraft.campaignNames = ["April-KR", "May-JP"]
        let expected = OrderEditFeature.State(
            id: UUID(0),
            options: options,
            currentDate: TestDependencies.fixedNow,
            prefill: OrderEditFeature.State.Prefill(
                draft: prefillDraft,
                mergeSourceIDs: ["PRIMARY", "SECONDARY"],
                keptPhotos: []
            )
        )
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .constant(UUID(0))
        }

        // When
        await store.send(
            .presentation(.delegate(.mergeConfirmationDue(draft: draft, keptPhotos: [])))
        ) {
            $0.presentation.destination = .edit(expected)
        }

        // Then
        await store.finish()
        let editor = try #require(store.state.presentation.destination?.edit)
        #expect(editor.pickers.options.campaigns == ["April-KR", "May-JP"])
        #expect(
            editor.pickers.options.currencyCodes
                == [CurrencyCode(rawValue: "EUR"), .jpy, .krw, .twd]
        )
        #expect(editor.draft.campaignNames == ["April-KR", "May-JP"])
        #expect(editor.isMergeContext)
        #expect(store.state.currencyCodes == [.twd, .jpy, CurrencyCode(rawValue: "EUR")])
    }
}

// MARK: - Nested Types

extension OrderEditCampaignOptionsTests {

    /// 編輯開團選項案例
    struct CampaignOptionCase: Sendable {

        /// 是否另有六月進行中開團
        let hasJuneCampaign: Bool

        /// 既有訂單的開團歸屬
        let assigned: [String]

        /// 除未歸團外可選的開團名稱
        let expected: [String]
    }
}

// MARK: - Private Method

private extension OrderEditCampaignOptionsTests {

    /// 編輯開團選項的字面值案例
    ///
    /// - Note: 只建立值，不存取測試的主執行緒狀態
    nonisolated static var campaignOptionCases: [CampaignOptionCase] {
        [
            CampaignOptionCase(hasJuneCampaign: false, assigned: [], expected: ["May-JP"]),
            CampaignOptionCase(
                hasJuneCampaign: false,
                assigned: ["April-KR"],
                expected: ["April-KR", "May-JP"]
            ),
            CampaignOptionCase(
                hasJuneCampaign: true,
                assigned: [],
                expected: ["June-US", "May-JP"]
            ),
        ]
    }
}
